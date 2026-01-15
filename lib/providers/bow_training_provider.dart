import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../services/firestore_sync_service.dart';

/// Timer phases for bow training
enum TimerPhase {
  idle,           // Not started
  hold,           // Holding at draw
  rest,           // Resting between reps
  exerciseBreak,  // Transition between exercises
  complete,       // Session finished
}

/// State of the timer
enum TimerState {
  stopped,
  running,
  paused,
}

/// Movement stimulus intensity for custom sessions
enum MovementStimulus {
  none,
  some,
  lots,
}

/// Hold:Rest ratio options (in seconds)
class HoldRestRatio {
  final int holdSeconds;
  final int restSeconds;
  final String label;

  const HoldRestRatio(this.holdSeconds, this.restSeconds, this.label);

  static const ratio15_45 = HoldRestRatio(15, 45, '15:45');
  static const ratio20_40 = HoldRestRatio(20, 40, '20:40');
  static const ratio25_35 = HoldRestRatio(25, 35, '25:35');
  static const ratio30_30 = HoldRestRatio(30, 30, '30:30');

  static const List<HoldRestRatio> all = [
    ratio15_45,
    ratio20_40,
    ratio25_35,
    ratio30_30,
  ];
}

/// Custom session configuration
class CustomSessionConfig {
  final int durationMinutes;
  final HoldRestRatio ratio;
  final MovementStimulus movementStimulus;

  const CustomSessionConfig({
    required this.durationMinutes,
    required this.ratio,
    required this.movementStimulus,
  });

  /// Patrick's default warm-up: 5 minutes at 30:30
  static const defaultWarmUp = CustomSessionConfig(
    durationMinutes: 5,
    ratio: HoldRestRatio.ratio30_30,
    movementStimulus: MovementStimulus.none,
  );

  /// Calculate number of reps that fit in the duration
  int get totalReps {
    final cycleSeconds = ratio.holdSeconds + ratio.restSeconds;
    final totalSeconds = durationMinutes * 60;
    return totalSeconds ~/ cycleSeconds;
  }

  String get displayName => '${durationMinutes}min @ ${ratio.label}';
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

  // Custom session state
  CustomSessionConfig? _customConfig;
  CustomSessionConfig? get customConfig => _customConfig;
  int _customTotalReps = 0;
  int _customCurrentRep = 0;
  String? _currentMovementCue;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  OlySessionExercise? get currentExercise {
    if (_exercises.isEmpty || _currentExerciseIndex >= _exercises.length) {
      return null;
    }
    return _exercises[_currentExerciseIndex];
  }

  OlyExerciseType? get currentExerciseType {
    final exercise = currentExercise;
    if (exercise == null) return null;
    return _exerciseTypesMap[exercise.exerciseTypeId];
  }

  String get currentExerciseName {
    return currentExerciseType?.name ?? 'Unknown';
  }

  String? get currentExerciseDetails {
    return currentExercise?.details;
  }

  int get currentExerciseNumber => _currentExerciseIndex + 1;
  int get totalExercises => _exercises.length;

  int get currentExerciseReps => currentExercise?.reps ?? 0;

  bool get isActive => _timerState != TimerState.stopped;

  int get totalHoldSecondsActual => _totalHoldSecondsActual;
  int get completedExercisesCount => _completedExercises;

  bool get isCustomSession => _customConfig != null;
  String? get movementCue => _currentMovementCue;
  int get customRep => _customCurrentRep;
  int get customTotalReps => _customTotalReps;

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
    _phase = TimerPhase.hold;
    _timerState = TimerState.running;
    _secondsRemaining = _exercises.first.workSeconds;
    _sessionStartedAt = DateTime.now();
    _totalHoldSecondsActual = 0;
    _totalRestSecondsActual = 0;
    _completedExercises = 0;

    _startTimer();
    _playStartBeep();
    notifyListeners();
  }

  /// Start a custom training session
  void startCustomSession(CustomSessionConfig config) {
    _customConfig = config;
    _activeSession = null;
    _exercises = [];
    _customTotalReps = config.totalReps;
    _customCurrentRep = 1;
    _currentExerciseIndex = 0;
    _currentRep = 1;
    _phase = TimerPhase.hold;
    _timerState = TimerState.running;
    _secondsRemaining = config.ratio.holdSeconds;
    _sessionStartedAt = DateTime.now();
    _totalHoldSecondsActual = 0;
    _totalRestSecondsActual = 0;
    _completedExercises = 0;

    // Generate initial movement cue if enabled
    _updateMovementCue();

    _startTimer();
    _playStartBeep();
    notifyListeners();
  }

  /// Update movement cue based on stimulus setting
  void _updateMovementCue() {
    if (_customConfig == null) {
      _currentMovementCue = null;
      return;
    }

    switch (_customConfig!.movementStimulus) {
      case MovementStimulus.none:
        _currentMovementCue = null;
        break;
      case MovementStimulus.some:
        // Occasional cues - 30% chance
        if (_shouldShowCue(0.3)) {
          _currentMovementCue = _generateMovementCue();
        } else {
          _currentMovementCue = null;
        }
        break;
      case MovementStimulus.lots:
        // Frequent cues - always show
        _currentMovementCue = _generateMovementCue();
        break;
    }
  }

  bool _shouldShowCue(double probability) {
    return DateTime.now().millisecondsSinceEpoch % 100 < (probability * 100);
  }

  String _generateMovementCue() {
    final cues = [
      'Front end: squeeze in',
      'Front end: push out',
      'Back end: pull through',
      'Back end: squeeze in',
      'Feel the back tension',
      'Relax the front shoulder',
    ];
    return cues[DateTime.now().millisecondsSinceEpoch % cues.length];
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

  /// Complete a custom session and log it
  Future<void> completeCustomSession() async {
    if (_customConfig == null || _sessionStartedAt == null) return;

    final config = _customConfig!;
    final log = OlyTrainingLogsCompanion.insert(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      sessionTemplateId: const Value.absent(), // No template for custom
      sessionVersion: 'custom',
      sessionName: config.displayName,
      plannedDurationSeconds: config.durationMinutes * 60,
      actualDurationSeconds: DateTime.now().difference(_sessionStartedAt!).inSeconds,
      plannedExercises: _customTotalReps,
      completedExercises: _completedExercises,
      totalHoldSeconds: _totalHoldSecondsActual,
      totalRestSeconds: _totalRestSecondsActual,
      feedbackShaking: const Value.absent(),
      feedbackStructure: const Value.absent(),
      feedbackRest: const Value.absent(),
      progressionSuggestion: const Value.absent(),
      suggestedNextVersion: const Value.absent(),
      notes: Value('${config.ratio.label} ratio, ${config.movementStimulus.name} movement'),
      startedAt: _sessionStartedAt!,
      completedAt: DateTime.now(),
    );

    await _db.insertOlyTrainingLog(log);
    await loadData(); // Refresh recent logs
    _triggerCloudBackup(); // Backup to cloud
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
    if (_activeSession == null || _sessionStartedAt == null) return;

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
    _triggerCloudBackup(); // Backup to cloud
    _resetState();
    notifyListeners();
  }

  /// Trigger cloud backup in background (non-blocking)
  void _triggerCloudBackup() {
    Future.microtask(() async {
      try {
        final syncService = FirestoreSyncService();
        if (syncService.isAuthenticated) {
          await syncService.backupAllData(_db);
          debugPrint('Cloud backup completed after bow training session');
        }
      } catch (e) {
        debugPrint('Cloud backup error (non-fatal): $e');
      }
    });
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
    if (_customConfig != null) {
      _advanceCustomPhase();
      return;
    }

    final exercise = currentExercise;
    if (exercise == null || _activeSession == null) return;

    switch (_phase) {
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
        // No-op
        break;
    }

    notifyListeners();
  }

  void _advanceCustomPhase() {
    final config = _customConfig!;

    switch (_phase) {
      case TimerPhase.hold:
        // Finished a hold - start rest or complete
        if (_customCurrentRep < _customTotalReps) {
          _phase = TimerPhase.rest;
          _secondsRemaining = config.ratio.restSeconds;
          _currentMovementCue = null; // Clear cue during rest
          _playRestBeep();
        } else {
          // Session complete
          _timer?.cancel();
          _phase = TimerPhase.complete;
          _timerState = TimerState.stopped;
          _completedExercises = _customTotalReps;
          _playCompleteSound();
        }
        break;

      case TimerPhase.rest:
        // Finished resting - start next hold
        _customCurrentRep++;
        _phase = TimerPhase.hold;
        _secondsRemaining = config.ratio.holdSeconds;
        _updateMovementCue(); // Generate new cue for hold
        _playHoldBeep();
        break;

      case TimerPhase.idle:
      case TimerPhase.complete:
      case TimerPhase.exerciseBreak:
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
    // Reset custom session state
    _customConfig = null;
    _customTotalReps = 0;
    _customCurrentRep = 0;
    _currentMovementCue = null;
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
      case TimerPhase.hold:
        return 'HOLD';
      case TimerPhase.rest:
        return 'Rest';
      case TimerPhase.exerciseBreak:
        return 'Next Exercise';
      case TimerPhase.complete:
        return 'Complete';
    }
  }

  /// Get progress within current phase (0.0 to 1.0)
  double get phaseProgress {
    // Handle custom session
    if (_customConfig != null) {
      int totalSeconds;
      switch (_phase) {
        case TimerPhase.hold:
          totalSeconds = _customConfig!.ratio.holdSeconds;
          break;
        case TimerPhase.rest:
          totalSeconds = _customConfig!.ratio.restSeconds;
          break;
        default:
          return 0;
      }
      if (totalSeconds <= 0) return 1.0;
      return 1 - (_secondsRemaining / totalSeconds);
    }

    final exercise = currentExercise;
    if (exercise == null) return 0;

    int totalSeconds;
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

    if (totalSeconds <= 0) return 1.0;
    return 1 - (_secondsRemaining / totalSeconds);
  }

  /// Get overall session progress (0.0 to 1.0)
  double get sessionProgress {
    // Handle custom session
    if (_customConfig != null) {
      if (_customTotalReps == 0) return 0;
      return (_customCurrentRep - 1) / _customTotalReps;
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
