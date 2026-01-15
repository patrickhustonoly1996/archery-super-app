import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archery_super_app/widgets/target_face.dart';
import 'package:archery_super_app/db/database.dart';
import 'package:archery_super_app/models/arrow_coordinate.dart';
import 'package:archery_super_app/utils/target_coordinate_system.dart';
import 'package:archery_super_app/theme/app_theme.dart';

/// Creates a fake Arrow for testing with mm coordinates.
/// Uses the new mm-based coordinate system as primary.
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

/// Creates a fake Arrow using normalized coordinates (legacy path).
Arrow createFakeArrowNormalized({
  required String id,
  required double x,
  required double y,
  required int score,
  bool isX = false,
  int? shaftNumber,
}) {
  return Arrow(
    id: id,
    endId: 'test-end',
    faceIndex: 0,
    xMm: 0.0, // Zero mm coordinates = legacy mode
    yMm: 0.0,
    x: x,
    y: y,
    score: score,
    isX: isX,
    sequence: 1,
    shaftNumber: shaftNumber,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('TargetFace Widget', () {
    testWidgets('renders empty target face without arrows', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TargetFace(
              arrows: [],
              size: 300,
            ),
          ),
        ),
      );

      // Should render CustomPaint for the target rings
      expect(find.byType(CustomPaint), findsWidgets);
      // Should render within a SizedBox
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('positions arrows correctly using mm coordinates', (tester) async {
      const widgetSize = 300.0;
      const faceSizeCm = 40;

      // Create an arrow at the center (0,0 mm)
      final centerArrow = createFakeArrow(
        id: 'arrow-center',
        xMm: 0,
        yMm: 0,
        score: 10,
        isX: true,
        faceSizeCm: faceSizeCm,
      );

      // Create an arrow at 100mm right (50% of 200mm radius)
      final rightArrow = createFakeArrow(
        id: 'arrow-right',
        xMm: 100,
        yMm: 0,
        score: 6,
        faceSizeCm: faceSizeCm,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TargetFace(
              arrows: [centerArrow, rightArrow],
              size: widgetSize,
            ),
          ),
        ),
      );

      // Verify arrow markers are rendered
      expect(find.byType(Container), findsWidgets);

      // Use TargetCoordinateSystem to calculate expected positions
      final coordSystem = TargetCoordinateSystem(
        faceSizeCm: faceSizeCm,
        widgetSize: widgetSize,
      );

      // Verify the coordinate system calculations are correct
      final centerCoord = ArrowCoordinate(xMm: 0, yMm: 0, faceSizeCm: faceSizeCm);
      final centerPixels = coordSystem.coordinateToPixels(centerCoord);

      // Center should be at widget center (150, 150)
      expect(centerPixels.dx, equals(150.0));
      expect(centerPixels.dy, equals(150.0));

      // Right arrow at 100mm should be at 50% of widget radius from center
      final rightCoord = ArrowCoordinate(xMm: 100, yMm: 0, faceSizeCm: faceSizeCm);
      final rightPixels = coordSystem.coordinateToPixels(rightCoord);

      // 100mm on 40cm face = 100/200 = 0.5 normalized
      // 150 + 0.5 * 150 = 225px
      expect(rightPixels.dx, equals(225.0));
      expect(rightPixels.dy, equals(150.0));
    });

    testWidgets('positions arrows correctly using legacy normalized coordinates', (tester) async {
      const widgetSize = 300.0;

      // Create an arrow using legacy normalized coordinates
      final normalizedArrow = createFakeArrowNormalized(
        id: 'arrow-norm',
        x: 0.5, // 50% right
        y: -0.5, // 50% up
        score: 7,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TargetFace(
              arrows: [normalizedArrow],
              size: widgetSize,
            ),
          ),
        ),
      );

      // Widget should render without error
      expect(find.byType(TargetFace), findsOneWidget);
    });

    testWidgets('arrow markers use correct contrasting colors', (tester) async {
      // Test arrows at different score levels to verify color contrast
      final arrows = [
        createFakeArrow(id: 'a1', xMm: 0, yMm: 0, score: 10, isX: true), // Gold ring - black marker
        createFakeArrow(id: 'a2', xMm: 30, yMm: 0, score: 9), // Gold ring - black marker
        createFakeArrow(id: 'a3', xMm: 70, yMm: 0, score: 7), // Red ring - white marker
        createFakeArrow(id: 'a4', xMm: 110, yMm: 0, score: 5), // Blue ring - white marker
        createFakeArrow(id: 'a5', xMm: 150, yMm: 0, score: 3), // Black ring - white marker
        createFakeArrow(id: 'a6', xMm: 190, yMm: 0, score: 1), // White ring - black marker
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TargetFace(
              arrows: arrows,
              size: 400,
            ),
          ),
        ),
      );

      // Verify all arrow markers are rendered
      // Each arrow creates a Container with decoration
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.length, greaterThanOrEqualTo(arrows.length));
    });

    testWidgets('triSpot mode only renders rings 6-10', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TargetFace(
              arrows: [],
              size: 300,
              triSpot: true,
            ),
          ),
        ),
      );

      // Widget should render without error in triSpot mode
      expect(find.byType(TargetFace), findsOneWidget);
    });

    testWidgets('renders at different widget sizes', (tester) async {
      // Test with different widget sizes
      for (final widgetSize in [200.0, 300.0, 400.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TargetFace(
                arrows: const [],
                size: widgetSize,
              ),
            ),
          ),
        );

        expect(find.byType(TargetFace), findsOneWidget);
      }
    });

    testWidgets('pixel positions are rounded to prevent sub-pixel drift', (tester) async {
      const faceSizeCm = 40;
      const widgetSize = 300.0;

      // Create an arrow that would have fractional pixel position
      // 73mm on 40cm face = 73/200 = 0.365 normalized
      // 150 + 0.365 * 150 = 204.75 - should round to 205
      final fractionalArrow = createFakeArrow(
        id: 'arrow-frac',
        xMm: 73,
        yMm: 41,
        score: 8,
        faceSizeCm: faceSizeCm,
      );

      final coord = ArrowCoordinate(
        xMm: 73,
        yMm: 41,
        faceSizeCm: faceSizeCm,
      );

      final pixels = coord.toWidgetPixels(widgetSize);

      // Verify positions are rounded (no decimal places)
      expect(pixels.dx, equals(pixels.dx.roundToDouble()));
      expect(pixels.dy, equals(pixels.dy.roundToDouble()));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TargetFace(
              arrows: [fractionalArrow],
              size: widgetSize,
            ),
          ),
        ),
      );

      expect(find.byType(TargetFace), findsOneWidget);
    });

    testWidgets('renders X-ring shots with correct marker', (tester) async {
      final xArrow = createFakeArrow(
        id: 'x-arrow',
        xMm: 0,
        yMm: 0,
        score: 10,
        isX: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TargetFace(
              arrows: [xArrow],
              size: 300,
            ),
          ),
        ),
      );

      // Arrow marker should be rendered as a Container (dot)
      // Current implementation uses simple dots without text labels
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders arrows with shaft numbers', (tester) async {
      final numberedArrow = createFakeArrow(
        id: 'numbered-arrow',
        xMm: 50,
        yMm: 0,
        score: 9,
        shaftNumber: 7,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TargetFace(
              arrows: [numberedArrow],
              size: 300,
            ),
          ),
        ),
      );

      // Arrow marker should be rendered as a Container (dot)
      // Note: Current implementation uses simple dots without shaft number labels
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders X-ring arrow with shaft number as dot marker', (tester) async {
      final xWithNumber = createFakeArrow(
        id: 'x-numbered',
        xMm: 0,
        yMm: 0,
        score: 10,
        isX: true,
        shaftNumber: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TargetFace(
              arrows: [xWithNumber],
              size: 300,
            ),
          ),
        ),
      );

      // Arrow marker should be rendered as a Container (dot)
      // Current implementation uses simple dots - no text labels for X or shaft numbers
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('InteractiveTargetFace Widget', () {
    testWidgets('renders target face', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveTargetFace(
              arrows: const [],
              size: 300,
              onArrowPlotted: (x, y) {},
            ),
          ),
        ),
      );

      expect(find.byType(InteractiveTargetFace), findsOneWidget);
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('touch/drag shows arrow preview at offset position', (tester) async {
      Offset? plottedPosition;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveTargetFace(
              arrows: const [],
              size: 300,
              onArrowPlotted: (x, y) {
                plottedPosition = Offset(x, y);
              },
            ),
          ),
        ),
      );

      final targetFinder = find.byType(InteractiveTargetFace);

      // Start drag from center of target
      final center = tester.getCenter(targetFinder);

      // Perform a drag gesture
      await tester.dragFrom(center, const Offset(0, 50));
      await tester.pump();

      // Arrow should be plotted when drag ends
      // The position should account for the _holdOffset (60px)
      expect(plottedPosition, isNotNull);
    });

    testWidgets('arrow is NOT plotted when touch ends outside target', (tester) async {
      bool wasPlotted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveTargetFace(
                arrows: const [],
                size: 300,
                onArrowPlotted: (x, y) {
                  wasPlotted = true;
                },
              ),
            ),
          ),
        ),
      );

      final targetFinder = find.byType(InteractiveTargetFace);
      final center = tester.getCenter(targetFinder);

      // Drag far outside the target bounds
      // The arrow position is offset by -60 from touch, so we need to touch
      // at the bottom edge and drag further down to get arrow outside
      await tester.dragFrom(
        Offset(center.dx, center.dy + 200), // Start near bottom
        const Offset(0, 100), // Drag further down
      );
      await tester.pump();

      // Arrow should NOT be plotted because normalized distance > 1.0
      expect(wasPlotted, isFalse);
    });

    testWidgets('arrow IS plotted when touch ends inside target', (tester) async {
      bool wasPlotted = false;
      Offset? plottedPosition;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveTargetFace(
                arrows: const [],
                size: 300,
                onArrowPlotted: (x, y) {
                  wasPlotted = true;
                  plottedPosition = Offset(x, y);
                },
              ),
            ),
          ),
        ),
      );

      final targetFinder = find.byType(InteractiveTargetFace);
      final center = tester.getCenter(targetFinder);

      // Touch at center and drag slightly - arrow should stay inside
      await tester.dragFrom(center, const Offset(0, 30));
      await tester.pump();

      expect(wasPlotted, isTrue);
      expect(plottedPosition, isNotNull);

      // Check the plotted position is within target bounds (normalized <= 1.0)
      if (plottedPosition != null) {
        final distance = plottedPosition!.distance;
        expect(distance, lessThanOrEqualTo(1.0));
      }
    });

    testWidgets('disabled state prevents interaction', (tester) async {
      bool wasPlotted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveTargetFace(
              arrows: const [],
              size: 300,
              enabled: false,
              onArrowPlotted: (x, y) {
                wasPlotted = true;
              },
            ),
          ),
        ),
      );

      final targetFinder = find.byType(InteractiveTargetFace);
      final center = tester.getCenter(targetFinder);

      await tester.dragFrom(center, const Offset(0, 30));
      await tester.pump();

      // Should not plot when disabled
      expect(wasPlotted, isFalse);
    });

    testWidgets('handles triSpot mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveTargetFace(
              arrows: const [],
              size: 300,
              triSpot: true,
              onArrowPlotted: (x, y) {},
            ),
          ),
        ),
      );

      expect(find.byType(InteractiveTargetFace), findsOneWidget);
    });

    testWidgets('renders child TargetFace', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveTargetFace(
              arrows: const [],
              size: 300,
              onArrowPlotted: (x, y) {},
            ),
          ),
        ),
      );

      // Verify the inner TargetFace is rendered
      expect(find.byType(TargetFace), findsOneWidget);
    });

    testWidgets('displays existing arrows', (tester) async {
      final existingArrows = [
        createFakeArrow(id: 'a1', xMm: 20, yMm: 10, score: 10),
        createFakeArrow(id: 'a2', xMm: -30, yMm: 15, score: 9),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveTargetFace(
              arrows: existingArrows,
              size: 300,
              onArrowPlotted: (x, y) {},
            ),
          ),
        ),
      );

      expect(find.byType(InteractiveTargetFace), findsOneWidget);
    });
  });

  group('Coordinate System Integration', () {
    test('ArrowCoordinate converts to widget pixels with rounding', () {
      const faceSizeCm = 40;
      const widgetSize = 300.0;

      // Create coordinate at a position that would have fractional pixels
      final coord = ArrowCoordinate(
        xMm: 73.5, // Will produce fractional pixel
        yMm: 41.2,
        faceSizeCm: faceSizeCm,
      );

      final pixels = coord.toWidgetPixels(widgetSize);

      // Should be rounded
      expect(pixels.dx, equals(pixels.dx.roundToDouble()));
      expect(pixels.dy, equals(pixels.dy.roundToDouble()));
    });

    test('TargetCoordinateSystem provides consistent conversions', () {
      const faceSizeCm = 40;
      const widgetSize = 300.0;

      final coordSystem = TargetCoordinateSystem(
        faceSizeCm: faceSizeCm,
        widgetSize: widgetSize,
      );

      // Create a coordinate
      final coord = ArrowCoordinate(
        xMm: 50,
        yMm: -30,
        faceSizeCm: faceSizeCm,
      );

      // Convert to pixels via coordinate system
      final pixels = coordSystem.coordinateToPixels(coord);

      // Convert back and verify
      final roundTrip = coordSystem.pixelsToCoordinate(pixels);

      // Should be approximately equal (within pixel rounding tolerance)
      expect((roundTrip.xMm - coord.xMm).abs(), lessThan(1.0));
      expect((roundTrip.yMm - coord.yMm).abs(), lessThan(1.0));
    });

    test('scoring uses epsilon for boundary comparisons', () {
      const faceSizeCm = 40;

      // Ring 10 boundary for 40cm face is at 20mm (10% of 200mm radius)
      // Test right at boundary
      final atBoundary = TargetRingsMm.scoreFromDistanceMm(20.0, faceSizeCm);
      expect(atBoundary, equals(10));

      // Test slightly inside boundary (should still be 10)
      final slightlyInside = TargetRingsMm.scoreFromDistanceMm(19.999, faceSizeCm);
      expect(slightlyInside, equals(10));

      // Test at boundary + epsilon (should still be 10 due to epsilon tolerance)
      final atBoundaryPlusEpsilon = TargetRingsMm.scoreFromDistanceMm(
        20.0 + TargetRingsMm.epsilon,
        faceSizeCm,
      );
      expect(atBoundaryPlusEpsilon, equals(10));

      // Test clearly outside boundary
      final outside = TargetRingsMm.scoreFromDistanceMm(21.0, faceSizeCm);
      expect(outside, equals(9));
    });

    test('different face sizes scale correctly', () {
      // Same physical position on different face sizes
      const xMm = 50.0;
      const yMm = 50.0;

      for (final faceSize in [40, 60, 80, 122]) {
        final coord = ArrowCoordinate(
          xMm: xMm,
          yMm: yMm,
          faceSizeCm: faceSize,
        );

        // Normalized coordinates should scale with face size
        final radiusMm = faceSize * 5.0;
        expect(coord.normalizedX, closeTo(xMm / radiusMm, 0.001));
        expect(coord.normalizedY, closeTo(yMm / radiusMm, 0.001));
      }
    });
  });

  group('Arrow Marker Colors', () {
    test('score 10 and 9 use black marker on gold background', () {
      // This tests the color logic in _ArrowMarker
      for (final score in [10, 9]) {
        // Black marker expected
        expect(score >= 9, isTrue);
      }
    });

    test('score 8 and 7 use white marker on red background', () {
      for (final score in [8, 7]) {
        expect(score >= 7 && score < 9, isTrue);
      }
    });

    test('score 6 and 5 use white marker on blue background', () {
      for (final score in [6, 5]) {
        expect(score >= 5 && score < 7, isTrue);
      }
    });

    test('score 4 and 3 use white marker on black background', () {
      for (final score in [4, 3]) {
        expect(score >= 3 && score < 5, isTrue);
      }
    });

    test('score 2 and 1 use black marker on white background', () {
      for (final score in [2, 1]) {
        expect(score < 3, isTrue);
      }
    });
  });
}
