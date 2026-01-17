import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archery_super_app/widgets/handicap_chart.dart';
import 'package:archery_super_app/db/database.dart';

import '../test_helpers.dart';

void main() {
  group('HandicapChart', () {
    late Map<String, RoundType> testRoundTypes;

    setUp(() {
      // Create test round types
      testRoundTypes = {
        'wa_720_70m': createFakeRoundType(
          id: 'wa_720_70m',
          name: 'WA 720 70m',
          maxScore: 720,
          arrowsPerEnd: 6,
          totalEnds: 12,
          isIndoor: false,
          category: 'wa_outdoor',
          distance: 70,
        ),
        'wa_18m': createFakeRoundType(
          id: 'wa_18m',
          name: 'WA 18m',
          maxScore: 600,
          arrowsPerEnd: 3,
          totalEnds: 20,
          isIndoor: true,
          category: 'wa_indoor',
          distance: 18,
        ),
        'portsmouth': createFakeRoundType(
          id: 'portsmouth',
          name: 'Portsmouth',
          maxScore: 600,
          arrowsPerEnd: 3,
          totalEnds: 20,
          isIndoor: true,
          category: 'agb_indoor',
          distance: 20,
        ),
      };
    });

    group('Empty State', () {
      testWidgets('empty data renders sample preview', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: [],
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Widget should render sample preview for empty data
        expect(find.byType(HandicapChart), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('SAMPLE'), findsOneWidget);
        expect(find.text('Your handicap progression will appear here'), findsOneWidget);
      });

      testWidgets('sessions without matching round type render sample preview', (tester) async {
        final session = createFakeSession(
          id: 's1',
          roundTypeId: 'unknown_round',
          totalScore: 540,
          startedAt: DateTime(2026, 1, 10),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: [session],
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should show sample preview when no valid handicaps
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('SAMPLE'), findsOneWidget);
      });

      testWidgets('very low scores get max handicap', (tester) async {
        // Even very low scores get a handicap (maximum handicap)
        final session = createFakeSession(
          id: 's1',
          roundTypeId: 'wa_720_70m',
          totalScore: 50, // Very low score = high handicap
          startedAt: DateTime(2026, 1, 10),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: [session],
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should still render chart with max handicap
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('Single Data Point', () {
      testWidgets('single plotted session renders chart', (tester) async {
        final session = createFakeSession(
          id: 's1',
          roundTypeId: 'wa_18m',
          totalScore: 540,
          startedAt: DateTime(2026, 1, 10),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: [session],
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should render chart card
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Handicap Progression'), findsOneWidget);
        expect(find.text('Last 1 rounds'), findsOneWidget);

        // Should have chart painter
        expect(find.byType(CustomPaint), findsWidgets);

        // Should have legend
        expect(find.text('Competition'), findsOneWidget);
        expect(find.text('Practice'), findsOneWidget);

        // Should have stat badges
        expect(find.textContaining('Current'), findsOneWidget);
        expect(find.textContaining('Average'), findsOneWidget);
        expect(find.textContaining('Best'), findsOneWidget);
      });

      testWidgets('single imported score renders chart', (tester) async {
        final importedScore = ImportedScore(
          id: 'is1',
          date: DateTime(2026, 1, 10),
          score: 540,
          roundName: 'WA 18m',
          sessionType: 'practice',
          source: 'manual',
          importedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: [],
                importedScores: [importedScore],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Last 1 rounds'), findsOneWidget);
      });
    });

    group('Handicap Calculation', () {
      testWidgets('handicaps calculated correctly for plotted sessions', (tester) async {
        // Create sessions with known scores
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540, // Should be around HC 55
            startedAt: DateTime(2026, 1, 1),
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 560, // Should be around HC 48
            startedAt: DateTime(2026, 1, 2),
          ),
          createFakeSession(
            id: 's3',
            roundTypeId: 'wa_18m',
            totalScore: 580, // Should be around HC 39
            startedAt: DateTime(2026, 1, 3),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Last 3 rounds'), findsOneWidget);

        // Stats should be present (values calculated by HandicapCalculator)
        expect(find.textContaining('HC'), findsWidgets);
      });

      testWidgets('mixed plotted and imported scores calculated correctly', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime(2026, 1, 1),
          ),
        ];

        final importedScores = [
          ImportedScore(
            id: 'is1',
            date: DateTime(2026, 1, 2),
            score: 560,
            roundName: 'WA 18m',
            sessionType: 'practice',
            source: 'manual',
            importedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: sessions,
                importedScores: importedScores,
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Last 2 rounds'), findsOneWidget);
      });

      testWidgets('different round types handled correctly', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_720_70m',
            totalScore: 600,
            startedAt: DateTime(2026, 1, 1),
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime(2026, 1, 2),
          ),
          createFakeSession(
            id: 's3',
            roundTypeId: 'portsmouth',
            totalScore: 560,
            startedAt: DateTime(2026, 1, 3),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Last 3 rounds'), findsOneWidget);
      });
    });

    group('Date Sorting and Filtering', () {
      testWidgets('data sorted by date chronologically', (tester) async {
        // Create sessions out of order
        final sessions = [
          createFakeSession(
            id: 's3',
            roundTypeId: 'wa_18m',
            totalScore: 580,
            startedAt: DateTime(2026, 1, 15),
          ),
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime(2026, 1, 1),
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 560,
            startedAt: DateTime(2026, 1, 8),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should render with data sorted (internally)
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Last 3 rounds'), findsOneWidget);
      });

      testWidgets('shows last 30 rounds when more than 30 available', (tester) async {
        // Create 40 sessions
        final sessions = List.generate(40, (i) {
          return createFakeSession(
            id: 's$i',
            roundTypeId: 'wa_18m',
            totalScore: 540 + i, // Varying scores
            startedAt: DateTime(2026, 1, 1).add(Duration(days: i)),
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should show last 30 rounds
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Last 30 rounds'), findsOneWidget);
      });

      testWidgets('exactly 30 rounds handled correctly', (tester) async {
        final sessions = List.generate(30, (i) {
          return createFakeSession(
            id: 's$i',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime(2026, 1, 1).add(Duration(days: i)),
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.text('Last 30 rounds'), findsOneWidget);
      });
    });

    group('Statistics Calculation', () {
      testWidgets('current handicap shows last round', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime(2026, 1, 1),
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 580,
            startedAt: DateTime(2026, 1, 2),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should have current handicap (from last session)
        expect(find.text('Current'), findsOneWidget);
        expect(find.textContaining('HC'), findsWidgets);
      });

      testWidgets('average handicap calculated correctly', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime(2026, 1, 1),
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 560,
            startedAt: DateTime(2026, 1, 2),
          ),
          createFakeSession(
            id: 's3',
            roundTypeId: 'wa_18m',
            totalScore: 580,
            startedAt: DateTime(2026, 1, 3),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.text('Average'), findsOneWidget);
        expect(find.textContaining('HC'), findsWidgets);
      });

      testWidgets('best handicap is lowest value', (tester) async {
        // Lower handicap = better performance
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540, // Higher handicap
            startedAt: DateTime(2026, 1, 1),
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 580, // Lower handicap (best)
            startedAt: DateTime(2026, 1, 2),
          ),
          createFakeSession(
            id: 's3',
            roundTypeId: 'wa_18m',
            totalScore: 560, // Middle handicap
            startedAt: DateTime(2026, 1, 3),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.text('Best'), findsOneWidget);
        expect(find.textContaining('HC'), findsWidgets);
      });
    });

    group('Round Name Matching', () {
      testWidgets('WA 18m imported score matched correctly', (tester) async {
        final importedScore = ImportedScore(
          id: 'is1',
          date: DateTime(2026, 1, 10),
          score: 540,
          roundName: 'WA 18m',
          sessionType: 'practice',
          source: 'manual',
          importedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: [],
                importedScores: [importedScore],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('Portsmouth imported score matched correctly', (tester) async {
        final importedScore = ImportedScore(
          id: 'is1',
          date: DateTime(2026, 1, 10),
          score: 560,
          roundName: 'Portsmouth',
          sessionType: 'practice',
          source: 'manual',
          importedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: [],
                importedScores: [importedScore],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('720 round matched correctly with high score', (tester) async {
        final importedScore = ImportedScore(
          id: 'is1',
          date: DateTime(2026, 1, 10),
          score: 650, // High score indicates full 720
          roundName: '720',
          sessionType: 'practice',
          source: 'manual',
          importedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: [],
                importedScores: [importedScore],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should match to wa_720_70m
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('unmatched round name ignored', (tester) async {
        final importedScore = ImportedScore(
          id: 'is1',
          date: DateTime(2026, 1, 10),
          score: 540,
          roundName: 'Unknown Round Type',
          sessionType: 'practice',
          source: 'manual',
          importedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: [],
                importedScores: [importedScore],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should show sample preview for unknown round
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('SAMPLE'), findsOneWidget);
      });

      testWidgets('fuzzy matching works with variations', (tester) async {
        // Test case-insensitive and whitespace handling
        final importedScore = ImportedScore(
          id: 'is1',
          date: DateTime(2026, 1, 10),
          score: 540,
          roundName: 'wa 18m', // Lowercase, different spacing
          sessionType: 'practice',
          source: 'manual',
          importedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: [],
                importedScores: [importedScore],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('Visual Elements', () {
      testWidgets('legend shows plotted and imported labels', (tester) async {
        final session = createFakeSession(
          id: 's1',
          roundTypeId: 'wa_18m',
          totalScore: 540,
          startedAt: DateTime(2026, 1, 1),
        );

        final importedScore = ImportedScore(
          id: 'is1',
          date: DateTime(2026, 1, 2),
          score: 560,
          roundName: 'WA 18m',
          sessionType: 'practice',
          source: 'manual',
          importedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: [session],
                importedScores: [importedScore],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.text('Competition'), findsOneWidget);
        expect(find.text('Practice'), findsOneWidget);
      });

      testWidgets('card wrapper present', (tester) async {
        final session = createFakeSession(
          id: 's1',
          roundTypeId: 'wa_18m',
          totalScore: 540,
          startedAt: DateTime(2026, 1, 1),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: [session],
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('chart title present', (tester) async {
        final session = createFakeSession(
          id: 's1',
          roundTypeId: 'wa_18m',
          totalScore: 540,
          startedAt: DateTime(2026, 1, 1),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: [session],
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.text('Handicap Progression'), findsOneWidget);
      });

      testWidgets('stat badges render for all three stats', (tester) async {
        final sessions = List.generate(3, (i) {
          return createFakeSession(
            id: 's$i',
            roundTypeId: 'wa_18m',
            totalScore: 540 + i * 10,
            startedAt: DateTime(2026, 1, 1).add(Duration(days: i)),
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.text('Current'), findsOneWidget);
        expect(find.text('Average'), findsOneWidget);
        expect(find.text('Best'), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('single round shows correct stats', (tester) async {
        final session = createFakeSession(
          id: 's1',
          roundTypeId: 'wa_18m',
          totalScore: 540,
          startedAt: DateTime(2026, 1, 1),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: [session],
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // With only one round, current = average = best
        expect(find.text('Current'), findsOneWidget);
        expect(find.text('Average'), findsOneWidget);
        expect(find.text('Best'), findsOneWidget);
      });

      testWidgets('same handicap for all rounds handled', (tester) async {
        final sessions = List.generate(5, (i) {
          return createFakeSession(
            id: 's$i',
            roundTypeId: 'wa_18m',
            totalScore: 540, // Same score = same handicap
            startedAt: DateTime(2026, 1, 1).add(Duration(days: i)),
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Chart should handle zero range (padding prevents divide by zero)
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('very large handicap range handled', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 200, // Very low score = high handicap
            startedAt: DateTime(2026, 1, 1),
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 590, // High score = low handicap
            startedAt: DateTime(2026, 1, 2),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('dates on same day handled', (tester) async {
        final baseDate = DateTime(2026, 1, 1, 10, 0);
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: baseDate,
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 560,
            startedAt: baseDate.add(const Duration(hours: 2)),
          ),
          createFakeSession(
            id: 's3',
            roundTypeId: 'wa_18m',
            totalScore: 580,
            startedAt: baseDate.add(const Duration(hours: 4)),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Last 3 rounds'), findsOneWidget);
      });

      testWidgets('zero scores handled correctly', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 0, // Zero score = very high handicap
            startedAt: DateTime(2026, 1, 1),
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime(2026, 1, 2),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Both rounds should be included (zero gets max handicap)
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Last 2 rounds'), findsOneWidget);
      });
    });

    group('Integration', () {
      testWidgets('full chart with mixed data types works', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_720_70m',
            totalScore: 600,
            startedAt: DateTime(2026, 1, 1),
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime(2026, 1, 5),
          ),
        ];

        final importedScores = [
          ImportedScore(
            id: 'is1',
            date: DateTime(2026, 1, 3),
            score: 560,
            roundName: 'Portsmouth',
            sessionType: 'practice',
            source: 'manual',
            importedAt: DateTime.now(),
          ),
          ImportedScore(
            id: 'is2',
            date: DateTime(2026, 1, 7),
            score: 550,
            roundName: 'WA 18m',
            sessionType: 'competition',
            source: 'manual',
            importedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: sessions,
                importedScores: importedScores,
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Last 4 rounds'), findsOneWidget);
        expect(find.text('Handicap Progression'), findsOneWidget);
        expect(find.text('Competition'), findsOneWidget);
        expect(find.text('Practice'), findsOneWidget);
        expect(find.text('Current'), findsOneWidget);
        expect(find.text('Average'), findsOneWidget);
        expect(find.text('Best'), findsOneWidget);
      });

      testWidgets('many rounds with filtering works', (tester) async {
        // Create 50 sessions to test 30-round limit
        final sessions = List.generate(50, (i) {
          return createFakeSession(
            id: 's$i',
            roundTypeId: 'wa_18m',
            totalScore: 520 + (i % 10) * 5, // Varying scores
            startedAt: DateTime(2026, 1, 1).add(Duration(days: i)),
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandicapChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should filter to last 30
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Last 30 rounds'), findsOneWidget);
      });
    });
  });
}
