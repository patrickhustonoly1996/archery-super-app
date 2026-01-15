import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/utils/volume_calculator.dart';
import '../test_helpers.dart';

void main() {
  group('VolumeCalculator', () {
    group('calculateEMA', () {
      test('returns 0.0 for empty data', () {
        final result = VolumeCalculator.calculateEMA(
          data: [],
          period: 7,
        );
        expect(result, equals(0.0));
      });

      test('returns first value for single entry', () {
        final data = [DailyVolume(date: DateTime.now(), arrowCount: 100)];
        final result = VolumeCalculator.calculateEMA(
          data: data,
          period: 7,
        );
        expect(result, equals(100.0));
      });

      test('calculates 7-day EMA correctly for constant data', () {
        // With constant data, EMA should converge to that value
        final data = createSteadyVolumeData(days: 30, arrowsPerDay: 100);
        final result = VolumeCalculator.calculateEMA(
          data: data,
          period: 7,
        );
        // After 30 days of constant 100, EMA should be very close to 100
        expect(result, closeTo(100.0, 1.0));
      });

      test('calculates 28-day EMA correctly for constant data', () {
        final data = createSteadyVolumeData(days: 60, arrowsPerDay: 150);
        final result = VolumeCalculator.calculateEMA(
          data: data,
          period: 28,
        );
        expect(result, closeTo(150.0, 2.0));
      });

      test('calculates 90-day EMA correctly for constant data', () {
        final data = createSteadyVolumeData(days: 180, arrowsPerDay: 120);
        final result = VolumeCalculator.calculateEMA(
          data: data,
          period: 90,
        );
        expect(result, closeTo(120.0, 3.0));
      });

      test('EMA responds to increasing data', () {
        // Start with 50 arrows, end with 150
        final data = createRampUpVolumeData(
          days: 30,
          startArrows: 50,
          endArrows: 150,
        );

        final ema7 = VolumeCalculator.calculateEMA(data: data, period: 7);
        final ema28 = VolumeCalculator.calculateEMA(data: data, period: 28);

        // 7-day EMA should be more responsive (closer to recent values)
        // 28-day EMA should be smoother (closer to average)
        expect(ema7, greaterThan(ema28));
        expect(ema7, greaterThan(100)); // Should be above average
        expect(ema7, lessThan(150)); // But not at max yet
      });

      test('uses previousEMA when provided', () {
        final data = [
          DailyVolume(date: DateTime.now(), arrowCount: 100),
        ];

        final withoutPrevious = VolumeCalculator.calculateEMA(
          data: data,
          period: 7,
        );

        final withPrevious = VolumeCalculator.calculateEMA(
          data: data,
          period: 7,
          previousEMA: 200.0,
        );

        // With previous EMA of 200, result should be pulled toward 200
        expect(withPrevious, greaterThan(withoutPrevious));
        expect(withPrevious, lessThan(200)); // But less than previous
      });

      test('multiplier calculation is correct', () {
        // EMA multiplier = 2 / (period + 1)
        // For period 7: multiplier = 2/8 = 0.25
        // For period 28: multiplier = 2/29 = ~0.069

        // With one new value of 200 added to EMA of 100:
        // New EMA = 200 * 0.25 + 100 * 0.75 = 50 + 75 = 125
        final data = [DailyVolume(date: DateTime.now(), arrowCount: 200)];
        final result = VolumeCalculator.calculateEMA(
          data: data,
          period: 7,
          previousEMA: 100.0,
        );
        expect(result, closeTo(125.0, 0.1));
      });
    });

    group('calculateEMATimeSeries', () {
      test('returns empty list for empty data', () {
        final result = VolumeCalculator.calculateEMATimeSeries(
          data: [],
          period: 7,
        );
        expect(result, isEmpty);
      });

      test('returns list of same length as input', () {
        final data = createSteadyVolumeData(days: 30, arrowsPerDay: 100);
        final result = VolumeCalculator.calculateEMATimeSeries(
          data: data,
          period: 7,
        );
        expect(result.length, equals(data.length));
      });

      test('first EMA value equals first data value', () {
        final data = createSteadyVolumeData(days: 10, arrowsPerDay: 123);
        final result = VolumeCalculator.calculateEMATimeSeries(
          data: data,
          period: 7,
        );
        expect(result.first, equals(123.0));
      });

      test('EMA series is monotonically increasing for ramp-up data', () {
        final data = createRampUpVolumeData(
          days: 30,
          startArrows: 50,
          endArrows: 200,
        );
        final result = VolumeCalculator.calculateEMATimeSeries(
          data: data,
          period: 7,
        );

        // Each value should be >= previous (smoothly increasing)
        for (int i = 1; i < result.length; i++) {
          expect(result[i], greaterThanOrEqualTo(result[i - 1]));
        }
      });

      test('shorter period EMA is more responsive', () {
        final data = createRampUpVolumeData(
          days: 30,
          startArrows: 50,
          endArrows: 200,
        );

        final ema7 = VolumeCalculator.calculateEMATimeSeries(data: data, period: 7);
        final ema28 = VolumeCalculator.calculateEMATimeSeries(data: data, period: 28);

        // At the end, 7-day EMA should be higher (more responsive to recent increase)
        expect(ema7.last, greaterThan(ema28.last));
      });
    });

    group('calculateAllMetrics', () {
      test('returns empty metrics for empty data', () {
        final result = VolumeCalculator.calculateAllMetrics([]);
        expect(result.ema7, isEmpty);
        expect(result.ema28, isEmpty);
        expect(result.ema90, isEmpty);
      });

      test('calculates all three EMA periods', () {
        final data = createSteadyVolumeData(days: 100, arrowsPerDay: 100);
        final result = VolumeCalculator.calculateAllMetrics(data);

        expect(result.ema7.length, equals(100));
        expect(result.ema28.length, equals(100));
        expect(result.ema90.length, equals(100));
      });

      test('7-day EMA is most responsive to changes', () {
        // Create data with sudden increase
        final data = <DailyVolume>[
          ...createSteadyVolumeData(days: 50, arrowsPerDay: 100),
          ...createSteadyVolumeData(
            days: 10,
            arrowsPerDay: 200,
            startDate: DateTime.now().subtract(const Duration(days: 10)),
          ),
        ];

        final result = VolumeCalculator.calculateAllMetrics(data);

        // At the end, 7-day should be highest (most responsive)
        // 90-day should be lowest (most smoothed)
        expect(result.ema7.last, greaterThan(result.ema28.last));
        expect(result.ema28.last, greaterThan(result.ema90.last));
      });
    });

    group('calculateRollingSum', () {
      test('returns 0 for empty data', () {
        final result = VolumeCalculator.calculateRollingSum([], 7);
        expect(result, equals(0));
      });

      test('sums all data if less than window size', () {
        final data = [
          DailyVolume(date: DateTime.now(), arrowCount: 50),
          DailyVolume(date: DateTime.now(), arrowCount: 30),
          DailyVolume(date: DateTime.now(), arrowCount: 20),
        ];
        final result = VolumeCalculator.calculateRollingSum(data, 7);
        expect(result, equals(100));
      });

      test('sums only window size entries', () {
        final data = createSteadyVolumeData(days: 30, arrowsPerDay: 10);
        final result = VolumeCalculator.calculateRollingSum(data, 7);
        expect(result, equals(70)); // 7 days * 10 arrows
      });

      test('uses first N entries (not last)', () {
        final data = [
          DailyVolume(date: DateTime(2024, 1, 1), arrowCount: 100),
          DailyVolume(date: DateTime(2024, 1, 2), arrowCount: 200),
          DailyVolume(date: DateTime(2024, 1, 3), arrowCount: 300),
        ];
        final result = VolumeCalculator.calculateRollingSum(data, 2);
        expect(result, equals(300)); // 100 + 200 (first 2)
      });
    });

    group('calculateRollingAverage', () {
      test('returns 0.0 for empty data', () {
        final result = VolumeCalculator.calculateRollingAverage([], 7);
        expect(result, equals(0.0));
      });

      test('calculates correct average for full window', () {
        final data = createSteadyVolumeData(days: 30, arrowsPerDay: 100);
        final result = VolumeCalculator.calculateRollingAverage(data, 7);
        expect(result, equals(100.0));
      });

      test('handles partial window correctly', () {
        final data = [
          DailyVolume(date: DateTime.now(), arrowCount: 60),
          DailyVolume(date: DateTime.now(), arrowCount: 40),
        ];
        // Window of 7, but only 2 entries
        final result = VolumeCalculator.calculateRollingAverage(data, 7);
        expect(result, equals(50.0)); // (60 + 40) / 2
      });

      test('calculates average not sum', () {
        final data = [
          DailyVolume(date: DateTime.now(), arrowCount: 100),
          DailyVolume(date: DateTime.now(), arrowCount: 200),
          DailyVolume(date: DateTime.now(), arrowCount: 300),
        ];
        final result = VolumeCalculator.calculateRollingAverage(data, 3);
        expect(result, equals(200.0)); // (100 + 200 + 300) / 3
      });
    });

    group('DailyVolume', () {
      test('creates with required parameters', () {
        final volume = DailyVolume(
          date: DateTime(2024, 6, 15),
          arrowCount: 150,
        );
        expect(volume.date, equals(DateTime(2024, 6, 15)));
        expect(volume.arrowCount, equals(150));
        expect(volume.notes, isNull);
      });

      test('creates with optional notes', () {
        final volume = DailyVolume(
          date: DateTime.now(),
          arrowCount: 100,
          notes: 'Good session',
        );
        expect(volume.notes, equals('Good session'));
      });
    });

    group('VolumeMetrics', () {
      test('holds all three EMA lists', () {
        final metrics = VolumeMetrics(
          ema7: [1.0, 2.0, 3.0],
          ema28: [4.0, 5.0, 6.0],
          ema90: [7.0, 8.0, 9.0],
        );
        expect(metrics.ema7, hasLength(3));
        expect(metrics.ema28, hasLength(3));
        expect(metrics.ema90, hasLength(3));
      });
    });

    group('Edge Cases', () {
      test('handles zero arrow counts', () {
        final data = createSteadyVolumeData(days: 10, arrowsPerDay: 0);
        final result = VolumeCalculator.calculateEMA(data: data, period: 7);
        expect(result, equals(0.0));
      });

      test('handles very large arrow counts', () {
        final data = createSteadyVolumeData(days: 10, arrowsPerDay: 10000);
        final result = VolumeCalculator.calculateEMA(data: data, period: 7);
        expect(result, closeTo(10000.0, 100.0));
      });

      test('handles period larger than data length', () {
        final data = createSteadyVolumeData(days: 5, arrowsPerDay: 100);
        final result = VolumeCalculator.calculateEMA(data: data, period: 90);
        // Should still work, just with limited smoothing
        expect(result, closeTo(100.0, 1.0));
      });

      test('handles period of 1', () {
        final data = [
          DailyVolume(date: DateTime.now(), arrowCount: 50),
          DailyVolume(date: DateTime.now(), arrowCount: 100),
          DailyVolume(date: DateTime.now(), arrowCount: 150),
        ];
        final result = VolumeCalculator.calculateEMA(data: data, period: 1);
        // With period 1, multiplier = 1, so EMA = last value
        expect(result, equals(150.0));
      });

      test('handles alternating zero and non-zero values', () {
        final data = [
          DailyVolume(date: DateTime.now(), arrowCount: 100),
          DailyVolume(date: DateTime.now(), arrowCount: 0),
          DailyVolume(date: DateTime.now(), arrowCount: 100),
          DailyVolume(date: DateTime.now(), arrowCount: 0),
        ];
        final result = VolumeCalculator.calculateEMA(data: data, period: 7);
        // Should handle rest days (0 arrows) correctly
        expect(result, greaterThan(0));
        expect(result, lessThan(100));
      });
    });

    group('Real-World Scenarios', () {
      test('typical training week pattern', () {
        // Simulate Mon-Fri training with rest on weekends
        final data = <DailyVolume>[];
        final start = DateTime(2024, 1, 1); // Monday

        for (int week = 0; week < 4; week++) {
          for (int day = 0; day < 7; day++) {
            final isWeekend = day >= 5;
            data.add(DailyVolume(
              date: start.add(Duration(days: week * 7 + day)),
              arrowCount: isWeekend ? 0 : 120,
            ));
          }
        }

        final metrics = VolumeCalculator.calculateAllMetrics(data);

        // 7-day EMA reflects weekly pattern with exponential weighting
        // EMA gives more weight to recent values, so weekend zeros have
        // stronger effect than simple average would suggest
        expect(metrics.ema7.last, closeTo(59.4, 15.0));
      });

      test('competition taper pattern', () {
        // Normal training followed by reduced volume before competition
        final data = <DailyVolume>[
          ...createSteadyVolumeData(days: 21, arrowsPerDay: 150),
          ...createRampUpVolumeData(
            days: 7,
            startArrows: 100,
            endArrows: 50,
            startDate: DateTime.now().subtract(const Duration(days: 7)),
          ),
        ];

        final metrics = VolumeCalculator.calculateAllMetrics(data);

        // 7-day EMA should drop significantly with taper
        // 28-day should show less dramatic drop (more history)
        expect(metrics.ema7.last, lessThan(metrics.ema28.last));
      });
    });
  });
}
