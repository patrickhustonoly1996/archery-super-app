/// Utility class for calculating training volume metrics and EMAs
class VolumeCalculator {
  /// Calculate Exponential Moving Average (EMA) for a given period
  ///
  /// EMA formula: EMA(today) = (Value(today) × multiplier) + (EMA(yesterday) × (1 - multiplier))
  /// where multiplier = 2 / (period + 1)
  static double calculateEMA({
    required List<DailyVolume> data,
    required int period,
    double? previousEMA,
  }) {
    if (data.isEmpty) return 0.0;

    final multiplier = 2.0 / (period + 1);

    // If we have a previous EMA, use it; otherwise start with first value
    double ema = previousEMA ?? data.first.arrowCount.toDouble();

    for (final entry in data) {
      ema = (entry.arrowCount * multiplier) + (ema * (1 - multiplier));
    }

    return ema;
  }

  /// Calculate EMA for all entries in a dataset
  /// Returns a list of EMA values corresponding to each date
  ///
  /// The EMA is seeded with the average of the first `period` values (or all
  /// available values if fewer than `period` exist). This prevents the EMA
  /// from starting at an extreme value and "dropping down" to the true average.
  static List<double> calculateEMATimeSeries({
    required List<DailyVolume> data,
    required int period,
  }) {
    if (data.isEmpty) return [];

    final multiplier = 2.0 / (period + 1);
    final emaValues = <double>[];

    // Calculate initial seed value: average of first N values (up to period)
    final seedCount = data.length < period ? data.length : period;
    double seedSum = 0;
    for (int i = 0; i < seedCount; i++) {
      seedSum += data[i].arrowCount;
    }
    double ema = seedSum / seedCount;
    emaValues.add(ema);

    // Calculate EMA for rest of values
    for (int i = 1; i < data.length; i++) {
      ema = (data[i].arrowCount * multiplier) + (ema * (1 - multiplier));
      emaValues.add(ema);
    }

    return emaValues;
  }

  /// Calculate 7-day, 28-day, and 90-day EMAs for a dataset
  static VolumeMetrics calculateAllMetrics(List<DailyVolume> data) {
    if (data.isEmpty) {
      return VolumeMetrics(
        ema7: [],
        ema28: [],
        ema90: [],
      );
    }

    return VolumeMetrics(
      ema7: calculateEMATimeSeries(data: data, period: 7),
      ema28: calculateEMATimeSeries(data: data, period: 28),
      ema90: calculateEMATimeSeries(data: data, period: 90),
    );
  }

  /// Calculate rolling sum for a given window size
  static int calculateRollingSum(List<DailyVolume> data, int windowSize) {
    if (data.isEmpty) return 0;

    final recentData = data.take(windowSize).toList();
    return recentData.fold<int>(0, (sum, entry) => sum + entry.arrowCount);
  }

  /// Calculate rolling average for a given window size
  static double calculateRollingAverage(List<DailyVolume> data, int windowSize) {
    if (data.isEmpty) return 0.0;

    final sum = calculateRollingSum(data, windowSize);
    final count = data.length < windowSize ? data.length : windowSize;

    return sum / count;
  }
}

/// Data class for daily volume entry
class DailyVolume {
  final DateTime date;
  final int arrowCount;
  final String? notes;

  DailyVolume({
    required this.date,
    required this.arrowCount,
    this.notes,
  });
}

/// Container for calculated volume metrics
class VolumeMetrics {
  final List<double> ema7;
  final List<double> ema28;
  final List<double> ema90;

  VolumeMetrics({
    required this.ema7,
    required this.ema28,
    required this.ema90,
  });
}
