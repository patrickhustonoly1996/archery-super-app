import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';

/// Timer phases for bow training
enum TimerPhase {
  idle,      // Not started
  hold,      // Holding at draw
  rest,      // Resting between holds
  breaking,  // Taking a longer break
  complete,  // Session finished
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

  // Cached presets
  List<BowTrainingPreset> _presets = [];
  List<BowTrainingPreset> get presets => _presets;

  // Recent logs
  List<BowTrainingLog> _recentLogs = [];
  List<BowTrainingLog> get recentLogs => _recentLogs;

  // Active session state
  BowTrainingPreset? _activePreset;
  BowTrainingPreset? get activePreset => _activePreset;

  TimerPhase _phase = TimerPhase.idle;
  TimerPhase get phase => _phase;

  TimerState _timerState = TimerState.stopped;
  TimerState get timerState => _timerState;

  int _secondsRemaining = 0;
  int get secondsRemaining => _secondsRemaining;

  int _currentSet = 0;
  int get currentSet => _currentSet;

  // Session tracking
  DateTime? _sessionStartedAt;
  int _totalHoldSecondsActual = 0;
  int _totalRestSecondsActual = 0;
  int _completedSets = 0;
  int get completedSets => _completedSets;
  int get totalHoldSecondsActual => _totalHoldSecondsActual;

  Timer? _timer;

  // ===========================================================================
  // PRESET MANAGEMENT
  // ===========================================================================

  /// Load all presets from database
  Future<void> loadPresets() async {
    _presets = await _db.getAllBowTrainingPresets();
    _recentLogs = await _db.getRecentBowTrainingLogs(limit: 5);
    notifyListeners();
  }

  /// Create a new custom preset
  Future<void> createPreset({
    required String name,
    required int holdSeconds,
    required int restSeconds,
    required int sets,
    int? breakAfterSets,
    int? breakDurationSeconds,
  }) async {
    final id = 'preset_${DateTime.now().millisecondsSinceEpoch}';
    await _db.insertBowTrainingPreset(BowTrainingPresetsCompanion.insert(
      id: id,
      name: name,
      holdSeconds: holdSeconds,
      restSeconds: restSeconds,
      sets: sets,
      breakAfterSets: Value(breakAfterSets),
      breakDurationSeconds: Value(breakDurationSeconds),
    ));
    await loadPresets();
  }

  /// Update an existing preset
  /// Set hasBreaks to false to remove breaks, or provide breakAfterSets/breakDurationSeconds to set them
  Future<void> updatePreset({
    required String id,
    String? name,
    int? holdSeconds,
    int? restSeconds,
    int? sets,
    bool hasBreaks = true,
    int? breakAfterSets,
    int? breakDurationSeconds,
  }) async {
    final existing = await _db.getBowTrainingPreset(id);
    if (existing == null) return;

    // If hasBreaks is false, explicitly set break fields to null
    final newBreakAfterSets = hasBreaks ? (breakAfterSets ?? existing.breakAfterSets) : null;
    final newBreakDuration = hasBreaks ? (breakDurationSeconds ?? existing.breakDurationSeconds) : null;

    await _db.updateBowTrainingPreset(BowTrainingPresetsCompanion(
      id: Value(id),
      name: Value(name ?? existing.name),
      holdSeconds: Value(holdSeconds ?? existing.holdSeconds),
      restSeconds: Value(restSeconds ?? existing.restSeconds),
      sets: Value(sets ?? existing.sets),
      breakAfterSets: Value(newBreakAfterSets),
      breakDurationSeconds: Value(newBreakDuration),
      updatedAt: Value(DateTime.now()),
    ));
    await loadPresets();
  }

  /// Delete a preset (hides system presets, deletes user presets)
  Future<void> deletePreset(String id) async {
    await _db.deleteBowTrainingPreset(id);
    await loadPresets();
  }

  // ===========================================================================
  // TIMER CONTROLS
  // ===========================================================================

  /// Start a new training session with the given preset
  void startSession(BowTrainingPreset preset) {
    _activePreset = preset;
    _phase = TimerPhase.hold;
    _timerState = TimerState.running;
    _currentSet = 1;
    _secondsRemaining = preset.holdSeconds;
    _sessionStartedAt = DateTime.now();
    _totalHoldSecondsActual = 0;
    _totalRestSecondsActual = 0;
    _completedSets = 0;

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

  /// Complete the session and log it
  Future<void> completeSession({String? notes}) async {
    if (_activePreset == null || _sessionStartedAt == null) return;

    final log = BowTrainingLogsCompanion.insert(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      presetId: Value(_activePreset!.id),
      presetName: _activePreset!.name,
      holdSeconds: _activePreset!.holdSeconds,
      restSeconds: _activePreset!.restSeconds,
      plannedSets: _activePreset!.sets,
      completedSets: _completedSets,
      totalHoldSeconds: _totalHoldSecondsActual,
      totalRestSeconds: _totalRestSecondsActual,
      notes: Value(notes),
      startedAt: _sessionStartedAt!,
      completedAt: DateTime.now(),
    );

    await _db.insertBowTrainingLog(log);
    await loadPresets(); // Refresh logs
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
    } else if (_phase == TimerPhase.rest || _phase == TimerPhase.breaking) {
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
    if (_activePreset == null) return;

    switch (_phase) {
      case TimerPhase.hold:
        _completedSets++;

        // Check if session is complete
        if (_currentSet >= _activePreset!.sets) {
          _timer?.cancel();
          _phase = TimerPhase.complete;
          _timerState = TimerState.stopped;
          _playCompleteSound();
          notifyListeners();
          return;
        }

        // Check if we need a break
        if (_activePreset!.breakAfterSets != null &&
            _currentSet % _activePreset!.breakAfterSets! == 0 &&
            _activePreset!.breakDurationSeconds != null &&
            _activePreset!.breakDurationSeconds! > 0) {
          _phase = TimerPhase.breaking;
          _secondsRemaining = _activePreset!.breakDurationSeconds!;
          _playBreakBeep();
        } else if (_activePreset!.restSeconds > 0) {
          _phase = TimerPhase.rest;
          _secondsRemaining = _activePreset!.restSeconds;
          _playRestBeep();
        } else {
          // Zero rest - go directly to next hold
          _currentSet++;
          _phase = TimerPhase.hold;
          _secondsRemaining = _activePreset!.holdSeconds;
          _playHoldBeep();
        }
        break;

      case TimerPhase.rest:
      case TimerPhase.breaking:
        _currentSet++;
        _phase = TimerPhase.hold;
        _secondsRemaining = _activePreset!.holdSeconds;
        _playHoldBeep();
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
    _activePreset = null;
    _phase = TimerPhase.idle;
    _timerState = TimerState.stopped;
    _secondsRemaining = 0;
    _currentSet = 0;
    _sessionStartedAt = null;
    _totalHoldSecondsActual = 0;
    _totalRestSecondsActual = 0;
    _completedSets = 0;
  }

  // ===========================================================================
  // AUDIO FEEDBACK
  // ===========================================================================

  void _playStartBeep() {
    HapticFeedback.heavyImpact();
  }

  void _playHoldBeep() {
    // Single beep for hold start
    HapticFeedback.heavyImpact();
  }

  void _playRestBeep() {
    // Double beep for rest
    HapticFeedback.mediumImpact();
  }

  void _playBreakBeep() {
    // Triple beep for break
    HapticFeedback.lightImpact();
  }

  void _playTickBeep() {
    HapticFeedback.selectionClick();
  }

  void _playCompleteSound() {
    HapticFeedback.heavyImpact();
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
      case TimerPhase.breaking:
        return 'Break';
      case TimerPhase.complete:
        return 'Complete';
    }
  }

  /// Get progress as fraction (0.0 to 1.0)
  double get phaseProgress {
    if (_activePreset == null) return 0;

    int totalSeconds;
    switch (_phase) {
      case TimerPhase.hold:
        totalSeconds = _activePreset!.holdSeconds;
        break;
      case TimerPhase.rest:
        totalSeconds = _activePreset!.restSeconds;
        break;
      case TimerPhase.breaking:
        totalSeconds = _activePreset!.breakDurationSeconds ?? 60;
        break;
      default:
        return 0;
    }

    // Guard against division by zero
    if (totalSeconds <= 0) return 1.0;

    return 1 - (_secondsRemaining / totalSeconds);
  }

  /// Get overall session progress (0.0 to 1.0)
  double get sessionProgress {
    if (_activePreset == null || _activePreset!.sets == 0) return 0;
    return _completedSets / _activePreset!.sets;
  }

  /// Check if timer is active
  bool get isActive => _timerState != TimerState.stopped;

  /// Format duration for display
  static String formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) {
      return '$minutes min ${seconds > 0 ? '$seconds sec' : ''}';
    }
    return '$seconds sec';
  }

  /// Calculate total session duration for a preset
  static int calculateTotalDuration(BowTrainingPreset preset) {
    int total = preset.sets * (preset.holdSeconds + preset.restSeconds);

    // Subtract rest from last set (no rest after final hold)
    total -= preset.restSeconds;

    // Add break time
    if (preset.breakAfterSets != null && preset.breakDurationSeconds != null) {
      final breakCount = (preset.sets - 1) ~/ preset.breakAfterSets!;
      total += breakCount * preset.breakDurationSeconds!;
    }

    return total;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
