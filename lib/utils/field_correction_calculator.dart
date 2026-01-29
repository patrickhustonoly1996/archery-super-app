import '../models/arrow_coordinate.dart';
import '../models/sight_mark.dart';
import 'angle_sight_mark_calculator.dart';

/// Result of a field correction calculation
class FieldSightMarkRecommendation {
  /// The final recommended sight mark value
  final double value;

  /// The flat (no-angle) base mark from sight tape
  final double flatMark;

  /// Adjustment for slope angle (always <= 0 since both uphill and downhill reduce the mark)
  final double angleAdjustment;

  /// Adjustment from course-specific learning
  final double courseAdjustment;

  /// Adjustment based on previous peg's impact point (walk-down)
  final double walkDownAdjustment;

  /// Human-readable explanation of the calculation
  final String explanation;

  /// Confidence in this recommendation
  final SightMarkConfidence confidence;

  /// Number of data points this recommendation is based on
  final int dataPoints;

  const FieldSightMarkRecommendation({
    required this.value,
    required this.flatMark,
    this.angleAdjustment = 0.0,
    this.courseAdjustment = 0.0,
    this.walkDownAdjustment = 0.0,
    required this.explanation,
    required this.confidence,
    this.dataPoints = 0,
  });

  /// Whether any adjustments are applied beyond the base mark
  bool get hasAdjustments =>
      angleAdjustment != 0.0 ||
      courseAdjustment != 0.0 ||
      walkDownAdjustment != 0.0;

  /// Format value for display
  String get displayValue => value.toStringAsFixed(2);

  /// Build a multi-line breakdown string
  String get breakdownText {
    final lines = <String>[];
    lines.add('base:    ${flatMark.toStringAsFixed(2)} (from your sight tape)');
    if (angleAdjustment != 0.0) {
      final sign = angleAdjustment >= 0 ? '+' : '';
      lines.add('angle:   $sign${angleAdjustment.toStringAsFixed(2)}');
    }
    if (courseAdjustment != 0.0) {
      final sign = courseAdjustment >= 0 ? '+' : '';
      lines.add('course:  $sign${courseAdjustment.toStringAsFixed(2)} (learned from $dataPoints visits)');
    }
    if (walkDownAdjustment != 0.0) {
      final sign = walkDownAdjustment >= 0 ? '+' : '';
      lines.add('walk-dn: $sign${walkDownAdjustment.toStringAsFixed(2)} (from previous peg)');
    }
    return lines.join('\n');
  }
}

/// Data from a previous peg's shot, used for walk-down correction
class PreviousPegResult {
  /// Arrow impact coordinate on the target face
  final ArrowCoordinate? coordinate;

  /// Whether the shot was marked as poor
  final bool isPoorShot;

  /// Direction of poor shot (high/low/left/right)
  final String? poorShotDirection;

  /// Distance at the previous peg
  final double previousDistance;

  /// Angle at the previous peg
  final double? previousAngle;

  /// Sight mark used at the previous peg
  final double? previousSightMark;

  const PreviousPegResult({
    this.coordinate,
    this.isPoorShot = false,
    this.poorShotDirection,
    required this.previousDistance,
    this.previousAngle,
    this.previousSightMark,
  });
}

/// Unified correction calculator for IFAA field archery.
///
/// Combines:
/// - Base sightmark from sight tape/curve
/// - Angle correction for slope
/// - Course-specific differential (learned from previous visits)
/// - Walk-down adjustment from previous peg's impact point
class FieldCorrectionCalculator {
  const FieldCorrectionCalculator._();

  /// Calculate recommended sight mark for a specific peg.
  ///
  /// [distance] - Distance to target at this peg
  /// [unit] - Distance unit
  /// [angleDegrees] - Slope angle (negative = uphill, positive = downhill), or null if flat/unknown
  /// [arrowSpeedFps] - Arrow speed in feet per second (for angle correction)
  /// [baseFlatMark] - Base flat sight mark from the sight tape for this distance
  /// [courseDifferential] - Course-specific learned differential (from FieldSightMarkProvider), or null
  /// [courseDataPoints] - Number of data points behind the course differential
  /// [previousPegResult] - Data from previous peg's shot (for walk-down), or null
  /// [baseConfidence] - Confidence of the base sight mark prediction
  static FieldSightMarkRecommendation calculateForPeg({
    required double distance,
    required DistanceUnit unit,
    double? angleDegrees,
    required double arrowSpeedFps,
    required double baseFlatMark,
    double? courseDifferential,
    int courseDataPoints = 0,
    PreviousPegResult? previousPegResult,
    SightMarkConfidence baseConfidence = SightMarkConfidence.medium,
  }) {
    double currentMark = baseFlatMark;
    double angleAdj = 0.0;
    double courseAdj = 0.0;
    double walkDownAdj = 0.0;
    final explanationParts = <String>[];

    // 1. Angle correction
    if (angleDegrees != null && angleDegrees != 0.0) {
      final angleMark = AngleSightMarkCalculator.getSightMarkForAngle(
        flatSightMark: baseFlatMark,
        angleDegrees: angleDegrees,
        arrowSpeedFps: arrowSpeedFps,
      );
      angleAdj = angleMark - baseFlatMark;
      currentMark += angleAdj;

      final direction = angleDegrees < 0 ? 'uphill' : 'downhill';
      explanationParts.add(
        '${angleAdj >= 0 ? "+" : ""}${angleAdj.toStringAsFixed(2)} angle (${angleDegrees.abs().toStringAsFixed(1)}° $direction)',
      );
    }

    // 2. Course differential
    if (courseDifferential != null && courseDifferential != 0.0) {
      courseAdj = courseDifferential;
      currentMark += courseAdj;
      explanationParts.add(
        '${courseAdj >= 0 ? "+" : ""}${courseAdj.toStringAsFixed(2)} course (from $courseDataPoints visits)',
      );
    }

    // 3. Walk-down adjustment from previous peg
    if (previousPegResult != null && previousPegResult.coordinate != null) {
      walkDownAdj = _calculateWalkDownAdjustment(
        previousResult: previousPegResult,
        currentDistance: distance,
        currentAngle: angleDegrees,
        baseFlatMark: baseFlatMark,
        arrowSpeedFps: arrowSpeedFps,
        unit: unit,
      );
      if (walkDownAdj.abs() > 0.005) {
        // Only apply if significant
        currentMark += walkDownAdj;
        explanationParts.add(
          '${walkDownAdj >= 0 ? "+" : ""}${walkDownAdj.toStringAsFixed(2)} walk-down correction',
        );
      } else {
        walkDownAdj = 0.0;
      }
    }

    // Build explanation
    final explanation = explanationParts.isEmpty
        ? 'Base sightmark from sight tape'
        : explanationParts.join(', ');

    // Calculate overall confidence
    final confidence = _calculateConfidence(
      baseConfidence: baseConfidence,
      hasAngle: angleDegrees != null,
      courseDataPoints: courseDataPoints,
      hasWalkDown: walkDownAdj != 0.0,
    );

    return FieldSightMarkRecommendation(
      value: currentMark,
      flatMark: baseFlatMark,
      angleAdjustment: angleAdj,
      courseAdjustment: courseAdj,
      walkDownAdjustment: walkDownAdj,
      explanation: explanation,
      confidence: confidence,
      dataPoints: courseDataPoints,
    );
  }

  /// Calculate the walk-down adjustment from the previous peg's impact point.
  ///
  /// Logic:
  /// - Convert the group centre offset from target centre to mm
  /// - Use the sightmark-per-mm ratio from the curve to convert to a sight adjustment
  /// - Poor shots get 25% weight in the offset calculation
  /// - Factor in the distance change (sight changes with distance anyway)
  static double _calculateWalkDownAdjustment({
    required PreviousPegResult previousResult,
    required double currentDistance,
    double? currentAngle,
    required double baseFlatMark,
    required double arrowSpeedFps,
    required DistanceUnit unit,
  }) {
    final coord = previousResult.coordinate;
    if (coord == null) return 0.0;

    // Calculate the vertical offset from target centre
    // In archery: yMm < 0 means arrow hit high, yMm > 0 means arrow hit low
    // If arrow hit high, sight mark needs to go UP (increase)
    // If arrow hit low, sight mark needs to go DOWN (decrease)
    double verticalOffsetMm = coord.yMm;

    // Apply poor shot weighting: poor shots only contribute 25%
    if (previousResult.isPoorShot) {
      verticalOffsetMm *= 0.25;
    }

    // Calculate sight-mark-per-mm ratio
    // This tells us how much the sight mark changes per mm of impact offset
    // Approximate: at the previous distance, 1mm at the target face corresponds
    // to a small sight mark change. Use the face radius to normalize.
    //
    // A rough model: the face radius in mm covers the scoring range.
    // The total sight mark range across the face is small.
    // Using empirical relationship: ~0.005 sight mark units per mm at 50yd face
    final faceRadiusMm = coord.faceSizeCm * 5.0; // cm to radius in mm
    final sightMarkRange = baseFlatMark * 0.1; // ~10% of mark covers the face
    final sightPerMm = sightMarkRange / faceRadiusMm;

    // Convert vertical offset to sight adjustment
    // Positive yMm (arrow low) -> need to decrease sight (negative adjustment)
    // Negative yMm (arrow high) -> need to increase sight (positive adjustment)
    double adjustment = -verticalOffsetMm * sightPerMm;

    // Scale adjustment based on distance change
    // When moving to a closer peg, the impact of the offset is reduced
    // because the archer is naturally adjusting their sight for distance
    if (previousResult.previousDistance > 0 && currentDistance > 0) {
      final distanceRatio = currentDistance / previousResult.previousDistance;
      // Only apply a fraction — the distance change already accounts for most of it
      adjustment *= distanceRatio * 0.5;
    }

    return adjustment;
  }

  /// Calculate weighted group centre from multiple arrows.
  ///
  /// Poor shots get 25% weight, good shots get 100%.
  /// Used for both walk-down adjustment and historical group centre.
  static ArrowCoordinate? calculateWeightedGroupCentre({
    required List<ArrowCoordinate> coordinates,
    required List<bool> isPoorShot,
    required int faceSizeCm,
  }) {
    if (coordinates.isEmpty) return null;

    double totalWeight = 0;
    double weightedX = 0;
    double weightedY = 0;

    for (int i = 0; i < coordinates.length; i++) {
      final weight = (i < isPoorShot.length && isPoorShot[i]) ? 0.25 : 1.0;
      weightedX += coordinates[i].xMm * weight;
      weightedY += coordinates[i].yMm * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) return null;

    return ArrowCoordinate(
      xMm: weightedX / totalWeight,
      yMm: weightedY / totalWeight,
      faceSizeCm: faceSizeCm,
    );
  }

  /// Calculate overall confidence from contributing factors.
  static SightMarkConfidence _calculateConfidence({
    required SightMarkConfidence baseConfidence,
    required bool hasAngle,
    required int courseDataPoints,
    required bool hasWalkDown,
  }) {
    // Start from base confidence
    int score = switch (baseConfidence) {
      SightMarkConfidence.high => 3,
      SightMarkConfidence.medium => 2,
      SightMarkConfidence.low => 1,
      SightMarkConfidence.unknown => 0,
    };

    // Course learning boosts confidence
    if (courseDataPoints >= 5) {
      score += 2;
    } else if (courseDataPoints >= 2) {
      score += 1;
    }

    // Having angle data slightly improves accuracy
    if (hasAngle) {
      score += 1;
    }

    // Walk-down data adds a small confidence boost
    if (hasWalkDown) {
      score += 1;
    }

    // Map score to confidence level
    if (score >= 5) return SightMarkConfidence.high;
    if (score >= 3) return SightMarkConfidence.medium;
    return SightMarkConfidence.low;
  }
}
