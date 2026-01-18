import 'dart:convert';

/// Weather/field conditions captured when recording a sight mark
/// Focused on what archers actually know and observe
class WeatherConditions {
  final double? temperature; // Celsius (optional)
  final String? sky; // 'sunny', 'cloudy', 'overcast', 'rainy'
  final String? sunPosition; // 'in_face', 'behind', 'left', 'right', 'overhead', 'none'
  final String? wind; // 'none', 'light', 'moderate', 'strong'

  const WeatherConditions({
    this.temperature,
    this.sky,
    this.sunPosition,
    this.wind,
  });

  factory WeatherConditions.fromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return const WeatherConditions();
    }
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return WeatherConditions.fromMap(map);
    } catch (e) {
      return const WeatherConditions();
    }
  }

  factory WeatherConditions.fromMap(Map<String, dynamic> map) {
    return WeatherConditions(
      temperature: _parseDouble(map['temperature']),
      sky: map['sky'] as String? ?? map['description'] as String?, // backwards compat
      sunPosition: map['sunPosition'] as String?,
      wind: map['wind'] as String?,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      if (temperature != null) 'temperature': temperature,
      if (sky != null) 'sky': sky,
      if (sunPosition != null) 'sunPosition': sunPosition,
      if (wind != null) 'wind': wind,
    };
  }

  String toJson() {
    final map = toMap();
    if (map.isEmpty) return '';
    return json.encode(map);
  }

  WeatherConditions copyWith({
    double? temperature,
    String? sky,
    String? sunPosition,
    String? wind,
  }) {
    return WeatherConditions(
      temperature: temperature ?? this.temperature,
      sky: sky ?? this.sky,
      sunPosition: sunPosition ?? this.sunPosition,
      wind: wind ?? this.wind,
    );
  }

  bool get hasAnyData =>
      temperature != null ||
      sky != null ||
      sunPosition != null ||
      wind != null;

  /// Get a summary string for display
  String get summaryText {
    final parts = <String>[];

    if (temperature != null) {
      parts.add('${temperature!.toStringAsFixed(0)}°C');
    }
    if (sky != null) {
      parts.add(_skyDisplayName(sky!));
    }
    if (sunPosition != null && sunPosition != 'none') {
      parts.add('Sun ${_sunPositionDisplayName(sunPosition!)}');
    }
    if (wind != null && wind != 'none') {
      parts.add('${_windDisplayName(wind!)} wind');
    }

    return parts.isEmpty ? 'No conditions recorded' : parts.join(' · ');
  }

  static String _skyDisplayName(String sky) {
    switch (sky) {
      case 'sunny': return 'Sunny';
      case 'cloudy': return 'Cloudy';
      case 'overcast': return 'Overcast';
      case 'rainy': return 'Rainy';
      default: return sky;
    }
  }

  static String _sunPositionDisplayName(String pos) {
    switch (pos) {
      case 'in_face': return 'in face';
      case 'behind': return 'behind';
      case 'left': return 'on left';
      case 'right': return 'on right';
      case 'overhead': return 'overhead';
      case 'none': return '';
      default: return pos;
    }
  }

  static String _windDisplayName(String wind) {
    switch (wind) {
      case 'none': return 'No';
      case 'light': return 'Light';
      case 'moderate': return 'Moderate';
      case 'strong': return 'Strong';
      default: return wind;
    }
  }

  @override
  String toString() => 'WeatherConditions($summaryText)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherConditions &&
        other.temperature == temperature &&
        other.sky == sky &&
        other.sunPosition == sunPosition &&
        other.wind == wind;
  }

  @override
  int get hashCode => Object.hash(temperature, sky, sunPosition, wind);
}

/// Sky condition options
class SkyOptions {
  static const sunny = 'sunny';
  static const cloudy = 'cloudy';
  static const overcast = 'overcast';
  static const rainy = 'rainy';

  static const all = [sunny, cloudy, overcast, rainy];

  static String displayName(String value) {
    switch (value) {
      case sunny: return 'Sunny';
      case cloudy: return 'Cloudy';
      case overcast: return 'Overcast';
      case rainy: return 'Rainy';
      default: return value;
    }
  }
}

/// Sun position options
class SunPositionOptions {
  static const inFace = 'in_face';
  static const behind = 'behind';
  static const left = 'left';
  static const right = 'right';
  static const overhead = 'overhead';
  static const none = 'none';

  static const all = [none, inFace, behind, left, right, overhead];

  static String displayName(String value) {
    switch (value) {
      case inFace: return 'In face';
      case behind: return 'Behind';
      case left: return 'Left';
      case right: return 'Right';
      case overhead: return 'Overhead';
      case none: return 'N/A';
      default: return value;
    }
  }
}

/// Wind strength options
class WindOptions {
  static const none = 'none';
  static const light = 'light';
  static const moderate = 'moderate';
  static const strong = 'strong';

  static const all = [none, light, moderate, strong];

  static String displayName(String value) {
    switch (value) {
      case none: return 'None';
      case light: return 'Light';
      case moderate: return 'Moderate';
      case strong: return 'Strong';
      default: return value;
    }
  }
}
