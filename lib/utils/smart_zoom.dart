import '../db/database.dart';
import '../theme/app_theme.dart';

/// Smart zoom utility - calculates optimal zoom based on arrow grouping
class SmartZoom {
  /// Minimum arrows needed for smart zoom calibration
  static const int minCalibrationArrows = 12;

  /// Calculate the optimal zoom factor based on historical arrow grouping
  /// Returns a factor representing the fraction of the target to show
  static double calculateZoomFactor(List<Arrow> arrows, {required bool isIndoor}) {
    // Default zoom if insufficient data
    if (arrows.length < minCalibrationArrows) {
      return 3.0; // Show ~1/3 of target
    }

    // Calculate typical scoring ring range
    final scores = arrows.map((a) => a.score).toList();
    scores.sort();

    // Use middle 80% of scores to determine typical range (ignore outliers)
    final startIdx = (scores.length * 0.1).floor();
    final endIdx = (scores.length * 0.9).ceil();
    final typicalScores = scores.sublist(startIdx, endIdx);

    if (typicalScores.isEmpty) {
      return 3.0;
    }

    final minScore = typicalScores.first;

    // Calculate radius of typical grouping area
    // minScore (worst shot in typical range) determines the outer boundary
    final maxRadius = _scoreToNormalizedRadius(minScore);

    // Add padding: indoor +2 rings, outdoor +3 rings
    final paddingRings = isIndoor ? 2 : 3;
    final paddingRadius = paddingRings * 0.1;

    final groupingRadius = maxRadius + paddingRadius;

    // Calculate zoom to show this area
    // If grouping radius is 0.5, we want to zoom 2x to fill the view
    // Formula: zoom = 1 / (groupingRadius)
    final calculatedZoom = 1.0 / groupingRadius.clamp(0.2, 1.0);

    // Clamp between 1.5x and 6x
    return calculatedZoom.clamp(1.5, 6.0);
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
