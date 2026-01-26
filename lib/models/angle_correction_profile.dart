import '../utils/angle_sight_mark_calculator.dart';

/// Stored profile for angle correction learning per bow.
///
/// Each bow can have its own learned correction factors based on
/// actual field results. The profile stores:
/// - Estimated arrow speed (from equipment or user input)
/// - Learned uphill/downhill factors
/// - Data point counts for confidence tracking
///
/// The learning algorithm uses exponential moving average to refine
/// factors over time while being responsive to new data.
class AngleCorrectionProfile {
  final String id;
  final String bowId;

  /// Arrow speed in fps (estimated or user-entered)
  final double arrowSpeedFps;

  /// Learned uphill factor per degree (from recording actual results)
  final double uphillFactor;

  /// Learned downhill factor per degree
  final double downhillFactor;

  /// Number of uphill data points recorded
  final int uphillDataPoints;

  /// Number of downhill data points recorded
  final int downhillDataPoints;

  /// Confidence score (0.0 to 1.0) based on data quality
  final double confidenceScore;

  /// Last time this profile was updated
  final DateTime lastUpdated;

  const AngleCorrectionProfile({
    required this.id,
    required this.bowId,
    required this.arrowSpeedFps,
    required this.uphillFactor,
    required this.downhillFactor,
    this.uphillDataPoints = 0,
    this.downhillDataPoints = 0,
    this.confidenceScore = 0.3,
    required this.lastUpdated,
  });

  /// Total number of data points recorded
  int get totalDataPoints => uphillDataPoints + downhillDataPoints;

  /// Whether this profile has enough data to be useful
  bool get hasLearnedData => totalDataPoints >= 3;

  /// Confidence level based on data points
  /// 3 points -> 0.5, 5 -> 0.7, 10 -> 0.85, 20+ -> 0.95
  double get calculatedConfidence {
    if (totalDataPoints < 3) return 0.3;
    if (totalDataPoints < 5) return 0.5;
    if (totalDataPoints < 10) return 0.7;
    if (totalDataPoints < 20) return 0.85;
    return 0.95;
  }

  /// Ratio of downhill to uphill factor
  double get upDownRatio => uphillFactor > 0 ? downhillFactor / uphillFactor : 1.0;

  /// Create a default profile for a bow based on arrow speed
  factory AngleCorrectionProfile.defaultForSpeed({
    required String id,
    required String bowId,
    required double arrowSpeedFps,
  }) {
    final factors = AngleSightMarkCalculator.getFactorsForSpeed(arrowSpeedFps);
    return AngleCorrectionProfile(
      id: id,
      bowId: bowId,
      arrowSpeedFps: arrowSpeedFps,
      uphillFactor: factors.uphill,
      downhillFactor: factors.downhill,
      uphillDataPoints: 0,
      downhillDataPoints: 0,
      confidenceScore: 0.3,
      lastUpdated: DateTime.now(),
    );
  }

  /// Apply learning from an actual result.
  ///
  /// When the actual sight mark differs from the prediction,
  /// we adjust the relevant factor using exponential moving average.
  ///
  /// [actualMark] - The sight mark that actually worked
  /// [predictedMark] - What our model predicted
  /// [angleDegrees] - The slope angle (negative = uphill, positive = downhill)
  /// [learningRate] - How much to weight new data (default 0.2 = 20%)
  AngleCorrectionProfile applyLearning({
    required double actualMark,
    required double predictedMark,
    required double angleDegrees,
    double learningRate = 0.2,
  }) {
    if (angleDegrees == 0) return this; // No learning at flat angles

    // Calculate the per-degree adjustment needed
    final differential = actualMark - predictedMark;
    final perDegree = differential / angleDegrees.abs();

    if (angleDegrees < 0) {
      // UPHILL - update uphill factor
      final newFactor = uphillFactor * (1 - learningRate) + perDegree * learningRate;
      return copyWith(
        uphillFactor: newFactor.clamp(0.001, 0.020),
        uphillDataPoints: uphillDataPoints + 1,
        confidenceScore: _calculateNewConfidence(uphillDataPoints + 1, downhillDataPoints),
        lastUpdated: DateTime.now(),
      );
    } else {
      // DOWNHILL - update downhill factor
      final newFactor = downhillFactor * (1 - learningRate) + perDegree * learningRate;
      return copyWith(
        downhillFactor: newFactor.clamp(0.001, 0.030),
        downhillDataPoints: downhillDataPoints + 1,
        confidenceScore: _calculateNewConfidence(uphillDataPoints, downhillDataPoints + 1),
        lastUpdated: DateTime.now(),
      );
    }
  }

  double _calculateNewConfidence(int upPoints, int downPoints) {
    final total = upPoints + downPoints;
    if (total < 3) return 0.3;
    if (total < 5) return 0.5;
    if (total < 10) return 0.7;
    if (total < 20) return 0.85;
    return 0.95;
  }

  /// Reset learned data to defaults for current speed
  AngleCorrectionProfile resetToDefaults() {
    final factors = AngleSightMarkCalculator.getFactorsForSpeed(arrowSpeedFps);
    return copyWith(
      uphillFactor: factors.uphill,
      downhillFactor: factors.downhill,
      uphillDataPoints: 0,
      downhillDataPoints: 0,
      confidenceScore: 0.3,
      lastUpdated: DateTime.now(),
    );
  }

  /// Update arrow speed and recalculate default factors
  AngleCorrectionProfile withUpdatedSpeed(double newSpeed) {
    final factors = AngleSightMarkCalculator.getFactorsForSpeed(newSpeed);
    return copyWith(
      arrowSpeedFps: newSpeed,
      // If no learned data, use new defaults; otherwise keep learned factors
      uphillFactor: hasLearnedData ? uphillFactor : factors.uphill,
      downhillFactor: hasLearnedData ? downhillFactor : factors.downhill,
      lastUpdated: DateTime.now(),
    );
  }

  AngleCorrectionProfile copyWith({
    String? id,
    String? bowId,
    double? arrowSpeedFps,
    double? uphillFactor,
    double? downhillFactor,
    int? uphillDataPoints,
    int? downhillDataPoints,
    double? confidenceScore,
    DateTime? lastUpdated,
  }) {
    return AngleCorrectionProfile(
      id: id ?? this.id,
      bowId: bowId ?? this.bowId,
      arrowSpeedFps: arrowSpeedFps ?? this.arrowSpeedFps,
      uphillFactor: uphillFactor ?? this.uphillFactor,
      downhillFactor: downhillFactor ?? this.downhillFactor,
      uphillDataPoints: uphillDataPoints ?? this.uphillDataPoints,
      downhillDataPoints: downhillDataPoints ?? this.downhillDataPoints,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() =>
      'AngleCorrectionProfile(bowId: $bowId, speed: ${arrowSpeedFps.toStringAsFixed(0)} fps, '
      'up: ${uphillFactor.toStringAsFixed(4)}, down: ${downhillFactor.toStringAsFixed(4)}, '
      'points: $totalDataPoints)';
}
