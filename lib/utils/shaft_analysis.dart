import 'dart:math' as math;
import '../db/database.dart';

/// Analysis result for a single shaft
class ShaftAnalysisResult {
  final Shaft shaft;
  final int arrowCount;
  final double avgXMm;
  final double avgYMm;
  final double avgDeviationMm; // Average distance from shaft's group center
  final double groupSpreadMm; // Max distance between any two arrows
  final Map<int, int> scoreDistribution; // score -> count
  final double avgScore;
  final int outlierCount; // Arrows > 2 std dev from group center
  final bool shouldRetire; // Recommendation based on performance
  final double overlapLikelihood; // 0-1, likelihood of shaft overlap with others

  ShaftAnalysisResult({
    required this.shaft,
    required this.arrowCount,
    required this.avgXMm,
    required this.avgYMm,
    required this.avgDeviationMm,
    required this.groupSpreadMm,
    required this.scoreDistribution,
    required this.avgScore,
    required this.outlierCount,
    required this.shouldRetire,
    required this.overlapLikelihood,
  });

  /// Get recommendation text
  String get recommendation {
    if (arrowCount < 10) {
      return 'Need more shots for reliable analysis (minimum 10)';
    }

    if (shouldRetire) {
      return 'Consider retiring - performance significantly worse than average';
    }

    if (outlierCount > arrowCount * 0.3) {
      return 'Inconsistent - high number of outliers';
    }

    if (avgScore > 8.5) {
      return 'Performing well - keep using';
    }

    if (avgScore < 7.0) {
      return 'Below average - check fletching and nock';
    }

    return 'Average performance';
  }

  /// Get color code for UI (green, yellow, red)
  String get performanceColor {
    if (arrowCount < 10) return 'gray';
    if (shouldRetire) return 'red';
    if (avgScore > 8.5) return 'green';
    if (avgScore < 7.0) return 'yellow';
    return 'green';
  }
}

/// Analyze shaft performance from arrow data
class ShaftAnalysis {
  /// Analyze a single shaft's performance
  static ShaftAnalysisResult analyzeShaft({
    required Shaft shaft,
    required List<Arrow> arrows,
    required List<Arrow> allArrows, // For comparison
  }) {
    if (arrows.isEmpty) {
      return ShaftAnalysisResult(
        shaft: shaft,
        arrowCount: 0,
        avgXMm: 0,
        avgYMm: 0,
        avgDeviationMm: 0,
        groupSpreadMm: 0,
        scoreDistribution: {},
        avgScore: 0,
        outlierCount: 0,
        shouldRetire: false,
        overlapLikelihood: 0,
      );
    }

    // Calculate group center
    final avgX = arrows.map((a) => a.xMm).reduce((a, b) => a + b) / arrows.length;
    final avgY = arrows.map((a) => a.yMm).reduce((a, b) => a + b) / arrows.length;

    // Calculate deviations
    final deviations = arrows.map((a) {
      final dx = a.xMm - avgX;
      final dy = a.yMm - avgY;
      return math.sqrt(dx * dx + dy * dy);
    }).toList();

    final avgDeviation = deviations.reduce((a, b) => a + b) / deviations.length;
    final stdDeviation = _calculateStdDev(deviations);

    // Calculate group spread (max distance between any two arrows)
    double maxSpread = 0;
    for (int i = 0; i < arrows.length; i++) {
      for (int j = i + 1; j < arrows.length; j++) {
        final dx = arrows[i].xMm - arrows[j].xMm;
        final dy = arrows[i].yMm - arrows[j].yMm;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist > maxSpread) maxSpread = dist;
      }
    }

    // Score distribution
    final scoreDistribution = <int, int>{};
    for (final arrow in arrows) {
      scoreDistribution[arrow.score] = (scoreDistribution[arrow.score] ?? 0) + 1;
    }

    final avgScore = arrows.map((a) => a.score).reduce((a, b) => a + b) / arrows.length;

    // Count outliers (> 2 std dev from center)
    final outlierThreshold = avgDeviation + (2 * stdDeviation);
    final outlierCount = deviations.where((d) => d > outlierThreshold).length;

    // Calculate overall average for comparison
    final overallAvgScore = allArrows.isEmpty
        ? avgScore
        : allArrows.map((a) => a.score).reduce((a, b) => a + b) / allArrows.length;

    // Retirement recommendation (significantly worse than average)
    final shouldRetire = arrows.length >= 20 &&
                        avgScore < (overallAvgScore - 1.5) &&
                        outlierCount > arrows.length * 0.3;

    // Calculate overlap likelihood
    final overlapLikelihood = _calculateOverlapLikelihood(
      arrows,
      allArrows,
      avgX,
      avgY,
    );

    return ShaftAnalysisResult(
      shaft: shaft,
      arrowCount: arrows.length,
      avgXMm: avgX,
      avgYMm: avgY,
      avgDeviationMm: avgDeviation,
      groupSpreadMm: maxSpread,
      scoreDistribution: scoreDistribution,
      avgScore: avgScore,
      outlierCount: outlierCount,
      shouldRetire: shouldRetire,
      overlapLikelihood: overlapLikelihood,
    );
  }

  /// Analyze all shafts in a quiver
  static Future<List<ShaftAnalysisResult>> analyzeQuiver({
    required List<Shaft> shafts,
    required List<Arrow> allArrows,
  }) async {
    final results = <ShaftAnalysisResult>[];

    for (final shaft in shafts) {
      // Get arrows for this shaft
      final shaftArrows = allArrows.where((a) => a.shaftId == shaft.id).toList();

      final result = analyzeShaft(
        shaft: shaft,
        arrows: shaftArrows,
        allArrows: allArrows,
      );

      results.add(result);
    }

    // Sort by arrow count descending (most used first)
    results.sort((a, b) => b.arrowCount.compareTo(a.arrowCount));

    return results;
  }

  /// Calculate standard deviation
  static double _calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
        .map((v) => math.pow(v - mean, 2))
        .reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }

  /// Calculate likelihood of overlap with other shafts (0-1)
  /// Higher values indicate this shaft groups differently than others
  static double _calculateOverlapLikelihood(
    List<Arrow> shaftArrows,
    List<Arrow> allArrows,
    double shaftAvgX,
    double shaftAvgY,
  ) {
    if (shaftArrows.length < 5 || allArrows.length < 20) return 0;

    // Calculate distance from shaft center to overall center
    final overallAvgX = allArrows.map((a) => a.xMm).reduce((a, b) => a + b) / allArrows.length;
    final overallAvgY = allArrows.map((a) => a.yMm).reduce((a, b) => a + b) / allArrows.length;

    final dx = shaftAvgX - overallAvgX;
    final dy = shaftAvgY - overallAvgY;
    final distanceFromCenter = math.sqrt(dx * dx + dy * dy);

    // Calculate average deviation for this shaft
    final shaftDeviations = shaftArrows.map((a) {
      final dx = a.xMm - shaftAvgX;
      final dy = a.yMm - shaftAvgY;
      return math.sqrt(dx * dx + dy * dy);
    }).toList();
    final shaftAvgDeviation = shaftDeviations.reduce((a, b) => a + b) / shaftDeviations.length;

    // If shaft center is far from overall center relative to shaft spread,
    // it's likely distinguishable
    if (shaftAvgDeviation == 0) return 0;

    final separationRatio = distanceFromCenter / shaftAvgDeviation;

    // Convert to 0-1 scale (clamp at 1.0)
    // Ratio > 2 means very distinguishable
    return math.min(separationRatio / 2, 1.0);
  }

  /// Get shafts that should be retired based on analysis
  static List<Shaft> getRetirementCandidates(List<ShaftAnalysisResult> results) {
    return results
        .where((r) => r.shouldRetire)
        .map((r) => r.shaft)
        .toList();
  }

  /// Get warning about potential overlap issues
  static String? getOverlapWarning(List<ShaftAnalysisResult> results) {
    final highOverlap = results.where((r) =>
      r.arrowCount >= 10 && r.overlapLikelihood > 0.7
    ).toList();

    if (highOverlap.isEmpty) return null;

    final shaftNumbers = highOverlap.map((r) => r.shaft.number).join(', ');
    return 'Shafts $shaftNumbers show distinct grouping - may help identify technique issues';
  }
}
