import 'dart:async';
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
  Completer<void>? _initCompleter;

  Future<void> _ensureInitialized() async {
    // Already initialized
    if (_prefs != null) return;

    // Initialization in progress - wait for it
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }

    // Start initialization
    _initCompleter = Completer<void>();
    try {
      _prefs = await SharedPreferences.getInstance();
      _enabled = _prefs!.getBool(_vibrationsEnabledKey) ?? true; // Default ON
    } catch (e) {
      // SharedPreferences not available (e.g., in tests)
      _enabled = true;
    }
    _initCompleter!.complete();
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
    try {
      await _prefs?.setBool(_vibrationsEnabledKey, enabled);
    } catch (e) {
      // SharedPreferences not available (e.g., in tests)
    }
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

  /// Inhale cue - one short buzz
  Future<void> inhale() async {
    await _ensureInitialized();
    if (_enabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Exhale cue - one long buzz (sustained feel via repeated impacts)
  Future<void> exhale() async {
    await _ensureInitialized();
    if (_enabled) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      HapticFeedback.heavyImpact();
    }
  }

  /// Hold transition - three short (approaching) + long + short (entering hold)
  Future<void> holdStart() async {
    await _ensureInitialized();
    if (_enabled) {
      // Three short approach signals
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      HapticFeedback.lightImpact();
      // Brief pause before transition
      await Future.delayed(const Duration(milliseconds: 200));
      // Long signal (entering hold)
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      HapticFeedback.heavyImpact();
      // Brief pause
      await Future.delayed(const Duration(milliseconds: 150));
      // Short signal (now in hold)
      HapticFeedback.mediumImpact();
    }
  }
}
