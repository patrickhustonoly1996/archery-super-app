import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing accessibility settings
/// Persists text scale factor to SharedPreferences
class AccessibilityService {
  static const String _textScaleKey = 'text_scale_factor';

  // Text scale bounds (0.8x to 1.5x)
  static const double minTextScale = 0.8;
  static const double maxTextScale = 1.5;
  static const double defaultTextScale = 1.0;

  SharedPreferences? _prefs;

  /// Initialize the service (call once at startup)
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the current text scale factor
  double get textScaleFactor {
    return _prefs?.getDouble(_textScaleKey) ?? defaultTextScale;
  }

  /// Set the text scale factor
  Future<void> setTextScaleFactor(double scale) async {
    // Clamp to valid range
    final clampedScale = scale.clamp(minTextScale, maxTextScale);
    await _prefs?.setDouble(_textScaleKey, clampedScale);
  }

  /// Reset text scale to default
  Future<void> resetTextScale() async {
    await _prefs?.remove(_textScaleKey);
  }
}
