/// Tests for ScorecardWidget
///
/// Tests the scorecard display showing ends with E/T and R/T calculations.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/widgets/scorecard_widget.dart';
import 'package:archery_super_app/db/database.dart';
import '../test_helpers.dart';

void main() {
  group('ScorecardWidget', () {
    Widget createScorecardWidget({
      List<End> completedEnds = const [],
      List<List<Arrow>> completedEndArrows = const [],
      List<Arrow> currentEndArrows = const [],
      int currentEndNumber = 1,
      int arrowsPerEnd = 6,
      int totalEnds = 12,
      String roundName = 'WA 720',
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ScorecardWidget(
            completedEnds: completedEnds,
            completedEndArrows: completedEndArrows,
            currentEndArrows: currentEndArrows,
            currentEndNumber: currentEndNumber,
            arrowsPerEnd: arrowsPerEnd,
            totalEnds: totalEnds,
            roundName: roundName,
          ),
        ),
      );
    }

    group('Header Row', () {
      testWidgets('displays End column header', (tester) async {
        await tester.pumpWidget(createScorecardWidget());
        expect(find.text('End'), findsOneWidget);
      });

      testWidgets('displays E/T column header', (tester) async {
        await tester.pumpWidget(createScorecardWidget());
        expect(find.text('E/T'), findsOneWidget);
      });

      testWidgets('displays R/T column header', (tester) async {
        await tester.pumpWidget(createScorecardWidget());
        expect(find.text('R/T'), findsOneWidget);
      });

      testWidgets('displays 10+X column header', (tester) async {
        await tester.pumpWidget(createScorecardWidget());
        expect(find.text('10+X'), findsOneWidget);
      });

      testWidgets('displays X column header', (tester) async {
        await tester.pumpWidget(createScorecardWidget());
        expect(find.text('X'), findsWidgets);
      });

      testWidgets('displays arrow number headers for 6-arrow ends', (tester) async {
        await tester.pumpWidget(createScorecardWidget(arrowsPerEnd: 6));
        for (int i = 1; i <= 6; i++) {
          expect(find.text('$i'), findsWidgets);
        }
      });

      testWidgets('displays arrow number headers for 3-arrow ends', (tester) async {
        await tester.pumpWidget(createScorecardWidget(arrowsPerEnd: 3));
        expect(find.text('1'), findsWidgets);
        expect(find.text('2'), findsWidgets);
        expect(find.text('3'), findsWidgets);
      });
    });

    group('Current End Display', () {
      testWidgets('displays current end number', (tester) async {
        await tester.pumpWidget(createScorecardWidget(currentEndNumber: 3));
        expect(find.text('3'), findsWidgets);
      });

      testWidgets('displays arrow scores in current end', (tester) async {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 0, yMm: 0, score: 10, endId: 'e1', sequence: 1),
          createFakeArrow(id: 'a2', xMm: 10, yMm: 10, score: 9, endId: 'e1', sequence: 2),
          createFakeArrow(id: 'a3', xMm: 20, yMm: 20, score: 8, endId: 'e1', sequence: 3),
        ];

        await tester.pumpWidget(createScorecardWidget(
          currentEndArrows: arrows,
          arrowsPerEnd: 3,
        ));

        expect(find.text('10'), findsWidgets);
        expect(find.text('9'), findsWidgets);
        expect(find.text('8'), findsWidgets);
      });

      testWidgets('displays X for X-ring hits', (tester) async {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 0, yMm: 0, score: 10, isX: true, endId: 'e1', sequence: 1),
        ];

        await tester.pumpWidget(createScorecardWidget(
          currentEndArrows: arrows,
          arrowsPerEnd: 3,
        ));

        expect(find.text('X'), findsWidgets);
      });

      testWidgets('displays end total', (tester) async {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 0, yMm: 0, score: 10, endId: 'e1', sequence: 1),
          createFakeArrow(id: 'a2', xMm: 10, yMm: 10, score: 9, endId: 'e1', sequence: 2),
          createFakeArrow(id: 'a3', xMm: 20, yMm: 20, score: 8, endId: 'e1', sequence: 3),
        ];

        await tester.pumpWidget(createScorecardWidget(
          currentEndArrows: arrows,
          arrowsPerEnd: 3,
        ));

        // End total: 10 + 9 + 8 = 27
        expect(find.text('27'), findsWidgets);
      });

      testWidgets('displays running total', (tester) async {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 0, yMm: 0, score: 10, endId: 'e1', sequence: 1),
          createFakeArrow(id: 'a2', xMm: 5, yMm: 5, score: 10, endId: 'e1', sequence: 2),
          createFakeArrow(id: 'a3', xMm: 8, yMm: 8, score: 10, endId: 'e1', sequence: 3),
        ];

        await tester.pumpWidget(createScorecardWidget(
          currentEndArrows: arrows,
          arrowsPerEnd: 3,
        ));

        // Running total same as end total for first end
        expect(find.text('30'), findsWidgets);
      });
    });

    group('With Completed Ends', () {
      testWidgets('includes completed ends in running total', (tester) async {
        final completedEnds = [
          createFakeEnd(id: 'e1', sessionId: 's1', endNumber: 1, endScore: 54, endXs: 2, status: 'committed'),
        ];
        final completedEndArrows = [
          [
            createFakeArrow(id: 'a1', xMm: 0, yMm: 0, score: 10, isX: true, endId: 'e1', sequence: 1),
            createFakeArrow(id: 'a2', xMm: 2, yMm: 2, score: 10, isX: true, endId: 'e1', sequence: 2),
            createFakeArrow(id: 'a3', xMm: 15, yMm: 15, score: 9, endId: 'e1', sequence: 3),
            createFakeArrow(id: 'a4', xMm: 18, yMm: 18, score: 9, endId: 'e1', sequence: 4),
            createFakeArrow(id: 'a5', xMm: 25, yMm: 25, score: 8, endId: 'e1', sequence: 5),
            createFakeArrow(id: 'a6', xMm: 28, yMm: 28, score: 8, endId: 'e1', sequence: 6),
          ],
        ];
        final currentArrows = [
          createFakeArrow(id: 'a7', xMm: 0, yMm: 0, score: 10, endId: 'e2', sequence: 1),
        ];

        await tester.pumpWidget(createScorecardWidget(
          completedEnds: completedEnds,
          completedEndArrows: completedEndArrows,
          currentEndArrows: currentArrows,
          currentEndNumber: 2,
          arrowsPerEnd: 6,
        ));

        // Running total: 54 (completed) + 10 (current) = 64
        expect(find.text('64'), findsOneWidget);
      });

      testWidgets('accumulates Xs from completed ends', (tester) async {
        final completedEnds = [
          createFakeEnd(id: 'e1', sessionId: 's1', endNumber: 1, endScore: 60, endXs: 3, status: 'committed'),
        ];
        final completedEndArrows = [
          [
            createFakeArrow(id: 'a1', xMm: 0, yMm: 0, score: 10, isX: true, endId: 'e1', sequence: 1),
            createFakeArrow(id: 'a2', xMm: 1, yMm: 1, score: 10, isX: true, endId: 'e1', sequence: 2),
            createFakeArrow(id: 'a3', xMm: 2, yMm: 2, score: 10, isX: true, endId: 'e1', sequence: 3),
            createFakeArrow(id: 'a4', xMm: 5, yMm: 5, score: 10, endId: 'e1', sequence: 4),
            createFakeArrow(id: 'a5', xMm: 6, yMm: 6, score: 10, endId: 'e1', sequence: 5),
            createFakeArrow(id: 'a6', xMm: 7, yMm: 7, score: 10, endId: 'e1', sequence: 6),
          ],
        ];
        final currentArrows = [
          createFakeArrow(id: 'a7', xMm: 0, yMm: 0, score: 10, isX: true, endId: 'e2', sequence: 1),
        ];

        await tester.pumpWidget(createScorecardWidget(
          completedEnds: completedEnds,
          completedEndArrows: completedEndArrows,
          currentEndArrows: currentArrows,
          currentEndNumber: 2,
          arrowsPerEnd: 6,
        ));

        // Total Xs: 3 (completed) + 1 (current) = 4
        expect(find.text('4'), findsWidgets);
      });
    });

    group('Empty States', () {
      testWidgets('renders without arrows', (tester) async {
        await tester.pumpWidget(createScorecardWidget());
        expect(find.byType(ScorecardWidget), findsOneWidget);
      });

      testWidgets('shows end row when within total ends', (tester) async {
        await tester.pumpWidget(createScorecardWidget(
          currentEndNumber: 1,
          totalEnds: 12,
        ));

        // Should display end number 1
        expect(find.text('1'), findsWidgets);
      });

      testWidgets('hides end row when past total ends', (tester) async {
        await tester.pumpWidget(createScorecardWidget(
          currentEndNumber: 13, // Past totalEnds of 12
          totalEnds: 12,
        ));

        // End 13 should not be displayed
        expect(find.text('13'), findsNothing);
      });
    });

    group('Score Calculations', () {
      testWidgets('calculates end total correctly', (tester) async {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 0, yMm: 0, score: 10, endId: 'e1', sequence: 1),
          createFakeArrow(id: 'a2', xMm: 10, yMm: 10, score: 9, endId: 'e1', sequence: 2),
          createFakeArrow(id: 'a3', xMm: 15, yMm: 15, score: 9, endId: 'e1', sequence: 3),
          createFakeArrow(id: 'a4', xMm: 25, yMm: 25, score: 8, endId: 'e1', sequence: 4),
          createFakeArrow(id: 'a5', xMm: 30, yMm: 30, score: 8, endId: 'e1', sequence: 5),
          createFakeArrow(id: 'a6', xMm: 40, yMm: 40, score: 7, endId: 'e1', sequence: 6),
        ];

        await tester.pumpWidget(createScorecardWidget(
          currentEndArrows: arrows,
          arrowsPerEnd: 6,
        ));

        // Total: 10 + 9 + 9 + 8 + 8 + 7 = 51
        expect(find.text('51'), findsWidgets);
      });

      testWidgets('counts 10s correctly', (tester) async {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 0, yMm: 0, score: 10, isX: true, endId: 'e1', sequence: 1),
          createFakeArrow(id: 'a2', xMm: 5, yMm: 5, score: 10, endId: 'e1', sequence: 2),
          createFakeArrow(id: 'a3', xMm: 8, yMm: 8, score: 10, endId: 'e1', sequence: 3),
          createFakeArrow(id: 'a4', xMm: 15, yMm: 15, score: 9, endId: 'e1', sequence: 4),
          createFakeArrow(id: 'a5', xMm: 18, yMm: 18, score: 9, endId: 'e1', sequence: 5),
          createFakeArrow(id: 'a6', xMm: 25, yMm: 25, score: 8, endId: 'e1', sequence: 6),
        ];

        await tester.pumpWidget(createScorecardWidget(
          currentEndArrows: arrows,
          arrowsPerEnd: 6,
        ));

        // 10+X count: 3
        expect(find.text('3'), findsWidgets);
      });
    });

    group('Different Round Formats', () {
      testWidgets('handles 3-arrow indoor format', (tester) async {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 0, yMm: 0, score: 10, endId: 'e1', sequence: 1),
          createFakeArrow(id: 'a2', xMm: 5, yMm: 5, score: 10, endId: 'e1', sequence: 2),
          createFakeArrow(id: 'a3', xMm: 8, yMm: 8, score: 10, endId: 'e1', sequence: 3),
        ];

        await tester.pumpWidget(createScorecardWidget(
          currentEndArrows: arrows,
          arrowsPerEnd: 3,
          totalEnds: 20,
          roundName: 'Portsmouth',
        ));

        // End total: 30
        expect(find.text('30'), findsWidgets);
      });

      testWidgets('handles 6-arrow outdoor format', (tester) async {
        final arrows = [
          createFakeArrow(id: 'a1', xMm: 0, yMm: 0, score: 10, endId: 'e1', sequence: 1),
          createFakeArrow(id: 'a2', xMm: 2, yMm: 2, score: 10, endId: 'e1', sequence: 2),
          createFakeArrow(id: 'a3', xMm: 4, yMm: 4, score: 10, endId: 'e1', sequence: 3),
          createFakeArrow(id: 'a4', xMm: 6, yMm: 6, score: 10, endId: 'e1', sequence: 4),
          createFakeArrow(id: 'a5', xMm: 8, yMm: 8, score: 10, endId: 'e1', sequence: 5),
          createFakeArrow(id: 'a6', xMm: 10, yMm: 10, score: 10, endId: 'e1', sequence: 6),
        ];

        await tester.pumpWidget(createScorecardWidget(
          currentEndArrows: arrows,
          arrowsPerEnd: 6,
          totalEnds: 12,
          roundName: 'WA 720',
        ));

        // End total: 60
        expect(find.text('60'), findsWidgets);
      });
    });
  });
}
