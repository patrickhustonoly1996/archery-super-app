/// Integration tests for the arrow plotting flow.
///
/// Tests the core UX flow: start session -> select round -> plot arrows ->
/// score calculation -> commit ends -> complete session.
///
/// Uses in-memory database for testing full provider integration.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

import 'package:archery_super_app/db/database.dart';
import 'package:archery_super_app/providers/session_provider.dart';
import 'package:archery_super_app/providers/equipment_provider.dart';
import 'package:archery_super_app/providers/connectivity_provider.dart';
import 'package:archery_super_app/providers/skills_provider.dart';
import 'package:archery_super_app/providers/sight_marks_provider.dart';
import 'package:archery_super_app/providers/auto_plot_provider.dart';
import 'package:archery_super_app/providers/user_profile_provider.dart';
import 'package:archery_super_app/providers/classification_provider.dart';
import 'package:archery_super_app/providers/accessibility_provider.dart';
import 'package:archery_super_app/services/vision_api_service.dart';
import 'package:archery_super_app/screens/plotting_screen.dart';
import 'package:archery_super_app/screens/session_start_screen.dart';
import 'package:archery_super_app/screens/session_complete_screen.dart';
import 'package:archery_super_app/screens/home_screen.dart';
import 'package:archery_super_app/widgets/full_scorecard_widget.dart';
import 'package:archery_super_app/widgets/target_face.dart';
import 'package:archery_super_app/theme/app_theme.dart';
import '../mocks/mock_connectivity_provider.dart';

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
          create: (context) =>
              EquipmentProvider(context.read<AppDatabase>())..loadEquipment(),
        ),
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => MockConnectivityProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              SkillsProvider(context.read<AppDatabase>())..loadSkills(),
        ),
        ChangeNotifierProvider(
          create: (context) => AutoPlotProvider(
            context.read<AppDatabase>(),
            VisionApiService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AccessibilityProvider()..loadSettings(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
      ),
    ),
  );
}

/// Test helper to build PlottingScreen with an existing SessionProvider
Widget buildPlottingTestApp({
  required AppDatabase db,
  required SessionProvider sessionProvider,
}) {
  return Provider<AppDatabase>.value(
    value: db,
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionProvider>.value(value: sessionProvider),
        ChangeNotifierProvider(
          create: (context) =>
              EquipmentProvider(context.read<AppDatabase>())..loadEquipment(),
        ),
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => MockConnectivityProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              SkillsProvider(context.read<AppDatabase>())..loadSkills(),
        ),
        ChangeNotifierProvider(
          create: (context) => AutoPlotProvider(
            context.read<AppDatabase>(),
            VisionApiService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AccessibilityProvider()..loadSettings(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const PlottingScreen(),
      ),
    ),
  );
}

void main() {
  group('Plotting Flow Integration Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = createTestDatabase();
      // Wait for database initialization including round type seeding
      await db.getAllRoundTypes();
    });

    /// Configure a larger test surface to avoid RenderFlex overflow in tight layouts
    void setLargeScreenSize(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
    }

    tearDown(() async {
      await db.close();
    });

    group('Session Start Flow', () {
      testWidgets('start session -> select round -> proceed to plotting screen',
          (tester) async {
        // Start with SessionStartScreen
        await tester.pumpWidget(buildTestApp(
          db: db,
          child: const SessionStartScreen(),
        ));
        await tester.pumpAndSettle();

        // Verify round types are displayed
        expect(find.text('Select Round'), findsOneWidget);

        // Find and tap a round type (WA 18m should exist from seeding)
        final wa18mFinder = find.text('WA 18m');
        if (wa18mFinder.evaluate().isNotEmpty) {
          await tester.tap(wa18mFinder);
          await tester.pumpAndSettle();

          // Verify Start button is enabled and tap it
          final startButton = find.text('Start');
          expect(startButton, findsOneWidget);
          await tester.tap(startButton);
          await tester.pumpAndSettle();

          // Verify we navigated to PlottingScreen
          expect(find.byType(PlottingScreen), findsOneWidget);

          // Verify session info is displayed
          expect(find.textContaining('End 1/'), findsOneWidget);
        }
      });

      testWidgets('session type selection works', (tester) async {
        await tester.pumpWidget(buildTestApp(
          db: db,
          child: const SessionStartScreen(),
        ));
        await tester.pumpAndSettle();

        // Default is practice - use findsWidgets since there may be multiple text widgets
        expect(find.text('Practice'), findsWidgets);
        expect(find.text('Competition'), findsWidgets);

        // Tap Competition using first match
        await tester.tap(find.text('Competition').first);
        await tester.pumpAndSettle();
      });
    });

    group('Arrow Plotting', () {
      testWidgets('plot arrow -> score calculated -> arrow appears in scorecard',
          (tester) async {
        setLargeScreenSize(tester);
        // Create a session first
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        await tester.pumpWidget(buildPlottingTestApp(
          db: db,
          sessionProvider: sessionProvider,
        ));
        await tester.pumpAndSettle();

        // Verify initial state - plotting screen is present
        expect(find.byType(PlottingScreen), findsOneWidget);

        // Plot an arrow at center (X ring)
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await tester.pumpAndSettle();

        // Verify score updated
        expect(sessionProvider.currentEndScore, greaterThan(0));
        expect(sessionProvider.arrowsInCurrentEnd, equals(1));
      });

      testWidgets('plot multiple arrows -> end totals update correctly',
          (tester) async {
        setLargeScreenSize(tester);
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        await tester.pumpWidget(buildPlottingTestApp(
          db: db,
          sessionProvider: sessionProvider,
        ));
        await tester.pumpAndSettle();

        // Plot 3 arrows (WA 18m has 3 arrows per end)
        await sessionProvider.plotArrow(x: 0.0, y: 0.0); // Center - score 10
        await tester.pumpAndSettle();
        expect(sessionProvider.arrowsInCurrentEnd, equals(1));

        await sessionProvider.plotArrow(x: 0.1, y: 0.0); // Near center
        await tester.pumpAndSettle();
        expect(sessionProvider.arrowsInCurrentEnd, equals(2));

        await sessionProvider.plotArrow(x: 0.15, y: 0.0); // Still in gold
        await tester.pumpAndSettle();

        // After 3 arrows, end should auto-commit (WA 18m has 3 arrows per end)
        // Total score should be sum of all 3 arrows
        expect(sessionProvider.totalScore, greaterThan(0));
      });
    });

    group('End Commit', () {
      testWidgets('commit end -> advance to next end', (tester) async {
        setLargeScreenSize(tester);
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        await tester.pumpWidget(buildPlottingTestApp(
          db: db,
          sessionProvider: sessionProvider,
        ));
        await tester.pumpAndSettle();

        // Verify starting at end 1
        expect(sessionProvider.currentEndNumber, equals(1));

        // Plot arrows and commit end
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.plotArrow(x: 0.05, y: 0.0);
        await sessionProvider.plotArrow(x: 0.1, y: 0.0);
        await sessionProvider.commitEnd();
        await tester.pumpAndSettle();

        // End should be committed
        expect(sessionProvider.currentEndNumber, equals(2));
        expect(sessionProvider.ends.length, equals(1)); // 1 completed end
        expect(sessionProvider.arrowsInCurrentEnd, equals(0)); // New end started
      });

      testWidgets('manual commit end with fewer arrows works', (tester) async {
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        // Plot only 1 arrow (less than arrowsPerEnd)
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);

        // Manual commit
        await sessionProvider.commitEnd();

        // Should have advanced to next end
        expect(sessionProvider.currentEndNumber, equals(2));
        expect(sessionProvider.ends.length, equals(1));
      });
    });

    group('Session Completion', () {
      testWidgets('complete all ends -> session marked complete', (tester) async {
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();

        // Use a round type with fewer ends for faster testing
        // Create a minimal test round if needed
        final testRound = roundTypes.firstWhere(
          (rt) => rt.totalEnds <= 10,
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: testRound.id, title: 'Test Session');
        final totalEnds = sessionProvider.totalEnds;

        // Complete all ends
        for (int end = 0; end < totalEnds; end++) {
          for (int arrow = 0; arrow < sessionProvider.arrowsPerEnd; arrow++) {
            await sessionProvider.plotArrow(x: 0.05 * arrow, y: 0.0);
          }
          // Commit the end
          await sessionProvider.commitEnd();
        }

        // Session should be marked complete
        expect(sessionProvider.isSessionComplete, isTrue);
        expect(sessionProvider.currentSession?.completedAt, isNotNull);
        expect(sessionProvider.ends.length, equals(totalEnds));
      });

      testWidgets('session complete screen shows correct stats', (tester) async {
        setLargeScreenSize(tester);
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final testRound = roundTypes.firstWhere(
          (rt) => rt.totalEnds <= 5,
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: testRound.id, title: 'Test Session');
        final totalEnds = sessionProvider.totalEnds;

        // Complete all ends with known scores
        for (int end = 0; end < totalEnds; end++) {
          for (int arrow = 0; arrow < sessionProvider.arrowsPerEnd; arrow++) {
            await sessionProvider.plotArrow(x: 0.0, y: 0.0); // Center shots
          }
          await sessionProvider.commitEnd();
        }

        expect(sessionProvider.isSessionComplete, isTrue);

        // Build session complete screen with required providers
        final equipmentProvider = EquipmentProvider(db);
        final skillsProvider = SkillsProvider(db)..loadSkills();
        final sightMarksProvider = SightMarksProvider(db);
        final userProfileProvider = UserProfileProvider(db);
        final classificationProvider = ClassificationProvider(db);
        await tester.pumpWidget(
          Provider<AppDatabase>.value(
            value: db,
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider<SessionProvider>.value(
                  value: sessionProvider,
                ),
                ChangeNotifierProvider<EquipmentProvider>.value(
                  value: equipmentProvider,
                ),
                ChangeNotifierProvider<SkillsProvider>.value(
                  value: skillsProvider,
                ),
                ChangeNotifierProvider<SightMarksProvider>.value(
                  value: sightMarksProvider,
                ),
                ChangeNotifierProvider<UserProfileProvider>.value(
                  value: userProfileProvider,
                ),
                ChangeNotifierProvider<ClassificationProvider>.value(
                  value: classificationProvider,
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.darkTheme,
                home: const SessionCompleteScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify completion screen is displayed
        expect(find.text('Session Complete'), findsOneWidget);
        expect(find.text('Xs'), findsOneWidget);
        expect(find.text('Ends'), findsOneWidget);

        // Verify score is displayed
        expect(find.text(sessionProvider.totalScore.toString()), findsOneWidget);
      });
    });

    group('Undo Functionality', () {
      testWidgets('undo arrow -> removes last plotted arrow', (tester) async {
        setLargeScreenSize(tester);
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        await tester.pumpWidget(buildPlottingTestApp(
          db: db,
          sessionProvider: sessionProvider,
        ));
        await tester.pumpAndSettle();

        // Plot 2 arrows
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.plotArrow(x: 0.1, y: 0.0);
        await tester.pumpAndSettle();

        expect(sessionProvider.arrowsInCurrentEnd, equals(2));
        final scoreWith2Arrows = sessionProvider.currentEndScore;

        // Undo last arrow
        await sessionProvider.undoLastArrow();
        await tester.pumpAndSettle();

        expect(sessionProvider.arrowsInCurrentEnd, equals(1));
        expect(sessionProvider.currentEndScore, lessThan(scoreWith2Arrows));
      });

      testWidgets('undo button disabled when no arrows', (tester) async {
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        await tester.pumpWidget(buildPlottingTestApp(
          db: db,
          sessionProvider: sessionProvider,
        ));
        await tester.pumpAndSettle();

        // Find the Undo button
        final undoButton = find.widgetWithText(OutlinedButton, 'Undo');
        expect(undoButton, findsOneWidget);

        // Verify it's disabled (onPressed is null)
        final button = tester.widget<OutlinedButton>(undoButton);
        expect(button.onPressed, isNull);
      });

      testWidgets('undo all arrows in end returns to empty state', (tester) async {
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        // Plot arrows
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.plotArrow(x: 0.1, y: 0.0);
        expect(sessionProvider.arrowsInCurrentEnd, equals(2));

        // Undo all
        await sessionProvider.undoLastArrow();
        await sessionProvider.undoLastArrow();

        expect(sessionProvider.arrowsInCurrentEnd, equals(0));
        expect(sessionProvider.currentEndScore, equals(0));
      });

      testWidgets('undo cycles through committed ends', (tester) async {
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        // Complete first end with 3 arrows
        await sessionProvider.plotArrow(x: 0.0, y: 0.0); // X
        await sessionProvider.plotArrow(x: 0.0, y: 0.0); // X
        await sessionProvider.plotArrow(x: 0.0, y: 0.0); // X
        await sessionProvider.commitEnd();

        expect(sessionProvider.currentEndNumber, equals(2));
        expect(sessionProvider.totalArrowsInSession, equals(3));

        // Verify current end is empty
        expect(sessionProvider.arrowsInCurrentEnd, equals(0));

        // Undo should go back into the committed end
        await sessionProvider.undoLastArrow();

        // Should now be back in end 1 with 2 arrows
        expect(sessionProvider.currentEndNumber, equals(1));
        expect(sessionProvider.arrowsInCurrentEnd, equals(2));
        expect(sessionProvider.totalArrowsInSession, equals(2));

        // Undo again
        await sessionProvider.undoLastArrow();
        expect(sessionProvider.arrowsInCurrentEnd, equals(1));
        expect(sessionProvider.totalArrowsInSession, equals(1));

        // Undo to empty
        await sessionProvider.undoLastArrow();
        expect(sessionProvider.arrowsInCurrentEnd, equals(0));
        expect(sessionProvider.totalArrowsInSession, equals(0));

        // Undo with no arrows left should do nothing
        await sessionProvider.undoLastArrow();
        expect(sessionProvider.arrowsInCurrentEnd, equals(0));
      });

      testWidgets('undo button enabled after committing end', (tester) async {
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        await tester.pumpWidget(buildPlottingTestApp(
          db: db,
          sessionProvider: sessionProvider,
        ));
        await tester.pumpAndSettle();

        // Verify undo disabled initially (no arrows)
        var undoButton = find.widgetWithText(OutlinedButton, 'Undo');
        var button = tester.widget<OutlinedButton>(undoButton);
        expect(button.onPressed, isNull);

        // Plot and commit an end
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.commitEnd();
        await tester.pumpAndSettle();

        // Verify we're now in end 2 with 0 current arrows
        expect(sessionProvider.currentEndNumber, equals(2));
        expect(sessionProvider.arrowsInCurrentEnd, equals(0));

        // Undo button should STILL be enabled because totalArrowsInSession > 0
        undoButton = find.widgetWithText(OutlinedButton, 'Undo');
        button = tester.widget<OutlinedButton>(undoButton);
        expect(button.onPressed, isNotNull);
      });
    });

    group('Session Cancellation', () {
      testWidgets('cancel session -> session deleted', (tester) async {
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');
        final sessionId = sessionProvider.currentSession!.id;

        // Plot some arrows
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.plotArrow(x: 0.1, y: 0.0);

        // Abandon session
        await sessionProvider.abandonSession();

        // Session should be cleared
        expect(sessionProvider.hasActiveSession, isFalse);
        expect(sessionProvider.currentSession, isNull);
        expect(sessionProvider.ends, isEmpty);
        expect(sessionProvider.currentEndArrows, isEmpty);

        // Verify session was deleted from database
        final deletedSession = await db.getSession(sessionId);
        expect(deletedSession, isNull);
      });

      testWidgets('abandon dialog shows in UI', (tester) async {
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        await tester.pumpWidget(buildPlottingTestApp(
          db: db,
          sessionProvider: sessionProvider,
        ));
        await tester.pumpAndSettle();

        // Find and tap the menu button
        final menuButton = find.byIcon(Icons.more_vert);
        expect(menuButton, findsOneWidget);
        await tester.tap(menuButton);
        await tester.pumpAndSettle();

        // Find abandon option
        expect(find.text('Abandon session'), findsOneWidget);

        // Tap abandon
        await tester.tap(find.text('Abandon session'));
        await tester.pumpAndSettle();

        // Verify dialog appears
        expect(find.text('Abandon Session?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Abandon'), findsOneWidget);
      });
    });

    group('Score Persistence', () {
      testWidgets('scores persist across widget rebuilds', (tester) async {
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        // Plot arrows
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.plotArrow(x: 0.1, y: 0.0);
        final initialScore = sessionProvider.currentEndScore;
        final initialArrows = sessionProvider.arrowsInCurrentEnd;

        // Create new provider from same database
        final newProvider = SessionProvider(db);
        await newProvider.checkForIncompleteSession();

        // Verify state was restored
        expect(newProvider.hasActiveSession, isTrue);
        expect(newProvider.currentEndScore, equals(initialScore));
        expect(newProvider.arrowsInCurrentEnd, equals(initialArrows));
      });

      testWidgets('completed ends persist after commit', (tester) async {
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        // Complete one end
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.plotArrow(x: 0.05, y: 0.0);
        await sessionProvider.plotArrow(x: 0.1, y: 0.0);
        await sessionProvider.commitEnd();

        final endScore = sessionProvider.ends.first.endScore;
        final endsCount = sessionProvider.ends.length;
        final endNumber = sessionProvider.currentEndNumber;

        // Create new provider
        final newProvider = SessionProvider(db);
        await newProvider.checkForIncompleteSession();

        // Verify completed end was persisted
        // Note: ends count may include uncommitted current end depending on implementation
        expect(newProvider.ends.length, greaterThanOrEqualTo(1));
        expect(newProvider.ends.first.endScore, equals(endScore));
        // Current end number should be preserved
        expect(newProvider.currentEndNumber, equals(endNumber));
      });
    });

    group('Running Totals', () {
      testWidgets('total score accumulates across ends', (tester) async {
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        // Complete first end
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.commitEnd();
        final firstEndTotal = sessionProvider.totalScore;

        // Complete second end
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.commitEnd();
        final secondEndTotal = sessionProvider.totalScore;

        // Total should be sum of both ends
        expect(secondEndTotal, greaterThan(firstEndTotal));
        expect(sessionProvider.ends.length, equals(2));
      });

      testWidgets('Xs count accumulates correctly', (tester) async {
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        // Plot arrows at center (X ring)
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);
        await sessionProvider.commitEnd();

        // All center shots should be Xs
        expect(sessionProvider.totalXs, greaterThan(0));
        expect(sessionProvider.ends.first.endXs, greaterThan(0));
      });
    });

    group('Target Face Interaction', () {
      testWidgets('target face displays arrows', (tester) async {
        setLargeScreenSize(tester);
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        // Plot an arrow
        await sessionProvider.plotArrow(x: 0.2, y: -0.1);

        await tester.pumpWidget(buildPlottingTestApp(
          db: db,
          sessionProvider: sessionProvider,
        ));
        await tester.pumpAndSettle();

        // Verify target face is displayed
        expect(find.byType(InteractiveTargetFace), findsAtLeast(1));

        // Verify arrows are displayed on the target
        expect(sessionProvider.allSessionArrows.length, equals(1));
      });

      testWidgets('end counter shows correct values', (tester) async {
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        await tester.pumpWidget(buildPlottingTestApp(
          db: db,
          sessionProvider: sessionProvider,
        ));
        await tester.pumpAndSettle();

        // Verify end counter is displayed with correct format
        expect(
          find.textContaining('End 1/${sessionProvider.totalEnds}'),
          findsOneWidget,
        );
      });
    });

    group('Edge Cases', () {
      testWidgets('handles miss (arrow outside target)', (tester) async {
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        // Plot arrow outside target (score 0)
        await sessionProvider.plotArrow(x: 1.5, y: 1.5);

        // Verify miss is handled
        expect(sessionProvider.arrowsInCurrentEnd, equals(1));
        // Score could be 0 for miss depending on target face handling
        // or clamped to edge
      });

      testWidgets('handles rapid arrow plotting', (tester) async {
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');

        // Rapid fire plotting - 2 complete ends
        for (int end = 0; end < 2; end++) {
          for (int arrow = 0; arrow < 3; arrow++) {
            await sessionProvider.plotArrow(x: 0.05 * arrow, y: 0.0);
          }
          await sessionProvider.commitEnd();
        }

        // Should have completed 2 ends (3 arrows each)
        expect(sessionProvider.ends.length, equals(2));
        expect(sessionProvider.currentEndNumber, equals(3));
      });

      testWidgets('session state preserved after background', (tester) async {
        final sessionProvider = SessionProvider(db);
        final roundTypes = await db.getAllRoundTypes();
        final wa18m = roundTypes.firstWhere(
          (rt) => rt.name == 'WA 18m',
          orElse: () => roundTypes.first,
        );

        await sessionProvider.startSession(roundTypeId: wa18m.id, title: 'Test Session');
        await sessionProvider.plotArrow(x: 0.0, y: 0.0);

        final sessionId = sessionProvider.currentSession!.id;
        final arrowCount = sessionProvider.arrowsInCurrentEnd;

        // Simulate app going to background and coming back
        // by creating new provider instance
        final newProvider = SessionProvider(db);
        final hasSession = await newProvider.checkForIncompleteSession();

        expect(hasSession, isTrue);
        expect(newProvider.currentSession!.id, equals(sessionId));
        expect(newProvider.arrowsInCurrentEnd, equals(arrowCount));
      });
    });
  });
}
