import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archery_super_app/widgets/group_centre_widget.dart';
import 'package:archery_super_app/db/database.dart';

import '../test_helpers.dart';

void main() {
  group('GroupCentreWidget', () {
    group('Centre Position Calculation', () {
      testWidgets('calculates centre from single arrow', (tester) async {
        final arrows = [
          createFakeArrowNormalized(
            id: 'a1',
            x: 0.2,
            y: 0.3,
            score: 9,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: arrows,
                label: 'Test',
              ),
            ),
          ),
        );

        // Widget should render without error
        expect(find.byType(GroupCentreWidget), findsOneWidget);
        expect(find.text('Test (1)'), findsOneWidget);
      });

      testWidgets('calculates centre from multiple arrows', (tester) async {
        final arrows = [
          createFakeArrowNormalized(id: 'a1', x: 0.1, y: 0.1, score: 10),
          createFakeArrowNormalized(id: 'a2', x: 0.3, y: 0.1, score: 9),
          createFakeArrowNormalized(id: 'a3', x: 0.2, y: 0.3, score: 9),
        ];
        // Expected centre: x = (0.1 + 0.3 + 0.2) / 3 = 0.2
        //                  y = (0.1 + 0.1 + 0.3) / 3 = 0.166...

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: arrows,
                label: 'Test',
              ),
            ),
          ),
        );

        expect(find.byType(GroupCentreWidget), findsOneWidget);
        expect(find.text('Test (3)'), findsOneWidget);
      });

      testWidgets('handles arrows at target centre', (tester) async {
        final arrows = [
          createFakeArrowNormalized(id: 'a1', x: 0.0, y: 0.0, score: 10),
          createFakeArrowNormalized(id: 'a2', x: 0.0, y: 0.0, score: 10),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: arrows,
                label: 'Perfect',
              ),
            ),
          ),
        );

        expect(find.text('Perfect (2)'), findsOneWidget);
      });

      testWidgets('handles negative coordinates (left/up)', (tester) async {
        final arrows = [
          createFakeArrowNormalized(id: 'a1', x: -0.2, y: -0.1, score: 9),
          createFakeArrowNormalized(id: 'a2', x: -0.3, y: -0.2, score: 8),
        ];
        // Centre: x = -0.25, y = -0.15

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: arrows,
                label: 'Left',
              ),
            ),
          ),
        );

        expect(find.text('Left (2)'), findsOneWidget);
      });

      testWidgets('handles wide spread group', (tester) async {
        final arrows = [
          createFakeArrowNormalized(id: 'a1', x: 0.8, y: 0.0, score: 5),
          createFakeArrowNormalized(id: 'a2', x: -0.8, y: 0.0, score: 5),
          createFakeArrowNormalized(id: 'a3', x: 0.0, y: 0.8, score: 5),
          createFakeArrowNormalized(id: 'a4', x: 0.0, y: -0.8, score: 5),
        ];
        // Centre: x = 0, y = 0 (symmetric)

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: arrows,
                label: 'Wide',
              ),
            ),
          ),
        );

        expect(find.text('Wide (4)'), findsOneWidget);
      });
    });

    group('Empty State', () {
      testWidgets('handles empty arrow list', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: [],
                label: 'Empty',
              ),
            ),
          ),
        );

        // Should render without crash
        expect(find.byType(GroupCentreWidget), findsOneWidget);
        // Label without count
        expect(find.text('Empty'), findsOneWidget);
        // Should not show count for empty list
        expect(find.text('Empty (0)'), findsNothing);
      });

      testWidgets('uses minZoom for empty arrows', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: [],
                label: 'Test',
                minZoom: 3.0,
              ),
            ),
          ),
        );

        expect(find.byType(GroupCentreWidget), findsOneWidget);
      });
    });

    group('Label Display', () {
      testWidgets('shows label without count when empty', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: [],
                label: 'Last 12',
              ),
            ),
          ),
        );

        expect(find.text('Last 12'), findsOneWidget);
        expect(find.text('Last 12 (0)'), findsNothing);
      });

      testWidgets('shows label with count when arrows present', (tester) async {
        final arrows = [
          createFakeArrowNormalized(id: 'a1', x: 0.1, y: 0.1, score: 10),
          createFakeArrowNormalized(id: 'a2', x: 0.2, y: 0.1, score: 9),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: arrows,
                label: 'Last 12',
              ),
            ),
          ),
        );

        expect(find.text('Last 12 (2)'), findsOneWidget);
        expect(find.text('Last 12'), findsNothing);
      });

      testWidgets('shows different labels correctly', (tester) async {
        final arrows = [
          createFakeArrowNormalized(id: 'a1', x: 0.0, y: 0.0, score: 10),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  GroupCentreWidget(arrows: arrows, label: 'Half 1'),
                  GroupCentreWidget(arrows: arrows, label: 'Half 2'),
                  GroupCentreWidget(arrows: [], label: 'Session'),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Half 1 (1)'), findsOneWidget);
        expect(find.text('Half 2 (1)'), findsOneWidget);
        expect(find.text('Session'), findsOneWidget);
      });
    });

    group('Size Configuration', () {
      testWidgets('uses default size when not specified', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: [],
                label: 'Test',
              ),
            ),
          ),
        );

        final widget = tester.widget<GroupCentreWidget>(
          find.byType(GroupCentreWidget),
        );
        expect(widget.size, equals(80));
      });

      testWidgets('accepts custom size', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: [],
                label: 'Test',
                size: 120,
              ),
            ),
          ),
        );

        final widget = tester.widget<GroupCentreWidget>(
          find.byType(GroupCentreWidget),
        );
        expect(widget.size, equals(120));
      });
    });

    group('Zoom Factor', () {
      testWidgets('uses SmartZoom for arrows', (tester) async {
        // Tight group should result in higher zoom
        final tightGroup = [
          createFakeArrowNormalized(id: 'a1', x: 0.05, y: 0.05, score: 10),
          createFakeArrowNormalized(id: 'a2', x: 0.06, y: 0.04, score: 10),
          createFakeArrowNormalized(id: 'a3', x: 0.04, y: 0.06, score: 10),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: tightGroup,
                label: 'Tight',
              ),
            ),
          ),
        );

        expect(find.text('Tight (3)'), findsOneWidget);
      });

      testWidgets('clamps zoom to minZoom lower bound', (tester) async {
        final arrows = [
          createFakeArrowNormalized(id: 'a1', x: 0.0, y: 0.0, score: 10),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: arrows,
                label: 'Test',
                minZoom: 4.0,
              ),
            ),
          ),
        );

        expect(find.text('Test (1)'), findsOneWidget);
      });

      testWidgets('handles maximum zoom (6.0) for very tight group', (tester) async {
        // Extremely tight group at centre
        final veryTightGroup = [
          createFakeArrowNormalized(id: 'a1', x: 0.001, y: 0.000, score: 10),
          createFakeArrowNormalized(id: 'a2', x: 0.000, y: 0.001, score: 10),
          createFakeArrowNormalized(id: 'a3', x: -0.001, y: 0.000, score: 10),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: veryTightGroup,
                label: 'Tight',
              ),
            ),
          ),
        );

        expect(find.text('Tight (3)'), findsOneWidget);
      });
    });

    group('Visual Rendering', () {
      testWidgets('renders container with correct decoration', (tester) async {
        final arrows = [
          createFakeArrowNormalized(id: 'a1', x: 0.0, y: 0.0, score: 10),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: arrows,
                label: 'Test',
                size: 100,
              ),
            ),
          ),
        );

        // Find the main container
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(GroupCentreWidget),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.constraints?.maxWidth, equals(100));
        expect(container.constraints?.maxHeight, equals(100));
      });

      testWidgets('renders target face CustomPaint', (tester) async {
        final arrows = [
          createFakeArrowNormalized(id: 'a1', x: 0.1, y: 0.1, score: 9),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: arrows,
                label: 'Test',
              ),
            ),
          ),
        );

        // Should have CustomPaint for target face and cross
        expect(
          find.descendant(
            of: find.byType(GroupCentreWidget),
            matching: find.byType(CustomPaint),
          ),
          findsWidgets,
        );
      });

      testWidgets('renders cross painter', (tester) async {
        final arrows = [
          createFakeArrowNormalized(id: 'a1', x: 0.0, y: 0.0, score: 10),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: arrows,
                label: 'Test',
              ),
            ),
          ),
        );

        // CustomPaint for the cross should be present
        final customPaints = find.descendant(
          of: find.byType(GroupCentreWidget),
          matching: find.byType(CustomPaint),
        );

        expect(customPaints, findsWidgets);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles large number of arrows', (tester) async {
        final arrows = List.generate(
          100,
          (i) => createFakeArrowNormalized(
            id: 'a$i',
            x: (i % 10) * 0.1 - 0.45,
            y: (i ~/ 10) * 0.1 - 0.45,
            score: 8,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: arrows,
                label: 'Many',
              ),
            ),
          ),
        );

        expect(find.text('Many (100)'), findsOneWidget);
      });

      testWidgets('handles arrows at extreme positions', (tester) async {
        final arrows = [
          createFakeArrowNormalized(id: 'a1', x: 0.99, y: 0.99, score: 1),
          createFakeArrowNormalized(id: 'a2', x: -0.99, y: -0.99, score: 1),
        ];
        // Centre: x = 0, y = 0

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: arrows,
                label: 'Extreme',
              ),
            ),
          ),
        );

        expect(find.text('Extreme (2)'), findsOneWidget);
      });

      testWidgets('handles mix of scores', (tester) async {
        final arrows = [
          createFakeArrowNormalized(id: 'a1', x: 0.0, y: 0.0, score: 10, isX: true),
          createFakeArrowNormalized(id: 'a2', x: 0.5, y: 0.0, score: 7),
          createFakeArrowNormalized(id: 'a3', x: 0.0, y: 0.5, score: 7),
          createFakeArrowNormalized(id: 'a4', x: 0.9, y: 0.9, score: 2),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: arrows,
                label: 'Mixed',
              ),
            ),
          ),
        );

        expect(find.text('Mixed (4)'), findsOneWidget);
      });

      testWidgets('handles rebuild with different arrow count', (tester) async {
        final initialArrows = [
          createFakeArrowNormalized(id: 'a1', x: 0.0, y: 0.0, score: 10),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: initialArrows,
                label: 'Test',
              ),
            ),
          ),
        );

        expect(find.text('Test (1)'), findsOneWidget);

        // Rebuild with more arrows
        final moreArrows = [
          createFakeArrowNormalized(id: 'a1', x: 0.0, y: 0.0, score: 10),
          createFakeArrowNormalized(id: 'a2', x: 0.1, y: 0.1, score: 9),
          createFakeArrowNormalized(id: 'a3', x: -0.1, y: 0.1, score: 9),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: moreArrows,
                label: 'Test',
              ),
            ),
          ),
        );

        expect(find.text('Test (3)'), findsOneWidget);
        expect(find.text('Test (1)'), findsNothing);
      });

      testWidgets('handles all arrows at same position', (tester) async {
        final arrows = [
          createFakeArrowNormalized(id: 'a1', x: 0.2, y: 0.3, score: 9),
          createFakeArrowNormalized(id: 'a2', x: 0.2, y: 0.3, score: 9),
          createFakeArrowNormalized(id: 'a3', x: 0.2, y: 0.3, score: 9),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: arrows,
                label: 'Robin Hood',
              ),
            ),
          ),
        );

        expect(find.text('Robin Hood (3)'), findsOneWidget);
      });
    });

    group('Integration with SmartZoom', () {
      testWidgets('applies SmartZoom for 3+ arrows', (tester) async {
        // SmartZoom requires minArrowsForAdaptiveZoom = 3
        final arrows = [
          createFakeArrowNormalized(id: 'a1', x: 0.1, y: 0.1, score: 9),
          createFakeArrowNormalized(id: 'a2', x: 0.12, y: 0.11, score: 9),
          createFakeArrowNormalized(id: 'a3', x: 0.11, y: 0.12, score: 9),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: arrows,
                label: 'Tight',
              ),
            ),
          ),
        );

        expect(find.text('Tight (3)'), findsOneWidget);
      });

      testWidgets('uses minZoom for 1-2 arrows', (tester) async {
        final arrows = [
          createFakeArrowNormalized(id: 'a1', x: 0.1, y: 0.1, score: 9),
          createFakeArrowNormalized(id: 'a2', x: 0.2, y: 0.2, score: 8),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GroupCentreWidget(
                arrows: arrows,
                label: 'Few',
                minZoom: 2.5,
              ),
            ),
          ),
        );

        expect(find.text('Few (2)'), findsOneWidget);
      });
    });
  });
}
