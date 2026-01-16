/// Integration tests for the CSV import flow.
///
/// Tests the core UX flow: navigate to import -> paste CSV -> preview rows ->
/// confirm import -> data saved -> summary displayed.
///
/// Uses in-memory database for testing full import integration.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

import 'package:archery_super_app/db/database.dart';
import 'package:archery_super_app/providers/session_provider.dart';
import 'package:archery_super_app/providers/bow_training_provider.dart';
import 'package:archery_super_app/providers/breath_training_provider.dart';
import 'package:archery_super_app/screens/import_screen.dart';
import 'package:archery_super_app/services/import_service.dart';
import 'package:archery_super_app/theme/app_theme.dart';

/// Creates an in-memory database for testing
AppDatabase createTestDatabase() {
  return AppDatabase.withExecutor(
    NativeDatabase.memory(),
  );
}

/// Test helper to build widgets with all required providers
Widget buildTestApp({
  required AppDatabase db,
  required Widget child,
}) {
  return Provider<AppDatabase>.value(
    value: db,
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => SessionProvider(context.read<AppDatabase>()),
        ),
        ChangeNotifierProvider(
          create: (context) => BowTrainingProvider(context.read<AppDatabase>()),
        ),
        ChangeNotifierProvider(
          create: (context) => BreathTrainingProvider(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
      ),
    ),
  );
}

void main() {
  group('Import Flow Integration Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = createTestDatabase();
      // Wait for database initialization
      await db.getAllRoundTypes();
    });

    tearDown(() async {
      await db.close();
    });

    group('Navigation and UI', () {
      testWidgets('import screen shows import options', (tester) async {
        await tester.pumpWidget(buildTestApp(
          db: db,
          child: const ImportScreen(),
        ));
        await tester.pumpAndSettle();

        // Verify import options are displayed
        expect(find.text('Import from CSV File'), findsOneWidget);
        expect(find.text('Paste CSV Text'), findsOneWidget);
        expect(find.text('Manual Entry'), findsOneWidget);
        expect(find.text('Import Scores'), findsOneWidget);
      });

      testWidgets('paste CSV option opens dialog', (tester) async {
        await tester.pumpWidget(buildTestApp(
          db: db,
          child: const ImportScreen(),
        ));
        await tester.pumpAndSettle();

        // Tap "Paste CSV Text" option
        await tester.tap(find.text('Paste CSV Text'));
        await tester.pumpAndSettle();

        // Verify dialog appears with expected content
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Parse'), findsOneWidget);
        expect(find.text('Cancel'), findsWidgets);
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('manual entry option opens dialog', (tester) async {
        await tester.pumpWidget(buildTestApp(
          db: db,
          child: const ImportScreen(),
        ));
        await tester.pumpAndSettle();

        // Tap "Manual Entry" option
        await tester.tap(find.text('Manual Entry'));
        await tester.pumpAndSettle();

        // Verify dialog appears
        expect(find.text('Add Score'), findsOneWidget);
        expect(find.text('Score'), findsOneWidget);
        expect(find.text('Round Name'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      });

      testWidgets('cancel in paste dialog returns to options', (tester) async {
        await tester.pumpWidget(buildTestApp(
          db: db,
          child: const ImportScreen(),
        ));
        await tester.pumpAndSettle();

        // Open paste dialog
        await tester.tap(find.text('Paste CSV Text'));
        await tester.pumpAndSettle();

        // Find cancel button in dialog
        final cancelButtons = find.text('Cancel');
        expect(cancelButtons, findsWidgets);

        // Tap the Cancel button in the dialog
        await tester.tap(cancelButtons.first);
        await tester.pumpAndSettle();

        // Should still be on import options
        expect(find.text('Import from CSV File'), findsOneWidget);
        expect(find.text('Paste CSV Text'), findsOneWidget);
      });
    });

    group('CSV Parsing Error States', () {
      testWidgets('empty CSV shows error', (tester) async {
        await tester.pumpWidget(buildTestApp(
          db: db,
          child: const ImportScreen(),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Paste CSV Text'));
        await tester.pumpAndSettle();

        // Enter empty string
        await tester.enterText(find.byType(TextField), '');
        await tester.tap(find.text('Parse'));
        await tester.pumpAndSettle();

        // Should show error for empty CSV
        expect(find.textContaining('Empty CSV'), findsOneWidget);
      });
    });

    group('ImportService Unit Tests', () {
      test('parseScoresCsv parses valid CSV correctly', () {
        final service = ImportService();
        final rows = [
          ['date', 'score', 'round', 'location'],
          ['2024-01-15', '580', 'WA 18m', 'Test Club'],
          ['2024-01-20', '590', 'WA 25m', 'Another Venue'],
        ];

        final result = service.parseScoresCsv(rows);

        expect(result.drafts.length, equals(2));
        expect(result.skipped, equals(0));
        expect(result.drafts[0].score, equals(580));
        expect(result.drafts[0].roundName, equals('WA 18m'));
        expect(result.drafts[1].score, equals(590));
      });

      test('parseScoresCsv handles different date formats', () {
        final service = ImportService();
        final rows = [
          ['date', 'score', 'round'],
          ['2024-01-15', '500', 'Round A'], // YYYY-MM-DD
          ['15/01/2024', '510', 'Round B'], // DD/MM/YYYY
          ['15-01-2024', '520', 'Round C'], // DD-MM-YYYY
          ['15.01.2024', '530', 'Round D'], // DD.MM.YYYY
        ];

        final result = service.parseScoresCsv(rows);

        expect(result.drafts.length, equals(4));
        expect(result.skipped, equals(0));
      });

      test('parseScoresCsv skips invalid dates', () {
        final service = ImportService();
        final rows = [
          ['date', 'score', 'round'],
          ['not-a-date', '500', 'Round A'],
          ['2024-01-15', '510', 'Round B'],
        ];

        final result = service.parseScoresCsv(rows);

        expect(result.drafts.length, equals(1));
        expect(result.skipped, equals(1));
        expect(result.reasons.first, contains('Invalid date'));
      });

      test('parseScoresCsv skips zero scores', () {
        final service = ImportService();
        final rows = [
          ['date', 'score', 'round'],
          ['2024-01-15', '0', 'Round A'],
          ['2024-01-16', '500', 'Round B'],
        ];

        final result = service.parseScoresCsv(rows);

        expect(result.drafts.length, equals(1));
        expect(result.skipped, equals(1));
        expect(result.drafts[0].score, equals(500));
      });

      test('parseScoresCsv skips non-numeric scores', () {
        final service = ImportService();
        final rows = [
          ['date', 'score', 'round'],
          ['2024-01-15', 'abc', 'Round A'],
          ['2024-01-16', '500', 'Round B'],
        ];

        final result = service.parseScoresCsv(rows);

        expect(result.drafts.length, equals(1));
        expect(result.skipped, equals(1));
      });

      test('parseScoresCsv handles scores with commas', () {
        final service = ImportService();
        final rows = [
          ['date', 'score', 'round'],
          ['2024-01-15', '1,296', 'Long Round'],
        ];

        final result = service.parseScoresCsv(rows);

        expect(result.drafts.length, equals(1));
        expect(result.drafts[0].score, equals(1296));
      });

      test('parseScoresCsv parses optional fields', () {
        final service = ImportService();
        final rows = [
          ['date', 'score', 'round', 'location', 'handicap', 'hits', 'golds', 'xs', 'bowstyle', 'eventtype', 'classification'],
          ['2024-01-15', '580', 'WA 18m', 'Test Club', '45', '60', '30', '5', 'Recurve', 'Competition', 'A'],
        ];

        final result = service.parseScoresCsv(rows);

        expect(result.drafts.length, equals(1));
        final draft = result.drafts[0];
        expect(draft.location, equals('Test Club'));
        expect(draft.handicap, equals(45));
        expect(draft.hits, equals(60));
        expect(draft.golds, equals(30));
        expect(draft.xs, equals(5));
        expect(draft.bowstyle, equals('Recurve'));
        expect(draft.eventType, equals('Competition'));
        expect(draft.classification, equals('A'));
      });

      test('parseScoresCsv handles CSV without header', () {
        final service = ImportService();
        // No header row - uses default column positions (date, score, round)
        final rows = [
          ['2024-01-15', '580', 'WA 18m'],
          ['2024-01-20', '590', 'WA 25m'],
        ];

        final result = service.parseScoresCsv(rows);

        expect(result.drafts.length, equals(2));
        expect(result.drafts[0].score, equals(580));
        expect(result.drafts[0].roundName, equals('WA 18m'));
      });

      test('parseScoresCsv handles flexible column names', () {
        final service = ImportService();
        final rows = [
          ['shot_date', 'total_score', 'round_name', 'venue'],
          ['2024-01-15', '580', 'WA 18m', 'My Club'],
        ];

        final result = service.parseScoresCsv(rows);

        expect(result.drafts.length, equals(1));
        expect(result.drafts[0].score, equals(580));
        expect(result.drafts[0].location, equals('My Club'));
      });

      test('parseScoresCsv returns empty for empty input', () {
        final service = ImportService();
        final result = service.parseScoresCsv([]);

        expect(result.drafts, isEmpty);
        expect(result.skipped, equals(0));
      });

      test('parseScoresCsv limits skip reasons to 5', () {
        final service = ImportService();
        final rows = [
          ['date', 'score', 'round'],
          ['bad1', '100', 'A'],
          ['bad2', '100', 'B'],
          ['bad3', '100', 'C'],
          ['bad4', '100', 'D'],
          ['bad5', '100', 'E'],
          ['bad6', '100', 'F'],
          ['bad7', '100', 'G'],
        ];

        final result = service.parseScoresCsv(rows);

        expect(result.skipped, equals(7));
        expect(result.reasons.length, equals(5)); // Limited to 5
      });

      test('parseScoresCsv shows skipped row count correctly', () {
        final service = ImportService();
        final rows = [
          ['date', 'score', 'round'],
          ['2024-05-01', '500', 'WA 18m'],
          ['invalid-date', '600', 'WA 18m'],
          ['2024-05-03', '0', 'WA 18m'],
          ['2024-05-04', '550', 'WA 18m'],
        ];

        final result = service.parseScoresCsv(rows);

        // 2 valid (500, 550), 2 skipped (invalid date, zero score)
        expect(result.drafts.length, equals(2));
        expect(result.skipped, equals(2));
      });

      test('parseScoresCsv shows reasons for skipped rows', () {
        final service = ImportService();
        final rows = [
          ['date', 'score', 'round'],
          ['bad-date', '500', 'WA 18m'],
          ['2024-05-02', 'abc', 'WA 18m'],
          ['2024-05-03', '600', 'WA 18m'],
        ];

        final result = service.parseScoresCsv(rows);

        expect(result.drafts.length, equals(1));
        expect(result.skipped, equals(2));
        expect(result.reasons.any((r) => r.contains('Invalid date')), isTrue);
        expect(result.reasons.any((r) => r.contains('Invalid score')), isTrue);
      });

      test('parseScoresCsv handles multiple round types', () {
        final service = ImportService();
        final rows = [
          ['date', 'score', 'round'],
          ['2024-01-01', '500', 'WA 18m'],
          ['2024-01-02', '600', 'WA 25m'],
          ['2024-01-03', '700', 'Portsmouth'],
        ];

        final result = service.parseScoresCsv(rows);

        expect(result.drafts.length, equals(3));
        final roundNames = result.drafts.map((d) => d.roundName).toSet();
        expect(roundNames.length, equals(3));
        expect(roundNames.contains('WA 18m'), isTrue);
        expect(roundNames.contains('WA 25m'), isTrue);
        expect(roundNames.contains('Portsmouth'), isTrue);
      });

      test('parseScoresCsv handles practice event type', () {
        final service = ImportService();
        final rows = [
          ['date', 'score', 'round', 'eventtype'],
          ['2024-01-15', '580', 'WA 18m', 'Practice'],
        ];

        final result = service.parseScoresCsv(rows);

        expect(result.drafts.length, equals(1));
        expect(result.drafts[0].eventType, equals('Practice'));
      });

      test('parseScoresCsv handles competition event type', () {
        final service = ImportService();
        final rows = [
          ['date', 'score', 'round', 'eventtype'],
          ['2024-01-15', '580', 'WA 18m', 'Competition'],
        ];

        final result = service.parseScoresCsv(rows);

        expect(result.drafts.length, equals(1));
        expect(result.drafts[0].eventType, equals('Competition'));
      });
    });

    group('Manual Entry', () {
      testWidgets('manual entry dialog shows correct fields', (tester) async {
        await tester.pumpWidget(buildTestApp(
          db: db,
          child: const ImportScreen(),
        ));
        await tester.pumpAndSettle();

        // Tap manual entry
        await tester.tap(find.text('Manual Entry'));
        await tester.pumpAndSettle();

        // Verify dialog fields
        expect(find.text('Add Score'), findsOneWidget);
        expect(find.text('Score'), findsOneWidget);
        expect(find.text('Round Name'), findsOneWidget);
        expect(find.text('Location (optional)'), findsOneWidget);
        expect(find.text('Date'), findsOneWidget);
      });

      testWidgets('manual entry saves score to database', (tester) async {
        await tester.pumpWidget(buildTestApp(
          db: db,
          child: const ImportScreen(),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Manual Entry'));
        await tester.pumpAndSettle();

        // Enter score data
        final scoreField = find.widgetWithText(TextField, 'Score');
        final roundField = find.widgetWithText(TextField, 'Round Name');

        await tester.enterText(scoreField, '555');
        await tester.enterText(roundField, 'Test Round');
        await tester.pumpAndSettle();

        // Tap Save
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Verify score was saved
        final scores = await db.select(db.importedScores).get();
        expect(scores.length, equals(1));
        expect(scores.first.score, equals(555));
        expect(scores.first.roundName, equals('Test Round'));
        expect(scores.first.source, equals('manual'));
      });

      testWidgets('manual entry cancel does not save', (tester) async {
        await tester.pumpWidget(buildTestApp(
          db: db,
          child: const ImportScreen(),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Manual Entry'));
        await tester.pumpAndSettle();

        // Enter some data
        final scoreField = find.widgetWithText(TextField, 'Score');
        await tester.enterText(scoreField, '600');
        await tester.pumpAndSettle();

        // Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify nothing was saved
        final scores = await db.select(db.importedScores).get();
        expect(scores.length, equals(0));
      });
    });

    group('Database Integration', () {
      test('duplicate detection works correctly', () async {
        // First, insert a score directly into the database
        await db.insertImportedScore(ImportedScoresCompanion.insert(
          id: 'existing_score_1',
          date: DateTime(2024, 6, 1),
          roundName: 'WA 18m',
          score: 580,
          source: const Value('manual'),
        ));

        // Check if duplicate detection works
        final isDuplicate = await db.isDuplicateScoreWithRound(
          DateTime(2024, 6, 1),
          580,
          'WA 18m',
        );
        expect(isDuplicate, isTrue);

        // Check non-duplicate
        final isNotDuplicate = await db.isDuplicateScoreWithRound(
          DateTime(2024, 6, 2),
          590,
          'WA 18m',
        );
        expect(isNotDuplicate, isFalse);
      });

      test('imported scores are stored with correct source', () async {
        await db.insertImportedScore(ImportedScoresCompanion.insert(
          id: 'csv_score_1',
          date: DateTime(2024, 7, 1),
          roundName: 'WA 18m',
          score: 600,
          source: const Value('csv'),
        ));

        final scores = await db.select(db.importedScores).get();
        expect(scores.length, equals(1));
        expect(scores.first.source, equals('csv'));
      });

      test('imported scores store session type', () async {
        await db.insertImportedScore(ImportedScoresCompanion.insert(
          id: 'practice_score_1',
          date: DateTime(2024, 8, 1),
          roundName: 'WA 18m',
          score: 610,
          sessionType: const Value('practice'),
          source: const Value('csv'),
        ));

        await db.insertImportedScore(ImportedScoresCompanion.insert(
          id: 'competition_score_1',
          date: DateTime(2024, 8, 2),
          roundName: 'WA 18m',
          score: 620,
          sessionType: const Value('competition'),
          source: const Value('csv'),
        ));

        final scores = await db.select(db.importedScores).get();
        expect(scores.length, equals(2));

        final practiceScore = scores.firstWhere((s) => s.id == 'practice_score_1');
        final competitionScore = scores.firstWhere((s) => s.id == 'competition_score_1');

        expect(practiceScore.sessionType, equals('practice'));
        expect(competitionScore.sessionType, equals('competition'));
      });

      test('imported scores store location and notes', () async {
        await db.insertImportedScore(ImportedScoresCompanion.insert(
          id: 'score_with_details',
          date: DateTime(2024, 9, 1),
          roundName: 'WA 18m',
          score: 630,
          location: const Value('Test Venue'),
          notes: const Value('HC: 45, Golds: 30'),
          source: const Value('csv'),
        ));

        final scores = await db.select(db.importedScores).get();
        expect(scores.length, equals(1));
        expect(scores.first.location, equals('Test Venue'));
        expect(scores.first.notes, equals('HC: 45, Golds: 30'));
      });
    });

    group('Volume Import Service', () {
      test('parseVolumeCsv parses valid volume data', () {
        final service = ImportService();
        final rows = [
          ['date', 'volume', 'title', 'notes'],
          ['2024-01-15', '120', 'Morning Practice', 'Good session'],
          ['2024-01-16', '150', 'Evening Practice', ''],
        ];

        final result = service.parseVolumeCsv(rows);

        expect(result.drafts.length, equals(2));
        expect(result.drafts[0].arrowCount, equals(120));
        expect(result.drafts[0].title, equals('Morning Practice'));
        expect(result.drafts[0].notes, equals('Good session'));
        expect(result.drafts[1].arrowCount, equals(150));
        expect(result.skipped, equals(0));
      });

      test('parseVolumeCsv handles different column names', () {
        final service = ImportService();
        final rows = [
          ['date', 'arrows', 'session'],
          ['2024-01-15', '100', 'Practice'],
        ];

        final result = service.parseVolumeCsv(rows);

        expect(result.drafts.length, equals(1));
        expect(result.drafts[0].arrowCount, equals(100));
      });

      test('parseVolumeCsv skips invalid rows', () {
        final service = ImportService();
        final rows = [
          ['date', 'volume'],
          ['invalid-date', '100'],
          ['2024-01-15', '0'],
          ['2024-01-16', 'abc'],
          ['2024-01-17', '120'],
        ];

        final result = service.parseVolumeCsv(rows);

        // Only the valid row should be parsed
        expect(result.drafts.length, equals(1));
        expect(result.drafts[0].arrowCount, equals(120));
        expect(result.skipped, equals(3));
        expect(result.reasons.length, greaterThan(0));
      });

      test('parseVolumeCsv handles scores with commas', () {
        final service = ImportService();
        final rows = [
          ['date', 'volume'],
          ['2024-01-15', '1,200'],
        ];

        final result = service.parseVolumeCsv(rows);

        expect(result.drafts.length, equals(1));
        expect(result.drafts[0].arrowCount, equals(1200));
      });

      test('parseVolumeCsv returns empty for empty input', () {
        final service = ImportService();
        final result = service.parseVolumeCsv([]);

        expect(result.drafts, isEmpty);
        expect(result.skipped, equals(0));
      });
    });
  });
}
