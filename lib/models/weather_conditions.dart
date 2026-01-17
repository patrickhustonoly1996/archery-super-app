import 'dart:convert';

/// Weather conditions captured when recording a sight mark
class WeatherConditions {
  final double? temperature; // Celsius
  final double? humidity; // Percentage (0-100)
  final double? pressure; // hPa (hectopascals)
  final double? windSpeed; // m/s
  final double? windDirection; // degrees (0-360)
  final String? description; // e.g., "Sunny", "Overcast"

  const WeatherConditions({
    this.temperature,
    this.humidity,
    this.pressure,
    this.windSpeed,
    this.windDirection,
    this.description,
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
      humidity: _parseDouble(map['humidity']),
      pressure: _parseDouble(map['pressure']),
      windSpeed: _parseDouble(map['windSpeed']),
      windDirection: _parseDouble(map['windDirection']),
      description: map['description'] as String?,
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
      if (humidity != null) 'humidity': humidity,
      if (pressure != null) 'pressure': pressure,
      if (windSpeed != null) 'windSpeed': windSpeed,
      if (windDirection != null) 'windDirection': windDirection,
      if (description != null) 'description': description,
    };
  }

  String toJson() {
    final map = toMap();
    if (map.isEmpty) return '';
    return json.encode(map);
  }

  WeatherConditions copyWith({
    double? temperature,
    double? humidity,
    double? pressure,
    double? windSpeed,
    double? windDirection,
    String? description,
  }) {
    return WeatherConditions(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      windSpeed: windSpeed ?? this.windSpeed,
      windDirection: windDirection ?? this.windDirection,
      description: description ?? this.description,
    );
  }

  bool get hasAnyData =>
      temperature != null ||
      humidity != null ||
      pressure != null ||
      windSpeed != null;

  /// Get a summary string for display
  String get summaryText {
    final parts = <String>[];

    if (temperature != null) {
      parts.add('${temperature!.toStringAsFixed(0)}°C');
    }
    if (humidity != null) {
      parts.add('${humidity!.toStringAsFixed(0)}%');
    }
    if (pressure != null) {
      parts.add('${pressure!.toStringAsFixed(0)} hPa');
    }

    return parts.isEmpty ? 'No weather data' : parts.join(' | ');
  }

  /// Get temperature adjusted pressure (density altitude indicator)
  /// Higher values = thinner air = arrows fly faster/flatter
  double? get densityIndicator {
    if (temperature == null || pressure == null) return null;
    // Simple ISA correction factor
    return pressure! * (288.15 / (273.15 + temperature!));
  }

  @override
  String toString() => 'WeatherConditions($summaryText)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherConditions &&
        other.temperature == temperature &&
        other.humidity == humidity &&
        other.pressure == pressure &&
        other.windSpeed == windSpeed &&
        other.windDirection == windDirection &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(
        temperature,
        humidity,
        pressure,
        windSpeed,
        windDirection,
        description,
      );
}
