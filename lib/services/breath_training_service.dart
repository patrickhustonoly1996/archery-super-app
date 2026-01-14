import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing breath training user preferences
class BreathTrainingService {
  static const String _holdDurationKey = 'breath_hold_duration';
  static const String _pacedInhaleKey = 'paced_inhale_duration';
  static const String _pacedExhaleKey = 'paced_exhale_duration';
  static const String _holdSessionRoundsKey = 'breath_hold_session_rounds';
  static const String _patrickBestExhaleKey = 'patrick_best_exhale';
  static const String _difficultyLevelKey = 'breath_hold_difficulty';

  SharedPreferences? _prefs;

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get the user's preferred breath hold duration (5-60 seconds)
  Future<int> getHoldDuration() async {
    await _ensureInitialized();
    return _prefs!.getInt(_holdDurationKey) ?? 15;
  }

  /// Set the user's preferred breath hold duration
  Future<void> setHoldDuration(int seconds) async {
    await _ensureInitialized();
    await _prefs!.setInt(_holdDurationKey, seconds.clamp(5, 60));
  }

  /// Get paced breathing inhale duration (default 4 seconds)
  Future<int> getPacedInhaleDuration() async {
    await _ensureInitialized();
    return _prefs!.getInt(_pacedInhaleKey) ?? 4;
  }

  /// Set paced breathing inhale duration
  Future<void> setPacedInhaleDuration(int seconds) async {
    await _ensureInitialized();
    await _prefs!.setInt(_pacedInhaleKey, seconds.clamp(2, 10));
  }

  /// Get paced breathing exhale duration (default 6 seconds)
  Future<int> getPacedExhaleDuration() async {
    await _ensureInitialized();
    return _prefs!.getInt(_pacedExhaleKey) ?? 6;
  }

  /// Set paced breathing exhale duration
  Future<void> setPacedExhaleDuration(int seconds) async {
    await _ensureInitialized();
    await _prefs!.setInt(_pacedExhaleKey, seconds.clamp(2, 10));
  }

  /// Get number of rounds in a breath hold session (default 5)
  Future<int> getHoldSessionRounds() async {
    await _ensureInitialized();
    return _prefs!.getInt(_holdSessionRoundsKey) ?? 5;
  }

  /// Set number of rounds in a breath hold session
  Future<void> setHoldSessionRounds(int rounds) async {
    await _ensureInitialized();
    await _prefs!.setInt(_holdSessionRoundsKey, rounds.clamp(3, 10));
  }

  /// Get Patrick's best exhale time (for personal record tracking)
  Future<int> getPatrickBestExhale() async {
    await _ensureInitialized();
    return _prefs!.getInt(_patrickBestExhaleKey) ?? 0;
  }

  /// Set Patrick's best exhale time if it's a new record
  Future<bool> updatePatrickBestExhale(int seconds) async {
    await _ensureInitialized();
    final current = _prefs!.getInt(_patrickBestExhaleKey) ?? 0;
    if (seconds > current) {
      await _prefs!.setInt(_patrickBestExhaleKey, seconds);
      return true; // New record!
    }
    return false;
  }

  /// Get difficulty level for breath hold sessions (0=beginner, 1=intermediate, 2=advanced)
  Future<int> getDifficultyLevel() async {
    await _ensureInitialized();
    return _prefs!.getInt(_difficultyLevelKey) ?? 1; // Default to intermediate
  }

  /// Set difficulty level for breath hold sessions
  Future<void> setDifficultyLevel(int level) async {
    await _ensureInitialized();
    await _prefs!.setInt(_difficultyLevelKey, level.clamp(0, 2));
  }
}
