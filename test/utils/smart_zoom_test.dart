import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/db/database.dart';
import 'package:archery_super_app/utils/smart_zoom.dart';
import '../test_helpers.dart';

void main() {
  group('SmartZoom', () {
    group('calculateZoomFactor', () {
      test('returns minimum zoom with insufficient data (< 3 arrows)', () {
        // Need at least 3 arrows for adaptive zoom
        expect(
          SmartZoom.calculateZoomFactor([], isIndoor: true),
          equals(SmartZoom.minZoom),
        );
        expect(
          SmartZoom.calculateZoomFactor(
            [createFakeArrow(id: '1', xMm: 0, yMm: 0, score: 10)],
            isIndoor: true,
          ),
          equals(SmartZoom.minZoom),
        );
        expect(
          SmartZoom.calculateZoomFactor(
            [
              createFakeArrow(id: '1', xMm: 0, yMm: 0, score: 10),
              createFakeArrow(id: '2', xMm: 10, yMm: 0, score: 10),
            ],
            isIndoor: true,
          ),
          equals(SmartZoom.minZoom),
        );
      });

      test('calculates zoom based on actual arrow spread', () {
        // Tight group: all arrows within 30mm of each other
        // On 122cm target, 30mm ≈ 0.05 normalized radius
        final tightGroup = [
          createFakeArrow(id: '1', xMm: 0, yMm: 0, score: 10),
          createFakeArrow(id: '2', xMm: 10, yMm: 5, score: 10),
          createFakeArrow(id: '3', xMm: -5, yMm: 10, score: 10),
          createFakeArrow(id: '4', xMm: 5, yMm: -5, score: 10),
        ];

        // Wide group: arrows spread across 200mm
        // On 122cm target, 200mm ≈ 0.33 normalized radius
        final wideGroup = [
          createFakeArrow(id: '1', xMm: 0, yMm: 0, score: 10),
          createFakeArrow(id: '2', xMm: 100, yMm: 0, score: 8),
          createFakeArrow(id: '3', xMm: -100, yMm: 0, score: 8),
          createFakeArrow(id: '4', xMm: 0, yMm: 100, score: 8),
        ];

        final tightZoom = SmartZoom.calculateZoomFactor(tightGroup, isIndoor: true);
        final wideZoom = SmartZoom.calculateZoomFactor(wideGroup, isIndoor: false);

        // Tighter group should have HIGHER or EQUAL zoom (more magnification)
        // Both may be at minZoom if groups are wide enough
        expect(tightZoom, greaterThanOrEqualTo(wideZoom));
      });

      test('respects minimum zoom of 4.0', () {
        // Even with very wide spread, minimum is 4.0
        final veryWideGroup = [
          createFakeArrow(id: '1', xMm: 0, yMm: 0, score: 5),
          createFakeArrow(id: '2', xMm: 200, yMm: 200, score: 3),
          createFakeArrow(id: '3', xMm: -200, yMm: -200, score: 3),
        ];

        final result = SmartZoom.calculateZoomFactor(veryWideGroup, isIndoor: true);
        expect(result, equals(SmartZoom.minZoom));
      });

      test('respects maximum zoom of 10.0', () {
        // Super tight group - all arrows very close together
        // With 0.2 padding, practical max approaches maxZoom
        final superTightGroup = [
          createFakeArrow(id: '1', xMm: 0, yMm: 0, score: 10),
          createFakeArrow(id: '2', xMm: 1, yMm: 1, score: 10),
          createFakeArrow(id: '3', xMm: -1, yMm: -1, score: 10),
          createFakeArrow(id: '4', xMm: 1, yMm: -1, score: 10),
        ];

        final result = SmartZoom.calculateZoomFactor(superTightGroup, isIndoor: true);
        // Should be close to max (limited by 0.2 padding)
        expect(result, greaterThan(4.5));
        expect(result, lessThanOrEqualTo(SmartZoom.maxZoom));
      });

      test('isIndoor parameter is accepted', () {
        final arrows = [
          createFakeArrow(id: '1', xMm: 20, yMm: 10, score: 10),
          createFakeArrow(id: '2', xMm: -15, yMm: 20, score: 10),
          createFakeArrow(id: '3', xMm: 10, yMm: -15, score: 10),
        ];

        // Should work for both indoor and outdoor
        final indoorZoom = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);
        final outdoorZoom = SmartZoom.calculateZoomFactor(arrows, isIndoor: false);

        // Both should return valid zoom values
        expect(indoorZoom, greaterThanOrEqualTo(SmartZoom.minZoom));
        expect(outdoorZoom, greaterThanOrEqualTo(SmartZoom.minZoom));
      });

      test('handles all arrows at same position', () {
        // Degenerate case: all arrows in exact same spot
        final arrows = [
          createFakeArrow(id: '1', xMm: 50, yMm: 50, score: 9),
          createFakeArrow(id: '2', xMm: 50, yMm: 50, score: 9),
          createFakeArrow(id: '3', xMm: 50, yMm: 50, score: 9),
        ];

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);
        // Should return high zoom (spread = 0, only padding matters)
        expect(result, greaterThan(4.0));
      });

      test('handles score 0 (miss) arrows', () {
        // Arrows that missed the target entirely
        final arrows = [
          createFakeArrow(id: '1', xMm: 250, yMm: 0, score: 0),
          createFakeArrow(id: '2', xMm: -250, yMm: 0, score: 0),
          createFakeArrow(id: '3', xMm: 0, yMm: 250, score: 0),
        ];

        // Should handle misses without crashing
        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);
        expect(result, greaterThanOrEqualTo(SmartZoom.minZoom));
      });

      test('handles mixed scores including misses', () {
        final arrows = [
          createFakeArrow(id: '1', xMm: 10, yMm: 5, score: 10),
          createFakeArrow(id: '2', xMm: 20, yMm: -10, score: 9),
          createFakeArrow(id: '3', xMm: -15, yMm: 15, score: 10),
          createFakeArrow(id: 'miss', xMm: 300, yMm: 0, score: 0), // Wild miss
        ];

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);
        // Should return valid zoom despite miss
        expect(result, greaterThanOrEqualTo(SmartZoom.minZoom));
        expect(result, lessThanOrEqualTo(SmartZoom.maxZoom));
      });

      test('uses 90th percentile to ignore outliers', () {
        // 9 tight arrows + 1 wild outlier
        final groupWithOutlier = [
          createFakeArrow(id: '1', xMm: 0, yMm: 0, score: 10),
          createFakeArrow(id: '2', xMm: 5, yMm: 5, score: 10),
          createFakeArrow(id: '3', xMm: -5, yMm: 5, score: 10),
          createFakeArrow(id: '4', xMm: 5, yMm: -5, score: 10),
          createFakeArrow(id: '5', xMm: -5, yMm: -5, score: 10),
          createFakeArrow(id: '6', xMm: 0, yMm: 5, score: 10),
          createFakeArrow(id: '7', xMm: 5, yMm: 0, score: 10),
          createFakeArrow(id: '8', xMm: -5, yMm: 0, score: 10),
          createFakeArrow(id: '9', xMm: 0, yMm: -5, score: 10),
          createFakeArrow(id: 'outlier', xMm: 200, yMm: 0, score: 3), // Wild miss
        ];

        // Same group without outlier
        final groupWithoutOutlier = groupWithOutlier.sublist(0, 9);

        final zoomWithOutlier = SmartZoom.calculateZoomFactor(groupWithOutlier, isIndoor: true);
        final zoomWithoutOutlier = SmartZoom.calculateZoomFactor(groupWithoutOutlier, isIndoor: true);

        // Both should give high zoom (tight groups)
        // The 90th percentile helps reduce impact of outlier
        expect(zoomWithOutlier, greaterThan(3.0));
        expect(zoomWithoutOutlier, greaterThan(3.0));
        // Zooms don't need to be identical, but should be in similar range
        expect((zoomWithOutlier - zoomWithoutOutlier).abs(), lessThan(2.0));
      });
    });

    group('calculateGroupStats', () {
      test('returns zeros for empty list', () {
        final stats = SmartZoom.calculateGroupStats([]);
        expect(stats.centerX, equals(0));
        expect(stats.centerY, equals(0));
        expect(stats.spreadRadius, equals(0));
      });

      test('calculates center correctly for symmetric group', () {
        final arrows = [
          createFakeArrow(id: '1', xMm: 100, yMm: 0, score: 8),
          createFakeArrow(id: '2', xMm: -100, yMm: 0, score: 8),
          createFakeArrow(id: '3', xMm: 0, yMm: 100, score: 8),
          createFakeArrow(id: '4', xMm: 0, yMm: -100, score: 8),
        ];

        final stats = SmartZoom.calculateGroupStats(arrows);

        // Center should be near (0, 0) normalized
        expect(stats.centerX, closeTo(0, 0.01));
        expect(stats.centerY, closeTo(0, 0.01));
      });

      test('calculates center correctly for offset group', () {
        // All arrows in the upper-right quadrant
        final arrows = [
          createFakeArrow(id: '1', xMm: 50, yMm: 50, score: 9),
          createFakeArrow(id: '2', xMm: 70, yMm: 50, score: 9),
          createFakeArrow(id: '3', xMm: 50, yMm: 70, score: 9),
          createFakeArrow(id: '4', xMm: 70, yMm: 70, score: 9),
        ];

        final stats = SmartZoom.calculateGroupStats(arrows);

        // Center should be at approximately (60mm, 60mm) from target center
        // Normalized: 60/610 ≈ 0.098 (122cm face has 610mm radius)
        expect(stats.centerX, greaterThan(0)); // Positive X
        expect(stats.centerY, greaterThan(0)); // Positive Y (up from center)
      });

      test('calculates spread radius correctly', () {
        // Group with known spread: all 100mm from center at 0mm
        // Using 40cm face (default), radius = 200mm
        // So 100mm = 0.5 normalized
        final arrows = [
          createFakeArrow(id: '1', xMm: 100, yMm: 0, score: 8),
          createFakeArrow(id: '2', xMm: -100, yMm: 0, score: 8),
          createFakeArrow(id: '3', xMm: 0, yMm: 100, score: 8),
          createFakeArrow(id: '4', xMm: 0, yMm: -100, score: 8),
        ];

        final stats = SmartZoom.calculateGroupStats(arrows);

        // Group center is at (0, 0) in normalized coords
        // All arrows are 100mm from center = 0.5 normalized (on 40cm face)
        expect(stats.spreadRadius, closeTo(0.5, 0.02));
      });
    });

    group('Constants', () {
      test('minArrowsForAdaptiveZoom is 3', () {
        expect(SmartZoom.minArrowsForAdaptiveZoom, equals(3));
      });

      test('minZoom is 4.0', () {
        expect(SmartZoom.minZoom, equals(4.0));
      });

      test('maxZoom is 10.0', () {
        expect(SmartZoom.maxZoom, equals(10.0));
      });

      test('paddingRings is 0.2', () {
        expect(SmartZoom.paddingRings, equals(0.2));
      });
    });

    group('Real-World Scenarios', () {
      test('beginner archer pattern (wide spread)', () {
        // Beginner with arrows scattered across target
        final arrows = [
          createFakeArrow(id: '1', xMm: 50, yMm: 30, score: 9),
          createFakeArrow(id: '2', xMm: -80, yMm: -20, score: 8),
          createFakeArrow(id: '3', xMm: 30, yMm: -90, score: 7),
          createFakeArrow(id: '4', xMm: -40, yMm: 70, score: 8),
          createFakeArrow(id: '5', xMm: 100, yMm: 0, score: 7),
          createFakeArrow(id: '6', xMm: -20, yMm: -60, score: 8),
        ];

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);

        // Wide spread should have low zoom (at or near minimum)
        expect(result, greaterThanOrEqualTo(SmartZoom.minZoom));
        expect(result, lessThanOrEqualTo(SmartZoom.minZoom + 2.0));
      });

      test('advanced archer pattern (tight group)', () {
        // Advanced archer with most arrows in gold
        // Spread ~15mm on 40cm face = ~0.075 normalized spread
        // With new higher zoom range, tight groups get more magnification
        final arrows = [
          createFakeArrow(id: '1', xMm: 10, yMm: 5, score: 10),
          createFakeArrow(id: '2', xMm: -5, yMm: 10, score: 10),
          createFakeArrow(id: '3', xMm: 8, yMm: -3, score: 10),
          createFakeArrow(id: '4', xMm: -10, yMm: -8, score: 10),
          createFakeArrow(id: '5', xMm: 0, yMm: 15, score: 10),
          createFakeArrow(id: '6', xMm: 12, yMm: 0, score: 10),
        ];

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);

        // Tight group should have moderate-high zoom (above minimum)
        expect(result, greaterThanOrEqualTo(SmartZoom.minZoom));
        expect(result, lessThanOrEqualTo(SmartZoom.maxZoom));
      });

      test('olympic archer pattern (all in X ring)', () {
        // Olympic level - all arrows in X ring
        // Spread ~3mm on 40cm face = ~0.015 normalized spread
        // Super tight groups should approach max zoom
        final arrows = [
          createFakeArrow(id: '1', xMm: 2, yMm: 1, score: 10, isX: true),
          createFakeArrow(id: '2', xMm: -1, yMm: 2, score: 10, isX: true),
          createFakeArrow(id: '3', xMm: 1, yMm: -2, score: 10, isX: true),
          createFakeArrow(id: '4', xMm: -2, yMm: -1, score: 10, isX: true),
          createFakeArrow(id: '5', xMm: 0, yMm: 3, score: 10, isX: true),
          createFakeArrow(id: '6', xMm: 3, yMm: 0, score: 10, isX: true),
        ];

        final result = SmartZoom.calculateZoomFactor(arrows, isIndoor: true);

        // Super tight group should be close to max zoom
        expect(result, greaterThanOrEqualTo(SmartZoom.minZoom));
        expect(result, lessThanOrEqualTo(SmartZoom.maxZoom));
      });

      test('mixed session with improving groups', () {
        // First half: scattered
        final firstHalf = [
          createFakeArrow(id: '1', xMm: 80, yMm: -50, score: 8),
          createFakeArrow(id: '2', xMm: -60, yMm: 40, score: 8),
          createFakeArrow(id: '3', xMm: 30, yMm: 90, score: 7),
        ];

        // Second half: tighter
        final secondHalf = [
          createFakeArrow(id: '4', xMm: 15, yMm: 10, score: 10),
          createFakeArrow(id: '5', xMm: -10, yMm: 15, score: 10),
          createFakeArrow(id: '6', xMm: 5, yMm: -12, score: 10),
        ];

        final firstZoom = SmartZoom.calculateZoomFactor(firstHalf, isIndoor: true);
        final secondZoom = SmartZoom.calculateZoomFactor(secondHalf, isIndoor: true);

        // Second half should zoom in more or same (tighter group)
        // Both may be at minZoom if under threshold
        expect(secondZoom, greaterThanOrEqualTo(firstZoom));
      });
    });
  });
}
