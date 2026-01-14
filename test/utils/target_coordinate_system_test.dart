import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archery_super_app/models/arrow_coordinate.dart';
import 'package:archery_super_app/utils/target_coordinate_system.dart';
import 'package:archery_super_app/theme/app_theme.dart';

void main() {
  group('TargetCoordinateSystem', () {
    group('Core Measurements', () {
      test('calculates radius in mm correctly', () {
        final sys40 = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);
        expect(sys40.radiusMm, equals(200.0)); // 40cm * 5 = 200mm

        final sys80 = TargetCoordinateSystem(faceSizeCm: 80, widgetSize: 300);
        expect(sys80.radiusMm, equals(400.0)); // 80cm * 5 = 400mm

        final sys122 = TargetCoordinateSystem(faceSizeCm: 122, widgetSize: 300);
        expect(sys122.radiusMm, equals(610.0)); // 122cm * 5 = 610mm
      });

      test('calculates diameter in mm correctly', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);
        expect(sys.diameterMm, equals(400.0)); // 40cm * 10 = 400mm
      });

      test('calculates widget center correctly', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);
        expect(sys.widgetCenter, equals(const Offset(150, 150)));

        final sys200 = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 200);
        expect(sys200.widgetCenter, equals(const Offset(100, 100)));
      });

      test('calculates pixels per mm correctly', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 400);
        // 400px / 400mm = 1 px/mm
        expect(sys.pixelsPerMm, equals(1.0));

        final sys2 = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 200);
        // 200px / 400mm = 0.5 px/mm
        expect(sys2.pixelsPerMm, equals(0.5));
      });
    });

    group('Coordinate Conversions', () {
      test('converts pixels to coordinate', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        // Center pixel
        final center = sys.pixelsToCoordinate(const Offset(150, 150));
        expect(center.xMm, closeTo(0.0, 0.1));
        expect(center.yMm, closeTo(0.0, 0.1));

        // Right edge (at widget edge = radius)
        final rightEdge = sys.pixelsToCoordinate(const Offset(300, 150));
        expect(rightEdge.xMm, closeTo(200.0, 0.1)); // Full radius
        expect(rightEdge.yMm, closeTo(0.0, 0.1));
      });

      test('converts coordinate to pixels (rounded)', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        final coord = ArrowCoordinate(xMm: 100, yMm: 50, faceSizeCm: 40);
        final pixels = sys.coordinateToPixels(coord);

        // Should be rounded
        expect(pixels.dx, equals(pixels.dx.roundToDouble()));
        expect(pixels.dy, equals(pixels.dy.roundToDouble()));

        // 100mm on 200mm radius = 0.5 normalized
        // 150 + 0.5 * 150 = 225
        expect(pixels.dx, equals(225.0));
        // 50mm = 0.25 normalized, 150 + 0.25 * 150 = 187.5 -> 188
        expect(pixels.dy, equals(188.0));
      });

      test('converts coordinate to pixels exact (no rounding)', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        final coord = ArrowCoordinate(xMm: 73.5, yMm: 41.2, faceSizeCm: 40);
        final exact = sys.coordinateToPixelsExact(coord);

        // May have decimals
        // 73.5mm = 73.5/200 = 0.3675 normalized
        // 150 + 0.3675 * 150 = 205.125
        expect(exact.dx, closeTo(205.125, 0.001));
      });

      test('converts normalized to pixels', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        final pixels = sys.normalizedToPixels(0.5, -0.25);

        // 150 + 0.5 * 150 = 225
        // 150 + (-0.25) * 150 = 112.5 -> 112 or 113
        expect(pixels.dx, equals(225.0));
        expect(pixels.dy, closeTo(112.5, 0.5));
      });

      test('converts pixels to normalized', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        final norm = sys.pixelsToNormalized(const Offset(225, 150));

        expect(norm.dx, closeTo(0.5, 0.001));
        expect(norm.dy, closeTo(0.0, 0.001));
      });

      test('mm to pixels and back', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        final originalMm = 75.0;
        final pixels = sys.mmToPixels(originalMm);
        final backToMm = sys.pixelsToMm(pixels);

        expect(backToMm, closeTo(originalMm, 0.001));
      });
    });

    group('Ring Boundaries', () {
      test('calculates ring boundary pixels', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        // Ring 10 boundary is at 10% of radius = 20mm
        final ring10Boundary = sys.ringBoundaryPixels(10);
        final expected10 = sys.mmToPixels(20.0); // 20mm for 40cm face
        expect(ring10Boundary, closeTo(expected10, 0.1));
      });

      test('calculates ring boundary normalized', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        // Ring 10 boundary is at 10% of radius
        final ring10Norm = sys.ringBoundaryNormalized(10);
        expect(ring10Norm, closeTo(0.1, 0.001));
      });

      test('provides all ring boundaries as pixels', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        final boundaries = sys.ringBoundariesPixels;

        expect(boundaries.length, equals(10));
        expect(boundaries.containsKey(1), isTrue);
        expect(boundaries.containsKey(10), isTrue);

        // Ring 1 should be largest (outermost)
        expect(boundaries[1]!, greaterThan(boundaries[10]!));
      });

      test('calculates X ring boundary', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        final xBoundary = sys.xRingBoundaryPixels;

        // X ring is smaller than ring 10
        expect(xBoundary, lessThan(sys.ringBoundaryPixels(10)));
        expect(xBoundary, greaterThan(0));
      });
    });

    group('Scoring', () {
      test('scores from coordinate using epsilon', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        // Center = X/10
        final center = ArrowCoordinate(xMm: 0, yMm: 0, faceSizeCm: 40);
        expect(sys.scoreFromCoordinate(center), equals(10));
        expect(sys.isXRing(center), isTrue);

        // At ring 10 outer boundary (20mm for 40cm face)
        final ring10Edge = ArrowCoordinate(xMm: 20, yMm: 0, faceSizeCm: 40);
        expect(sys.scoreFromCoordinate(ring10Edge), equals(10));

        // Just outside ring 10 (21mm)
        final ring9 = ArrowCoordinate(xMm: 21, yMm: 0, faceSizeCm: 40);
        expect(sys.scoreFromCoordinate(ring9), equals(9));
      });

      test('scoreAndX returns both score and X status', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        final center = ArrowCoordinate(xMm: 0, yMm: 0, faceSizeCm: 40);
        final result = sys.scoreAndX(center);

        expect(result.score, equals(10));
        expect(result.isX, isTrue);

        // Just outside X ring
        final notX = ArrowCoordinate(xMm: 15, yMm: 0, faceSizeCm: 40);
        final notXResult = sys.scoreAndX(notX);

        expect(notXResult.score, equals(10));
        expect(notXResult.isX, isFalse);
      });
    });

    group('Boundary Proximity Detection', () {
      test('detects when near ring boundary', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        // Ring 10 boundary is at 20mm for 40cm face
        // Create coordinate very close to boundary
        final nearBoundary = ArrowCoordinate(xMm: 20.5, yMm: 0, faceSizeCm: 40);

        final result = sys.nearestBoundary(nearBoundary, thresholdPercent: 1.5);

        expect(result, isNotNull);
        expect(result!.ring, isNotNull);
      });

      test('returns null when not near any boundary', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        // Coordinate in the middle of ring 9 (between 20mm and 40mm)
        final notNear = ArrowCoordinate(xMm: 30, yMm: 0, faceSizeCm: 40);

        final result = sys.nearestBoundary(notNear, thresholdPercent: 1.0);

        // With 1% threshold on 200mm radius = 2mm
        // 30mm is 10mm from both boundaries, so should be null
        expect(result, isNull);
      });
    });

    group('Zoom Window Support', () {
      test('calculates zoom window offset', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        final centerOn = ArrowCoordinate(xMm: 50, yMm: 30, faceSizeCm: 40);
        final offset = sys.zoomWindowOffset(
          centerOn: centerOn,
          zoomFactor: 3.0,
          windowSize: 120,
        );

        // The offset should position the target so centerOn appears at window center
        expect(offset.dx, isA<double>());
        expect(offset.dy, isA<double>());
      });

      test('transforms coordinate for zoom window', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        final centerOn = ArrowCoordinate(xMm: 50, yMm: 30, faceSizeCm: 40);
        final coord = ArrowCoordinate(xMm: 60, yMm: 40, faceSizeCm: 40);

        final zoomPixels = sys.coordinateToZoomWindowPixels(
          coord: coord,
          centerOn: centerOn,
          zoomFactor: 3.0,
          windowSize: 120,
        );

        // The centerOn point should be at window center (60, 60)
        final centerPixels = sys.coordinateToZoomWindowPixels(
          coord: centerOn,
          centerOn: centerOn,
          zoomFactor: 3.0,
          windowSize: 120,
        );
        expect(centerPixels.dx, equals(60.0));
        expect(centerPixels.dy, equals(60.0));

        // Other coords should be offset from center
        // coord is 10mm right and 10mm down from centerOn
        // At 3x zoom on 300px widget: 10mm = 7.5px, 7.5 * 3 = 22.5
        // So coord should be at (60 + 22.5, 60 + 22.5) rounded
        expect(zoomPixels.dx, greaterThan(60));
        expect(zoomPixels.dy, greaterThan(60));
      });

      test('calculates visible bounds in zoom window', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        final centerOn = ArrowCoordinate(xMm: 50, yMm: 30, faceSizeCm: 40);
        final bounds = sys.zoomWindowVisibleBounds(
          centerOn: centerOn,
          zoomFactor: 3.0,
          windowSize: 120,
        );

        // Bounds should be centered on the centerOn coordinate
        expect(bounds.center.dx, closeTo(centerOn.xMm, 0.1));
        expect(bounds.center.dy, closeTo(centerOn.yMm, 0.1));
      });
    });

    group('Auto-Zoom Calculation', () {
      test('returns minimum zoom for few arrows', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        final fewArrows = [
          ArrowCoordinate(xMm: 10, yMm: 10, faceSizeCm: 40),
          ArrowCoordinate(xMm: 20, yMm: 20, faceSizeCm: 40),
        ];

        final zoom = sys.calculateAutoZoom(arrows: fewArrows, minArrows: 6);

        expect(zoom, equals(1.5)); // Default minZoom
      });

      test('calculates zoom based on group spread', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        // Create a tight group near center
        final tightGroup = List.generate(
          12,
          (i) => ArrowCoordinate(
            xMm: 10 + (i % 4).toDouble(),
            yMm: 10 + (i ~/ 4).toDouble(),
            faceSizeCm: 40,
          ),
        );

        final zoom = sys.calculateAutoZoom(arrows: tightGroup);

        // Should zoom in for tight group
        expect(zoom, greaterThan(1.5));
      });

      test('limits zoom to maxZoom', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        // All arrows at exact same point
        final samePoint = List.generate(
          12,
          (i) => ArrowCoordinate(xMm: 10, yMm: 10, faceSizeCm: 40),
        );

        final zoom = sys.calculateAutoZoom(
          arrows: samePoint,
          maxZoom: 6.0,
        );

        expect(zoom, lessThanOrEqualTo(6.0));
      });
    });

    group('Equality', () {
      test('equal systems have same parameters', () {
        final sys1 = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);
        final sys2 = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);

        expect(sys1, equals(sys2));
        expect(sys1.hashCode, equals(sys2.hashCode));
      });

      test('different face sizes are not equal', () {
        final sys1 = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);
        final sys2 = TargetCoordinateSystem(faceSizeCm: 80, widgetSize: 300);

        expect(sys1, isNot(equals(sys2)));
      });

      test('different widget sizes are not equal', () {
        final sys1 = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);
        final sys2 = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 400);

        expect(sys1, isNot(equals(sys2)));
      });
    });

    group('toString', () {
      test('provides useful debug info', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 300);
        final str = sys.toString();

        expect(str, contains('40cm'));
        expect(str, contains('300'));
        expect(str, contains('px/mm'));
      });
    });

    group('Edge Cases', () {
      test('handles different standard face sizes', () {
        for (final faceSize in [40, 60, 80, 122]) {
          final sys = TargetCoordinateSystem(
            faceSizeCm: faceSize,
            widgetSize: 300,
          );

          expect(sys.radiusMm, equals(faceSize * 5.0));
          expect(sys.diameterMm, equals(faceSize * 10.0));

          // All ring boundaries should be valid
          for (int ring = 1; ring <= 10; ring++) {
            expect(sys.ringBoundaryPixels(ring), isPositive);
          }
        }
      });

      test('handles very small widget sizes', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 50);

        expect(sys.widgetCenter, equals(const Offset(25, 25)));
        expect(sys.pixelsPerMm, equals(50 / 400)); // 0.125
      });

      test('handles very large widget sizes', () {
        final sys = TargetCoordinateSystem(faceSizeCm: 40, widgetSize: 2000);

        expect(sys.widgetCenter, equals(const Offset(1000, 1000)));
        expect(sys.pixelsPerMm, equals(2000 / 400)); // 5.0
      });
    });
  });

  group('TargetRingsMm Scoring', () {
    test('epsilon constant is appropriate', () {
      // 0.001mm is sub-visual precision
      expect(TargetRingsMm.epsilon, equals(0.001));
    });

    test('scores correctly at all ring boundaries for 40cm face', () {
      const faceSizeCm = 40;

      // Test each ring boundary
      // Ring 10 boundary at 20mm
      expect(TargetRingsMm.scoreFromDistanceMm(0, faceSizeCm), equals(10));
      expect(TargetRingsMm.scoreFromDistanceMm(19.99, faceSizeCm), equals(10));
      expect(TargetRingsMm.scoreFromDistanceMm(20.0, faceSizeCm), equals(10));
      expect(TargetRingsMm.scoreFromDistanceMm(20.01, faceSizeCm), equals(9));

      // Ring 9 boundary at 40mm
      expect(TargetRingsMm.scoreFromDistanceMm(39.99, faceSizeCm), equals(9));
      expect(TargetRingsMm.scoreFromDistanceMm(40.0, faceSizeCm), equals(9));
      expect(TargetRingsMm.scoreFromDistanceMm(40.01, faceSizeCm), equals(8));

      // Miss (beyond ring 1)
      expect(TargetRingsMm.scoreFromDistanceMm(201, faceSizeCm), equals(0));
    });

    test('epsilon handles boundary line-cutters', () {
      const faceSizeCm = 40;

      // At exactly boundary + epsilon should still score higher ring
      final ring10Boundary = TargetRingsMm.getRingBoundaryMm(10, faceSizeCm);
      expect(
        TargetRingsMm.scoreFromDistanceMm(
          ring10Boundary + TargetRingsMm.epsilon,
          faceSizeCm,
        ),
        equals(10),
      );

      // At boundary + 2*epsilon should score lower ring
      expect(
        TargetRingsMm.scoreFromDistanceMm(
          ring10Boundary + 2 * TargetRingsMm.epsilon,
          faceSizeCm,
        ),
        equals(9),
      );
    });

    test('X ring detection works correctly', () {
      const faceSizeCm = 40;

      // X ring boundary is at ~10mm for 40cm face
      final xBoundary = TargetRingsMm.getXRingMm(faceSizeCm);

      expect(TargetRingsMm.isXRing(0, faceSizeCm), isTrue);
      expect(TargetRingsMm.isXRing(xBoundary - 0.01, faceSizeCm), isTrue);
      expect(TargetRingsMm.isXRing(xBoundary, faceSizeCm), isTrue);
      expect(TargetRingsMm.isXRing(xBoundary + 0.01, faceSizeCm), isFalse);
    });

    test('ring boundaries scale with face size', () {
      // Ring 10 is always 10% of radius
      expect(
        TargetRingsMm.getRingBoundaryMm(10, 40),
        equals(20.0), // 40cm * 5 * 0.1
      );
      expect(
        TargetRingsMm.getRingBoundaryMm(10, 80),
        equals(40.0), // 80cm * 5 * 0.1
      );
      expect(
        TargetRingsMm.getRingBoundaryMm(10, 122),
        equals(61.0), // 122cm * 5 * 0.1
      );
    });
  });
}
