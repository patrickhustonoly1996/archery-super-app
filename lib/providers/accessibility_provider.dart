import 'package:flutter/foundation.dart';
import '../services/accessibility_service.dart';

/// Provider for accessibility settings
/// Notifies listeners when text scale changes
class AccessibilityProvider extends ChangeNotifier {
  final AccessibilityService _service = AccessibilityService();

  double _textScaleFactor = AccessibilityService.defaultTextScale;
  bool _isInitialized = false;

  /// Current text scale factor (1.0 = normal)
  double get textScaleFactor => _textScaleFactor;

  /// Whether the provider has been initialized
  bool get isInitialized => _isInitialized;

  /// Minimum allowed text scale
  double get minTextScale => AccessibilityService.minTextScale;

  /// Maximum allowed text scale
  double get maxTextScale => AccessibilityService.maxTextScale;

  /// Initialize the provider (loads saved settings)
  Future<void> initialize() async {
    await _service.initialize();
    _textScaleFactor = _service.textScaleFactor;
    _isInitialized = true;
    notifyListeners();
  }

  /// Set the text scale factor
  Future<void> setTextScaleFactor(double scale) async {
    final clampedScale = scale.clamp(minTextScale, maxTextScale);
    if (_textScaleFactor == clampedScale) return;

    _textScaleFactor = clampedScale;
    await _service.setTextScaleFactor(clampedScale);
    notifyListeners();
  }

  /// Reset to default text scale
  Future<void> resetTextScale() async {
    _textScaleFactor = AccessibilityService.defaultTextScale;
    await _service.resetTextScale();
    notifyListeners();
  }

  /// Get a formatted percentage string for display
  String get textScalePercentage => '${(_textScaleFactor * 100).round()}%';
}
