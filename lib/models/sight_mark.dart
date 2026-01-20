import 'weather_conditions.dart';

/// Distance unit for sight marks
enum DistanceUnit {
  meters('m'),
  yards('yd');

  final String abbreviation;
  const DistanceUnit(this.abbreviation);

  static DistanceUnit fromString(String? value) {
    if (value == 'yards' || value == 'yd') return DistanceUnit.yards;
    return DistanceUnit.meters;
  }

  String toDbString() => this == DistanceUnit.yards ? 'yards' : 'meters';

  /// Get the opposite unit
  DistanceUnit get other => this == meters ? yards : meters;

  /// Convert a distance to the other unit
  double convert(double distance) {
    if (this == meters) {
      // meters to yards
      return distance / 0.9144;
    } else {
      // yards to meters
      return distance * 0.9144;
    }
  }

  /// Convert to meters (for consistent calculations)
  double toMeters(double distance) {
    if (this == yards) return distance * 0.9144;
    return distance;
  }

  /// Convert from meters to this unit
  double fromMeters(double meters) {
    if (this == yards) return meters / 0.9144;
    return meters;
  }

  /// Common distances for this unit
  List<double> get commonDistances {
    if (this == meters) {
      return [18, 25, 30, 40, 50, 60, 70, 90];
    } else {
      return [20, 30, 40, 50, 60, 70, 80, 100];
    }
  }
}

/// Notation style for sight mark values
enum SightNotationStyle {
  /// Decimal notation: 5.14 (common in Europe)
  decimal,
  /// Whole number notation: 514 or 51.4 (common in US)
  whole;

  static SightNotationStyle fromString(String? value) {
    if (value == 'whole') return SightNotationStyle.whole;
    return SightNotationStyle.decimal;
  }

  String toDbString() => name;
}

/// Sight mark preferences for a specific bow
class SightMarkPreferences {
  final String bowId;
  final SightNotationStyle notationStyle;
  final int decimalPlaces;

  const SightMarkPreferences({
    required this.bowId,
    this.notationStyle = SightNotationStyle.decimal,
    this.decimalPlaces = 2,
  });

  SightMarkPreferences copyWith({
    SightNotationStyle? notationStyle,
    int? decimalPlaces,
  }) {
    return SightMarkPreferences(
      bowId: bowId,
      notationStyle: notationStyle ?? this.notationStyle,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
    );
  }
}

/// A single sight mark record
class SightMark {
  final String id;
  final String bowId;
  final double distance;
  final DistanceUnit unit;
  final String sightValue; // Stored as string to preserve user's notation
  final WeatherConditions? weather;
  final double? elevationDelta; // meters above/below reference
  final double? slopeAngle; // degrees (-15 to +15)
  final String? sessionId;
  final int? endNumber;
  final int? shotCount; // Number of arrows shot with this mark
  final double? confidenceScore; // 0.0 to 1.0
  final DateTime recordedAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const SightMark({
    required this.id,
    required this.bowId,
    required this.distance,
    required this.unit,
    required this.sightValue,
    this.weather,
    this.elevationDelta,
    this.slopeAngle,
    this.sessionId,
    this.endNumber,
    this.shotCount,
    this.confidenceScore,
    required this.recordedAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Parse sight value to a numeric value for calculations
  double get numericValue {
    final cleaned = sightValue.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Check if this is a valid sight mark
  bool get isValid => numericValue > 0 && distance > 0;

  /// Distance in meters (for calculations)
  double get distanceInMeters {
    if (unit == DistanceUnit.yards) {
      return distance * 0.9144; // yards to meters
    }
    return distance;
  }

  /// Confidence level category
  SightMarkConfidence get confidenceLevel {
    if (confidenceScore == null) return SightMarkConfidence.unknown;
    if (confidenceScore! >= 0.8) return SightMarkConfidence.high;
    if (confidenceScore! >= 0.5) return SightMarkConfidence.medium;
    return SightMarkConfidence.low;
  }

  /// Format the display string
  String get displayValue => sightValue;

  /// Format distance for display
  String get distanceDisplay => '${distance.toStringAsFixed(0)}${unit.abbreviation}';

  SightMark copyWith({
    String? id,
    String? bowId,
    double? distance,
    DistanceUnit? unit,
    String? sightValue,
    WeatherConditions? weather,
    double? elevationDelta,
    double? slopeAngle,
    String? sessionId,
    int? endNumber,
    int? shotCount,
    double? confidenceScore,
    DateTime? recordedAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return SightMark(
      id: id ?? this.id,
      bowId: bowId ?? this.bowId,
      distance: distance ?? this.distance,
      unit: unit ?? this.unit,
      sightValue: sightValue ?? this.sightValue,
      weather: weather ?? this.weather,
      elevationDelta: elevationDelta ?? this.elevationDelta,
      slopeAngle: slopeAngle ?? this.slopeAngle,
      sessionId: sessionId ?? this.sessionId,
      endNumber: endNumber ?? this.endNumber,
      shotCount: shotCount ?? this.shotCount,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      recordedAt: recordedAt ?? this.recordedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() => 'SightMark($distanceDisplay: $sightValue)';
}

/// Confidence level for sight marks
enum SightMarkConfidence {
  high, // 80%+ - Gold
  medium, // 50-80% - White
  low, // <50% - Gray
  unknown;

  bool get isHigh => this == high;
  bool get isMedium => this == medium;
  bool get isLow => this == low || this == unknown;
}

/// Predicted/interpolated sight mark
class PredictedSightMark {
  final double distance;
  final DistanceUnit unit;
  final double predictedValue;
  final SightMarkConfidence confidence;
  final String source; // 'exact', 'interpolated', 'extrapolated', 'similar_bow'
  final SightMark? basedOn; // The mark this prediction is based on (if exact)
  final List<SightMark>? interpolatedFrom; // Marks used for interpolation

  const PredictedSightMark({
    required this.distance,
    required this.unit,
    required this.predictedValue,
    required this.confidence,
    required this.source,
    this.basedOn,
    this.interpolatedFrom,
  });

  String get displayValue => predictedValue.toStringAsFixed(2);

  String get distanceDisplay => '${distance.toStringAsFixed(0)}${unit.abbreviation}';

  bool get isExact => source == 'exact';
  bool get isInterpolated => source == 'interpolated';
  bool get isExtrapolated => source == 'extrapolated';
  bool get isFromSimilarBow => source == 'similar_bow';

  @override
  String toString() => 'PredictedSightMark($distanceDisplay: $displayValue [$source])';
}
