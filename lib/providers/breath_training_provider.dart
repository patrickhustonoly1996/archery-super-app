import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../widgets/breathing_visualizer.dart';

/// Types of breath training sessions
enum BreathSessionType {
  pacedBreathing,
  breathHold,
  patrickBreath,
}

/// Session states for breath training
enum BreathSessionState {
  setup,
  idle,
  pacedBreathing,
  holding,
  recovery,
  exhaling, // For patrick breath
  complete,
}

/// Difficulty for breath hold sessions
enum BreathDifficulty {
  beginner,     // +10% per round
  intermediate, // +20% per round
  advanced,     // +30% per round
}

/// Central provider for breath training session state
/// Supports all three breath training types with pause/resume
class BreathTrainingProvider extends ChangeNotifier {
  // Common constants
  static const int inhaleSeconds = 4;
  static const int exhaleSeconds = 6;
  static const int pacedBreathsPerCycle = 3;
  static const int recoveryBreaths = 4;

  Timer? _timer;

  // Current session type
  BreathSessionType? _sessionType;
  BreathSessionType? get sessionType => _sessionType;

  // Session state
  BreathSessionState _state = BreathSessionState.idle;
  BreathSessionState get state => _state;

  BreathPhase _breathPhase = BreathPhase.idle;
  BreathPhase get breathPhase => _breathPhase;

  // Timing
  int _phaseSecondsRemaining = 0;
  int get phaseSecondsRemaining => _phaseSecondsRemaining;

  double _phaseProgress = 0.0;
  double get phaseProgress => _phaseProgress;

  int _tickCount = 0;

  // ===========================================================================
  // BREATH HOLD SPECIFIC STATE
  // ===========================================================================

  int _baseHoldDuration = 15;
  int get baseHoldDuration => _baseHoldDuration;
  set baseHoldDuration(int value) {
    _baseHoldDuration = value;
    notifyListeners();
  }

  int _totalRounds = 5;
  int get totalRounds => _totalRounds;
  set totalRounds(int value) {
    _totalRounds = value;
    notifyListeners();
  }

  BreathDifficulty _difficulty = BreathDifficulty.intermediate;
  BreathDifficulty get difficulty => _difficulty;
  set difficulty(BreathDifficulty value) {
    _difficulty = value;
    notifyListeners();
  }

  int _currentRound = 0;
  int get currentRound => _currentRound;

  int _pacedBreathCount = 0;
  int get pacedBreathCount => _pacedBreathCount;

  int _totalHoldTime = 0;
  int get totalHoldTime => _totalHoldTime;

  double get progressionIncrement {
    switch (_difficulty) {
      case BreathDifficulty.beginner:
        return 0.1;
      case BreathDifficulty.intermediate:
        return 0.2;
      case BreathDifficulty.advanced:
        return 0.3;
    }
  }

  int get currentHoldTarget {
    final progressionFactor = 1.0 + (_currentRound * progressionIncrement);
    return (_baseHoldDuration * progressionFactor).round();
  }

  // ===========================================================================
  // PACED BREATHING SPECIFIC STATE
  // ===========================================================================

  int _pacedDurationMinutes = 3;
  int get pacedDurationMinutes => _pacedDurationMinutes;
  set pacedDurationMinutes(int value) {
    _pacedDurationMinutes = value;
    notifyListeners();
  }

  int _totalPacedSeconds = 0;
  int _elapsedPacedSeconds = 0;
  int get elapsedPacedSeconds => _elapsedPacedSeconds;

  // ===========================================================================
  // PATRICK BREATH SPECIFIC STATE
  // ===========================================================================

  int _exhaleSeconds = 0;
  int get patrickExhaleSeconds => _exhaleSeconds;

  int _bestExhale = 0;
  int get bestExhale => _bestExhale;
  set bestExhale(int value) {
    _bestExhale = value;
    notifyListeners();
  }

  // ===========================================================================
  // COMPUTED PROPERTIES
  // ===========================================================================

  bool get isActive => _state != BreathSessionState.idle &&
                       _state != BreathSessionState.complete &&
                       _state != BreathSessionState.setup;

  String get statusText {
    switch (_state) {
      case BreathSessionState.setup:
        return 'Setup';
      case BreathSessionState.idle:
        return 'Ready';
      case BreathSessionState.pacedBreathing:
        return _breathPhase == BreathPhase.inhale ? 'Breathe In' : 'Breathe Out';
      case BreathSessionState.holding:
        return 'Hold';
      case BreathSessionState.recovery:
        return _breathPhase == BreathPhase.inhale ? 'Breathe In' : 'Breathe Out';
      case BreathSessionState.exhaling:
        return 'Exhale...';
      case BreathSessionState.complete:
        return 'Complete';
    }
  }

  String get secondaryText {
    if (_sessionType == BreathSessionType.pacedBreathing) {
      final remaining = _totalPacedSeconds - _elapsedPacedSeconds;
      final mins = remaining ~/ 60;
      final secs = remaining % 60;
      return '$mins:${secs.toString().padLeft(2, '0')} remaining';
    }

    if (_sessionType == BreathSessionType.patrickBreath) {
      if (_state == BreathSessionState.exhaling) {
        return '${_exhaleSeconds}s';
      }
      return _bestExhale > 0 ? 'Best: ${_bestExhale}s' : 'How long can you exhale?';
    }

    switch (_state) {
      case BreathSessionState.setup:
        return 'Configure your session';
      case BreathSessionState.idle:
        return 'Tap Start to begin';
      case BreathSessionState.pacedBreathing:
        return 'Preparing for hold';
      case BreathSessionState.holding:
        return 'Target: ${currentHoldTarget}s';
      case BreathSessionState.recovery:
        return 'Recovery breath ${_pacedBreathCount + 1}/$recoveryBreaths';
      case BreathSessionState.complete:
        return 'Total hold time: ${_totalHoldTime}s';
      case BreathSessionState.exhaling:
        return '';
    }
  }

  // ===========================================================================
  // SESSION CONTROLS
  // ===========================================================================

  /// Start a breath hold session
  void startBreathHoldSession() {
    _sessionType = BreathSessionType.breathHold;
    _state = BreathSessionState.pacedBreathing;
    _breathPhase = BreathPhase.inhale;
    _currentRound = 0;
    _pacedBreathCount = 0;
    _phaseSecondsRemaining = inhaleSeconds;
    _phaseProgress = 0.0;
    _totalHoldTime = 0;
    _tickCount = 0;
    _startTimer();
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  /// Start a paced breathing session
  void startPacedBreathingSession() {
    _sessionType = BreathSessionType.pacedBreathing;
    _state = BreathSessionState.pacedBreathing;
    _breathPhase = BreathPhase.inhale;
    _phaseSecondsRemaining = inhaleSeconds;
    _phaseProgress = 0.0;
    _totalPacedSeconds = _pacedDurationMinutes * 60;
    _elapsedPacedSeconds = 0;
    _tickCount = 0;
    _startTimer();
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  /// Start a patrick breath (long exhale) session
  void startPatrickBreathSession() {
    _sessionType = BreathSessionType.patrickBreath;
    _state = BreathSessionState.exhaling;
    _breathPhase = BreathPhase.exhale;
    _exhaleSeconds = 0;
    _phaseProgress = 0.0;
    _tickCount = 0;
    _startTimer();
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  /// Stop the current session
  void stopSession() {
    _timer?.cancel();
    _state = BreathSessionState.idle;
    _breathPhase = BreathPhase.idle;
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  /// Pause for navigation (without resetting)
  void pauseForNavigation() {
    _timer?.cancel();
    // Don't change state - keep everything paused
    notifyListeners();
  }

  /// Resume a paused session
  void resumeSession() {
    if (_state != BreathSessionState.idle && _state != BreathSessionState.complete) {
      _startTimer();
      notifyListeners();
    }
  }

  /// End patrick breath and record time
  void endPatrickBreath() {
    _timer?.cancel();
    _state = BreathSessionState.complete;
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  /// Reset to setup/idle state
  void reset() {
    _timer?.cancel();
    _sessionType = null;
    _state = BreathSessionState.idle;
    _breathPhase = BreathPhase.idle;
    _phaseSecondsRemaining = 0;
    _phaseProgress = 0.0;
    _currentRound = 0;
    _pacedBreathCount = 0;
    _totalHoldTime = 0;
    _exhaleSeconds = 0;
    _tickCount = 0;
    notifyListeners();
  }

  // ===========================================================================
  // TIMER LOGIC
  // ===========================================================================

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), _tick);
  }

  void _tick(Timer timer) {
    _tickCount++;

    if (_tickCount % 10 != 0) {
      _updateProgress();
      return;
    }

    // Full second tick
    switch (_sessionType) {
      case BreathSessionType.breathHold:
        _handleBreathHoldTick();
        break;
      case BreathSessionType.pacedBreathing:
        _handlePacedBreathingTick();
        break;
      case BreathSessionType.patrickBreath:
        _handlePatrickBreathTick();
        break;
      case null:
        break;
    }
  }

  void _updateProgress() {
    int totalPhaseMs;
    switch (_state) {
      case BreathSessionState.pacedBreathing:
      case BreathSessionState.recovery:
        totalPhaseMs = (_breathPhase == BreathPhase.inhale ? inhaleSeconds : exhaleSeconds) * 1000;
        break;
      case BreathSessionState.holding:
        totalPhaseMs = currentHoldTarget * 1000;
        break;
      case BreathSessionState.exhaling:
        // Patrick breath - no fixed target
        _phaseProgress = 0.5; // Just keep visualizer active
        notifyListeners();
        return;
      default:
        return;
    }

    final subSecondMs = (_tickCount % 10) * 100;
    final elapsedMs = totalPhaseMs - (_phaseSecondsRemaining * 1000) + subSecondMs;
    _phaseProgress = (elapsedMs / totalPhaseMs).clamp(0.0, 1.0);
    notifyListeners();
  }

  void _handleBreathHoldTick() {
    _phaseSecondsRemaining--;

    switch (_state) {
      case BreathSessionState.pacedBreathing:
        if (_phaseSecondsRemaining <= 0) {
          HapticFeedback.lightImpact();
          if (_breathPhase == BreathPhase.inhale) {
            _breathPhase = BreathPhase.exhale;
            _phaseSecondsRemaining = exhaleSeconds;
          } else {
            _pacedBreathCount++;
            if (_pacedBreathCount >= pacedBreathsPerCycle) {
              HapticFeedback.mediumImpact();
              _state = BreathSessionState.holding;
              _breathPhase = BreathPhase.hold;
              _phaseSecondsRemaining = currentHoldTarget;
              _pacedBreathCount = 0;
            } else {
              _breathPhase = BreathPhase.inhale;
              _phaseSecondsRemaining = inhaleSeconds;
            }
          }
          _phaseProgress = 0.0;
        }
        break;

      case BreathSessionState.holding:
        _totalHoldTime++;
        if (_phaseSecondsRemaining <= 0) {
          HapticFeedback.heavyImpact();
          _currentRound++;
          if (_currentRound >= _totalRounds) {
            _state = BreathSessionState.complete;
            _timer?.cancel();
          } else {
            _state = BreathSessionState.recovery;
            _breathPhase = BreathPhase.inhale;
            _phaseSecondsRemaining = inhaleSeconds;
            _pacedBreathCount = 0;
          }
          _phaseProgress = 0.0;
        }
        break;

      case BreathSessionState.recovery:
        if (_phaseSecondsRemaining <= 0) {
          HapticFeedback.lightImpact();
          if (_breathPhase == BreathPhase.inhale) {
            _breathPhase = BreathPhase.exhale;
            _phaseSecondsRemaining = exhaleSeconds;
          } else {
            _pacedBreathCount++;
            if (_pacedBreathCount >= recoveryBreaths) {
              _state = BreathSessionState.pacedBreathing;
              _breathPhase = BreathPhase.inhale;
              _phaseSecondsRemaining = inhaleSeconds;
              _pacedBreathCount = 0;
            } else {
              _breathPhase = BreathPhase.inhale;
              _phaseSecondsRemaining = inhaleSeconds;
            }
          }
          _phaseProgress = 0.0;
        }
        break;

      default:
        break;
    }

    notifyListeners();
  }

  void _handlePacedBreathingTick() {
    _elapsedPacedSeconds++;
    _phaseSecondsRemaining--;

    if (_elapsedPacedSeconds >= _totalPacedSeconds) {
      _state = BreathSessionState.complete;
      _timer?.cancel();
      HapticFeedback.heavyImpact();
      notifyListeners();
      return;
    }

    if (_phaseSecondsRemaining <= 0) {
      HapticFeedback.lightImpact();
      if (_breathPhase == BreathPhase.inhale) {
        _breathPhase = BreathPhase.exhale;
        _phaseSecondsRemaining = exhaleSeconds;
      } else {
        _breathPhase = BreathPhase.inhale;
        _phaseSecondsRemaining = inhaleSeconds;
      }
      _phaseProgress = 0.0;
    }

    notifyListeners();
  }

  void _handlePatrickBreathTick() {
    _exhaleSeconds++;
    notifyListeners();
  }

  // ===========================================================================
  // PAUSE/RESUME SUPPORT
  // ===========================================================================

  /// Export current session state for persistence
  Map<String, dynamic>? exportState() {
    if (_sessionType == null || _state == BreathSessionState.idle || _state == BreathSessionState.complete) {
      return null;
    }

    return {
      'sessionType': _sessionType!.index,
      'state': _state.index,
      'breathPhase': _breathPhase.index,
      'phaseSecondsRemaining': _phaseSecondsRemaining,
      'phaseProgress': _phaseProgress,
      // Breath hold specific
      'baseHoldDuration': _baseHoldDuration,
      'totalRounds': _totalRounds,
      'difficulty': _difficulty.index,
      'currentRound': _currentRound,
      'pacedBreathCount': _pacedBreathCount,
      'totalHoldTime': _totalHoldTime,
      // Paced breathing specific
      'pacedDurationMinutes': _pacedDurationMinutes,
      'totalPacedSeconds': _totalPacedSeconds,
      'elapsedPacedSeconds': _elapsedPacedSeconds,
      // Patrick breath specific
      'exhaleSeconds': _exhaleSeconds,
    };
  }

  /// Restore session state from a saved state map
  bool restoreState(Map<String, dynamic> state) {
    try {
      _sessionType = BreathSessionType.values[state['sessionType'] as int];
      _state = BreathSessionState.values[state['state'] as int];
      _breathPhase = BreathPhase.values[state['breathPhase'] as int];
      _phaseSecondsRemaining = state['phaseSecondsRemaining'] as int;
      _phaseProgress = state['phaseProgress'] as double;

      // Breath hold specific
      _baseHoldDuration = state['baseHoldDuration'] as int? ?? 15;
      _totalRounds = state['totalRounds'] as int? ?? 5;
      _difficulty = BreathDifficulty.values[state['difficulty'] as int? ?? 1];
      _currentRound = state['currentRound'] as int? ?? 0;
      _pacedBreathCount = state['pacedBreathCount'] as int? ?? 0;
      _totalHoldTime = state['totalHoldTime'] as int? ?? 0;

      // Paced breathing specific
      _pacedDurationMinutes = state['pacedDurationMinutes'] as int? ?? 3;
      _totalPacedSeconds = state['totalPacedSeconds'] as int? ?? 0;
      _elapsedPacedSeconds = state['elapsedPacedSeconds'] as int? ?? 0;

      // Patrick breath specific
      _exhaleSeconds = state['exhaleSeconds'] as int? ?? 0;

      _tickCount = 0;
      // Don't auto-start timer - user taps to resume
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error restoring breath training state: $e');
      return false;
    }
  }

  /// Get title for paused session display
  String get pausedSessionTitle {
    switch (_sessionType) {
      case BreathSessionType.pacedBreathing:
        return 'Paced Breathing';
      case BreathSessionType.breathHold:
        return 'Breath Holds';
      case BreathSessionType.patrickBreath:
        return 'Long Exhale';
      case null:
        return 'Breath Training';
    }
  }

  /// Get subtitle for paused session display
  String get pausedSessionSubtitle {
    switch (_sessionType) {
      case BreathSessionType.pacedBreathing:
        final remaining = _totalPacedSeconds - _elapsedPacedSeconds;
        final mins = remaining ~/ 60;
        return '$mins min remaining';
      case BreathSessionType.breathHold:
        return 'Round ${_currentRound + 1}/$_totalRounds';
      case BreathSessionType.patrickBreath:
        return '${_exhaleSeconds}s elapsed';
      case null:
        return '';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
