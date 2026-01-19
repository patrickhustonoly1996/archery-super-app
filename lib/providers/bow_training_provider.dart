import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../services/sync_service.dart';
import '../services/vibration_service.dart';
import '../services/training_session_service.dart';
import '../utils/unique_id.dart';

/// Timer phases for bow training
enum TimerPhase {
  idle,           // Not started
  prep,           // Preparation countdown before first hold
  hold,           // Holding at draw
  rest,           // Resting between reps
  exerciseBreak,  // Transition between exercises
  complete,       // Session finished
}

/// Default prep/intro time before exercises (seconds)
const int kPrepCountdownSeconds = 5;

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

/// Custom session configuration (for quick sessions)
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

/// A custom user-created bow training session (saved sessions)
class CustomBowSession {
  final String id;
  final String name;
  final List<CustomExercise> exercises;
  final DateTime createdAt;

  CustomBowSession({
    required this.id,
    required this.name,
    required this.exercises,
    required this.createdAt,
  });

  int get totalDurationSeconds {
    int total = 0;
    for (final ex in exercises) {
      total += ex.reps * (ex.holdSeconds + ex.restSeconds);
    }
    return total;
  }

  int get totalDurationMinutes => (totalDurationSeconds / 60).ceil();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory CustomBowSession.fromJson(Map<String, dynamic> json) {
    return CustomBowSession(
      id: json['id'] as String,
      name: json['name'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => CustomExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// A single exercise within a custom session
class CustomExercise {
  final String exerciseTypeId;
  final String name;
  final int reps;
  final int holdSeconds;
  final int restSeconds;

  CustomExercise({
    required this.exerciseTypeId,
    required this.name,
    required this.reps,
    required this.holdSeconds,
    required this.restSeconds,
  });

  Map<String, dynamic> toJson() => {
    'exerciseTypeId': exerciseTypeId,
    'name': name,
    'reps': reps,
    'holdSeconds': holdSeconds,
    'restSeconds': restSeconds,
  };

  factory CustomExercise.fromJson(Map<String, dynamic> json) {
    return CustomExercise(
      exerciseTypeId: json['exerciseTypeId'] as String,
      name: json['name'] as String,
      reps: json['reps'] as int,
      holdSeconds: json['holdSeconds'] as int,
      restSeconds: json['restSeconds'] as int,
    );
  }
}

class BowTrainingProvider extends ChangeNotifier with WidgetsBindingObserver {
  final AppDatabase _db;
  final _vibration = VibrationService();
  final _trainingSession = TrainingSessionService();

  BowTrainingProvider(this._db) {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Tracks if timer was running before app went to background
  bool _wasRunningBeforeBackground = false;

  // ===========================================================================
  // PREFERENCE KEYS
  // ===========================================================================

  static const String _prefLastDuration = 'bow_training_last_duration';
  static const String _prefLastWorkRatio = 'bow_training_last_work_ratio';
  static const String _prefFavoriteSessions = 'bow_training_favorites';

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

  // User preferences (remembered settings)
  int _lastDuration = 10;
  int get lastDuration => _lastDuration;

  double _lastWorkRatio = 0.5;
  double get lastWorkRatio => _lastWorkRatio;

  Set<String> _favoriteSessions = {};
  Set<String> get favoriteSessions => _favoriteSessions;

  // Most used sessions (computed from logs)
  List<({String sessionId, String sessionName, int count})> _mostUsedSessions = [];
  List<({String sessionId, String sessionName, int count})> get mostUsedSessions => _mostUsedSessions;

  // Custom sessions
  List<CustomBowSession> _customSessions = [];
  List<CustomBowSession> get customSessions => _customSessions;

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

  /// True if timer was auto-paused because app went to background
  bool get wasPausedByBackground => _wasRunningBeforeBackground;

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

    // Load user preferences (remembered settings)
    await _loadPreferences();

    // Compute most-used sessions from logs
    await _computeMostUsedSessions();

    // Load custom sessions
    await _loadCustomSessions();

    notifyListeners();
  }

  /// Load user preferences from database
  Future<void> _loadPreferences() async {
    final durationStr = await _db.getPreference(_prefLastDuration);
    if (durationStr != null) {
      _lastDuration = int.tryParse(durationStr) ?? 10;
    }

    final ratioStr = await _db.getPreference(_prefLastWorkRatio);
    if (ratioStr != null) {
      _lastWorkRatio = double.tryParse(ratioStr) ?? 0.5;
    }

    final favoritesStr = await _db.getPreference(_prefFavoriteSessions);
    if (favoritesStr != null && favoritesStr.isNotEmpty) {
      _favoriteSessions = favoritesStr.split(',').toSet();
    }
  }

  /// Save quick session preferences
  Future<void> saveQuickSessionPreferences({
    required int duration,
    required double workRatio,
  }) async {
    _lastDuration = duration;
    _lastWorkRatio = workRatio;
    await _db.setPreference(_prefLastDuration, duration.toString());
    await _db.setPreference(_prefLastWorkRatio, workRatio.toString());
    notifyListeners();
  }

  /// Compute most-used sessions from training logs
  Future<void> _computeMostUsedSessions() async {
    final allLogs = await _db.getAllOlyTrainingLogs();

    // Count sessions by template ID
    final counts = <String, ({String name, int count})>{};
    for (final log in allLogs) {
      if (log.sessionTemplateId != null) {
        final existing = counts[log.sessionTemplateId!];
        if (existing != null) {
          counts[log.sessionTemplateId!] = (name: log.sessionName, count: existing.count + 1);
        } else {
          counts[log.sessionTemplateId!] = (name: log.sessionName, count: 1);
        }
      }
    }

    // Sort by count descending and take top 5
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));

    _mostUsedSessions = sorted.take(5).map((e) => (
      sessionId: e.key,
      sessionName: e.value.name,
      count: e.value.count,
    )).toList();
  }

  // ===========================================================================
  // FAVORITES
  // ===========================================================================

  bool isFavorite(String sessionId) => _favoriteSessions.contains(sessionId);

  Future<void> toggleFavorite(String sessionId) async {
    if (_favoriteSessions.contains(sessionId)) {
      _favoriteSessions.remove(sessionId);
    } else {
      _favoriteSessions.add(sessionId);
    }
    await _db.setPreference(_prefFavoriteSessions, _favoriteSessions.join(','));
    notifyListeners();
  }

  List<OlySessionTemplate> get favoriteSectionTemplates {
    return _sessionTemplates
        .where((s) => _favoriteSessions.contains(s.id))
        .toList();
  }

  // ===========================================================================
  // CUSTOM SESSIONS
  // ===========================================================================

  static const String _prefCustomSessions = 'bow_training_custom_sessions';

  Future<void> _loadCustomSessions() async {
    final jsonStr = await _db.getPreference(_prefCustomSessions);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> jsonList = json.decode(jsonStr);
        _customSessions = jsonList
            .map((e) => CustomBowSession.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _customSessions = [];
      }
    }
  }

  Future<void> saveCustomSession(CustomBowSession session) async {
    // Remove existing with same ID if editing
    _customSessions.removeWhere((s) => s.id == session.id);
    _customSessions.insert(0, session);
    await _persistCustomSessions();
    notifyListeners();
  }

  Future<void> deleteCustomSession(String sessionId) async {
    _customSessions.removeWhere((s) => s.id == sessionId);
    await _persistCustomSessions();
    notifyListeners();
  }

  Future<void> _persistCustomSessions() async {
    final jsonStr = json.encode(_customSessions.map((s) => s.toJson()).toList());
    await _db.setPreference(_prefCustomSessions, jsonStr);
  }

  /// Start a saved custom session (user-created)
  void startSavedSession(CustomBowSession session) {
    // Calculate totals
    int totalVolume = 0;
    for (final ex in session.exercises) {
      totalVolume += ex.reps * ex.holdSeconds;
    }

    // Create a virtual session template
    _activeSession = OlySessionTemplate(
      id: 'custom_${session.id}',
      version: 'Custom',
      name: session.name,
      focus: 'Custom session',
      durationMinutes: session.totalDurationMinutes,
      volumeLoad: totalVolume,
      adjustedVolumeLoad: totalVolume,
      workRatio: 0.5, // Default
      adjustedWorkRatio: 0.5,
      equipment: 'Bow, elbow sling',
      sortOrder: 0,
      createdAt: session.createdAt,
    );

    // Convert custom exercises to session exercises
    _exercises = session.exercises.asMap().entries.map((entry) {
      final idx = entry.key;
      final ex = entry.value;
      return OlySessionExercise(
        id: 'custom_ex_${session.id}_$idx',
        sessionTemplateId: _activeSession!.id,
        exerciseTypeId: ex.exerciseTypeId,
        exerciseOrder: idx + 1,
        reps: ex.reps,
        workSeconds: ex.holdSeconds,
        restSeconds: ex.restSeconds,
      );
    }).toList();

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

  /// Get available exercise types for custom session builder
  List<OlyExerciseType> get availableExerciseTypes {
    return _exerciseTypesMap.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
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

  /// Start a quick session with custom duration and work/rest ratio
  /// This generates a simple session on-the-fly without following the structured plan
  void startQuickSession({
    required int durationMinutes,
    required double workRatio,
  }) {
    // Calculate hold and rest times based on ratio
    // Using 40s total cycle as base
    const cycleTime = 40.0;
    final holdSeconds = (workRatio / (1 + workRatio) * cycleTime).round();
    final restSeconds = (cycleTime - holdSeconds).round();

    // Calculate number of reps to fill duration
    final cycleSeconds = holdSeconds + restSeconds;
    final totalSeconds = durationMinutes * 60;
    final numReps = (totalSeconds / cycleSeconds).floor();
    final volumeLoad = holdSeconds * numReps;

    // Create a virtual session template
    _activeSession = OlySessionTemplate(
      id: 'quick_${DateTime.now().millisecondsSinceEpoch}',
      version: 'Quick',
      name: '$durationMinutes min Quick Session',
      focus: 'Custom training session',
      durationMinutes: durationMinutes,
      volumeLoad: volumeLoad,
      adjustedVolumeLoad: volumeLoad, // Same as volumeLoad for quick sessions
      workRatio: workRatio,
      adjustedWorkRatio: workRatio, // Same as workRatio for quick sessions
      equipment: 'Bow, elbow sling',
      sortOrder: 0,
      createdAt: DateTime.now(),
    );

    // Create a single exercise with all the reps
    _exercises = [
      OlySessionExercise(
        id: 'quick_ex_${DateTime.now().millisecondsSinceEpoch}',
        sessionTemplateId: _activeSession!.id,
        exerciseTypeId: 'static_reversals', // Default exercise type
        exerciseOrder: 1,
        reps: numReps,
        workSeconds: holdSeconds,
        restSeconds: restSeconds,
      ),
    ];

    _currentExerciseIndex = 0;
    _currentRep = 1;
    _phase = TimerPhase.hold;
    _timerState = TimerState.running;
    _secondsRemaining = holdSeconds;
    _sessionStartedAt = DateTime.now();
    _totalHoldSecondsActual = 0;
    _totalRestSecondsActual = 0;
    _completedExercises = 0;

    _startTimer();
    _playStartBeep();
    notifyListeners();
  }

  /// Set the user's current level (called after max hold test)
  Future<void> setUserLevel(String level) async {
    await _db.updateUserLevel(level);
    await loadData();
  }

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
    _phase = TimerPhase.prep;
    _timerState = TimerState.running;
    _secondsRemaining = kPrepCountdownSeconds;
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
    _phase = TimerPhase.prep;
    _timerState = TimerState.running;
    _secondsRemaining = kPrepCountdownSeconds;
    _sessionStartedAt = DateTime.now();
    _totalHoldSecondsActual = 0;
    _totalRestSecondsActual = 0;
    _completedExercises = 0;

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
    _wasRunningBeforeBackground = false; // Clear background pause indicator
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
      id: UniqueId.withPrefix('log'),
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
      id: UniqueId.withPrefix('log'),
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

  /// Trigger cloud sync in background (non-blocking)
  void _triggerCloudBackup() {
    // SyncService handles its own error handling and retry logic
    SyncService().syncAll();
  }

  // ===========================================================================
  // TIMER LOGIC
  // ===========================================================================

  void _startTimer() {
    _timer?.cancel();
    _trainingSession.startSession();
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
      case TimerPhase.prep:
        // Prep countdown finished - start first hold
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
            _trainingSession.endSession();
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
      case TimerPhase.prep:
        // Prep countdown finished - start first hold
        _phase = TimerPhase.hold;
        _secondsRemaining = config.ratio.holdSeconds;
        _updateMovementCue(); // Generate initial cue for hold
        _playHoldBeep();
        break;

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
          _trainingSession.endSession();
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
    _trainingSession.endSession();
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
    _vibration.heavy();
  }

  void _playHoldBeep() {
    _vibration.heavy();
  }

  void _playRestBeep() {
    _vibration.medium();
  }

  void _playExerciseCompleteBeep() {
    _vibration.double();
  }

  void _playTickBeep() {
    _vibration.selection();
  }

  void _playCompleteSound() {
    _vibration.heavy();
    Future.delayed(const Duration(milliseconds: 150), () {
      _vibration.heavy();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      _vibration.heavy();
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
      case TimerPhase.prep:
        return 'Get Ready';
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
        case TimerPhase.prep:
          totalSeconds = kPrepCountdownSeconds;
          break;
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
    if (exercise == null && _phase != TimerPhase.prep) return 0;

    int totalSeconds;
    switch (_phase) {
      case TimerPhase.prep:
        totalSeconds = kPrepCountdownSeconds;
        break;
      case TimerPhase.hold:
        totalSeconds = exercise?.workSeconds ?? 0;
        break;
      case TimerPhase.rest:
        totalSeconds = exercise?.restSeconds ?? 0;
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

  // ===========================================================================
  // STATE PERSISTENCE
  // ===========================================================================

  /// Export current session state for persistence
  Map<String, dynamic>? exportState() {
    if (_timerState == TimerState.stopped && _phase == TimerPhase.idle) {
      return null;
    }

    return {
      'phase': _phase.index,
      'timerState': _timerState.index,
      'secondsRemaining': _secondsRemaining,
      'currentExerciseIndex': _currentExerciseIndex,
      'currentRep': _currentRep,
      'totalHoldSecondsActual': _totalHoldSecondsActual,
      'totalRestSecondsActual': _totalRestSecondsActual,
      'completedExercises': _completedExercises,
      'wasRunningBeforeBackground': _wasRunningBeforeBackground,
      // Custom session specific
      'isCustomSession': _customConfig != null,
      'customDurationMinutes': _customConfig?.durationMinutes,
      'customHoldSeconds': _customConfig?.ratio.holdSeconds,
      'customRestSeconds': _customConfig?.ratio.restSeconds,
      'customRatioLabel': _customConfig?.ratio.label,
      'customMovementStimulus': _customConfig?.movementStimulus.index,
      'customTotalReps': _customTotalReps,
      'customCurrentRep': _customCurrentRep,
      'currentMovementCue': _currentMovementCue,
      // OLY session specific
      'activeSessionId': _activeSession?.id,
      'sessionStartedAt': _sessionStartedAt?.toIso8601String(),
    };
  }

  /// Restore session state from a saved state map
  bool restoreState(Map<String, dynamic> state) {
    try {
      _phase = TimerPhase.values[state['phase'] as int];
      _timerState = TimerState.values[state['timerState'] as int];
      _secondsRemaining = state['secondsRemaining'] as int;
      _currentExerciseIndex = state['currentExerciseIndex'] as int;
      _currentRep = state['currentRep'] as int;
      _totalHoldSecondsActual = state['totalHoldSecondsActual'] as int;
      _totalRestSecondsActual = state['totalRestSecondsActual'] as int;
      _completedExercises = state['completedExercises'] as int;
      _wasRunningBeforeBackground = state['wasRunningBeforeBackground'] as bool? ?? false;

      // Custom session specific
      final isCustomSession = state['isCustomSession'] as bool? ?? false;
      if (isCustomSession) {
        final durationMinutes = state['customDurationMinutes'] as int?;
        final holdSeconds = state['customHoldSeconds'] as int?;
        final restSeconds = state['customRestSeconds'] as int?;
        final ratioLabel = state['customRatioLabel'] as String?;
        final stimulusIndex = state['customMovementStimulus'] as int?;

        if (durationMinutes != null && holdSeconds != null && restSeconds != null && ratioLabel != null) {
          _customConfig = CustomSessionConfig(
            durationMinutes: durationMinutes,
            ratio: HoldRestRatio(holdSeconds, restSeconds, ratioLabel),
            movementStimulus: stimulusIndex != null
                ? MovementStimulus.values[stimulusIndex]
                : MovementStimulus.none,
          );
        }
        _customTotalReps = state['customTotalReps'] as int? ?? 0;
        _customCurrentRep = state['customCurrentRep'] as int? ?? 0;
        _currentMovementCue = state['currentMovementCue'] as String?;
      }

      // Session started at
      final startedAtStr = state['sessionStartedAt'] as String?;
      if (startedAtStr != null) {
        _sessionStartedAt = DateTime.parse(startedAtStr);
      }

      // Note: _activeSession and _exercises need to be reloaded from database
      // by calling loadData() and then restoring the activeSessionId

      // Don't auto-start timer - user taps to resume
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error restoring bow training state: $e');
      return false;
    }
  }

  /// Get title for paused session display
  String get pausedSessionTitle {
    if (_customConfig != null) {
      return 'Custom Session';
    }
    return _activeSession?.name ?? 'Bow Training';
  }

  /// Get subtitle for paused session display
  String get pausedSessionSubtitle {
    if (_customConfig != null) {
      return '${_customCurrentRep}/${_customTotalReps} reps';
    }
    return 'Exercise ${_currentExerciseIndex + 1}/${_exercises.length}';
  }

  // ===========================================================================
  // APP LIFECYCLE
  // ===========================================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App going to background - pause timer if running
      if (_timerState == TimerState.running) {
        _wasRunningBeforeBackground = true;
        pauseTimer();
      }
    }
    // Note: We do NOT auto-resume - user must manually resume
    // This prevents confusion when returning to the app
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _trainingSession.endSession();
    super.dispose();
  }
}
