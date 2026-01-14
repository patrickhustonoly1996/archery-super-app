import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';

/// Timer phases for bow training
enum TimerPhase {
  idle,           // Not started
  leadIn,         // 10 second countdown before first hold
  hold,           // Holding at draw
  rest,           // Resting between reps
  exerciseBreak,  // Transition between exercises
  midBlockBreak,  // Break in middle of a block
  complete,       // Session finished
}

/// Lead-in duration in seconds before holds start
const int kLeadInSeconds = 10;

/// A training block preset that can be dragged to build custom sessions
class TrainingBlock {
  final String id;
  final String name;
  final int durationMinutes;
  final int holdSeconds;
  final int restSeconds;
  final int? breakAtMinutes; // Optional mid-block break
  final int breakDurationSeconds;
  final TrainingBlock? alternateVariant; // For toggleable blocks
  final bool isAlternate;

  const TrainingBlock({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.holdSeconds,
    required this.restSeconds,
    this.breakAtMinutes,
    this.breakDurationSeconds = 60,
    this.alternateVariant,
    this.isAlternate = false,
  });

  /// Create a copy with alternate variant applied
  TrainingBlock withAlternate() {
    if (alternateVariant == null) return this;
    return alternateVariant!;
  }

  /// Calculate number of reps for this block
  int get totalReps {
    final cycleSeconds = holdSeconds + restSeconds;
    if (cycleSeconds <= 0) return 0;
    final totalSeconds = durationMinutes * 60;
    return totalSeconds ~/ cycleSeconds;
  }

  /// Format timing as "hold:rest"
  String get timingLabel => '$holdSeconds:$restSeconds';

  /// Copy with new ID for instance tracking
  TrainingBlock copyWithNewId() {
    return TrainingBlock(
      id: '${id}_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      durationMinutes: durationMinutes,
      holdSeconds: holdSeconds,
      restSeconds: restSeconds,
      breakAtMinutes: breakAtMinutes,
      breakDurationSeconds: breakDurationSeconds,
      alternateVariant: alternateVariant,
      isAlternate: isAlternate,
    );
  }
}

/// Default training block presets
class TrainingBlockPresets {
  static const patrickWarmUp = TrainingBlock(
    id: 'patrick_warmup',
    name: "Patrick's Warm Up",
    durationMinutes: 5,
    holdSeconds: 30,
    restSeconds: 30,
  );

  static const standardFitnessBlock = TrainingBlock(
    id: 'standard_fitness',
    name: 'Standard Fitness Block',
    durationMinutes: 10,
    holdSeconds: 20,
    restSeconds: 40,
    breakAtMinutes: 5,
    breakDurationSeconds: 60,
    alternateVariant: TrainingBlock(
      id: 'standard_fitness_alt',
      name: 'Standard Fitness Block',
      durationMinutes: 10,
      holdSeconds: 35,
      restSeconds: 35,
      breakAtMinutes: 5,
      breakDurationSeconds: 60,
      isAlternate: true,
    ),
  );

  static const introductionVolume = TrainingBlock(
    id: 'intro_volume',
    name: 'Introduction Volume',
    durationMinutes: 5,
    holdSeconds: 15,
    restSeconds: 45,
  );

  static const introductionFitnessBlock = TrainingBlock(
    id: 'intro_fitness',
    name: 'Introduction Fitness Block',
    durationMinutes: 10,
    holdSeconds: 15,
    restSeconds: 45,
  );

  static List<TrainingBlock> get all => [
    patrickWarmUp,
    standardFitnessBlock,
    introductionVolume,
    introductionFitnessBlock,
  ];
}

/// Internal exercise representation for custom sessions
class _CustomExercise {
  final String name;
  final int reps;
  final int workSeconds;
  final int restSeconds;
  final String? details;
  final bool isBreak;

  const _CustomExercise({
    required this.name,
    required this.reps,
    required this.workSeconds,
    required this.restSeconds,
    this.details,
    this.isBreak = false,
  });
}

/// State of the timer
enum TimerState {
  stopped,
  running,
  paused,
}

class BowTrainingProvider extends ChangeNotifier {
  final AppDatabase _db;

  BowTrainingProvider(this._db);

  // ===========================================================================
  // CACHED DATA
  // ===========================================================================

  List<OlySessionTemplate> _sessionTemplates = [];
  List<OlySessionTemplate> get sessionTemplates => _sessionTemplates;

  Map<String, OlyExerciseType> _exerciseTypesMap = {};
  List<OlyTrainingLog> _recentLogs = [];
  List<OlyTrainingLog> get recentLogs => _recentLogs;

  UserTrainingProgressData? _userProgress;
  UserTrainingProgressData? get userProgress => _userProgress;

  // ===========================================================================
  // CUSTOM SESSION BUILDER STATE
  // ===========================================================================

  /// Preset blocks available to drag
  List<TrainingBlock> get presetBlocks => TrainingBlockPresets.all;

  /// Blocks added to current custom session (with toggle state)
  final List<({TrainingBlock block, bool useAlternate})> _customSessionBlocks = [];
  List<({TrainingBlock block, bool useAlternate})> get customSessionBlocks => List.unmodifiable(_customSessionBlocks);

  /// Get total duration of custom session in minutes
  int get customSessionDuration {
    return _customSessionBlocks.fold(0, (sum, entry) {
      final block = entry.useAlternate ? entry.block.withAlternate() : entry.block;
      return sum + block.durationMinutes;
    });
  }

  /// Add a block to custom session
  void addBlockToSession(TrainingBlock block) {
    _customSessionBlocks.add((block: block.copyWithNewId(), useAlternate: false));
    notifyListeners();
  }

  /// Remove a block from custom session by index
  void removeBlockFromSession(int index) {
    if (index >= 0 && index < _customSessionBlocks.length) {
      _customSessionBlocks.removeAt(index);
      notifyListeners();
    }
  }

  /// Reorder blocks in custom session
  void reorderBlocks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _customSessionBlocks.removeAt(oldIndex);
    _customSessionBlocks.insert(newIndex, item);
    notifyListeners();
  }

  /// Toggle a block's alternate variant
  void toggleBlockVariant(int index) {
    if (index >= 0 && index < _customSessionBlocks.length) {
      final entry = _customSessionBlocks[index];
      if (entry.block.alternateVariant != null) {
        _customSessionBlocks[index] = (block: entry.block, useAlternate: !entry.useAlternate);
        notifyListeners();
      }
    }
  }

  /// Clear all blocks from custom session
  void clearCustomSession() {
    _customSessionBlocks.clear();
    notifyListeners();
  }

  // ===========================================================================
  // CUSTOM SESSION EXECUTION
  // ===========================================================================

  /// Build and start a custom session from the current blocks
  void startCustomSession() {
    if (_customSessionBlocks.isEmpty) return;

    // Build custom exercises from blocks
    _customExercises = [];
    for (final entry in _customSessionBlocks) {
      final block = entry.useAlternate ? entry.block.withAlternate() : entry.block;
      _customExercises.addAll(_buildExercisesFromBlock(block));
    }

    if (_customExercises.isEmpty) return;

    // Start session with lead-in countdown
    _isCustomSession = true;
    _customSessionName = _buildCustomSessionName();
    _currentExerciseIndex = 0;
    _currentRep = 1;
    _phase = TimerPhase.leadIn; // Start with lead-in countdown
    _timerState = TimerState.running;
    _secondsRemaining = kLeadInSeconds;
    _sessionStartedAt = DateTime.now();
    _totalHoldSecondsActual = 0;
    _totalRestSecondsActual = 0;
    _completedExercises = 0;

    _startTimer();
    _playStartBeep();
    notifyListeners();
  }

  List<_CustomExercise> _buildExercisesFromBlock(TrainingBlock block) {
    final exercises = <_CustomExercise>[];
    final cycleSeconds = block.holdSeconds + block.restSeconds;
    if (cycleSeconds <= 0) return exercises;

    final totalSeconds = block.durationMinutes * 60;
    final totalReps = totalSeconds ~/ cycleSeconds;

    // Calculate reps before and after break
    int repsBeforeBreak = totalReps;
    int repsAfterBreak = 0;

    if (block.breakAtMinutes != null && block.breakAtMinutes! < block.durationMinutes) {
      final secondsBeforeBreak = block.breakAtMinutes! * 60;
      repsBeforeBreak = secondsBeforeBreak ~/ cycleSeconds;
      repsAfterBreak = totalReps - repsBeforeBreak;
    }

    // Add exercise for first segment
    if (repsBeforeBreak > 0) {
      exercises.add(_CustomExercise(
        name: block.name,
        reps: repsBeforeBreak,
        workSeconds: block.holdSeconds,
        restSeconds: block.restSeconds,
        details: '${block.holdSeconds}s hold / ${block.restSeconds}s rest',
      ));
    }

    // Add break if configured
    if (block.breakAtMinutes != null && repsAfterBreak > 0) {
      exercises.add(_CustomExercise(
        name: 'Break',
        reps: 1,
        workSeconds: block.breakDurationSeconds,
        restSeconds: 0,
        details: '${block.breakDurationSeconds}s recovery',
        isBreak: true,
      ));

      // Add exercise for second segment
      exercises.add(_CustomExercise(
        name: block.name,
        reps: repsAfterBreak,
        workSeconds: block.holdSeconds,
        restSeconds: block.restSeconds,
        details: '${block.holdSeconds}s hold / ${block.restSeconds}s rest',
      ));
    }

    return exercises;
  }

  String _buildCustomSessionName() {
    if (_customSessionBlocks.length == 1) {
      return _customSessionBlocks.first.block.name;
    }
    return 'Custom Session (${_customSessionBlocks.length} blocks)';
  }

  // Custom session tracking
  bool _isCustomSession = false;
  bool get isCustomSession => _isCustomSession;

  String _customSessionName = '';
  String get customSessionName => _customSessionName;

  List<_CustomExercise> _customExercises = [];

  /// Get current exercise for custom session
  _CustomExercise? get currentCustomExercise {
    if (!_isCustomSession || _customExercises.isEmpty) return null;
    if (_currentExerciseIndex >= _customExercises.length) return null;
    return _customExercises[_currentExerciseIndex];
  }

  /// Get total custom exercises count
  int get totalCustomExercises => _customExercises.length;

  // ===========================================================================
  // ACTIVE SESSION STATE
  // ===========================================================================

  OlySessionTemplate? _activeSession;
  OlySessionTemplate? get activeSession => _activeSession;

  List<OlySessionExercise> _exercises = [];
  List<OlySessionExercise> get exercises => _exercises;

  int _currentExerciseIndex = 0;
  int get currentExerciseIndex => _currentExerciseIndex;

  int _currentRep = 0;
  int get currentRep => _currentRep;

  TimerPhase _phase = TimerPhase.idle;
  TimerPhase get phase => _phase;

  TimerState _timerState = TimerState.stopped;
  TimerState get timerState => _timerState;

  int _secondsRemaining = 0;
  int get secondsRemaining => _secondsRemaining;

  // Session tracking
  DateTime? _sessionStartedAt;
  int _totalHoldSecondsActual = 0;
  int _totalRestSecondsActual = 0;
  int _completedExercises = 0;

  Timer? _timer;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  OlySessionExercise? get currentExercise {
    if (_isCustomSession) return null; // Use currentCustomExercise instead
    if (_exercises.isEmpty || _currentExerciseIndex >= _exercises.length) {
      return null;
    }
    return _exercises[_currentExerciseIndex];
  }

  OlyExerciseType? get currentExerciseType {
    if (_isCustomSession) return null;
    final exercise = currentExercise;
    if (exercise == null) return null;
    return _exerciseTypesMap[exercise.exerciseTypeId];
  }

  String get currentExerciseName {
    if (_isCustomSession) {
      return currentCustomExercise?.name ?? 'Unknown';
    }
    return currentExerciseType?.name ?? 'Unknown';
  }

  String? get currentExerciseDetails {
    if (_isCustomSession) {
      return currentCustomExercise?.details;
    }
    return currentExercise?.details;
  }

  int get currentExerciseNumber => _currentExerciseIndex + 1;

  int get totalExercises {
    if (_isCustomSession) return _customExercises.length;
    return _exercises.length;
  }

  int get currentExerciseReps {
    if (_isCustomSession) {
      return currentCustomExercise?.reps ?? 0;
    }
    return currentExercise?.reps ?? 0;
  }

  /// Get the active session name (OLY template or custom)
  String get activeSessionName {
    if (_isCustomSession) return _customSessionName;
    return _activeSession?.name ?? '';
  }

  /// Check if current exercise is a break (custom sessions only)
  bool get isCurrentExerciseBreak {
    if (!_isCustomSession) return false;
    return currentCustomExercise?.isBreak ?? false;
  }

  bool get isActive => _timerState != TimerState.stopped;

  int get totalHoldSecondsActual => _totalHoldSecondsActual;
  int get completedExercisesCount => _completedExercises;

  // ===========================================================================
  // DATA LOADING
  // ===========================================================================

  /// Load all session templates, exercise types, and user progress
  Future<void> loadData() async {
    await _db.ensureUserTrainingProgressExists();
    await _db.ensureOlyTrainingDataExists();

    _sessionTemplates = await _db.getAllOlySessionTemplates();
    _recentLogs = await _db.getRecentOlyTrainingLogs(limit: 5);
    _userProgress = await _db.getUserTrainingProgress();

    // Load exercise types into a map for quick lookup
    final exerciseTypes = await _db.getAllOlyExerciseTypes();
    _exerciseTypesMap = {for (var et in exerciseTypes) et.id: et};

    notifyListeners();
  }

  /// Get sessions grouped by level (1.x, 2.x)
  Map<String, List<OlySessionTemplate>> get sessionsByLevel {
    final grouped = <String, List<OlySessionTemplate>>{};
    for (final session in _sessionTemplates) {
      final level = session.version.split('.').first;
      grouped.putIfAbsent('Level $level', () => []).add(session);
    }
    return grouped;
  }

  /// Get the suggested next session based on user progress
  OlySessionTemplate? get suggestedSession {
    if (_userProgress == null || _sessionTemplates.isEmpty) return null;

    return _sessionTemplates.firstWhere(
      (s) => s.version == _userProgress!.currentLevel,
      orElse: () => _sessionTemplates.first,
    );
  }

  // ===========================================================================
  // SESSION CONTROLS
  // ===========================================================================

  /// Start a new OLY training session
  Future<void> startSession(OlySessionTemplate template) async {
    _activeSession = template;
    _exercises = await _db.getOlySessionExercises(template.id);

    if (_exercises.isEmpty) {
      // No exercises - shouldn't happen but handle gracefully
      _activeSession = null;
      return;
    }

    _currentExerciseIndex = 0;
    _currentRep = 1;
    _phase = TimerPhase.leadIn; // Start with lead-in countdown
    _timerState = TimerState.running;
    _secondsRemaining = kLeadInSeconds;
    _sessionStartedAt = DateTime.now();
    _totalHoldSecondsActual = 0;
    _totalRestSecondsActual = 0;
    _completedExercises = 0;

    _startTimer();
    _playStartBeep();
    notifyListeners();
  }

  /// Pause the timer
  void pauseTimer() {
    if (_timerState != TimerState.running) return;
    _timer?.cancel();
    _timerState = TimerState.paused;
    notifyListeners();
  }

  /// Resume a paused timer
  void resumeTimer() {
    if (_timerState != TimerState.paused) return;
    _timerState = TimerState.running;
    _startTimer();
    notifyListeners();
  }

  /// Skip to the next phase
  void skipPhase() {
    if (_timerState == TimerState.stopped) return;
    _advancePhase();
  }

  /// Stop and discard the current session
  void cancelSession() {
    _timer?.cancel();
    _resetState();
    notifyListeners();
  }

  /// Complete the session and log it with feedback
  Future<void> completeSession({
    int? feedbackShaking,
    int? feedbackStructure,
    int? feedbackRest,
    String? notes,
  }) async {
    if (_sessionStartedAt == null) return;

    // Custom sessions - just reset without logging to OLY progression
    if (_isCustomSession) {
      // For custom sessions, we could log to a separate table in the future
      // For now, just reset
      _resetState();
      notifyListeners();
      return;
    }

    // OLY session logging
    if (_activeSession == null) return;

    // Calculate progression suggestion
    final suggestion = _calculateProgressionSuggestion(
      feedbackShaking: feedbackShaking,
      feedbackStructure: feedbackStructure,
      feedbackRest: feedbackRest,
    );

    final log = OlyTrainingLogsCompanion.insert(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      sessionTemplateId: Value(_activeSession!.id),
      sessionVersion: _activeSession!.version,
      sessionName: _activeSession!.name,
      plannedDurationSeconds: _activeSession!.durationMinutes * 60,
      actualDurationSeconds: DateTime.now().difference(_sessionStartedAt!).inSeconds,
      plannedExercises: _exercises.length,
      completedExercises: _completedExercises,
      totalHoldSeconds: _totalHoldSecondsActual,
      totalRestSeconds: _totalRestSecondsActual,
      feedbackShaking: Value(feedbackShaking),
      feedbackStructure: Value(feedbackStructure),
      feedbackRest: Value(feedbackRest),
      progressionSuggestion: Value(suggestion.suggestion),
      suggestedNextVersion: Value(suggestion.nextVersion),
      notes: Value(notes),
      startedAt: _sessionStartedAt!,
      completedAt: DateTime.now(),
    );

    await _db.insertOlyTrainingLog(log);

    // Update user progress
    await _db.updateProgressAfterSession(
      completedVersion: _activeSession!.version,
      suggestedNextVersion: suggestion.nextVersion,
      progressionSuggestion: suggestion.suggestion,
    );

    await loadData(); // Refresh data
    _resetState();
    notifyListeners();
  }

  // ===========================================================================
  // TIMER LOGIC
  // ===========================================================================

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  void _tick() {
    if (_timerState != TimerState.running) return;

    // Track actual time
    if (_phase == TimerPhase.hold) {
      _totalHoldSecondsActual++;
    } else if (_phase == TimerPhase.rest || _phase == TimerPhase.exerciseBreak) {
      _totalRestSecondsActual++;
    }

    _secondsRemaining--;

    if (_secondsRemaining <= 0) {
      _advancePhase();
    } else if (_secondsRemaining <= 3) {
      // Countdown beeps for last 3 seconds
      _playTickBeep();
    }

    notifyListeners();
  }

  void _advancePhase() {
    // Handle custom session
    if (_isCustomSession) {
      _advancePhaseCustom();
      return;
    }

    final exercise = currentExercise;
    if (exercise == null || _activeSession == null) return;

    switch (_phase) {
      case TimerPhase.leadIn:
        // Lead-in complete - start first hold
        _phase = TimerPhase.hold;
        _secondsRemaining = exercise.workSeconds;
        _playHoldBeep();
        break;

      case TimerPhase.hold:
        // Finished a hold rep
        if (_currentRep < exercise.reps) {
          // More reps to go - start rest
          if (exercise.restSeconds > 0) {
            _phase = TimerPhase.rest;
            _secondsRemaining = exercise.restSeconds;
            _playRestBeep();
          } else {
            // No rest - go directly to next rep
            _currentRep++;
            _secondsRemaining = exercise.workSeconds;
            _playHoldBeep();
          }
        } else {
          // Finished all reps for this exercise
          _completedExercises++;

          if (_currentExerciseIndex < _exercises.length - 1) {
            // More exercises - transition to next
            _phase = TimerPhase.exerciseBreak;
            _secondsRemaining = 3; // 3 second transition
            _playExerciseCompleteBeep();
          } else {
            // Session complete
            _timer?.cancel();
            _phase = TimerPhase.complete;
            _timerState = TimerState.stopped;
            _playCompleteSound();
          }
        }
        break;

      case TimerPhase.rest:
        // Finished resting - start next rep
        _currentRep++;
        _phase = TimerPhase.hold;
        _secondsRemaining = exercise.workSeconds;
        _playHoldBeep();
        break;

      case TimerPhase.exerciseBreak:
        // Transition complete - start next exercise
        _currentExerciseIndex++;
        _currentRep = 1;
        _phase = TimerPhase.hold;
        final nextExercise = currentExercise;
        _secondsRemaining = nextExercise?.workSeconds ?? 0;
        _playHoldBeep();
        break;

      case TimerPhase.idle:
      case TimerPhase.complete:
      case TimerPhase.midBlockBreak:
        // No-op for OLY sessions
        break;
    }

    notifyListeners();
  }

  void _advancePhaseCustom() {
    final exercise = currentCustomExercise;
    if (exercise == null) return;

    switch (_phase) {
      case TimerPhase.leadIn:
        // Lead-in complete - start first hold or break
        if (exercise.isBreak) {
          _phase = TimerPhase.midBlockBreak;
        } else {
          _phase = TimerPhase.hold;
        }
        _secondsRemaining = exercise.workSeconds;
        if (exercise.isBreak) {
          _playRestBeep();
        } else {
          _playHoldBeep();
        }
        break;

      case TimerPhase.hold:
      case TimerPhase.midBlockBreak:
        // Finished a hold/break rep
        if (_currentRep < exercise.reps) {
          // More reps to go - start rest
          if (exercise.restSeconds > 0) {
            _phase = TimerPhase.rest;
            _secondsRemaining = exercise.restSeconds;
            _playRestBeep();
          } else {
            // No rest - go directly to next rep
            _currentRep++;
            _secondsRemaining = exercise.workSeconds;
            _playHoldBeep();
          }
        } else {
          // Finished all reps for this exercise
          _completedExercises++;

          if (_currentExerciseIndex < _customExercises.length - 1) {
            // More exercises - transition to next
            _phase = TimerPhase.exerciseBreak;
            _secondsRemaining = 3; // 3 second transition
            _playExerciseCompleteBeep();
          } else {
            // Session complete
            _timer?.cancel();
            _phase = TimerPhase.complete;
            _timerState = TimerState.stopped;
            _playCompleteSound();
          }
        }
        break;

      case TimerPhase.rest:
        // Finished resting - start next rep
        _currentRep++;
        _phase = TimerPhase.hold;
        _secondsRemaining = exercise.workSeconds;
        _playHoldBeep();
        break;

      case TimerPhase.exerciseBreak:
        // Transition complete - start next exercise
        _currentExerciseIndex++;
        _currentRep = 1;
        final nextExercise = currentCustomExercise;
        if (nextExercise != null) {
          _phase = nextExercise.isBreak ? TimerPhase.midBlockBreak : TimerPhase.hold;
          _secondsRemaining = nextExercise.workSeconds;
          if (nextExercise.isBreak) {
            _playRestBeep();
          } else {
            _playHoldBeep();
          }
        }
        break;

      case TimerPhase.idle:
      case TimerPhase.complete:
        // No-op
        break;
    }

    notifyListeners();
  }

  void _resetState() {
    _timer?.cancel();
    _activeSession = null;
    _exercises = [];
    _currentExerciseIndex = 0;
    _currentRep = 0;
    _phase = TimerPhase.idle;
    _timerState = TimerState.stopped;
    _secondsRemaining = 0;
    _sessionStartedAt = null;
    _totalHoldSecondsActual = 0;
    _totalRestSecondsActual = 0;
    _completedExercises = 0;
    // Custom session state
    _isCustomSession = false;
    _customSessionName = '';
    _customExercises = [];
  }

  // ===========================================================================
  // PROGRESSION LOGIC
  // ===========================================================================

  ({String suggestion, String? nextVersion}) _calculateProgressionSuggestion({
    int? feedbackShaking,
    int? feedbackStructure,
    int? feedbackRest,
  }) {
    if (_activeSession == null) {
      return (suggestion: 'repeat', nextVersion: null);
    }

    final currentVersion = _activeSession!.version;

    // Calculate completion rate
    final completionRate = _exercises.isNotEmpty
        ? _completedExercises / _exercises.length
        : 0.0;

    // If feedback is not provided, suggest repeat
    if (feedbackShaking == null ||
        feedbackStructure == null ||
        feedbackRest == null) {
      return (suggestion: 'repeat', nextVersion: currentVersion);
    }

    final avgScore = (feedbackShaking + feedbackStructure + feedbackRest) / 3;
    final maxScore = [feedbackShaking, feedbackStructure, feedbackRest]
        .reduce((a, b) => a > b ? a : b);

    // Regress conditions
    if (completionRate < 0.7 || maxScore > 7 || avgScore > 6) {
      final previousVersion = _getPreviousVersion(currentVersion);
      return (suggestion: 'regress', nextVersion: previousVersion);
    }

    // Progress conditions
    if (avgScore < 4 && completionRate >= 1.0) {
      final nextVersion = _getNextVersion(currentVersion);
      return (suggestion: 'progress', nextVersion: nextVersion);
    }

    // Default: repeat
    return (suggestion: 'repeat', nextVersion: currentVersion);
  }

  String _getNextVersion(String current) {
    final parts = current.split('.');
    if (parts.length != 2) return current;

    final major = int.tryParse(parts[0]) ?? 1;
    final minor = int.tryParse(parts[1]) ?? 0;

    // Find next available version
    final nextMinor = '$major.${minor + 1}';
    final nextMajor = '${major + 1}.0';

    // Check if next minor exists
    if (_sessionTemplates.any((s) => s.version == nextMinor)) {
      return nextMinor;
    }
    // Check if next major exists
    if (_sessionTemplates.any((s) => s.version == nextMajor)) {
      return nextMajor;
    }

    return current; // Stay at current if no next version
  }

  String _getPreviousVersion(String current) {
    final parts = current.split('.');
    if (parts.length != 2) return current;

    final major = int.tryParse(parts[0]) ?? 1;
    final minor = int.tryParse(parts[1]) ?? 0;

    if (minor > 0) {
      return '$major.${minor - 1}';
    } else if (major > 1) {
      // Find highest minor in previous major
      final prevMajorSessions = _sessionTemplates
          .where((s) => s.version.startsWith('${major - 1}.'))
          .toList();
      if (prevMajorSessions.isNotEmpty) {
        prevMajorSessions.sort((a, b) => b.version.compareTo(a.version));
        return prevMajorSessions.first.version;
      }
    }

    return '1.0'; // Minimum version
  }

  // ===========================================================================
  // AUDIO FEEDBACK
  // ===========================================================================

  void _playStartBeep() {
    HapticFeedback.heavyImpact();
  }

  void _playHoldBeep() {
    HapticFeedback.heavyImpact();
  }

  void _playRestBeep() {
    HapticFeedback.mediumImpact();
  }

  void _playExerciseCompleteBeep() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });
  }

  void _playTickBeep() {
    HapticFeedback.selectionClick();
  }

  void _playCompleteSound() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.heavyImpact();
    });
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  /// Get formatted time string (MM:SS)
  String get formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get phase display name
  String get phaseDisplayName {
    switch (_phase) {
      case TimerPhase.idle:
        return 'Ready';
      case TimerPhase.leadIn:
        return 'Get Ready';
      case TimerPhase.hold:
        return 'HOLD';
      case TimerPhase.rest:
        return 'Rest';
      case TimerPhase.exerciseBreak:
        return 'Next Exercise';
      case TimerPhase.midBlockBreak:
        return 'BREAK';
      case TimerPhase.complete:
        return 'Complete';
    }
  }

  /// Get progress within current phase (0.0 to 1.0)
  double get phaseProgress {
    int totalSeconds;

    // Handle lead-in phase
    if (_phase == TimerPhase.leadIn) {
      return 1 - (_secondsRemaining / kLeadInSeconds);
    }

    if (_isCustomSession) {
      final exercise = currentCustomExercise;
      if (exercise == null) return 0;

      switch (_phase) {
        case TimerPhase.hold:
        case TimerPhase.midBlockBreak:
          totalSeconds = exercise.workSeconds;
          break;
        case TimerPhase.rest:
          totalSeconds = exercise.restSeconds;
          break;
        case TimerPhase.exerciseBreak:
          totalSeconds = 3;
          break;
        default:
          return 0;
      }
    } else {
      final exercise = currentExercise;
      if (exercise == null) return 0;

      switch (_phase) {
        case TimerPhase.hold:
          totalSeconds = exercise.workSeconds;
          break;
        case TimerPhase.rest:
          totalSeconds = exercise.restSeconds;
          break;
        case TimerPhase.exerciseBreak:
          totalSeconds = 3;
          break;
        default:
          return 0;
      }
    }

    if (totalSeconds <= 0) return 1.0;
    return 1 - (_secondsRemaining / totalSeconds);
  }

  /// Get overall session progress (0.0 to 1.0)
  double get sessionProgress {
    if (_isCustomSession) {
      if (_customExercises.isEmpty) return 0;

      int totalReps = _customExercises.fold(0, (sum, e) => sum + e.reps);
      if (totalReps == 0) return 0;

      int completedReps = 0;
      for (int i = 0; i < _currentExerciseIndex; i++) {
        completedReps += _customExercises[i].reps;
      }
      completedReps += _currentRep - 1; // Current rep in progress

      return completedReps / totalReps;
    }

    if (_exercises.isEmpty) return 0;

    int totalReps = _exercises.fold(0, (sum, e) => sum + e.reps);
    if (totalReps == 0) return 0;

    int completedReps = 0;
    for (int i = 0; i < _currentExerciseIndex; i++) {
      completedReps += _exercises[i].reps;
    }
    completedReps += _currentRep - 1; // Current rep in progress

    return completedReps / totalReps;
  }

  /// Format duration for display
  static String formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) {
      return '$minutes min${seconds > 0 ? ' $seconds sec' : ''}';
    }
    return '$seconds sec';
  }

  /// Get intensity for current exercise (from exercise type or override)
  double get currentExerciseIntensity {
    final exercise = currentExercise;
    if (exercise == null) return 1.0;

    if (exercise.intensityOverride != null) {
      return exercise.intensityOverride!;
    }

    return currentExerciseType?.intensity ?? 1.0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
