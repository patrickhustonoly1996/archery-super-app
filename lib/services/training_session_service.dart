import 'package:wakelock_plus/wakelock_plus.dart';

/// Service for managing training session state, including wake lock.
/// Keeps screen on during active training sessions.
class TrainingSessionService {
  static final TrainingSessionService _instance = TrainingSessionService._internal();
  factory TrainingSessionService() => _instance;
  TrainingSessionService._internal();

  bool _isSessionActive = false;

  /// Start a training session - enables wake lock to keep screen on
  Future<void> startSession() async {
    if (_isSessionActive) return;
    _isSessionActive = true;
    await WakelockPlus.enable();
  }

  /// End a training session - disables wake lock
  Future<void> endSession() async {
    if (!_isSessionActive) return;
    _isSessionActive = false;
    await WakelockPlus.disable();
  }

  /// Check if a session is currently active
  bool get isSessionActive => _isSessionActive;
}
