import 'dart:math' as math;
import '../db/database.dart';

/// Result of comparing shaft combinations
class ShaftCombinationResult {
  final List<Shaft> shafts;
  final List<Arrow> arrows;
  final double groupSpreadMm; // Max distance between any two arrows
  final double centerXMm;
  final double centerYMm;
  final double avgDeviationMm; // Average distance from group center

  ShaftCombinationResult({
    required this.shafts,
    required this.arrows,
    required this.groupSpreadMm,
    required this.centerXMm,
    required this.centerYMm,
    required this.avgDeviationMm,
  });

  /// Shaft numbers as display string
  String get shaftNumbersDisplay {
    final numbers = shafts.map((s) => s.number).toList()..sort();
    return numbers.join(', ');
  }

  /// Center offset from target center in mm
  double get centerOffsetMm =>
      math.sqrt(centerXMm * centerXMm + centerYMm * centerYMm);

  /// Clock position of center offset (1-12, 12 = up)
  int get centerOffsetClock {
    if (centerOffsetMm < 1) return 12; // Essentially centered
    final angle = math.atan2(-centerXMm, -centerYMm); // Flip for target coords
    final degrees = (angle * 180 / math.pi + 180) % 360;
    final clock = ((degrees + 15) / 30).floor() % 12;
    return clock == 0 ? 12 : clock;
  }
}

/// Per-shaft statistics for the comparison view
class ShaftComparisonStats {
  final Shaft shaft;
  final List<Arrow> arrows;
  final double centerXMm;
  final double centerYMm;
  final double groupSpreadMm;
  final double avgDeviationMm;
  final double avgScore;

  ShaftComparisonStats({
    required this.shaft,
    required this.arrows,
    required this.centerXMm,
    required this.centerYMm,
    required this.groupSpreadMm,
    required this.avgDeviationMm,
    required this.avgScore,
  });

  int get arrowCount => arrows.length;
}

/// Shaft comparison and selection algorithms
class ShaftComparison {
  /// Calculate group spread (max pairwise distance) for a set of arrows
  static double calculateGroupSpread(List<Arrow> arrows) {
    if (arrows.length < 2) return 0;

    double maxSpread = 0;
    for (int i = 0; i < arrows.length; i++) {
      for (int j = i + 1; j < arrows.length; j++) {
        final dx = arrows[i].xMm - arrows[j].xMm;
        final dy = arrows[i].yMm - arrows[j].yMm;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist > maxSpread) maxSpread = dist;
      }
    }
    return maxSpread;
  }

  /// Calculate group center for a set of arrows
  static (double centerX, double centerY) calculateGroupCenter(
      List<Arrow> arrows) {
    if (arrows.isEmpty) return (0, 0);

    final avgX = arrows.map((a) => a.xMm).reduce((a, b) => a + b) / arrows.length;
    final avgY = arrows.map((a) => a.yMm).reduce((a, b) => a + b) / arrows.length;
    return (avgX, avgY);
  }

  /// Calculate average deviation from center
  static double calculateAvgDeviation(
      List<Arrow> arrows, double centerX, double centerY) {
    if (arrows.isEmpty) return 0;

    final deviations = arrows.map((a) {
      final dx = a.xMm - centerX;
      final dy = a.yMm - centerY;
      return math.sqrt(dx * dx + dy * dy);
    });
    return deviations.reduce((a, b) => a + b) / arrows.length;
  }

  /// Get statistics for each shaft
  static List<ShaftComparisonStats> analyzeShafts({
    required List<Shaft> shafts,
    required List<Arrow> allArrows,
    int minRating = 3,
  }) {
    // Filter to rated arrows only
    final ratedArrows = allArrows.where((a) => a.rating >= minRating).toList();

    final results = <ShaftComparisonStats>[];
    for (final shaft in shafts) {
      final shaftArrows =
          ratedArrows.where((a) => a.shaftId == shaft.id).toList();
      if (shaftArrows.isEmpty) continue;

      final (centerX, centerY) = calculateGroupCenter(shaftArrows);
      final spread = calculateGroupSpread(shaftArrows);
      final avgDev = calculateAvgDeviation(shaftArrows, centerX, centerY);
      final avgScore = shaftArrows.map((a) => a.score).reduce((a, b) => a + b) /
          shaftArrows.length;

      results.add(ShaftComparisonStats(
        shaft: shaft,
        arrows: shaftArrows,
        centerXMm: centerX,
        centerYMm: centerY,
        groupSpreadMm: spread,
        avgDeviationMm: avgDev,
        avgScore: avgScore,
      ));
    }

    // Sort by arrow count descending
    results.sort((a, b) => b.arrowCount.compareTo(a.arrowCount));
    return results;
  }

  /// Analyze a specific combination of shafts
  static ShaftCombinationResult analyzeCombination({
    required List<Shaft> shafts,
    required List<Arrow> allArrows,
    int minRating = 3,
  }) {
    // Get arrows for selected shafts with rating filter
    final shaftIds = shafts.map((s) => s.id).toSet();
    final selectedArrows = allArrows
        .where((a) => a.shaftId != null && shaftIds.contains(a.shaftId))
        .where((a) => a.rating >= minRating)
        .toList();

    final (centerX, centerY) = calculateGroupCenter(selectedArrows);
    final spread = calculateGroupSpread(selectedArrows);
    final avgDev = calculateAvgDeviation(selectedArrows, centerX, centerY);

    return ShaftCombinationResult(
      shafts: shafts,
      arrows: selectedArrows,
      groupSpreadMm: spread,
      centerXMm: centerX,
      centerYMm: centerY,
      avgDeviationMm: avgDev,
    );
  }

  /// Find the best N shafts that produce the tightest group.
  /// Uses brute-force combination testing (feasible for ≤12 shafts).
  ///
  /// Returns null if there aren't enough shafts with data.
  static ShaftCombinationResult? findBestCombination({
    required int n,
    required List<Shaft> availableShafts,
    required List<Arrow> allArrows,
    int minRating = 3,
    int minArrowsPerShaft = 3,
  }) {
    // Filter to rated arrows
    final ratedArrows = allArrows.where((a) => a.rating >= minRating).toList();

    // Filter to shafts that have enough arrows
    final shaftsWithData = availableShafts.where((shaft) {
      final arrowCount =
          ratedArrows.where((a) => a.shaftId == shaft.id).length;
      return arrowCount >= minArrowsPerShaft;
    }).toList();

    if (shaftsWithData.length < n) return null;

    // Generate all combinations of n shafts
    final combinations = _combinations(shaftsWithData, n);

    ShaftCombinationResult? best;
    double bestSpread = double.infinity;

    for (final combo in combinations) {
      final result = analyzeCombination(
        shafts: combo,
        allArrows: ratedArrows,
        minRating: 0, // Already filtered
      );

      // Must have arrows to be valid
      if (result.arrows.isEmpty) continue;

      if (result.groupSpreadMm < bestSpread) {
        bestSpread = result.groupSpreadMm;
        best = result;
      }
    }

    return best;
  }

  /// Generate all combinations of k items from a list
  static List<List<T>> _combinations<T>(List<T> items, int k) {
    if (k == 0) return [[]];
    if (items.isEmpty) return [];
    if (k == items.length) return [items];

    final result = <List<T>>[];

    // Include first item
    final withFirst = _combinations(items.sublist(1), k - 1);
    for (final combo in withFirst) {
      result.add([items[0], ...combo]);
    }

    // Exclude first item
    result.addAll(_combinations(items.sublist(1), k));

    return result;
  }
}
