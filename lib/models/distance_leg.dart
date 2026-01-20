import 'dart:convert';

/// Represents a single distance leg in a multi-distance round.
///
/// Multi-distance rounds like York (100/80/60 yards) have multiple legs,
/// each shot at a different distance with a specific number of arrows.
class DistanceLeg {
  /// Distance value (e.g., 100, 80, 60)
  final int distance;

  /// Unit of measurement ('m' for meters, 'yd' for yards)
  final String unit;

  /// Number of arrows shot at this distance
  final int arrowCount;

  /// Target face size in cm (optional, if different from default)
  final int? faceSize;

  const DistanceLeg({
    required this.distance,
    required this.unit,
    required this.arrowCount,
    this.faceSize,
  });

  /// Number of ends at this distance (assuming 6 arrows per end for imperial,
  /// 3 for indoor). This is a computed property based on arrowCount.
  int endsForArrowsPerEnd(int arrowsPerEnd) => arrowCount ~/ arrowsPerEnd;

  /// Format distance with unit for display (e.g., "100yd", "70m")
  String get displayDistance => '$distance$unit';

  factory DistanceLeg.fromJson(Map<String, dynamic> json) {
    return DistanceLeg(
      distance: json['distance'] as int,
      unit: json['unit'] as String? ?? 'm',
      arrowCount: json['arrowCount'] as int,
      faceSize: json['faceSize'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'distance': distance,
    'unit': unit,
    'arrowCount': arrowCount,
    if (faceSize != null) 'faceSize': faceSize,
  };

  @override
  String toString() => 'DistanceLeg($displayDistance, $arrowCount arrows)';
}

/// Extension to parse distance legs from JSON string stored in database
extension DistanceLegsParser on String? {
  /// Parse JSON string into list of DistanceLeg objects.
  /// Returns null if string is null or empty.
  List<DistanceLeg>? parseDistanceLegs() {
    if (this == null || this!.isEmpty) return null;
    try {
      final List<dynamic> jsonList = jsonDecode(this!);
      return jsonList
          .map((e) => DistanceLeg.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }
}

/// Extension to encode distance legs to JSON for database storage
extension DistanceLegsEncoder on List<DistanceLeg> {
  /// Convert list of DistanceLeg to JSON string for database storage.
  String toDistanceLegsJson() {
    return jsonEncode(map((leg) => leg.toJson()).toList());
  }
}

/// Helper class for working with distance legs during a session
class DistanceLegTracker {
  final List<DistanceLeg> legs;
  final int arrowsPerEnd;

  DistanceLegTracker({
    required this.legs,
    required this.arrowsPerEnd,
  });

  /// Check if this is a multi-distance round
  bool get isMultiDistance => legs.length > 1;

  /// Get the leg index for a given end number (1-based)
  int getLegIndexForEnd(int endNumber) {
    int cumulativeEnds = 0;
    for (int i = 0; i < legs.length; i++) {
      cumulativeEnds += legs[i].endsForArrowsPerEnd(arrowsPerEnd);
      if (endNumber <= cumulativeEnds) {
        return i;
      }
    }
    return legs.length - 1; // Return last leg if past all
  }

  /// Get the distance leg for a given end number (1-based)
  DistanceLeg getLegForEnd(int endNumber) {
    return legs[getLegIndexForEnd(endNumber)];
  }

  /// Get the end number where each leg ends (for scorecard subtotals)
  /// Returns a list of end numbers marking the end of each leg.
  List<int> get legBoundaryEnds {
    final boundaries = <int>[];
    int cumulativeEnds = 0;
    for (final leg in legs) {
      cumulativeEnds += leg.endsForArrowsPerEnd(arrowsPerEnd);
      boundaries.add(cumulativeEnds);
    }
    return boundaries;
  }

  /// Check if a given end number is the last end of a distance leg
  bool isLegBoundary(int endNumber) {
    return legBoundaryEnds.contains(endNumber);
  }

  /// Get cumulative arrow count up to and including a specific leg index
  int cumulativeArrowsAtLeg(int legIndex) {
    int total = 0;
    for (int i = 0; i <= legIndex && i < legs.length; i++) {
      total += legs[i].arrowCount;
    }
    return total;
  }

  /// Get the first end number of a specific leg (1-based)
  int firstEndOfLeg(int legIndex) {
    if (legIndex == 0) return 1;
    int cumulativeEnds = 0;
    for (int i = 0; i < legIndex && i < legs.length; i++) {
      cumulativeEnds += legs[i].endsForArrowsPerEnd(arrowsPerEnd);
    }
    return cumulativeEnds + 1;
  }

  /// Get the last end number of a specific leg (1-based)
  int lastEndOfLeg(int legIndex) {
    int cumulativeEnds = 0;
    for (int i = 0; i <= legIndex && i < legs.length; i++) {
      cumulativeEnds += legs[i].endsForArrowsPerEnd(arrowsPerEnd);
    }
    return cumulativeEnds;
  }
}
