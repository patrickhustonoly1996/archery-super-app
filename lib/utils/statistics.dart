/// Statistical utility functions for archery analysis

/// Calculate the nth percentile from a list of values
/// Returns null if the list has fewer than [minSamples] values
double? calculatePercentile(
  List<int> values, {
  required int percentile,
  int minSamples = 5,
}) {
  if (values.length < minSamples) return null;
  if (percentile < 0 || percentile > 100) return null;

  final sorted = List<int>.from(values)..sort();

  // Use linear interpolation for percentile calculation
  final index = (percentile / 100) * (sorted.length - 1);
  final lower = index.floor();
  final upper = index.ceil();

  if (lower == upper) {
    return sorted[lower].toDouble();
  }

  // Linear interpolation between two values
  final fraction = index - lower;
  return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction;
}

/// Check if a score is in the top N percent of historical scores
/// Returns true if the score is >= the (100-topPercent) percentile
/// Returns null if there aren't enough samples to calculate
bool? isTopPercentile(
  int score,
  List<int> historicalScores, {
  required int topPercent,
  int minSamples = 5,
}) {
  final threshold = calculatePercentile(
    historicalScores,
    percentile: 100 - topPercent,
    minSamples: minSamples,
  );

  if (threshold == null) return null;
  return score >= threshold;
}

/// Calculate mean of a list of integers
double? calculateMean(List<int> values) {
  if (values.isEmpty) return null;
  return values.reduce((a, b) => a + b) / values.length;
}

/// Calculate standard deviation
double? calculateStdDev(List<int> values) {
  if (values.length < 2) return null;

  final mean = calculateMean(values)!;
  final sumSquaredDiff = values.fold<double>(
    0,
    (sum, value) => sum + (value - mean) * (value - mean),
  );

  return (sumSquaredDiff / (values.length - 1)).sqrt();
}

extension _DoubleSqrt on double {
  double sqrt() {
    if (this < 0) return double.nan;
    return _sqrt(this);
  }
}

// Newton's method for square root
double _sqrt(double n) {
  if (n == 0) return 0;
  double x = n;
  double y = (x + 1) / 2;
  while (y < x) {
    x = y;
    y = (x + n / x) / 2;
  }
  return x;
}
