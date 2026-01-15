import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archery_super_app/models/arrow_coordinate.dart';

void main() {
  group('ArrowCoordinate', () {
    group('Creation', () {
      test('creates from mm coordinates', () {
        final coord = ArrowCoordinate(
          xMm: 50.0,
          yMm: -30.0,
          faceSizeCm: 40,
        );

        expect(coord.xMm, equals(50.0));
        expect(coord.yMm, equals(-30.0));
        expect(coord.faceSizeCm, equals(40));
      });

      test('creates from normalized coordinates', () {
        final coord = ArrowCoordinate.fromNormalized(
          x: 0.5,
          y: -0.25,
          faceSizeCm: 40,
        );

        // 40cm face = 200mm radius
        // 0.5 * 200 = 100mm, -0.25 * 200 = -50mm
        expect(coord.xMm, equals(100.0));
        expect(coord.yMm, equals(-50.0));
      });

      test('creates from widget pixels', () {
        final coord = ArrowCoordinate.fromWidgetPixels(
          px: 225, // 75% across 300px widget
          py: 150, // center
          widgetSize: 300,
          faceSizeCm: 40,
        );

        // px 225 on 300 widget: normalized = (225-150)/150 = 0.5
        // 0.5 * 200mm radius = 100mm
        expect(coord.normalizedX, closeTo(0.5, 0.001));
        expect(coord.normalizedY, closeTo(0.0, 0.001));
        expect(coord.xMm, closeTo(100.0, 0.1));
        expect(coord.yMm, closeTo(0.0, 0.1));
      });

      test('creates from polar coordinates', () {
        final coord = ArrowCoordinate.fromPolar(
          distanceMm: 100.0,
          angleRadians: 0, // Right (3 o'clock)
          faceSizeCm: 40,
        );

        expect(coord.xMm, closeTo(100.0, 0.001));
        expect(coord.yMm, closeTo(0.0, 0.001));

        // Test 90 degrees (down)
        final downCoord = ArrowCoordinate.fromPolar(
          distanceMm: 50.0,
          angleRadians: math.pi / 2,
          faceSizeCm: 40,
        );

        expect(downCoord.xMm, closeTo(0.0, 0.001));
        expect(downCoord.yMm, closeTo(50.0, 0.001));
      });
    });

    group('Derived Properties', () {
      test('calculates distance from center', () {
        final coord = ArrowCoordinate(
          xMm: 30.0,
          yMm: 40.0,
          faceSizeCm: 40,
        );

        // Pythagorean: sqrt(30^2 + 40^2) = sqrt(900 + 1600) = sqrt(2500) = 50
        expect(coord.distanceMm, equals(50.0));
      });

      test('calculates normalized coordinates', () {
        final coord = ArrowCoordinate(
          xMm: 100.0,
          yMm: -50.0,
          faceSizeCm: 40, // 200mm radius
        );

        // 100/200 = 0.5, -50/200 = -0.25
        expect(coord.normalizedX, equals(0.5));
        expect(coord.normalizedY, equals(-0.25));
      });

      test('calculates normalized distance', () {
        final coord = ArrowCoordinate(
          xMm: 200.0, // At edge of 40cm face
          yMm: 0.0,
          faceSizeCm: 40,
        );

        expect(coord.normalizedDistance, equals(1.0));
      });

      test('detects on-target status', () {
        final onTarget = ArrowCoordinate(
          xMm: 100.0,
          yMm: 100.0,
          faceSizeCm: 40,
        );
        // Distance = sqrt(100^2 + 100^2) = 141.4mm
        // 141.4/200 = 0.707 < 1.0, so on target
        expect(onTarget.isOnTarget, isTrue);

        final offTarget = ArrowCoordinate(
          xMm: 200.0,
          yMm: 100.0,
          faceSizeCm: 40,
        );
        // Distance = sqrt(200^2 + 100^2) = 223.6mm
        // 223.6/200 = 1.118 > 1.0, so off target
        expect(offTarget.isOnTarget, isFalse);
      });

      test('calculates angle correctly', () {
        // Right (0 degrees)
        final right = ArrowCoordinate(xMm: 100, yMm: 0, faceSizeCm: 40);
        expect(right.angleDegrees, closeTo(0.0, 0.001));

        // Down (90 degrees)
        final down = ArrowCoordinate(xMm: 0, yMm: 100, faceSizeCm: 40);
        expect(down.angleDegrees, closeTo(90.0, 0.001));

        // Left (180 degrees or -180)
        final left = ArrowCoordinate(xMm: -100, yMm: 0, faceSizeCm: 40);
        expect(left.angleDegrees.abs(), closeTo(180.0, 0.001));

        // Up (-90 degrees)
        final up = ArrowCoordinate(xMm: 0, yMm: -100, faceSizeCm: 40);
        expect(up.angleDegrees, closeTo(-90.0, 0.001));
      });
    });

    group('Conversions', () {
      test('converts to widget pixels with rounding', () {
        final coord = ArrowCoordinate(
          xMm: 73.5, // Will produce fractional pixel
          yMm: 41.2,
          faceSizeCm: 40,
        );

        final pixels = coord.toWidgetPixels(300);

        // Verify positions are rounded (no decimal places)
        expect(pixels.dx, equals(pixels.dx.roundToDouble()));
        expect(pixels.dy, equals(pixels.dy.roundToDouble()));
      });

      test('converts to widget pixels exact (no rounding)', () {
        final coord = ArrowCoordinate(
          xMm: 73.5,
          yMm: 41.2,
          faceSizeCm: 40,
        );

        final exact = coord.toWidgetPixelsExact(300);
        final rounded = coord.toWidgetPixels(300);

        // Exact may have decimals, rounded should not
        // They should be within 0.5 of each other
        expect((exact.dx - rounded.dx).abs(), lessThanOrEqualTo(0.5));
        expect((exact.dy - rounded.dy).abs(), lessThanOrEqualTo(0.5));
      });

      test('converts for different face sizes', () {
        final coord = ArrowCoordinate(
          xMm: 50,
          yMm: 30,
          faceSizeCm: 40,
        );

        // Convert to 80cm face
        final largerFace = coord.forFaceSize(80);

        // mm values stay the same (physical position)
        expect(largerFace.xMm, equals(50));
        expect(largerFace.yMm, equals(30));
        expect(largerFace.faceSizeCm, equals(80));

        // But normalized values change
        // On 40cm: 50/200 = 0.25
        // On 80cm: 50/400 = 0.125
        expect(coord.normalizedX, equals(0.25));
        expect(largerFace.normalizedX, equals(0.125));
      });
    });

    group('Utility Methods', () {
      test('calculates distance to another coordinate', () {
        final a = ArrowCoordinate(xMm: 0, yMm: 0, faceSizeCm: 40);
        final b = ArrowCoordinate(xMm: 30, yMm: 40, faceSizeCm: 40);

        expect(a.distanceTo(b), equals(50.0));
        expect(b.distanceTo(a), equals(50.0)); // Symmetric
      });

      test('calculates midpoint', () {
        final a = ArrowCoordinate(xMm: 0, yMm: 0, faceSizeCm: 40);
        final b = ArrowCoordinate(xMm: 100, yMm: 50, faceSizeCm: 40);

        final mid = a.midpointTo(b);

        expect(mid.xMm, equals(50.0));
        expect(mid.yMm, equals(25.0));
      });

      test('applies offset', () {
        final coord = ArrowCoordinate(xMm: 50, yMm: 30, faceSizeCm: 40);
        final offset = coord.offset(10, -5);

        expect(offset.xMm, equals(60.0));
        expect(offset.yMm, equals(25.0));
      });
    });

    group('Equality', () {
      test('equals within epsilon tolerance (0.01mm)', () {
        final a = ArrowCoordinate(xMm: 50.0, yMm: 30.0, faceSizeCm: 40);
        final b = ArrowCoordinate(xMm: 50.005, yMm: 30.005, faceSizeCm: 40);

        // Within 0.01mm tolerance
        expect(a, equals(b));
      });

      test('not equal when difference exceeds epsilon', () {
        final a = ArrowCoordinate(xMm: 50.0, yMm: 30.0, faceSizeCm: 40);
        final b = ArrowCoordinate(xMm: 50.02, yMm: 30.0, faceSizeCm: 40);

        // 0.02mm > 0.01mm tolerance
        expect(a, isNot(equals(b)));
      });

      test('not equal when face size differs', () {
        final a = ArrowCoordinate(xMm: 50.0, yMm: 30.0, faceSizeCm: 40);
        final b = ArrowCoordinate(xMm: 50.0, yMm: 30.0, faceSizeCm: 80);

        expect(a, isNot(equals(b)));
      });

      test('hashCode is consistent with equality', () {
        final a = ArrowCoordinate(xMm: 50.0, yMm: 30.0, faceSizeCm: 40);
        // Use values within 0.005 tolerance that also round to same hashCode
        // hashCode uses (xMm * 100).round(), so 50.0 and 50.004 both round to 5000
        final b = ArrowCoordinate(xMm: 50.004, yMm: 30.004, faceSizeCm: 40);

        // Equal objects should have same hash
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('Display Strings', () {
      test('toString provides debug info', () {
        final coord = ArrowCoordinate(xMm: 50.5, yMm: -30.2, faceSizeCm: 40);
        final str = coord.toString();

        expect(str, contains('50.5'));
        expect(str, contains('-30.2'));
        expect(str, contains('40cm'));
      });

      test('toDisplayString provides human-readable position', () {
        final coord = ArrowCoordinate(xMm: 50.0, yMm: -30.0, faceSizeCm: 40);
        final display = coord.toDisplayString();

        expect(display, contains('mm'));
        expect(display, contains('R')); // Right
        expect(display, contains('U')); // Up (negative Y)
      });
    });

    group('Edge Cases', () {
      test('handles center position (0, 0)', () {
        final center = ArrowCoordinate(xMm: 0, yMm: 0, faceSizeCm: 40);

        expect(center.distanceMm, equals(0.0));
        expect(center.normalizedDistance, equals(0.0));
        expect(center.isOnTarget, isTrue);
      });

      test('handles coordinates at face edge', () {
        final edge = ArrowCoordinate(xMm: 200, yMm: 0, faceSizeCm: 40);

        expect(edge.normalizedDistance, equals(1.0));
        expect(edge.isOnTarget, isTrue); // Exactly on edge is on target
      });

      test('handles coordinates outside face', () {
        final outside = ArrowCoordinate(xMm: 250, yMm: 0, faceSizeCm: 40);

        expect(outside.normalizedDistance, equals(1.25));
        expect(outside.isOnTarget, isFalse);
      });

      test('handles different face sizes correctly', () {
        // Same mm position on different faces
        for (final faceSize in [40, 60, 80, 122]) {
          final coord = ArrowCoordinate(
            xMm: 50,
            yMm: 30,
            faceSizeCm: faceSize,
          );

          final radiusMm = faceSize * 5.0;
          expect(coord.normalizedX, equals(50 / radiusMm));
          expect(coord.normalizedY, equals(30 / radiusMm));
        }
      });
    });
  });
}
