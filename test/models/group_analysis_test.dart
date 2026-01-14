import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

import 'package:archery_super_app/models/arrow_coordinate.dart';
import 'package:archery_super_app/models/group_analysis.dart';

void main() {
  group('GroupAnalysis', () {
    group('Creation', () {
      test('calculates center from multiple arrows', () {
        final arrows = [
          ArrowCoordinate(xMm: 20, yMm: 10, faceSizeCm: 40),
          ArrowCoordinate(xMm: 30, yMm: 20, faceSizeCm: 40),
          ArrowCoordinate(xMm: 25, yMm: 15, faceSizeCm: 40),
        ];

        final group = GroupAnalysis.calculate(arrows);

        // Center = average: (20+30+25)/3 = 25, (10+20+15)/3 = 15
        expect(group.center.xMm, equals(25.0));
        expect(group.center.yMm, equals(15.0));
        expect(group.arrowCount, equals(3));
      });

      test('handles single arrow', () {
        final arrows = [
          ArrowCoordinate(xMm: 50, yMm: -30, faceSizeCm: 40),
        ];

        final group = GroupAnalysis.calculate(arrows);

        expect(group.center.xMm, equals(50.0));
        expect(group.center.yMm, equals(-30.0));
        expect(group.arrowCount, equals(1));
        expect(group.meanSpreadMm, equals(0.0));
        expect(group.maxSpreadMm, equals(0.0));
      });

      test('tryCalculate returns null for empty list', () {
        final result = GroupAnalysis.tryCalculate([]);
        expect(result, isNull);
      });

      test('calculate throws ArgumentError for empty list', () {
        expect(
          () => GroupAnalysis.calculate([]),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Spread Calculations', () {
      test('calculates mean spread correctly', () {
        // Create a perfect square: 4 points equidistant from center
        // Center at (50, 50), points at (40, 40), (60, 40), (40, 60), (60, 60)
        final arrows = [
          ArrowCoordinate(xMm: 40, yMm: 40, faceSizeCm: 40),
          ArrowCoordinate(xMm: 60, yMm: 40, faceSizeCm: 40),
          ArrowCoordinate(xMm: 40, yMm: 60, faceSizeCm: 40),
          ArrowCoordinate(xMm: 60, yMm: 60, faceSizeCm: 40),
        ];

        final group = GroupAnalysis.calculate(arrows);

        // Center should be (50, 50)
        expect(group.center.xMm, equals(50.0));
        expect(group.center.yMm, equals(50.0));

        // Each point is sqrt(10^2 + 10^2) = sqrt(200) = 14.14mm from center
        final expectedSpread = math.sqrt(200);
        expect(group.meanSpreadMm, closeTo(expectedSpread, 0.01));
        expect(group.maxSpreadMm, closeTo(expectedSpread, 0.01));
      });

      test('zero spread when all arrows at same point', () {
        final arrows = [
          ArrowCoordinate(xMm: 50, yMm: 30, faceSizeCm: 40),
          ArrowCoordinate(xMm: 50, yMm: 30, faceSizeCm: 40),
          ArrowCoordinate(xMm: 50, yMm: 30, faceSizeCm: 40),
        ];

        final group = GroupAnalysis.calculate(arrows);

        expect(group.meanSpreadMm, equals(0.0));
        expect(group.maxSpreadMm, equals(0.0));
        expect(group.standardDeviationMm, closeTo(0.0, 0.001));
      });

      test('calculates max spread correctly', () {
        // Create a line: 3 points with one outlier
        final arrows = [
          ArrowCoordinate(xMm: 50, yMm: 50, faceSizeCm: 40),
          ArrowCoordinate(xMm: 50, yMm: 50, faceSizeCm: 40),
          ArrowCoordinate(xMm: 50, yMm: 80, faceSizeCm: 40), // Outlier
        ];

        final group = GroupAnalysis.calculate(arrows);

        // Center: (50, 60)
        // First two arrows: 10mm from center
        // Third arrow: 20mm from center
        expect(group.maxSpreadMm, equals(20.0));
      });

      test('calculates standard deviation', () {
        final arrows = [
          ArrowCoordinate(xMm: 0, yMm: 0, faceSizeCm: 40),
          ArrowCoordinate(xMm: 20, yMm: 0, faceSizeCm: 40),
          ArrowCoordinate(xMm: 40, yMm: 0, faceSizeCm: 40),
        ];

        final group = GroupAnalysis.calculate(arrows);

        // Center at (20, 0)
        // Deviations: 20, 0, 20 from center
        // Mean deviation: (20+0+20)/3 = 13.33
        expect(group.standardDeviationMm, greaterThan(0));
      });
    });

    group('Derived Properties', () {
      test('calculates group diameter', () {
        final arrows = [
          ArrowCoordinate(xMm: 40, yMm: 50, faceSizeCm: 40),
          ArrowCoordinate(xMm: 60, yMm: 50, faceSizeCm: 40),
        ];

        final group = GroupAnalysis.calculate(arrows);

        // Center at (50, 50), each point 10mm away
        // Diameter = 2 * maxSpread = 2 * 10 = 20
        expect(group.groupDiameterMm, equals(20.0));
      });

      test('detects off-target center', () {
        final offTarget = [
          ArrowCoordinate(xMm: 220, yMm: 0, faceSizeCm: 40), // Outside
          ArrowCoordinate(xMm: 240, yMm: 0, faceSizeCm: 40), // Outside
        ];

        final group = GroupAnalysis.calculate(offTarget);

        // Center at (230, 0), which is > 200mm radius
        expect(group.centerIsOffTarget, isTrue);
      });

      test('calculates offset from target center', () {
        final arrows = [
          ArrowCoordinate(xMm: 30, yMm: 40, faceSizeCm: 40),
        ];

        final group = GroupAnalysis.calculate(arrows);

        // Distance from (0,0) to (30,40) = 50mm
        expect(group.offsetFromTargetCenterMm, equals(50.0));
        expect(group.horizontalOffsetMm, equals(30.0));
        expect(group.verticalOffsetMm, equals(40.0));
      });
    });

    group('Sight Adjustment Calculations', () {
      test('calculates sight clicks for centered group', () {
        final centered = [
          ArrowCoordinate(xMm: 0, yMm: 0, faceSizeCm: 40),
        ];

        final group = GroupAnalysis.calculate(centered);
        final clicks = group.calculateSightClicks(mmPerClick: 1.0);

        expect(clicks.horizontal, equals(0));
        expect(clicks.vertical, equals(0));
      });

      test('calculates sight clicks for offset group', () {
        final offset = [
          ArrowCoordinate(xMm: 10, yMm: -20, faceSizeCm: 40),
        ];

        final group = GroupAnalysis.calculate(offset);
        final clicks = group.calculateSightClicks(mmPerClick: 5.0);

        // 10mm / 5mm per click = 2 clicks right
        // -20mm / 5mm per click = -4 clicks (up)
        expect(clicks.horizontal, equals(2));
        expect(clicks.vertical, equals(-4));
      });

      test('rounds to nearest click', () {
        final offset = [
          ArrowCoordinate(xMm: 7, yMm: 0, faceSizeCm: 40),
        ];

        final group = GroupAnalysis.calculate(offset);
        final clicks = group.calculateSightClicks(mmPerClick: 5.0);

        // 7mm / 5mm = 1.4, rounds to 1
        expect(clicks.horizontal, equals(1));
      });

      test('throws for invalid mmPerClick', () {
        final arrows = [ArrowCoordinate(xMm: 10, yMm: 10, faceSizeCm: 40)];
        final group = GroupAnalysis.calculate(arrows);

        expect(
          () => group.calculateSightClicks(mmPerClick: 0),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => group.calculateSightClicks(mmPerClick: -1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('provides human-readable sight adjustment description', () {
        final offset = [
          ArrowCoordinate(xMm: 10, yMm: -15, faceSizeCm: 40),
        ];

        final group = GroupAnalysis.calculate(offset);
        final description = group.sightAdjustmentDescription(mmPerClick: 5.0);

        expect(description, contains('right'));
        expect(description, contains('up'));
      });

      test('reports no adjustment needed for centered group', () {
        final centered = [
          ArrowCoordinate(xMm: 2, yMm: -2, faceSizeCm: 40),
        ];

        final group = GroupAnalysis.calculate(centered);
        // With 5mm per click, 2mm offset rounds to 0 clicks
        final description = group.sightAdjustmentDescription(mmPerClick: 5.0);

        expect(description, equals('No adjustment needed'));
      });
    });

    group('Display Methods', () {
      test('summary provides arrow count and key metrics', () {
        final arrows = [
          ArrowCoordinate(xMm: 10, yMm: 10, faceSizeCm: 40),
          ArrowCoordinate(xMm: 20, yMm: 20, faceSizeCm: 40),
          ArrowCoordinate(xMm: 15, yMm: 15, faceSizeCm: 40),
        ];

        final group = GroupAnalysis.calculate(arrows);
        final summary = group.summary;

        expect(summary, contains('3 arrows'));
        expect(summary, contains('mm'));
      });

      test('toDisplayString provides detailed breakdown', () {
        final arrows = [
          ArrowCoordinate(xMm: 25, yMm: 15, faceSizeCm: 40),
          ArrowCoordinate(xMm: 30, yMm: 20, faceSizeCm: 40),
        ];

        final group = GroupAnalysis.calculate(arrows);
        final display = group.toDisplayString();

        expect(display, contains('Group Analysis'));
        expect(display, contains('Center'));
        expect(display, contains('Mean spread'));
        expect(display, contains('Max spread'));
        expect(display, contains('Std dev'));
        expect(display, contains('Offset'));
      });
    });

    group('Extension Method', () {
      test('groupAnalysis extension returns analysis', () {
        final arrows = [
          ArrowCoordinate(xMm: 10, yMm: 10, faceSizeCm: 40),
          ArrowCoordinate(xMm: 20, yMm: 20, faceSizeCm: 40),
        ];

        final analysis = arrows.groupAnalysis;

        expect(analysis, isNotNull);
        expect(analysis!.arrowCount, equals(2));
      });

      test('groupAnalysis extension returns null for empty list', () {
        final arrows = <ArrowCoordinate>[];
        final analysis = arrows.groupAnalysis;

        expect(analysis, isNull);
      });
    });

    group('Edge Cases', () {
      test('handles large number of arrows', () {
        final arrows = List.generate(
          1000,
          (i) => ArrowCoordinate(
            xMm: (i % 100).toDouble(),
            yMm: (i ~/ 100).toDouble(),
            faceSizeCm: 40,
          ),
        );

        final group = GroupAnalysis.calculate(arrows);

        expect(group.arrowCount, equals(1000));
        expect(group.meanSpreadMm, isNonNegative);
        expect(group.maxSpreadMm, isNonNegative);
      });

      test('preserves arrows list as unmodifiable', () {
        final arrows = [
          ArrowCoordinate(xMm: 10, yMm: 10, faceSizeCm: 40),
        ];

        final group = GroupAnalysis.calculate(arrows);

        // The arrows list should be unmodifiable
        expect(
          () => (group.arrows as List).add(
            ArrowCoordinate(xMm: 0, yMm: 0, faceSizeCm: 40),
          ),
          throwsUnsupportedError,
        );
      });

      test('handles negative coordinates', () {
        final arrows = [
          ArrowCoordinate(xMm: -50, yMm: -30, faceSizeCm: 40),
          ArrowCoordinate(xMm: -40, yMm: -20, faceSizeCm: 40),
        ];

        final group = GroupAnalysis.calculate(arrows);

        expect(group.center.xMm, equals(-45.0));
        expect(group.center.yMm, equals(-25.0));
      });
    });
  });
}
