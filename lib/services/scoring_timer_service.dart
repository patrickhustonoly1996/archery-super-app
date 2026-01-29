import 'dart:async';
import 'package:flutter/foundation.dart';

/// Timer states for the scoring timer
enum ScoringTimerState {
  idle,      // Ready to start
  leadIn,    // Lead-in countdown before main timer
  running,   // Main timer running (green)
  warning,   // Warning phase (amber, 30s remaining)
  expired,   // Time has expired (red)
}

/// Callback signatures for timer events
typedef TimerTickCallback = void Function(ScoringTimerState state, int secondsRemaining);
typedef TimerAudioCallback = void Function(TimerAudioEvent event);

/// Audio events that the timer can trigger
enum TimerAudioEvent {
  leadInStart,    // 3 beeps - lead-in begins
  mainTimerStart, // 1 beep - main timer starts
  tenSecWarning,  // 2 beeps - 10 seconds remaining
  timerExpired,   // 3 beeps - time's up
}

/// Service for managing competition-style scoring timers.
/// Provides lead-in countdown, main timer, and audio signal callbacks.
class ScoringTimerService {
  static final ScoringTimerService _instance = ScoringTimerService._internal();
  factory ScoringTimerService() => _instance;
  ScoringTimerService._internal();

  Timer? _timer;
  ScoringTimerState _state = ScoringTimerState.idle;
  bool _isPaused = false;

  // Configuration
  int _leadInSeconds = 10;
  int _mainDurationSeconds = 120;

  // Current countdown
  int _secondsRemaining = 0;
  int _mainSecondsRemaining = 0; // Tracks main timer separately during lead-in

  // Callbacks
  TimerTickCallback? _onTick;
  TimerAudioCallback? _onAudio;
  VoidCallback? _onStateChange;

  // Warning threshold (constant)
  static const int _warningThreshold = 30;

  // Getters
  ScoringTimerState get state => _state;
  int get secondsRemaining => _secondsRemaining;
  int get leadInSeconds => _leadInSeconds;
  int get mainDurationSeconds => _mainDurationSeconds;
  bool get isRunning => _timer != null && !_isPaused;
  bool get isIdle => _state == ScoringTimerState.idle;
  bool get isPaused => _isPaused;

  /// Configure the timer durations
  void configure({
    required int leadInSeconds,
    required int mainDurationSeconds,
  }) {
    _leadInSeconds = leadInSeconds;
    _mainDurationSeconds = mainDurationSeconds;
  }

  /// Set callbacks for timer events
  void setCallbacks({
    TimerTickCallback? onTick,
    TimerAudioCallback? onAudio,
    VoidCallback? onStateChange,
  }) {
    _onTick = onTick;
    _onAudio = onAudio;
    _onStateChange = onStateChange;
  }

  /// Start the timer (begins with lead-in if configured)
  void start() {
    if (_state != ScoringTimerState.idle) return;

    _timer?.cancel();
    _isPaused = false;

    if (_leadInSeconds > 0) {
      // Start with lead-in countdown
      _state = ScoringTimerState.leadIn;
      _secondsRemaining = _leadInSeconds;
      _mainSecondsRemaining = _mainDurationSeconds;
      _onAudio?.call(TimerAudioEvent.leadInStart);
    } else {
      // Skip lead-in, start main timer directly
      _state = ScoringTimerState.running;
      _secondsRemaining = _mainDurationSeconds;
      _mainSecondsRemaining = _mainDurationSeconds;
      _onAudio?.call(TimerAudioEvent.mainTimerStart);
    }

    _onStateChange?.call();
    _onTick?.call(_state, _secondsRemaining);

    // Use 100ms tick for smooth updates
    _timer = Timer.periodic(const Duration(milliseconds: 100), _tick);
  }

  /// Pause the timer
  void pause() {
    if (!isRunning) return;
    _timer?.cancel();
    _timer = null;
    _isPaused = true;
    _onStateChange?.call();
  }

  /// Resume the timer after pause
  void resume() {
    if (_state == ScoringTimerState.idle || _state == ScoringTimerState.expired) return;
    if (!_isPaused) return;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), _tick);
    _isPaused = false;
    _onStateChange?.call();
  }

  /// Stop and reset the timer
  void stop() {
    _timer?.cancel();
    _timer = null;
    _state = ScoringTimerState.idle;
    _secondsRemaining = 0;
    _mainSecondsRemaining = 0;
    _isPaused = false;
    _onStateChange?.call();
    _onTick?.call(_state, _secondsRemaining);
  }

  /// Reset to idle state (same as stop, but explicit naming)
  void reset() => stop();

  int _tickCount = 0;

  void _tick(Timer timer) {
    _tickCount++;

    // Only process full seconds (every 10 ticks at 100ms)
    if (_tickCount < 10) {
      return;
    }
    _tickCount = 0;

    // Decrement the appropriate counter
    if (_state == ScoringTimerState.leadIn) {
      _secondsRemaining--;

      if (_secondsRemaining <= 0) {
        // Lead-in complete, start main timer
        _state = ScoringTimerState.running;
        _secondsRemaining = _mainSecondsRemaining;
        _onAudio?.call(TimerAudioEvent.mainTimerStart);
        _onStateChange?.call();
      }
    } else if (_state == ScoringTimerState.running || _state == ScoringTimerState.warning) {
      _secondsRemaining--;

      // Check for 10 second warning
      if (_secondsRemaining == 10) {
        _onAudio?.call(TimerAudioEvent.tenSecWarning);
      }

      // Check for warning threshold
      if (_state == ScoringTimerState.running && _secondsRemaining <= _warningThreshold) {
        _state = ScoringTimerState.warning;
        _onStateChange?.call();
      }

      // Check for expiration
      if (_secondsRemaining <= 0) {
        _state = ScoringTimerState.expired;
        _secondsRemaining = 0;
        _timer?.cancel();
        _timer = null;
        _onAudio?.call(TimerAudioEvent.timerExpired);
        _onStateChange?.call();
      }
    }

    _onTick?.call(_state, _secondsRemaining);
  }

  /// Get display-friendly time string (MM:SS or S for lead-in)
  String get displayTime {
    if (_state == ScoringTimerState.leadIn) {
      return '$_secondsRemaining';
    }
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Dispose of resources
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _onTick = null;
    _onAudio = null;
    _onStateChange = null;
  }
}
