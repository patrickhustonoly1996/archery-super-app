import '../widgets/temperature_slider.dart';

/// A shooting venue/location where sightmarks are recorded
/// Used for location-based sightmark memory and suggestions
class Venue {
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final TemperatureRegion temperatureRegion;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Venue({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.temperatureRegion = TemperatureRegion.temperate,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if venue has GPS coordinates
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Get display string for location
  String get locationDisplay {
    if (!hasCoordinates) return 'No GPS';
    return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
  }

  Venue copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    TemperatureRegion? temperatureRegion,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Venue(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      temperatureRegion: temperatureRegion ?? this.temperatureRegion,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Venue($name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Venue && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Summary of sightmark history at a venue
class VenueSightmarkSummary {
  final String venueId;
  final String venueName;
  final int totalMarks;
  final DateTime? lastVisit;

  /// Average adjustment from baseline for this venue (positive = higher sight)
  /// Null if not enough data
  final double? averageAdjustment;

  /// Confidence in the adjustment (0-1)
  final double confidence;

  const VenueSightmarkSummary({
    required this.venueId,
    required this.venueName,
    required this.totalMarks,
    this.lastVisit,
    this.averageAdjustment,
    this.confidence = 0.0,
  });

  /// Whether we have enough data to suggest an adjustment
  bool get canSuggestAdjustment =>
      totalMarks >= 3 && averageAdjustment != null && confidence >= 0.5;

  /// Get a human-readable suggestion
  String? getSuggestion() {
    if (!canSuggestAdjustment) return null;

    final adj = averageAdjustment!;
    if (adj.abs() < 0.05) {
      return 'Sightmarks typically match baseline at this venue';
    }

    final direction = adj > 0 ? 'higher' : 'lower';
    final amount = adj.abs().toStringAsFixed(2);

    return 'Sightmarks typically run $amount $direction here';
  }
}

/// Sightmark adjustment data for venue intelligence
class VenueAdjustmentData {
  final String venueId;
  final double distance;
  final String unit;

  /// Difference from predicted baseline (positive = sight was higher than predicted)
  final double adjustment;

  final DateTime recordedAt;

  const VenueAdjustmentData({
    required this.venueId,
    required this.distance,
    required this.unit,
    required this.adjustment,
    required this.recordedAt,
  });
}
