import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/utils/statistics.dart';

void main() {
  group('calculatePercentile', () {
    test('returns null for empty list', () {
      expect(calculatePercentile([], percentile: 80), isNull);
    });

    test('returns null for list with fewer than minSamples', () {
      expect(calculatePercentile([100, 200, 300], percentile: 80, minSamples: 5), isNull);
    });

    test('returns null for invalid percentile (negative)', () {
      expect(calculatePercentile([1, 2, 3, 4, 5], percentile: -10, minSamples: 5), isNull);
    });

    test('returns null for invalid percentile (over 100)', () {
      expect(calculatePercentile([1, 2, 3, 4, 5], percentile: 110, minSamples: 5), isNull);
    });

    test('calculates 50th percentile (median) correctly for odd-length list', () {
      final result = calculatePercentile([10, 20, 30, 40, 50], percentile: 50, minSamples: 5);
      expect(result, equals(30.0));
    });

    test('calculates 80th percentile correctly', () {
      // For [10, 20, 30, 40, 50], 80th percentile index = 0.8 * 4 = 3.2
      // Interpolate between index 3 (40) and index 4 (50): 40 + 0.2 * 10 = 42
      final result = calculatePercentile([10, 20, 30, 40, 50], percentile: 80, minSamples: 5);
      expect(result, equals(42.0));
    });

    test('handles unsorted input correctly', () {
      final result = calculatePercentile([50, 10, 30, 40, 20], percentile: 50, minSamples: 5);
      expect(result, equals(30.0));
    });

    test('returns exact value at 0th percentile (minimum)', () {
      final result = calculatePercentile([10, 20, 30, 40, 50], percentile: 0, minSamples: 5);
      expect(result, equals(10.0));
    });

    test('returns exact value at 100th percentile (maximum)', () {
      final result = calculatePercentile([10, 20, 30, 40, 50], percentile: 100, minSamples: 5);
      expect(result, equals(50.0));
    });

    test('works with minSamples = 1', () {
      final result = calculatePercentile([100], percentile: 50, minSamples: 1);
      expect(result, equals(100.0));
    });
  });

  group('isTopPercentile', () {
    test('returns null when insufficient data', () {
      final result = isTopPercentile(100, [50, 60, 70], topPercent: 20);
      expect(result, isNull);
    });

    test('returns true when score is in top 20%', () {
      // [100, 200, 300, 400, 500] - 80th percentile = 420
      // Score 450 >= 420, so it's in top 20%
      final result = isTopPercentile(450, [100, 200, 300, 400, 500], topPercent: 20);
      expect(result, isTrue);
    });

    test('returns false when score is not in top 20%', () {
      // [100, 200, 300, 400, 500] - 80th percentile = 420
      // Score 350 < 420, so it's not in top 20%
      final result = isTopPercentile(350, [100, 200, 300, 400, 500], topPercent: 20);
      expect(result, isFalse);
    });

    test('returns true when score equals threshold', () {
      // Score exactly at the threshold should be included
      final result = isTopPercentile(420, [100, 200, 300, 400, 500], topPercent: 20);
      expect(result, isTrue);
    });

    test('works with top 10%', () {
      // [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]
      // 90th percentile index = 0.9 * 9 = 8.1, interpolate between 900 and 1000
      final scores = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000];
      final result = isTopPercentile(950, scores, topPercent: 10, minSamples: 5);
      expect(result, isTrue);
    });
  });

  group('calculateMean', () {
    test('returns null for empty list', () {
      expect(calculateMean([]), isNull);
    });

    test('calculates mean correctly', () {
      expect(calculateMean([10, 20, 30]), equals(20.0));
    });

    test('handles single value', () {
      expect(calculateMean([100]), equals(100.0));
    });
  });

  group('calculateStdDev', () {
    test('returns null for empty list', () {
      expect(calculateStdDev([]), isNull);
    });

    test('returns null for single value', () {
      expect(calculateStdDev([100]), isNull);
    });

    test('calculates standard deviation correctly', () {
      // For [2, 4, 4, 4, 5, 5, 7, 9], mean = 5
      // Variance = ((2-5)^2 + (4-5)^2*3 + (5-5)^2*2 + (7-5)^2 + (9-5)^2) / 7
      //          = (9 + 3 + 0 + 4 + 16) / 7 = 32/7 ≈ 4.57
      // StdDev ≈ sqrt(4.57) ≈ 2.14
      final result = calculateStdDev([2, 4, 4, 4, 5, 5, 7, 9]);
      expect(result, closeTo(2.138, 0.01));
    });

    test('returns 0 for identical values', () {
      final result = calculateStdDev([5, 5, 5, 5, 5]);
      expect(result, equals(0.0));
    });
  });
}
