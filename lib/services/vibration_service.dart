import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing vibration feedback during training sessions.
/// Wraps HapticFeedback with a user-controllable toggle.
class VibrationService {
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;
  VibrationService._internal();

  static const String _vibrationsEnabledKey = 'vibrations_enabled';

  SharedPreferences? _prefs;
  bool _enabled = true; // Default ON

  Future<void> _ensureInitialized() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    _enabled = _prefs!.getBool(_vibrationsEnabledKey) ?? true; // Default ON
  }

  /// Check if vibrations are enabled
  Future<bool> isEnabled() async {
    await _ensureInitialized();
    return _enabled;
  }

  /// Set whether vibrations are enabled
  Future<void> setEnabled(bool enabled) async {
    await _ensureInitialized();
    _enabled = enabled;
    await _prefs!.setBool(_vibrationsEnabledKey, enabled);
  }

  /// Light vibration - phase changes, countdown ticks
  Future<void> light() async {
    await _ensureInitialized();
    if (_enabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Medium vibration - session start, round transitions
  Future<void> medium() async {
    await _ensureInitialized();
    if (_enabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Heavy vibration - round complete, important events
  Future<void> heavy() async {
    await _ensureInitialized();
    if (_enabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Double vibration - session complete
  Future<void> double() async {
    await _ensureInitialized();
    if (_enabled) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      HapticFeedback.heavyImpact();
    }
  }

  /// Selection click - UI feedback
  Future<void> selection() async {
    await _ensureInitialized();
    if (_enabled) {
      HapticFeedback.selectionClick();
    }
  }

  // ===========================================================================
  // BREATHING PATTERNS
  // ===========================================================================

  /// Inhale cue - two quick buzzes
  Future<void> inhale() async {
    await _ensureInitialized();
    if (_enabled) {
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      HapticFeedback.mediumImpact();
    }
  }

  /// Exhale cue - one longer buzz
  Future<void> exhale() async {
    await _ensureInitialized();
    if (_enabled) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      HapticFeedback.heavyImpact();
    }
  }

  /// Hold warning - three quick buzzes then extended buzz
  Future<void> holdStart() async {
    await _ensureInitialized();
    if (_enabled) {
      // Three quick warning buzzes
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.lightImpact();
      // Brief pause
      await Future.delayed(const Duration(milliseconds: 150));
      // Extended buzz (multiple heavy impacts to simulate longer vibration)
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      HapticFeedback.heavyImpact();
    }
  }
}
