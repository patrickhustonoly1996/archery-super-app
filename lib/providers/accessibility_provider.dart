import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Types of colorblind accessibility modes
enum ColorblindMode {
  /// Standard colors - no adjustments
  none('Off', 'Standard colors'),

  /// Deuteranopia (red-green colorblindness) - most common (~6% of males)
  /// Difficulty distinguishing red from green
  deuteranopia('Deuteranopia', 'Red-green (most common)'),

  /// Protanopia (red colorblindness) - ~1% of males
  /// Red appears dark, difficulty with red-green
  protanopia('Protanopia', 'Red weakness'),

  /// Deuteranomaly (mild red-green) - ~5% of males
  /// Green looks more red, milder than deuteranopia
  deuteranomaly('Deuteranomaly', 'Mild red-green'),

  /// Protanomaly (mild red weakness) - ~1% of males
  /// Red appears weaker/darker
  protanomaly('Protanomaly', 'Mild red weakness'),

  /// Tritanopia (blue-yellow colorblindness) - rare (~0.01%)
  /// Difficulty distinguishing blue from green, yellow from violet
  tritanopia('Tritanopia', 'Blue-yellow'),

  /// Tritanomaly (mild blue-yellow) - very rare
  /// Blue appears greener, difficulty with blue-yellow
  tritanomaly('Tritanomaly', 'Mild blue-yellow'),

  /// Achromatopsia (complete colorblindness) - very rare (~0.003%)
  /// Only sees in grayscale, uses patterns/shapes for distinction
  achromatopsia('Achromatopsia', 'Monochrome (no color)'),

  /// High contrast mode with patterns
  /// Uses patterns/textures in addition to colors for maximum distinction
  highContrast('High Contrast', 'Patterns + labels');

  final String displayName;
  final String description;

  const ColorblindMode(this.displayName, this.description);

  static ColorblindMode fromString(String? value) {
    if (value == null) return ColorblindMode.none;
    return ColorblindMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => ColorblindMode.none,
    );
  }
}

/// Manages accessibility settings
/// Settings are stored locally via SharedPreferences (display preferences, not synced data)
class AccessibilityProvider extends ChangeNotifier {
  static const String _colorblindModeKey = 'colorblind_mode';
  static const String _showRingLabelsKey = 'show_ring_labels';

  ColorblindMode _colorblindMode = ColorblindMode.none;
  bool _showRingLabels = false;
  bool _isLoaded = false;

  // Getters
  ColorblindMode get colorblindMode => _colorblindMode;
  bool get showRingLabels => _showRingLabels;
  bool get isLoaded => _isLoaded;

  /// Whether any colorblind mode is active
  bool get isColorblindModeActive => _colorblindMode != ColorblindMode.none;

  /// Whether to use patterns (high contrast mode)
  bool get usePatterns => _colorblindMode == ColorblindMode.highContrast;

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _colorblindMode = ColorblindMode.fromString(prefs.getString(_colorblindModeKey));
      _showRingLabels = prefs.getBool(_showRingLabelsKey) ?? false;
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading accessibility settings: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Set the colorblind mode
  Future<void> setColorblindMode(ColorblindMode mode) async {
    if (_colorblindMode == mode) return;

    _colorblindMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_colorblindModeKey, mode.name);
    } catch (e) {
      debugPrint('Error saving colorblind mode: $e');
    }
  }

  /// Toggle ring labels on target faces
  Future<void> setShowRingLabels(bool show) async {
    if (_showRingLabels == show) return;

    _showRingLabels = show;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showRingLabelsKey, show);
    } catch (e) {
      debugPrint('Error saving ring labels setting: $e');
    }
  }
}
