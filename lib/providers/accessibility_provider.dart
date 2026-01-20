import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Text size scaling options
enum TextScaleOption {
  small('Small', 0.85),
  normal('Normal', 1.0),
  large('Large', 1.15),
  extraLarge('Extra Large', 1.3);

  final String displayName;
  final double scaleFactor;

  const TextScaleOption(this.displayName, this.scaleFactor);

  static TextScaleOption fromString(String? value) {
    if (value == null) return TextScaleOption.normal;
    return TextScaleOption.values.firstWhere(
      (o) => o.name == value,
      orElse: () => TextScaleOption.normal,
    );
  }
}

/// Temperature unit options
enum TemperatureUnit {
  celsius('Celsius', '°C'),
  fahrenheit('Fahrenheit', '°F');

  final String displayName;
  final String symbol;

  const TemperatureUnit(this.displayName, this.symbol);

  static TemperatureUnit fromString(String? value) {
    if (value == 'fahrenheit') return TemperatureUnit.fahrenheit;
    return TemperatureUnit.celsius;
  }

  /// Convert temperature to this unit from Celsius
  double fromCelsius(double celsius) {
    if (this == fahrenheit) {
      return (celsius * 9 / 5) + 32;
    }
    return celsius;
  }

  /// Convert temperature from this unit to Celsius
  double toCelsius(double value) {
    if (this == fahrenheit) {
      return (value - 32) * 5 / 9;
    }
    return value;
  }

  /// Format temperature for display
  String format(double? celsius) {
    if (celsius == null) return '--$symbol';
    final value = fromCelsius(celsius);
    return '${value.round()}$symbol';
  }
}

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
  static const String _textScaleKey = 'text_scale';
  static const String _reduceMotionKey = 'reduce_motion';
  static const String _boldTextKey = 'bold_text';
  static const String _screenReaderOptimizedKey = 'screen_reader_optimized';
  static const String _temperatureUnitKey = 'temperature_unit';

  ColorblindMode _colorblindMode = ColorblindMode.none;
  bool _showRingLabels = false;
  TextScaleOption _textScale = TextScaleOption.large; // Default to Large for better readability
  bool _reduceMotion = false;
  bool _boldText = false;
  bool _screenReaderOptimized = false;
  TemperatureUnit _temperatureUnit = TemperatureUnit.celsius;
  bool _isLoaded = false;

  // Getters
  ColorblindMode get colorblindMode => _colorblindMode;
  bool get showRingLabels => _showRingLabels;
  TextScaleOption get textScale => _textScale;
  double get textScaleFactor => _textScale.scaleFactor;
  String get textScalePercentage => '${(_textScale.scaleFactor * 100).round()}%';
  double get minTextScale => 0.85; // TextScaleOption.small
  double get maxTextScale => 1.30; // TextScaleOption.extraLarge
  bool get reduceMotion => _reduceMotion;
  bool get boldText => _boldText;
  bool get screenReaderOptimized => _screenReaderOptimized;
  TemperatureUnit get temperatureUnit => _temperatureUnit;
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
      _textScale = TextScaleOption.fromString(prefs.getString(_textScaleKey));
      _reduceMotion = prefs.getBool(_reduceMotionKey) ?? false;
      _boldText = prefs.getBool(_boldTextKey) ?? false;
      _screenReaderOptimized = prefs.getBool(_screenReaderOptimizedKey) ?? false;
      _temperatureUnit = TemperatureUnit.fromString(prefs.getString(_temperatureUnitKey));
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

  /// Set text scaling option
  Future<void> setTextScale(TextScaleOption scale) async {
    if (_textScale == scale) return;

    _textScale = scale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_textScaleKey, scale.name);
    } catch (e) {
      debugPrint('Error saving text scale: $e');
    }
  }

  /// Set text scale by factor (maps to nearest TextScaleOption)
  Future<void> setTextScaleFactor(double factor) async {
    TextScaleOption option;
    if (factor <= 0.92) {
      option = TextScaleOption.small;
    } else if (factor <= 1.07) {
      option = TextScaleOption.normal;
    } else if (factor <= 1.22) {
      option = TextScaleOption.large;
    } else {
      option = TextScaleOption.extraLarge;
    }
    await setTextScale(option);
  }

  /// Reset to default text scale
  Future<void> resetTextScale() async {
    await setTextScale(TextScaleOption.normal);
  }

  /// Toggle reduced motion (disables animations)
  Future<void> setReduceMotion(bool reduce) async {
    if (_reduceMotion == reduce) return;

    _reduceMotion = reduce;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reduceMotionKey, reduce);
    } catch (e) {
      debugPrint('Error saving reduce motion: $e');
    }
  }

  /// Toggle bold text
  Future<void> setBoldText(bool bold) async {
    if (_boldText == bold) return;

    _boldText = bold;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_boldTextKey, bold);
    } catch (e) {
      debugPrint('Error saving bold text: $e');
    }
  }

  /// Toggle screen reader optimization (enhanced semantic labels)
  Future<void> setScreenReaderOptimized(bool optimized) async {
    if (_screenReaderOptimized == optimized) return;

    _screenReaderOptimized = optimized;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_screenReaderOptimizedKey, optimized);
    } catch (e) {
      debugPrint('Error saving screen reader optimization: $e');
    }
  }

  /// Set temperature unit preference
  Future<void> setTemperatureUnit(TemperatureUnit unit) async {
    if (_temperatureUnit == unit) return;

    _temperatureUnit = unit;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_temperatureUnitKey, unit.name);
    } catch (e) {
      debugPrint('Error saving temperature unit: $e');
    }
  }

  /// Format temperature in the user's preferred unit
  /// [celsius] - Temperature in Celsius
  String formatTemperature(double? celsius) {
    return _temperatureUnit.format(celsius);
  }
}
