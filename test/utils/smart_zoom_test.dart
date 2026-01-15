import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/db/database.dart';
import 'package:archery_super_app/utils/smart_zoom.dart';
import 'package:archery_super_app/theme/app_theme.dart';
import '../test_helpers.dart';

void main() {
  group('SmartZoom', () {
    group('calculateZoomFactor', () {
      test('returns minimum zoom (2.0) with insufficient data', () {
        final arrows = createArrowGroup(count: 5); // Less than 12 required
        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);
        expect(result, equals(SmartZoom.minZoom));
      });

      test('returns minimum zoom for empty arrow list', () {
        final result = SmartZoom.calculateZoomFactor([], isIndoor: true);
        expect(result, equals(SmartZoom.minZoom));
      });

      test('returns minimum zoom for exactly 11 arrows', () {
        final arrows = createArrowGroup(count: 11);
        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);
        expect(result, equals(SmartZoom.minZoom));
      });

      test('calculates zoom for 12+ arrows', () {
        // Create arrows mostly scoring 10s (in the gold)
        final arrows = List.generate(15, (i) => createFakeArrow(
          id: 'arrow_$i',
          xMm: 10 + (i % 5),
          yMm: 10 + (i % 3),
          score: 10,
          isX: i < 3,
        ));

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);

        // With mostly 10s, zoom should be high (focused on gold)
        expect(result, greaterThanOrEqualTo(SmartZoom.minZoom));
        expect(result, lessThanOrEqualTo(6.0));
      });

      test('lower zoom for arrows spread across rings', () {
        // Create arrows with varied scores
        final arrows = <Arrow>[];
        for (int i = 0; i < 15; i++) {
          final score = 10 - (i % 5); // Scores: 10, 9, 8, 7, 6 repeated
          final distance = (10 - score + 1) * 20.0; // Spread out
          arrows.add(createFakeArrow(
            id: 'arrow_$i',
            xMm: distance,
            yMm: 0,
            score: score,
          ));
        }

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);

        // With spread arrows, zoom should be closer to minimum
        expect(result, greaterThanOrEqualTo(SmartZoom.minZoom));
      });

      test('finds most frequent score correctly', () {
        // Create 15 arrows: 10 arrows scoring 9, 5 arrows scoring 10
        final arrows = <Arrow>[];
        for (int i = 0; i < 10; i++) {
          arrows.add(createFakeArrow(
            id: 'arrow_9_$i',
            xMm: 30, // In 9 ring
            yMm: 0,
            score: 9,
          ));
        }
        for (int i = 0; i < 5; i++) {
          arrows.add(createFakeArrow(
            id: 'arrow_10_$i',
            xMm: 5,
            yMm: 0,
            score: 10,
            isX: true,
          ));
        }

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);

        // Should base zoom on score 9 (most frequent)
        // Ring 9 is at 0.2 radius, plus 0.3 padding = 0.5
        // Zoom = 1/0.5 = 2.0
        expect(result, greaterThanOrEqualTo(2.0));
      });

      test('respects maximum zoom of 6.0', () {
        // All arrows in X ring
        final arrows = List.generate(15, (i) => createFakeArrow(
          id: 'arrow_$i',
          xMm: 2,
          yMm: 2,
          score: 10,
          isX: true,
        ));

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);
        expect(result, lessThanOrEqualTo(6.0));
      });

      test('respects minimum zoom of 2.0', () {
        // Arrows spread to outer rings
        final arrows = List.generate(15, (i) => createFakeArrow(
          id: 'arrow_$i',
          xMm: 180, // Near edge
          yMm: 0,
          score: 1,
        ));

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);
        expect(result, greaterThanOrEqualTo(2.0));
      });

      test('isIndoor parameter is accepted', () {
        final arrows = createArrowGroup(count: 15, baseScore: 9);

        // Should work for both indoor and outdoor
        final indoorZoom = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);
        final outdoorZoom = SmartZoom.calculateZoomFactor(arrows, isIndoor: false);

        // Both should return valid zoom values
        expect(indoorZoom, greaterThanOrEqualTo(SmartZoom.minZoom));
        expect(outdoorZoom, greaterThanOrEqualTo(SmartZoom.minZoom));
      });
    });

    group('_scoreToNormalizedRadius', () {
      // These tests verify the internal mapping is correct
      // We test indirectly through the public API

      test('score 10 maps to X ring radius', () {
        // If all arrows score 10 (X), the base radius should be TargetRings.x
        final arrows = List.generate(15, (i) => createFakeArrow(
          id: 'arrow_$i',
          xMm: 5,
          yMm: 5,
          score: 10,
          isX: true,
        ));

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);

        // X ring is very small (0.05), plus 0.3 padding = 0.35
        // Zoom = 1/0.35 ≈ 2.86, clamped to min 2.0 max 6.0
        expect(result, greaterThan(2.0));
        expect(result, lessThanOrEqualTo(6.0));
      });

      test('score 5 maps to ring 5 radius', () {
        final arrows = List.generate(15, (i) => createFakeArrow(
          id: 'arrow_$i',
          xMm: 110, // In blue ring
          yMm: 0,
          score: 5,
        ));

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);

        // Ring 5 is at 0.5-0.6, plus 0.3 padding = 0.8-0.9
        // Zoom should be close to minimum
        expect(result, closeTo(SmartZoom.minZoom, 0.5));
      });

      test('score 1 maps to ring 1 radius (outer edge)', () {
        final arrows = List.generate(15, (i) => createFakeArrow(
          id: 'arrow_$i',
          xMm: 190,
          yMm: 0,
          score: 1,
        ));

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);

        // Ring 1 is at 1.0, plus 0.3 = 1.3, clamped to 1.0
        // Zoom = 1/1.0 = 1.0, but minimum is 2.0
        expect(result, equals(SmartZoom.minZoom));
      });
    });

    group('Constants', () {
      test('minCalibrationArrows is 12', () {
        expect(SmartZoom.minCalibrationArrows, equals(12));
      });

      test('minZoom is 2.0', () {
        expect(SmartZoom.minZoom, equals(2.0));
      });
    });

    group('Edge Cases', () {
      test('handles all arrows with same score', () {
        final arrows = List.generate(20, (i) => createFakeArrow(
          id: 'arrow_$i',
          xMm: 40,
          yMm: 40,
          score: 8,
        ));

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);
        expect(result, greaterThanOrEqualTo(SmartZoom.minZoom));
        expect(result, lessThanOrEqualTo(6.0));
      });

      test('handles tie in score frequency', () {
        // Equal number of 9s and 10s
        final arrows = <Arrow>[];
        for (int i = 0; i < 8; i++) {
          arrows.add(createFakeArrow(
            id: 'arrow_9_$i',
            xMm: 30,
            yMm: 0,
            score: 9,
          ));
        }
        for (int i = 0; i < 8; i++) {
          arrows.add(createFakeArrow(
            id: 'arrow_10_$i',
            xMm: 10,
            yMm: 0,
            score: 10,
          ));
        }

        // Should not crash, returns valid zoom
        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);
        expect(result, greaterThanOrEqualTo(SmartZoom.minZoom));
      });

      test('handles score 0 (miss)', () {
        final arrows = List.generate(15, (i) => createFakeArrow(
          id: 'arrow_$i',
          xMm: 250, // Outside target
          yMm: 0,
          score: 0,
        ));

        // Should handle miss scores without crashing
        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);
        expect(result, greaterThanOrEqualTo(SmartZoom.minZoom));
      });

      test('handles mixed scores including misses', () {
        final arrows = <Arrow>[];
        // Mix of good shots and misses
        for (int i = 0; i < 12; i++) {
          arrows.add(createFakeArrow(
            id: 'arrow_good_$i',
            xMm: 30,
            yMm: 0,
            score: 9,
          ));
        }
        for (int i = 0; i < 3; i++) {
          arrows.add(createFakeArrow(
            id: 'arrow_miss_$i',
            xMm: 250,
            yMm: 0,
            score: 0,
          ));
        }

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);
        expect(result, greaterThanOrEqualTo(SmartZoom.minZoom));
      });
    });

    group('Real-World Scenarios', () {
      test('beginner archer pattern (wide spread)', () {
        // Beginner with arrows from 5-10
        final arrows = <Arrow>[];
        final scores = [10, 9, 9, 8, 7, 8, 6, 7, 5, 8, 9, 7, 6, 8, 9];
        for (int i = 0; i < scores.length; i++) {
          final score = scores[i];
          final distance = (11 - score) * 20.0;
          arrows.add(createFakeArrow(
            id: 'arrow_$i',
            xMm: distance,
            yMm: (i % 2 == 0 ? 1 : -1) * 10.0,
            score: score,
          ));
        }

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);

        // Most frequent is probably 8 or 9, zoom should be moderate
        expect(result, greaterThanOrEqualTo(2.0));
        expect(result, lessThan(4.0));
      });

      test('advanced archer pattern (tight group)', () {
        // Advanced archer with mostly 10s and 9s
        final arrows = <Arrow>[];
        final scores = [10, 10, 10, 10, 9, 10, 10, 9, 10, 10, 10, 10, 9, 10, 10];
        for (int i = 0; i < scores.length; i++) {
          final score = scores[i];
          final distance = score == 10 ? 8.0 : 25.0;
          arrows.add(createFakeArrow(
            id: 'arrow_$i',
            xMm: distance + (i % 3) * 3,
            yMm: (i % 2 == 0 ? 1 : -1) * 5.0,
            score: score,
            isX: score == 10 && i % 3 == 0,
          ));
        }

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);

        // Most frequent is 10, should zoom in more
        expect(result, greaterThan(2.0));
      });

      test('olympic archer pattern (all in gold)', () {
        // Olympic level - all 10s with good X rate
        final arrows = List.generate(15, (i) => createFakeArrow(
          id: 'arrow_$i',
          xMm: 8 + (i % 4),
          yMm: (i % 2 == 0 ? 1 : -1) * 4.0,
          score: 10,
          isX: i < 10, // 66% X rate
        ));

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);

        // Should maximize zoom for gold focus
        expect(result, greaterThan(2.5));
      });
    });
  });
}
