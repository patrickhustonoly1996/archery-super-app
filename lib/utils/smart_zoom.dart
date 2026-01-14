import '../db/database.dart';
import '../theme/app_theme.dart';

/// Smart zoom utility - calculates optimal zoom based on arrow grouping
class SmartZoom {
  /// Minimum arrows needed for smart zoom calibration
  static const int minCalibrationArrows = 12;

  /// Minimum zoom factor - always start with at least 2x
  static const double minZoom = 2.0;

  /// Calculate the optimal zoom factor based on most frequently used rings + 3 rings
  /// Returns a zoom factor (minimum 2x)
  static double calculateZoomFactor(List<Arrow> arrows, {required bool isIndoor}) {
    // Default zoom if insufficient data - use minimum 2x
    if (arrows.length < minCalibrationArrows) {
      return minZoom;
    }

    // Count score frequency to find most commonly used rings
    final scoreCounts = <int, int>{};
    for (final arrow in arrows) {
      scoreCounts[arrow.score] = (scoreCounts[arrow.score] ?? 0) + 1;
    }

    // Find most frequent score
    int mostFrequentScore = 10;
    int maxCount = 0;
    for (final entry in scoreCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostFrequentScore = entry.key;
      }
    }

    // Calculate radius of most frequent scoring ring
    final baseRadius = _scoreToNormalizedRadius(mostFrequentScore);

    // Add 3 rings padding (each ring = 0.1 of radius)
    final paddedRadius = baseRadius + 0.3;

    // Calculate zoom to show this area
    // If padded radius is 0.5, we want to zoom 2x to fill the view
    final calculatedZoom = 1.0 / paddedRadius.clamp(0.2, 1.0);

    // Ensure minimum 2x zoom, maximum 6x
    return calculatedZoom.clamp(minZoom, 6.0);
  }

  /// Convert score (1-10, X=10) to normalized radius from center
  static double _scoreToNormalizedRadius(int score) {
    // X ring (10): 0.05
    // 10 ring: 0.1
    // 9 ring: 0.2
    // 8 ring: 0.3
    // ... down to
    // 1 ring: 1.0

    if (score >= 10) return TargetRings.x; // X ring
    if (score == 9) return TargetRings.ring9;
    if (score == 8) return TargetRings.ring8;
    if (score == 7) return TargetRings.ring7;
    if (score == 6) return TargetRings.ring6;
    if (score == 5) return TargetRings.ring5;
    if (score == 4) return TargetRings.ring4;
    if (score == 3) return TargetRings.ring3;
    if (score == 2) return TargetRings.ring2;
    return TargetRings.ring1; // 1 ring or miss
  }
}
