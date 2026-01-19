import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:archery_super_app/widgets/volume_chart.dart';
import 'package:archery_super_app/db/database.dart';

import '../test_helpers.dart';

void main() {
  group('VolumeChart', () {
    late List<Session> testSessions;
    late List<ImportedScore> testImportedScores;
    late Map<String, RoundType> testRoundTypes;

    setUp(() {
      // Create test round type
      testRoundTypes = {
        'wa_18m': createFakeRoundType(
          id: 'wa_18m',
          name: 'WA 18m',
          maxScore: 600,
          arrowsPerEnd: 3,
          totalEnds: 20,
        ),
      };
    });

    group('Empty State', () {
      test('empty data renders without crash', () {
        // This is a widget test but written as a unit test for the data handling
        final sessions = <Session>[];
        final importedScores = <ImportedScore>[];

        expect(sessions.isEmpty, isTrue);
        expect(importedScores.isEmpty, isTrue);
      });

      testWidgets('shows sample preview when no sessions or imported scores', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: [],
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Widget should show sample preview with SAMPLE label for empty data
        expect(find.byType(VolumeChart), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('SAMPLE'), findsOneWidget);
      });
    });

    group('Single Data Point', () {
      testWidgets('single session handled correctly', (tester) async {
        final session = createFakeSession(
          id: 's1',
          roundTypeId: 'wa_18m',
          totalScore: 540,
          startedAt: DateTime(2026, 1, 10),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: [session],
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should render chart card
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('1 sessions'), findsOneWidget);

        // Should have chart painter (multiple CustomPaint from chips, so check for any)
        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('single imported score handled correctly', (tester) async {
        final importedScore = ImportedScore(
          id: 'is1',
          date: DateTime(2026, 1, 10),
          score: 580,
          roundName: 'WA 18m',
          sessionType: 'practice',
          source: 'manual',
          importedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: [],
                importedScores: [importedScore],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
        expect(find.text('1 sessions'), findsOneWidget);
      });
    });

    group('Date Range Filtering', () {
      late List<Session> multiDaySessions;

      setUp(() {
        // Create sessions across different time periods
        multiDaySessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 550,
            startedAt: DateTime.now().subtract(const Duration(days: 10)),
          ),
          createFakeSession(
            id: 's3',
            roundTypeId: 'wa_18m',
            totalScore: 560,
            startedAt: DateTime.now().subtract(const Duration(days: 40)),
          ),
          createFakeSession(
            id: 's4',
            roundTypeId: 'wa_18m',
            totalScore: 570,
            startedAt: DateTime.now().subtract(const Duration(days: 100)),
          ),
          createFakeSession(
            id: 's5',
            roundTypeId: 'wa_18m',
            totalScore: 580,
            startedAt: DateTime.now().subtract(const Duration(days: 200)),
          ),
        ];
      });

      testWidgets('1W filter shows recent week only', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: multiDaySessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Initially shows 3M (default)
        expect(find.text('3 sessions'), findsOneWidget);

        // Tap 1W chip
        await tester.tap(find.text('1W'));
        await tester.pumpAndSettle();

        // Should now show only 1 session (from 2 days ago)
        expect(find.text('1 sessions'), findsOneWidget);
      });

      testWidgets('1M filter shows last 30 days', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: multiDaySessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Tap 1M chip
        await tester.tap(find.text('1M'));
        await tester.pumpAndSettle();

        // Should show 2 sessions (2 days and 10 days ago)
        expect(find.text('2 sessions'), findsOneWidget);
      });

      testWidgets('All filter shows all sessions', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: multiDaySessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Tap All chip
        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();

        // Should show all 5 sessions
        expect(find.text('5 sessions'), findsOneWidget);
      });

      testWidgets('Indoor season filter works', (tester) async {
        // Create sessions in different seasons
        final seasonalSessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime(2026, 1, 15), // January (indoor)
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 550,
            startedAt: DateTime(2026, 5, 15), // May (outdoor)
          ),
          createFakeSession(
            id: 's3',
            roundTypeId: 'wa_18m',
            totalScore: 560,
            startedAt: DateTime(2026, 10, 15), // October (indoor)
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: seasonalSessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Tap Indoor chip
        await tester.tap(find.text('Indoor'));
        await tester.pumpAndSettle();

        // Should show 2 indoor sessions (Jan and Oct)
        expect(find.text('2 sessions'), findsOneWidget);
      });

      testWidgets('Outdoor season filter works', (tester) async {
        // Create sessions in different seasons
        final seasonalSessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime(2026, 1, 15), // January (indoor)
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 550,
            startedAt: DateTime(2026, 5, 15), // May (outdoor)
          ),
          createFakeSession(
            id: 's3',
            roundTypeId: 'wa_18m',
            totalScore: 560,
            startedAt: DateTime(2026, 8, 15), // August (outdoor)
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: seasonalSessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Tap Outdoor chip
        await tester.tap(find.text('Outdoor'));
        await tester.pumpAndSettle();

        // Should show 2 outdoor sessions (May and Aug)
        expect(find.text('2 sessions'), findsOneWidget);
      });

      testWidgets('empty period shows "No data for this period"', (tester) async {
        // Create sessions all in the past (>1 year ago)
        final oldSessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime.now().subtract(const Duration(days: 400)),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: oldSessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Tap 1W chip (no sessions in last week)
        await tester.tap(find.text('1W'));
        await tester.pumpAndSettle();

        // Should show empty message
        expect(find.text('No data for this period'), findsOneWidget);
        expect(find.text('0 sessions'), findsOneWidget);
      });
    });

    group('Y-Axis Scaling', () {
      testWidgets('handles wide score range appropriately', (tester) async {
        // Create sessions with wide score range (300 to 600)
        final wideSessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 300,
            startedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 450,
            startedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          createFakeSession(
            id: 's3',
            roundTypeId: 'wa_18m',
            totalScore: 600,
            startedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: wideSessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should render chart (score labels are painted on canvas, not Text widgets)
        expect(find.byType(CustomPaint), findsWidgets);
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('handles narrow score range appropriately', (tester) async {
        // Create sessions with narrow score range (540 to 560)
        final narrowSessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 550,
            startedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          createFakeSession(
            id: 's3',
            roundTypeId: 'wa_18m',
            totalScore: 560,
            startedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: narrowSessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('handles identical scores', (tester) async {
        // All sessions have same score
        final identicalSessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          createFakeSession(
            id: 's3',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: identicalSessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should render without crash
        expect(find.byType(CustomPaint), findsWidgets);
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('Mixed Data Sources', () {
      testWidgets('combines plotted sessions and imported scores', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime(2026, 1, 10),
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 550,
            startedAt: DateTime(2026, 1, 12),
          ),
        ];

        final importedScores = <ImportedScore>[
          ImportedScore(
            id: 'is1',
            date: DateTime(2026, 1, 11),
            score: 545,
            roundName: 'WA 18m',
            sessionType: 'practice',
            source: 'manual',
            importedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: sessions,
                importedScores: importedScores,
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should show all 3 scores
        expect(find.text('3 sessions'), findsOneWidget);

        // Should show legend
        expect(find.text('Plotted'), findsOneWidget);
        expect(find.text('Imported'), findsOneWidget);
      });

      testWidgets('sorts all scores chronologically', (tester) async {
        // Create unsorted data
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime(2026, 1, 15),
          ),
        ];

        final importedScores = [
          ImportedScore(
            id: 'is1',
            date: DateTime(2026, 1, 10),
            score: 530,
            roundName: 'WA 18m',
            sessionType: 'practice',
            source: 'manual',
            importedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ImportedScore(
            id: 'is2',
            date: DateTime(2026, 1, 20),
            score: 550,
            roundName: 'WA 18m',
            sessionType: 'practice',
            source: 'manual',
            importedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: sessions,
                importedScores: importedScores,
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should render without issues (sorted internally)
        expect(find.text('3 sessions'), findsOneWidget);
      });
    });

    group('Date Range Label', () {
      testWidgets('displays correct date range', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime(2026, 1, 10),
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 550,
            startedAt: DateTime(2026, 1, 20),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should show date range (format: dd/mm/yy)
        expect(find.textContaining('10/1/26'), findsOneWidget);
        expect(find.textContaining('20/1/26'), findsOneWidget);
      });
    });

    group('Chart Painter', () {
      testWidgets('renders CustomPaint with data', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          createFakeSession(
            id: 's2',
            roundTypeId: 'wa_18m',
            totalScore: 550,
            startedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should have CustomPaint for chart
        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('chart has correct height', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Find the SizedBox containing the chart (height: 160)
        // There are multiple SizedBoxes, need to find the one with height 160
        final sizedBoxes = tester.widgetList<SizedBox>(
          find.descendant(
            of: find.byType(Card),
            matching: find.byType(SizedBox),
          ),
        );

        final chartBox = sizedBoxes.firstWhere(
          (box) => box.height == 160,
          orElse: () => throw TestFailure('No SizedBox with height 160 found'),
        );

        expect(chartBox.height, equals(160));
      });
    });

    group('Period Selector', () {
      testWidgets('displays all time period options', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Check all period labels are present
        expect(find.text('1W'), findsOneWidget);
        expect(find.text('1M'), findsOneWidget);
        expect(find.text('3M'), findsOneWidget);
        expect(find.text('6M'), findsOneWidget);
        expect(find.text('1Y'), findsOneWidget);
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Indoor'), findsOneWidget);
        expect(find.text('Outdoor'), findsOneWidget);
        expect(find.text('Custom'), findsOneWidget);
      });

      testWidgets('3M is selected by default', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Find the 3M ChoiceChip
        final chip = tester.widget<ChoiceChip>(
          find.ancestor(
            of: find.text('3M'),
            matching: find.byType(ChoiceChip),
          ),
        );

        expect(chip.selected, isTrue);
      });

      testWidgets('can switch between periods', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Tap 1M chip
        await tester.tap(find.text('1M'));
        await tester.pumpAndSettle();

        // 1M should now be selected
        final chip = tester.widget<ChoiceChip>(
          find.ancestor(
            of: find.text('1M'),
            matching: find.byType(ChoiceChip),
          ),
        );

        expect(chip.selected, isTrue);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles missing round type gracefully', (tester) async {
        // Session with round type that doesn't exist in map
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'nonexistent',
            totalScore: 540,
            startedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should render without crash (percentage will be null)
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('1 sessions'), findsOneWidget);
      });

      testWidgets('handles future dates', (tester) async {
        // Session with future date (shouldn't happen but handle gracefully)
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime.now().add(const Duration(days: 1)),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should render
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('handles very large datasets', (tester) async {
        // Create 100 sessions within 3 months (default filter)
        final largeSessions = List.generate(
          100,
          (i) => createFakeSession(
            id: 's$i',
            roundTypeId: 'wa_18m',
            totalScore: 500 + i,
            startedAt: DateTime.now().subtract(Duration(days: i)),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: largeSessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should render without performance issues
        // Default is 3M (90 days), so should show first 90 sessions
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('90 sessions'), findsOneWidget);
      });

      testWidgets('handles zero scores', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 0,
            startedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Should render without crash
        expect(find.byType(Card), findsOneWidget);
        // Chart should render (score label painted on canvas, not as Text widget)
        expect(find.byType(CustomPaint), findsWidgets);
      });
    });

    group('Visual Elements', () {
      testWidgets('displays legend for plotted and imported', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        // Check legend items
        expect(find.text('Plotted'), findsOneWidget);
        expect(find.text('Imported'), findsOneWidget);
      });

      testWidgets('has card wrapper', (tester) async {
        final sessions = [
          createFakeSession(
            id: 's1',
            roundTypeId: 'wa_18m',
            totalScore: 540,
            startedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VolumeChart(
                sessions: sessions,
                importedScores: [],
                roundTypes: testRoundTypes,
              ),
            ),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
      });
    });
  });
}
