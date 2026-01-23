import 'dart:convert';
import 'field_course.dart';
import 'sight_mark.dart';

/// Peg types for IFAA field archery
enum PegType {
  /// Single peg - one shooting position
  single,
  /// Fan - multiple pegs at different distances, archer chooses one
  fan,
  /// Walk-down - shoot from furthest to closest, one arrow each
  walkDown,
  /// Walk-up - shoot from closest to furthest (animal rounds)
  walkUp;

  static PegType fromString(String value) {
    return PegType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => PegType.single,
    );
  }
}

/// Individual peg position within a target
class PegPosition {
  final double distance;
  final DistanceUnit unit;
  final String? label; // e.g., "1", "2", "3", "4" or "Near", "Far"

  const PegPosition({
    required this.distance,
    required this.unit,
    this.label,
  });

  /// Distance in meters for calculations
  double get distanceInMeters => unit.toMeters(distance);

  /// Display string
  String get displayString => '${distance.toStringAsFixed(0)}${unit.abbreviation}';

  Map<String, dynamic> toJson() => {
        'distance': distance,
        'unit': unit.name,
        'label': label,
      };

  factory PegPosition.fromJson(Map<String, dynamic> json) {
    return PegPosition(
      distance: (json['distance'] as num).toDouble(),
      unit: DistanceUnit.fromString(json['unit'] as String?),
      label: json['label'] as String?,
    );
  }

  @override
  String toString() => displayString;
}

/// Configuration of pegs for a target
class PegConfiguration {
  final PegType type;
  final List<PegPosition> positions;

  const PegConfiguration({
    required this.type,
    required this.positions,
  });

  /// Single peg convenience constructor
  factory PegConfiguration.single(double distance, DistanceUnit unit) {
    return PegConfiguration(
      type: PegType.single,
      positions: [PegPosition(distance: distance, unit: unit)],
    );
  }

  /// Walk-down convenience constructor
  factory PegConfiguration.walkDown(List<double> distances, DistanceUnit unit) {
    return PegConfiguration(
      type: PegType.walkDown,
      positions: distances
          .asMap()
          .entries
          .map((e) => PegPosition(
                distance: e.value,
                unit: unit,
                label: '${e.key + 1}',
              ))
          .toList(),
    );
  }

  /// Walk-up convenience constructor (animal rounds)
  factory PegConfiguration.walkUp(List<double> distances, DistanceUnit unit) {
    return PegConfiguration(
      type: PegType.walkUp,
      positions: distances
          .asMap()
          .entries
          .map((e) => PegPosition(
                distance: e.value,
                unit: unit,
                label: '${e.key + 1}',
              ))
          .toList(),
    );
  }

  /// Fan peg convenience constructor
  factory PegConfiguration.fan(List<double> distances, DistanceUnit unit) {
    return PegConfiguration(
      type: PegType.fan,
      positions: distances
          .map((d) => PegPosition(distance: d, unit: unit))
          .toList(),
    );
  }

  /// Primary distance (longest for walk-down, shortest for walk-up, only for single)
  double get primaryDistance {
    if (positions.isEmpty) return 0;
    switch (type) {
      case PegType.single:
      case PegType.fan:
        return positions.first.distance;
      case PegType.walkDown:
        // Walk-down: furthest first
        return positions.map((p) => p.distance).reduce((a, b) => a > b ? a : b);
      case PegType.walkUp:
        // Walk-up: nearest first
        return positions.map((p) => p.distance).reduce((a, b) => a < b ? a : b);
    }
  }

  /// Unit of the first position
  DistanceUnit get unit => positions.isNotEmpty ? positions.first.unit : DistanceUnit.meters;

  /// Number of shooting positions
  int get positionCount => positions.length;

  /// Whether this requires multiple arrows shot sequentially
  bool get isSequential => type == PegType.walkDown || type == PegType.walkUp;

  /// Display string (e.g., "80-70-60-50yd walk-down")
  String get displayString {
    if (positions.isEmpty) return 'No pegs';
    if (type == PegType.single) {
      return positions.first.displayString;
    }
    final distances = positions.map((p) => p.distance.toStringAsFixed(0)).join('-');
    final unitStr = unit.abbreviation;
    final typeStr = type == PegType.walkDown
        ? ' walk-down'
        : type == PegType.walkUp
            ? ' walk-up'
            : ' fan';
    return '$distances$unitStr$typeStr';
  }

  String toJson() => jsonEncode({
        'type': type.name,
        'positions': positions.map((p) => p.toJson()).toList(),
      });

  factory PegConfiguration.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return PegConfiguration(
      type: PegType.fromString(map['type'] as String),
      positions: (map['positions'] as List)
          .map((p) => PegPosition.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() => displayString;
}

/// A single target within a field course
class FieldCourseTarget {
  final String id;
  final String courseId;
  final int targetNumber; // 1-indexed
  final PegConfiguration pegConfig;
  final int faceSize; // cm
  final double primaryDistance;
  final DistanceUnit unit;
  final bool isWalkUp; // For animal rounds
  final bool isWalkDown; // For field rounds with walk-down pegs
  final int arrowsRequired;
  final String? notes;

  const FieldCourseTarget({
    required this.id,
    required this.courseId,
    required this.targetNumber,
    required this.pegConfig,
    required this.faceSize,
    required this.primaryDistance,
    required this.unit,
    this.isWalkUp = false,
    this.isWalkDown = false,
    required this.arrowsRequired,
    this.notes,
  });

  /// Calculate max score for this target based on round type
  int getMaxScore(FieldRoundType roundType) {
    switch (roundType) {
      case FieldRoundType.field:
      case FieldRoundType.hunter:
        return arrowsRequired * 5; // 5-4-3 scoring, max 5 per arrow
      case FieldRoundType.expert:
        return arrowsRequired * 5; // 5-4-3-2-1 scoring, max 5 per arrow
      case FieldRoundType.animal:
        return 21; // Best case: first arrow vital hit
      case FieldRoundType.marked3dStandard:
        return arrowsRequired * 11; // 11-10-8-5 scoring
      case FieldRoundType.marked3dHunting:
        return 20; // Kill shot
    }
  }

  /// Default max score (assumes field round type)
  int get maxScore => arrowsRequired * 5;

  /// Display string for distance
  String get distanceDisplay =>
      '${primaryDistance.toStringAsFixed(0)}${unit.abbreviation}';

  /// Display string for face size
  String get faceSizeDisplay => '${faceSize}cm';

  FieldCourseTarget copyWith({
    String? id,
    String? courseId,
    int? targetNumber,
    PegConfiguration? pegConfig,
    int? faceSize,
    double? primaryDistance,
    DistanceUnit? unit,
    bool? isWalkUp,
    bool? isWalkDown,
    int? arrowsRequired,
    String? notes,
  }) {
    return FieldCourseTarget(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      targetNumber: targetNumber ?? this.targetNumber,
      pegConfig: pegConfig ?? this.pegConfig,
      faceSize: faceSize ?? this.faceSize,
      primaryDistance: primaryDistance ?? this.primaryDistance,
      unit: unit ?? this.unit,
      isWalkUp: isWalkUp ?? this.isWalkUp,
      isWalkDown: isWalkDown ?? this.isWalkDown,
      arrowsRequired: arrowsRequired ?? this.arrowsRequired,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'FieldCourseTarget(#$targetNumber: $distanceDisplay, ${faceSizeDisplay})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FieldCourseTarget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Standard IFAA face sizes based on distance (in yards)
class IFAAFaceSizes {
  static const Map<int, int> fieldFaceSizes = {
    80: 65, // 80yd -> 65cm face
    70: 65,
    65: 50,
    60: 50,
    55: 50,
    50: 50,
    45: 35,
    40: 35,
    35: 35,
    30: 20,
    25: 20,
    20: 20,
    15: 20,
  };

  /// Get face size for a given distance (yards)
  static int getFaceSize(double distanceYards) {
    // Find the closest matching distance
    final roundedDist = distanceYards.round();
    if (fieldFaceSizes.containsKey(roundedDist)) {
      return fieldFaceSizes[roundedDist]!;
    }
    // Default based on range
    if (distanceYards >= 65) return 65;
    if (distanceYards >= 45) return 50;
    if (distanceYards >= 25) return 35;
    return 20;
  }
}

/// Standard IFAA peg configurations
class IFAAPegPresets {
  /// Standard field round walk-down pegs
  static const List<List<double>> fieldWalkDowns = [
    [80, 70, 60, 50], // 80yd walk-down
    [70, 65, 61, 58],
    [65, 60, 55, 50],
    [60, 55, 50, 45],
    [55, 50, 45, 40],
    [50, 45, 40, 35],
    [45, 40, 36, 32],
    [40, 35, 30, 25],
    [35, 30, 25, 20],
    [30, 25, 20, 15],
  ];

  /// Standard fan peg configurations
  static const List<List<double>> fieldFans = [
    [55, 52, 49, 46], // Fan at ~50yd
    [45, 42, 39, 36],
    [35, 32, 29, 26],
  ];

  /// Animal round walk-up distances (3 stations)
  static const List<List<double>> animalWalkUps = [
    [60, 50, 40], // Group 1
    [45, 38, 30], // Group 2
    [35, 28, 20], // Group 3
    [25, 20, 15], // Group 4
  ];
}
