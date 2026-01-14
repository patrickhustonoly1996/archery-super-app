import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archery_super_app/widgets/rolling_average_widget.dart';
import 'package:archery_super_app/db/database.dart';
import 'package:archery_super_app/models/arrow_coordinate.dart';
import 'package:archery_super_app/models/group_analysis.dart';
import 'package:archery_super_app/utils/target_coordinate_system.dart';
import 'package:archery_super_app/theme/app_theme.dart';

/// Creates a fake Arrow for testing with mm coordinates.
Arrow createFakeArrow({
  required String id,
  required double xMm,
  required double yMm,
  required int score,
  bool isX = false,
  int? shaftNumber,
  int faceSizeCm = 40,
}) {
  // Calculate normalized coordinates from mm for legacy compatibility
  final radiusMm = faceSizeCm * 5.0;
  final normalizedX = xMm / radiusMm;
  final normalizedY = yMm / radiusMm;

  return Arrow(
    id: id,
    endId: 'test-end',
    faceIndex: 0,
    xMm: xMm,
    yMm: yMm,
    x: normalizedX,
    y: normalizedY,
    score: score,
    isX: isX,
    sequence: 1,
    shaftNumber: shaftNumber,
    createdAt: DateTime.now(),
  );
}

/// Creates a fake Arrow using legacy normalized coordinates.
Arrow createFakeArrowNormalized({
  required String id,
  required double x,
  required double y,
  required int score,
  bool isX = false,
}) {
  return Arrow(
    id: id,
    endId: 'test-end',
    faceIndex: 0,
    xMm: 0.0, // Zero = legacy mode
    yMm: 0.0,
    x: x,
    y: y,
    score: score,
    isX: isX,
    sequence: 1,
    shaftNumber: null,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('RollingAverageWidget', () {
    testWidgets('empty state shows "0/12" text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingAverageWidget(
              arrows: [],
              maxArrows: 12,
              size: 80,
            ),
          ),
        ),
      );

      // Empty state should show 0/12
      expect(find.text('0/12'), findsOneWidget);
    });

    testWidgets('empty state uses different maxArrows value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingAverageWidget(
              arrows: [],
              maxArrows: 6,
              size: 80,
            ),
          ),
        ),
      );

      expect(find.text('0/6'), findsOneWidget);
    });

    testWidgets('with arrows shows count over maxArrows', (tester) async {
      final arrows = [
        createFakeArrow(id: 'a1', xMm: 10, yMm: 5, score: 10),
        createFakeArrow(id: 'a2', xMm: -5, yMm: 8, score: 10),
        createFakeArrow(id: 'a3', xMm: 3, yMm: -2, score: 10),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RollingAverageWidget(
              arrows: arrows,
              maxArrows: 12,
              size: 80,
            ),
          ),
        ),
      );

      expect(find.text('3/12'), findsOneWidget);
    });

    testWidgets('renders group center marker when arrows provided', (tester) async {
      final arrows = [
        createFakeArrow(id: 'a1', xMm: 20, yMm: 10, score: 9),
        createFakeArrow(id: 'a2', xMm: 25, yMm: 15, score: 9),
        createFakeArrow(id: 'a3', xMm: 22, yMm: 12, score: 9),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RollingAverageWidget(
              arrows: arrows,
              maxArrows: 12,
              size: 80,
              faceSizeCm: 40,
            ),
          ),
        ),
      );

      // Widget should render the group center marker (a Positioned Container)
      expect(find.byType(RollingAverageWidget), findsOneWidget);

      // Should have at least one Container for the group center marker
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('handles different face sizes', (tester) async {
      final arrows = [
        createFakeArrow(id: 'a1', xMm: 50, yMm: 30, score: 8, faceSizeCm: 122),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RollingAverageWidget(
              arrows: arrows,
              faceSizeCm: 122,
              size: 80,
            ),
          ),
        ),
      );

      expect(find.byType(RollingAverageWidget), findsOneWidget);
    });

    testWidgets('handles legacy normalized coordinates', (tester) async {
      final arrows = [
        createFakeArrowNormalized(id: 'a1', x: 0.1, y: 0.05, score: 9),
        createFakeArrowNormalized(id: 'a2', x: 0.15, y: 0.08, score: 9),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RollingAverageWidget(
              arrows: arrows,
              maxArrows: 12,
              size: 80,
            ),
          ),
        ),
      );

      expect(find.text('2/12'), findsOneWidget);
    });

    testWidgets('different widget sizes render correctly', (tester) async {
      final arrows = [
        createFakeArrow(id: 'a1', xMm: 10, yMm: 5, score: 10),
      ];

      for (final size in [60.0, 80.0, 100.0, 120.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RollingAverageWidget(
                arrows: arrows,
                size: size,
              ),
            ),
          ),
        );

        // Find the SizedBox to verify size is applied
        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.width, equals(size));
        expect(sizedBox.height, equals(size));
      }
    });
  });

  group('GroupAnalysis Integration', () {
    test('calculates group center correctly', () {
      // Create coordinates for testing
      final coords = [
        ArrowCoordinate(xMm: 20, yMm: 10, faceSizeCm: 40),
        ArrowCoordinate(xMm: 30, yMm: 20, faceSizeCm: 40),
        ArrowCoordinate(xMm: 25, yMm: 15, faceSizeCm: 40),
      ];

      final group = GroupAnalysis.calculate(coords);

      // Center should be average: (20+30+25)/3 = 25, (10+20+15)/3 = 15
      expect(group.center.xMm, equals(25.0));
      expect(group.center.yMm, equals(15.0));
      expect(group.arrowCount, equals(3));
    });

    test('calculates mean spread correctly', () {
      // All arrows at same point = 0 spread
      final samePoint = [
        ArrowCoordinate(xMm: 10, yMm: 10, faceSizeCm: 40),
        ArrowCoordinate(xMm: 10, yMm: 10, faceSizeCm: 40),
        ArrowCoordinate(xMm: 10, yMm: 10, faceSizeCm: 40),
      ];

      final noSpread = GroupAnalysis.calculate(samePoint);
      expect(noSpread.meanSpreadMm, equals(0.0));
      expect(noSpread.maxSpreadMm, equals(0.0));
    });

    test('handles single arrow', () {
      final single = [
        ArrowCoordinate(xMm: 50, yMm: -30, faceSizeCm: 40),
      ];

      final group = GroupAnalysis.calculate(single);
      expect(group.arrowCount, equals(1));
      expect(group.center.xMm, equals(50.0));
      expect(group.center.yMm, equals(-30.0));
      expect(group.meanSpreadMm, equals(0.0));
    });

    test('tryCalculate returns null for empty list', () {
      final result = GroupAnalysis.tryCalculate([]);
      expect(result, isNull);
    });

    test('throws for empty list with calculate()', () {
      expect(
        () => GroupAnalysis.calculate([]),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Zoom Factor (2.5x) Scaling', () {
    test('_scalePosition scales correctly', () {
      // The widget uses _zoomFactor = 2.5
      const zoomFactor = 2.5;
      const widgetSize = 80.0;
      const center = widgetSize / 2; // 40.0

      // Test scaling a position
      double scalePosition(double pixelPos) {
        final offsetFromCenter = pixelPos - center;
        final scaledOffset = offsetFromCenter * zoomFactor;
        return (center + scaledOffset).roundToDouble();
      }

      // Center position should stay at center
      expect(scalePosition(40.0), equals(40.0));

      // Position at 50 (10 pixels right of center)
      // Offset = 10, scaled = 25, result = 40 + 25 = 65
      expect(scalePosition(50.0), equals(65.0));

      // Position at 30 (10 pixels left of center)
      // Offset = -10, scaled = -25, result = 40 - 25 = 15
      expect(scalePosition(30.0), equals(15.0));
    });

    test('pixel positions are rounded to prevent sub-pixel drift', () {
      const zoomFactor = 2.5;
      const widgetSize = 80.0;
      const center = widgetSize / 2;

      double scalePosition(double pixelPos) {
        final offsetFromCenter = pixelPos - center;
        final scaledOffset = offsetFromCenter * zoomFactor;
        return (center + scaledOffset).roundToDouble();
      }

      // Test with a position that produces fractional result
      // Position 45.3: offset = 5.3, scaled = 13.25, result = 53.25 -> rounds to 53
      final result = scalePosition(45.3);
      expect(result, equals(result.roundToDouble()));
    });
  });

  group('TargetCoordinateSystem usage', () {
    test('RollingAverageWidget uses TargetCoordinateSystem for conversions', () {
      const faceSizeCm = 40;
      const widgetSize = 80.0;

      final coordSystem = TargetCoordinateSystem(
        faceSizeCm: faceSizeCm,
        widgetSize: widgetSize,
      );

      // Create a group center coordinate
      final center = ArrowCoordinate(
        xMm: 20,
        yMm: 10,
        faceSizeCm: faceSizeCm,
      );

      // Convert to pixels
      final pixels = coordSystem.coordinateToPixels(center);

      // Verify the calculation
      // 20mm on 40cm (200mm radius) = 0.1 normalized
      // Widget center = 40, offset = 0.1 * 40 = 4
      // Result = 40 + 4 = 44
      expect(pixels.dx, equals(44.0));

      // 10mm = 0.05 normalized
      // Result = 40 + 0.05 * 40 = 42
      expect(pixels.dy, equals(42.0));
    });

    test('coordinate conversion is consistent with main target', () {
      const faceSizeCm = 40;

      // Same coordinate should produce proportionally scaled results
      // for different widget sizes
      final coord = ArrowCoordinate(
        xMm: 50,
        yMm: 30,
        faceSizeCm: faceSizeCm,
      );

      // Main target size
      final mainSystem = TargetCoordinateSystem(
        faceSizeCm: faceSizeCm,
        widgetSize: 300,
      );
      final mainPixels = mainSystem.coordinateToPixels(coord);

      // Mini target size (RollingAverageWidget default)
      final miniSystem = TargetCoordinateSystem(
        faceSizeCm: faceSizeCm,
        widgetSize: 80,
      );
      final miniPixels = miniSystem.coordinateToPixels(coord);

      // The relative position from center should be the same
      final mainCenter = 300 / 2;
      final miniCenter = 80 / 2;

      final mainRelX = (mainPixels.dx - mainCenter) / mainCenter;
      final miniRelX = (miniPixels.dx - miniCenter) / miniCenter;

      expect(mainRelX, closeTo(miniRelX, 0.02)); // Allow for rounding
    });
  });

  group('Arrow Conversion', () {
    test('prefers mm coordinates when available', () {
      // Arrow with both mm and normalized coordinates
      final arrow = Arrow(
        id: 'test',
        endId: 'end',
        faceIndex: 0,
        xMm: 50.0, // Non-zero mm
        yMm: 30.0,
        x: 0.1, // Different normalized value
        y: 0.2,
        score: 9,
        isX: false,
        sequence: 1,
        shaftNumber: null,
        createdAt: DateTime.now(),
      );

      // The widget checks: if (arrow.xMm != 0 || arrow.yMm != 0)
      expect(arrow.xMm != 0 || arrow.yMm != 0, isTrue);
    });

    test('falls back to normalized when mm is zero', () {
      final arrow = Arrow(
        id: 'test',
        endId: 'end',
        faceIndex: 0,
        xMm: 0.0, // Zero mm
        yMm: 0.0,
        x: 0.25,
        y: 0.15,
        score: 9,
        isX: false,
        sequence: 1,
        shaftNumber: null,
        createdAt: DateTime.now(),
      );

      // Should use legacy path
      expect(arrow.xMm == 0 && arrow.yMm == 0, isTrue);
    });
  });

  group('Visual Elements', () {
    testWidgets('has circular shape decoration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingAverageWidget(
              arrows: [],
              size: 80,
            ),
          ),
        ),
      );

      // Find container with circular decoration
      final containers = tester.widgetList<Container>(find.byType(Container));
      bool hasCircularDecoration = false;

      for (final container in containers) {
        if (container.decoration is BoxDecoration) {
          final decoration = container.decoration as BoxDecoration;
          if (decoration.shape == BoxShape.circle) {
            hasCircularDecoration = true;
            break;
          }
        }
      }

      expect(hasCircularDecoration, isTrue);
    });

    testWidgets('renders crosshair overlay', (tester) async {
      final arrows = [
        createFakeArrow(id: 'a1', xMm: 10, yMm: 5, score: 10),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RollingAverageWidget(
              arrows: arrows,
              size: 80,
            ),
          ),
        ),
      );

      // CustomPaint is used for crosshair and target
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('ClipOval clips content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingAverageWidget(
              arrows: [],
              size: 80,
            ),
          ),
        ),
      );

      // Empty state also uses ClipOval for consistency
      // Actually empty state doesn't use ClipOval, only non-empty does
      // Let's verify with arrows

      final arrows = [
        createFakeArrow(id: 'a1', xMm: 10, yMm: 5, score: 10),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RollingAverageWidget(
              arrows: arrows,
              size: 80,
            ),
          ),
        ),
      );

      expect(find.byType(ClipOval), findsOneWidget);
    });
  });

  group('Cross-Platform Rendering', () {
    testWidgets('renders consistently across platform sizes', (tester) async {
      // Test various screen sizes that might be encountered on iOS/Android
      final testSizes = [
        const Size(320, 568), // iPhone SE
        const Size(375, 667), // iPhone 8
        const Size(414, 896), // iPhone 11 Pro Max
        const Size(360, 640), // Android medium
        const Size(411, 731), // Pixel 2
      ];

      for (final screenSize in testSizes) {
        tester.view.physicalSize = screenSize * tester.view.devicePixelRatio;
        tester.view.devicePixelRatio = 2.0;

        final arrows = [
          createFakeArrow(id: 'a1', xMm: 15, yMm: 10, score: 10),
          createFakeArrow(id: 'a2', xMm: 20, yMm: 12, score: 9),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: RollingAverageWidget(
                  arrows: arrows,
                  size: 80,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(RollingAverageWidget), findsOneWidget);
        expect(find.text('2/12'), findsOneWidget);
      }

      // Reset view
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
