import 'dart:math' as math;
import 'arrow_coordinate.dart';

/// Analysis of arrow grouping - calculates center, spread, and other metrics.
/// Used for group visualization and sight adjustment calculations.
class GroupAnalysis {
  /// Center of the group (average position)
  final ArrowCoordinate center;

  /// Mean radial deviation from center in mm (average spread)
  final double meanSpreadMm;

  /// Maximum spread - distance from center to furthest arrow in mm
  final double maxSpreadMm;

  /// Standard deviation of arrow positions in mm
  final double standardDeviationMm;

  /// Number of arrows in this analysis
  final int arrowCount;

  /// The arrows that were analyzed
  final List<ArrowCoordinate> arrows;

  const GroupAnalysis._({
    required this.center,
    required this.meanSpreadMm,
    required this.maxSpreadMm,
    required this.standardDeviationMm,
    required this.arrowCount,
    required this.arrows,
  });

  /// Calculate group analysis from a list of arrow coordinates.
  /// Requires at least one arrow.
  factory GroupAnalysis.calculate(List<ArrowCoordinate> arrows) {
    if (arrows.isEmpty) {
      throw ArgumentError('Cannot calculate group analysis with no arrows');
    }

    final faceSizeCm = arrows.first.faceSizeCm;

    // Calculate centroid (average position)
    double sumX = 0, sumY = 0;
    for (final arrow in arrows) {
      sumX += arrow.xMm;
      sumY += arrow.yMm;
    }
    final centerX = sumX / arrows.length;
    final centerY = sumY / arrows.length;

    final center = ArrowCoordinate(
      xMm: centerX,
      yMm: centerY,
      faceSizeCm: faceSizeCm,
    );

    // Calculate spread metrics
    double sumDeviation = 0;
    double maxDeviation = 0;
    double sumSquaredDeviation = 0;

    for (final arrow in arrows) {
      final dx = arrow.xMm - centerX;
      final dy = arrow.yMm - centerY;
      final deviation = math.sqrt(dx * dx + dy * dy);

      sumDeviation += deviation;
      sumSquaredDeviation += deviation * deviation;

      if (deviation > maxDeviation) {
        maxDeviation = deviation;
      }
    }

    final meanSpread = sumDeviation / arrows.length;

    // Standard deviation of radial distances
    final variance = (sumSquaredDeviation / arrows.length) - (meanSpread * meanSpread);
    final stdDev = math.sqrt(variance.abs());

    return GroupAnalysis._(
      center: center,
      meanSpreadMm: meanSpread,
      maxSpreadMm: maxDeviation,
      standardDeviationMm: stdDev,
      arrowCount: arrows.length,
      arrows: List.unmodifiable(arrows),
    );
  }

  /// Create an empty/null analysis for when there are no arrows
  static GroupAnalysis? tryCalculate(List<ArrowCoordinate> arrows) {
    if (arrows.isEmpty) return null;
    return GroupAnalysis.calculate(arrows);
  }

  // ============================================================================
  // DERIVED PROPERTIES
  // ============================================================================

  /// Group diameter (2x max spread) - useful for sight mark calculations
  double get groupDiameterMm => maxSpreadMm * 2;

  /// Whether the group center is off-target (outside the face)
  bool get centerIsOffTarget => center.normalizedDistance > 1.0;

  /// Distance from target center to group center
  double get offsetFromTargetCenterMm => center.distanceMm;

  /// Angle of offset from target center in degrees (0 = right, 90 = down)
  double get offsetAngleDegrees => center.angleDegrees;

  /// X offset from target center in mm (positive = right)
  double get horizontalOffsetMm => center.xMm;

  /// Y offset from target center in mm (positive = down)
  double get verticalOffsetMm => center.yMm;

  // ============================================================================
  // SIGHT ADJUSTMENT HELPERS
  // ============================================================================

  /// Calculate sight click adjustment needed.
  /// Returns (horizontal clicks, vertical clicks) where positive = move sight right/down.
  /// Requires knowing the click value (mm per click at the target distance).
  ({int horizontal, int vertical}) calculateSightClicks({
    required double mmPerClick,
  }) {
    if (mmPerClick <= 0) {
      throw ArgumentError('mmPerClick must be positive');
    }

    // To move group center to target center, move sight in opposite direction
    // If group is right of center (positive xMm), move sight right (arrows will go left)
    // If group is below center (positive yMm), move sight down (arrows will go up)
    final horizontalClicks = (center.xMm / mmPerClick).round();
    final verticalClicks = (center.yMm / mmPerClick).round();

    return (horizontal: horizontalClicks, vertical: verticalClicks);
  }

  /// Get a description of the sight adjustment needed
  String sightAdjustmentDescription({required double mmPerClick}) {
    final clicks = calculateSightClicks(mmPerClick: mmPerClick);

    final parts = <String>[];

    if (clicks.horizontal != 0) {
      final dir = clicks.horizontal > 0 ? 'right' : 'left';
      parts.add('${clicks.horizontal.abs()} $dir');
    }

    if (clicks.vertical != 0) {
      final dir = clicks.vertical > 0 ? 'down' : 'up';
      parts.add('${clicks.vertical.abs()} $dir');
    }

    if (parts.isEmpty) {
      return 'No adjustment needed';
    }

    return parts.join(', ');
  }

  // ============================================================================
  // DISPLAY HELPERS
  // ============================================================================

  /// Human-readable summary of the group
  String get summary {
    final offset = offsetFromTargetCenterMm.toStringAsFixed(1);
    final spread = meanSpreadMm.toStringAsFixed(1);
    return '$arrowCount arrows, ${spread}mm spread, ${offset}mm off center';
  }

  /// Detailed display string
  String toDisplayString() {
    return '''
Group Analysis ($arrowCount arrows):
  Center: ${center.toDisplayString()}
  Mean spread: ${meanSpreadMm.toStringAsFixed(1)}mm
  Max spread: ${maxSpreadMm.toStringAsFixed(1)}mm
  Std dev: ${standardDeviationMm.toStringAsFixed(1)}mm
  Offset: ${horizontalOffsetMm.toStringAsFixed(1)}mm H, ${verticalOffsetMm.toStringAsFixed(1)}mm V
''';
  }

  @override
  String toString() => 'GroupAnalysis($summary)';
}

/// Extension to easily calculate group analysis from a list of arrows
extension GroupAnalysisExtension on List<ArrowCoordinate> {
  GroupAnalysis? get groupAnalysis => GroupAnalysis.tryCalculate(this);
}
