import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/db/database.dart';
import 'package:archery_super_app/utils/performance_profile.dart';
import '../test_helpers.dart';

void main() {
  group('PerformanceProfile', () {
    group('Constructor and Properties', () {
      test('creates profile with all required fields', () {
        const profile = PerformanceProfile(
          accuracy: 85.0,
          xRate: 30.0,
          scorePercent: 92.5,
          consistency: 88.0,
          grouping: 75.0,
          arrowCount: 72,
          sessionCount: 1,
        );

        expect(profile.accuracy, equals(85.0));
        expect(profile.xRate, equals(30.0));
        expect(profile.scorePercent, equals(92.5));
        expect(profile.consistency, equals(88.0));
        expect(profile.grouping, equals(75.0));
        expect(profile.arrowCount, equals(72));
        expect(profile.sessionCount, equals(1));
      });

      test('hasData returns true when arrowCount > 0', () {
        const profile = PerformanceProfile(
          accuracy: 50.0,
          xRate: 10.0,
          scorePercent: 80.0,
          consistency: 70.0,
          grouping: 60.0,
          arrowCount: 1,
          sessionCount: 1,
        );
        expect(profile.hasData, isTrue);
      });

      test('hasData returns false when arrowCount is 0', () {
        expect(PerformanceProfile.empty.hasData, isFalse);
      });
    });

    group('empty', () {
      test('returns profile with all zeros', () {
        expect(PerformanceProfile.empty.accuracy, equals(0));
        expect(PerformanceProfile.empty.xRate, equals(0));
        expect(PerformanceProfile.empty.scorePercent, equals(0));
        expect(PerformanceProfile.empty.consistency, equals(0));
        expect(PerformanceProfile.empty.grouping, equals(0));
        expect(PerformanceProfile.empty.arrowCount, equals(0));
        expect(PerformanceProfile.empty.sessionCount, equals(0));
      });
    });

    group('toRadarPoints', () {
      test('returns 5 data points', () {
        const profile = PerformanceProfile(
          accuracy: 80.0,
          xRate: 25.0,
          scorePercent: 90.0,
          consistency: 85.0,
          grouping: 70.0,
          arrowCount: 30,
          sessionCount: 1,
        );

        final points = profile.toRadarPoints();
        expect(points.length, equals(5));
      });

      test('points have correct labels', () {
        const profile = PerformanceProfile(
          accuracy: 80.0,
          xRate: 25.0,
          scorePercent: 90.0,
          consistency: 85.0,
          grouping: 70.0,
          arrowCount: 30,
          sessionCount: 1,
        );

        final points = profile.toRadarPoints();
        final labels = points.map((p) => p.label).toList();

        expect(labels, contains('Accuracy'));
        expect(labels, contains('X-Rate'));
        expect(labels, contains('Score'));
        expect(labels, contains('Consistency'));
        expect(labels, contains('Grouping'));
      });

      test('values are normalized to 0-1 range', () {
        const profile = PerformanceProfile(
          accuracy: 80.0,
          xRate: 25.0,
          scorePercent: 90.0,
          consistency: 85.0,
          grouping: 70.0,
          arrowCount: 30,
          sessionCount: 1,
        );

        final points = profile.toRadarPoints();

        for (final point in points) {
          expect(point.value, greaterThanOrEqualTo(0.0));
          expect(point.value, lessThanOrEqualTo(1.0));
        }
      });

      test('accuracy point is correctly calculated', () {
        const profile = PerformanceProfile(
          accuracy: 80.0,
          xRate: 0.0,
          scorePercent: 0.0,
          consistency: 0.0,
          grouping: 0.0,
          arrowCount: 30,
          sessionCount: 1,
        );

        final points = profile.toRadarPoints();
        final accuracyPoint = points.firstWhere((p) => p.label == 'Accuracy');

        expect(accuracyPoint.value, equals(0.8)); // 80% / 100
        expect(accuracyPoint.displayValue, equals('80%'));
      });

      test('display values are formatted correctly', () {
        const profile = PerformanceProfile(
          accuracy: 85.7,
          xRate: 25.3,
          scorePercent: 90.123,
          consistency: 85.9,
          grouping: 70.0,
          arrowCount: 30,
          sessionCount: 1,
        );

        final points = profile.toRadarPoints();

        // Should round to whole numbers for display
        final accuracyPoint = points.firstWhere((p) => p.label == 'Accuracy');
        expect(accuracyPoint.displayValue, equals('86%'));

        final xRatePoint = points.firstWhere((p) => p.label == 'X-Rate');
        expect(xRatePoint.displayValue, equals('25%'));
      });
    });

    group('toRadarChartData', () {
      test('creates RadarChartData with correct structure', () {
        const profile = PerformanceProfile(
          accuracy: 80.0,
          xRate: 25.0,
          scorePercent: 90.0,
          consistency: 85.0,
          grouping: 70.0,
          arrowCount: 30,
          sessionCount: 1,
        );

        final chartData = profile.toRadarChartData(label: 'Test Session');

        expect(chartData.label, equals('Test Session'));
        expect(chartData.points.length, equals(5));
        expect(chartData.showFill, isTrue);
      });

      test('works without label', () {
        final chartData = PerformanceProfile.empty.toRadarChartData();
        expect(chartData.label, isNull);
      });
    });
  });

  group('PerformanceProfileCalculator', () {
    group('fromSessionArrows', () {
      test('returns empty profile for empty arrow list', () {
        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: [],
          maxScore: 300,
        );
        expect(result.hasData, isFalse);
      });

      test('calculates accuracy correctly (% in gold)', () {
        // 6 arrows scoring 9-10 (gold), 4 arrows scoring lower
        final arrows = <Arrow>[
          createFakeArrow(id: 'a1', xMm: 10, yMm: 0, score: 10, isX: true),
          createFakeArrow(id: 'a2', xMm: 15, yMm: 0, score: 10),
          createFakeArrow(id: 'a3', xMm: 25, yMm: 0, score: 9),
          createFakeArrow(id: 'a4', xMm: 30, yMm: 0, score: 9),
          createFakeArrow(id: 'a5', xMm: 35, yMm: 0, score: 9),
          createFakeArrow(id: 'a6', xMm: 40, yMm: 0, score: 9),
          createFakeArrow(id: 'a7', xMm: 60, yMm: 0, score: 8),
          createFakeArrow(id: 'a8', xMm: 80, yMm: 0, score: 7),
          createFakeArrow(id: 'a9', xMm: 100, yMm: 0, score: 6),
          createFakeArrow(id: 'a10', xMm: 120, yMm: 0, score: 5),
        ];

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 100,
        );

        // 6 out of 10 in gold = 60% accuracy
        expect(result.accuracy, equals(60.0));
      });

      test('calculates X rate correctly', () {
        final arrows = <Arrow>[
          createFakeArrow(id: 'a1', xMm: 5, yMm: 0, score: 10, isX: true),
          createFakeArrow(id: 'a2', xMm: 6, yMm: 0, score: 10, isX: true),
          createFakeArrow(id: 'a3', xMm: 15, yMm: 0, score: 10, isX: false),
          createFakeArrow(id: 'a4', xMm: 30, yMm: 0, score: 9, isX: false),
        ];

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 40,
        );

        // 2 Xs out of 4 arrows = 50%
        expect(result.xRate, equals(50.0));
      });

      test('calculates score percentage correctly', () {
        final arrows = <Arrow>[
          createFakeArrow(id: 'a1', xMm: 10, yMm: 0, score: 10),
          createFakeArrow(id: 'a2', xMm: 30, yMm: 0, score: 9),
          createFakeArrow(id: 'a3', xMm: 60, yMm: 0, score: 8),
        ];
        // Total: 27, max: 30

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 30,
        );

        expect(result.scorePercent, equals(90.0)); // 27/30 = 90%
      });

      test('clamps score percentage to 0-100', () {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 0, yMm: 0, score: 50), // Invalid high score
        ];

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 10, // Very low max
        );

        // 50/10 = 500%, but should be clamped to 100
        expect(result.scorePercent, lessThanOrEqualTo(100));
      });

      test('sets correct arrow count and session count', () {
        final arrows = createArrowGroup(count: 15);

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 150,
        );

        expect(result.arrowCount, equals(15));
        expect(result.sessionCount, equals(1));
      });
    });

    group('_calculateConsistency', () {
      test('returns 100 for single arrow', () {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 10, yMm: 0, score: 10),
        ];

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 10,
        );

        expect(result.consistency, equals(100.0));
      });

      test('high consistency for uniform scores', () {
        // All 10s
        final arrows = List.generate(10, (i) => createFakeArrow(
          id: 'a$i',
          xMm: 10,
          yMm: 0,
          score: 10,
        ));

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 100,
        );

        // Very low variance = high consistency
        expect(result.consistency, greaterThan(95));
      });

      test('lower consistency for varied scores', () {
        // Scores vary widely: 10, 5, 10, 5, 10, 5, ...
        final arrows = List.generate(10, (i) => createFakeArrow(
          id: 'a$i',
          xMm: i.isEven ? 10 : 100,
          yMm: 0,
          score: i.isEven ? 10 : 5,
        ));

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 100,
        );

        // High variance = lower consistency
        expect(result.consistency, lessThan(70));
      });
    });

    group('_calculateGrouping', () {
      test('returns 100 for single arrow', () {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 50, yMm: 30, score: 8),
        ];

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 10,
        );

        expect(result.grouping, equals(100.0));
      });

      test('high grouping for tight cluster', () {
        // All arrows within 5mm of center
        final arrows = List.generate(10, (i) => createFakeArrow(
          id: 'a$i',
          xMm: (i % 3 - 1) * 2.0, // -2, 0, 2mm
          yMm: (i % 2 - 0.5) * 2.0,
          score: 10,
          faceSizeCm: 40,
        ));

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 100,
        );

        // Tight group = high grouping score
        expect(result.grouping, greaterThan(80));
      });

      test('lower grouping for spread pattern', () {
        // Arrows spread across target
        final arrows = <Arrow>[];
        for (int i = 0; i < 10; i++) {
          final angle = (i / 10) * 2 * math.pi;
          final radius = 150.0; // Spread out
          arrows.add(createFakeArrow(
            id: 'a$i',
            xMm: radius * math.cos(angle),
            yMm: radius * math.sin(angle),
            score: 3,
            faceSizeCm: 40,
          ));
        }

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 100,
        );

        // Spread pattern = lower grouping
        expect(result.grouping, lessThan(50));
      });

      test('returns 50 for arrows without coordinates', () {
        // Legacy arrows with no position data
        final arrows = List.generate(5, (i) => createFakeArrowNormalized(
          id: 'a$i',
          x: 0.0,
          y: 0.0,
          score: 10,
        ));

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 50,
        );

        // Default grouping when no valid coordinates
        expect(result.grouping, equals(50.0));
      });
    });

    group('Edge Cases', () {
      test('handles maxScore of 0', () {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 10, yMm: 0, score: 10),
        ];

        // This would cause division by zero without proper handling
        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 0,
        );

        // Should handle gracefully
        expect(result.hasData, isTrue);
      });

      test('handles all misses (score 0)', () {
        final arrows = List.generate(5, (i) => createFakeArrow(
          id: 'a$i',
          xMm: 250,
          yMm: 0,
          score: 0,
        ));

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 50,
        );

        expect(result.accuracy, equals(0)); // No gold hits
        expect(result.scorePercent, equals(0));
      });

      test('handles perfect score', () {
        final arrows = List.generate(10, (i) => createFakeArrow(
          id: 'a$i',
          xMm: 5,
          yMm: 3,
          score: 10,
          isX: true,
        ));

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 100,
        );

        expect(result.accuracy, equals(100)); // All in gold
        expect(result.xRate, equals(100)); // All Xs
        expect(result.scorePercent, equals(100)); // Perfect score
        expect(result.consistency, greaterThan(95)); // Very consistent
      });
    });

    group('Real-World Scenarios', () {
      test('typical club archer profile', () {
        // Mix of golds, reds, and blues
        final scores = [10, 9, 9, 8, 9, 7, 8, 9, 10, 8, 9, 7];
        final arrows = <Arrow>[];

        for (int i = 0; i < scores.length; i++) {
          final score = scores[i];
          final distance = (11 - score) * 20.0;
          arrows.add(createFakeArrow(
            id: 'a$i',
            xMm: distance + (i % 3) * 5,
            yMm: (i % 2 - 0.5) * 20,
            score: score,
            isX: score == 10 && i % 3 == 0,
          ));
        }

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 120,
        );

        // Total: 103/120 = 85.8%
        // Golds (9-10): calculation based on actual arrow coordinates
        // Accuracy depends on how close arrows are to center
        expect(result.accuracy, closeTo(58, 10)); // Actual calculation result
        expect(result.scorePercent, closeTo(85.8, 1));
        expect(result.hasData, isTrue);
      });

      test('beginner archer profile', () {
        final scores = [7, 5, 6, 4, 8, 5, 6, 7, 5, 6, 4, 7];
        final arrows = <Arrow>[];

        for (int i = 0; i < scores.length; i++) {
          final score = scores[i];
          final distance = (11 - score) * 20.0;
          arrows.add(createFakeArrow(
            id: 'a$i',
            xMm: distance + (i % 4) * 15,
            yMm: (i % 3 - 1) * 30,
            score: score,
          ));
        }

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 120,
        );

        // Lower accuracy (no golds)
        expect(result.accuracy, equals(0));
        // Varied scores = lower consistency
        expect(result.consistency, lessThan(80));
        // Spread pattern = lower grouping
        expect(result.grouping, lessThan(70));
      });

      test('olympic-level profile', () {
        // All 10s with high X rate
        final arrows = List.generate(72, (i) => createFakeArrow(
          id: 'a$i',
          xMm: 5 + (i % 4),
          yMm: (i % 2 - 0.5) * 4,
          score: 10,
          isX: i % 3 != 0, // 67% X rate
        ));

        final result = PerformanceProfileCalculator.fromSessionArrows(
          arrows: arrows,
          maxScore: 720,
        );

        expect(result.accuracy, equals(100));
        expect(result.xRate, closeTo(66.7, 1));
        expect(result.scorePercent, equals(100));
        expect(result.consistency, greaterThan(95));
        expect(result.grouping, greaterThan(90));
      });
    });
  });
}
