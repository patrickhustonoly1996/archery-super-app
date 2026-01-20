/// Integration tests for the bow training flow.
///
/// Tests the core UX flow: navigate to bow training -> select exercise ->
/// start session -> timer updates -> pause/resume -> complete session.
///
/// Uses fake_async for timer testing and mock database for isolation.
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';

import 'package:archery_super_app/providers/bow_training_provider.dart';
import 'package:archery_super_app/db/database.dart';
import 'package:archery_super_app/screens/bow_training_screen.dart';
import 'package:archery_super_app/screens/bow_training_home_screen.dart';
import 'package:archery_super_app/theme/app_theme.dart';
import 'package:archery_super_app/providers/accessibility_provider.dart';

// =============================================================================
// MOCK CLASSES
// =============================================================================

class MockAppDatabase extends Mock implements AppDatabase {}

class MockOlySessionTemplate extends Mock implements OlySessionTemplate {
  @override
  final String id;
  @override
  final String version;
  @override
  final String name;
  @override
  final int durationMinutes;
  @override
  final String? focus;

  MockOlySessionTemplate({
    this.id = 'template_1',
    this.version = '1.0',
    this.name = 'Test Session 1.0',
    this.durationMinutes = 10,
    this.focus = 'Test focus',
  });
}

class MockOlySessionExercise extends Mock implements OlySessionExercise {
  @override
  final String id;
  @override
  final String sessionTemplateId;
  @override
  final String exerciseTypeId;
  @override
  final int exerciseOrder;
  @override
  final int reps;
  @override
  final int workSeconds;
  @override
  final int restSeconds;
  @override
  final String? details;
  @override
  final double? intensityOverride;

  MockOlySessionExercise({
    this.id = 'exercise_1',
    this.sessionTemplateId = 'template_1',
    this.exerciseTypeId = 'type_1',
    this.exerciseOrder = 1,
    this.reps = 3,
    this.workSeconds = 5,
    this.restSeconds = 3,
    this.details,
    this.intensityOverride,
  });
}

class MockOlyExerciseType extends Mock implements OlyExerciseType {
  @override
  final String id;
  @override
  final String name;
  @override
  final double intensity;
  @override
  final String? description;
  @override
  final String category;
  @override
  final String? firstIntroducedAt;
  @override
  final int sortOrder;

  MockOlyExerciseType({
    this.id = 'type_1',
    this.name = 'Test Exercise',
    this.intensity = 1.0,
    this.description,
    this.category = 'static',
    this.firstIntroducedAt,
    this.sortOrder = 0,
  });
}

class MockUserTrainingProgressData extends Mock
    implements UserTrainingProgressData {
  @override
  final String currentLevel;
  @override
  final int totalSessionsCompleted;

  MockUserTrainingProgressData({
    this.currentLevel = '1.0',
    this.totalSessionsCompleted = 5,
  });
}

class MockOlyTrainingLog extends Mock implements OlyTrainingLog {
  @override
  final String id;
  @override
  final String? sessionTemplateId;
  @override
  final String sessionVersion;
  @override
  final String sessionName;
  @override
  final int plannedDurationSeconds;
  @override
  final int actualDurationSeconds;
  @override
  final int plannedExercises;
  @override
  final int completedExercises;
  @override
  final int totalHoldSeconds;
  @override
  final int totalRestSeconds;
  @override
  final int? feedbackShaking;
  @override
  final int? feedbackStructure;
  @override
  final int? feedbackRest;
  @override
  final String? progressionSuggestion;
  @override
  final String? suggestedNextVersion;
  @override
  final String? notes;
  @override
  final DateTime startedAt;
  @override
  final DateTime completedAt;

  MockOlyTrainingLog({
    this.id = 'log_1',
    this.sessionTemplateId,
    this.sessionVersion = '1.0',
    this.sessionName = 'Test Session',
    this.plannedDurationSeconds = 600,
    this.actualDurationSeconds = 580,
    this.plannedExercises = 10,
    this.completedExercises = 10,
    this.totalHoldSeconds = 300,
    this.totalRestSeconds = 280,
    this.feedbackShaking,
    this.feedbackStructure,
    this.feedbackRest,
    this.progressionSuggestion,
    this.suggestedNextVersion,
    this.notes,
    DateTime? startedAt,
    DateTime? completedAt,
  })  : startedAt = startedAt ?? DateTime.now().subtract(const Duration(minutes: 10)),
        completedAt = completedAt ?? DateTime.now();
}

// Fake classes for mocktail fallbacks
class FakeOlyTrainingLogsCompanion extends Fake
    implements OlyTrainingLogsCompanion {}

// =============================================================================
// TEST HELPERS
// =============================================================================

/// Creates a test BowTrainingProvider with mocked database
BowTrainingProvider createTestProvider(MockAppDatabase db) {
  return BowTrainingProvider(db);
}

/// Builds test widget tree with provider
Widget buildTestApp({
  required BowTrainingProvider provider,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BowTrainingProvider>.value(value: provider),
      ChangeNotifierProvider(create: (_) => AccessibilityProvider()..loadSettings()),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

/// Sets up mock database with standard training data
void setupMockDatabase(MockAppDatabase db) {
  // Mock database methods
  when(() => db.ensureUserTrainingProgressExists()).thenAnswer((_) async {});
  when(() => db.ensureOlyTrainingDataExists()).thenAnswer((_) async {});
  when(() => db.getPreference(any())).thenAnswer((_) async => null);
  when(() => db.getAllOlyTrainingLogs()).thenAnswer((_) async => []);
  when(() => db.getAllOlySessionTemplates()).thenAnswer((_) async => [
        MockOlySessionTemplate(id: 'template_1', version: '1.0', name: 'Session 1.0'),
        MockOlySessionTemplate(id: 'template_2', version: '1.1', name: 'Session 1.1'),
        MockOlySessionTemplate(id: 'template_3', version: '2.0', name: 'Session 2.0'),
      ]);
  when(() => db.getRecentOlyTrainingLogs(limit: any(named: 'limit')))
      .thenAnswer((_) async => []);
  when(() => db.getUserTrainingProgress()).thenAnswer((_) async =>
      MockUserTrainingProgressData(currentLevel: '1.0', totalSessionsCompleted: 5));
  when(() => db.getAllOlyExerciseTypes()).thenAnswer((_) async => [
        MockOlyExerciseType(id: 'type_1', name: 'Hold at Draw'),
        MockOlyExerciseType(id: 'type_2', name: 'SPT Draw'),
      ]);
  when(() => db.getOlySessionExercises(any())).thenAnswer((_) async => [
        MockOlySessionExercise(
          id: 'ex_1',
          reps: 3,
          workSeconds: 5,
          restSeconds: 3,
          exerciseTypeId: 'type_1',
        ),
        MockOlySessionExercise(
          id: 'ex_2',
          reps: 2,
          workSeconds: 4,
          restSeconds: 2,
          exerciseTypeId: 'type_2',
        ),
      ]);
  when(() => db.insertOlyTrainingLog(any())).thenAnswer((_) async => 1);
  when(() => db.updateProgressAfterSession(
        completedVersion: any(named: 'completedVersion'),
        suggestedNextVersion: any(named: 'suggestedNextVersion'),
        progressionSuggestion: any(named: 'progressionSuggestion'),
      )).thenAnswer((_) async {});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeOlyTrainingLogsCompanion());
  });

  group('Bow Training Flow Integration Tests', () {
    late MockAppDatabase db;
    late BowTrainingProvider provider;

    setUp(() {
      db = MockAppDatabase();
      setupMockDatabase(db);
      provider = createTestProvider(db);
    });

    tearDown(() {
      provider.dispose();
    });

    group('Navigation and Session Selection', () {
      testWidgets('navigate to bow training -> select exercise -> start session',
          (tester) async {
        // Use larger screen size to avoid overflow errors
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await provider.loadData();

        await tester.pumpWidget(buildTestApp(
          provider: provider,
          child: const BowTrainingScreen(),
        ));
        await tester.pumpAndSettle();

        // Verify session selection screen is shown (intro screen)
        expect(find.text('Bow Training'), findsOneWidget);
        expect(find.text('Duration'), findsOneWidget);

        // Find and tap a preset session from the provider
        final templates = provider.sessionTemplates;
        expect(templates.isNotEmpty, isTrue);

        // Start session programmatically (simulating tap)
        provider.startSession(templates.first);
        await tester.pumpAndSettle();

        // Verify timer view is displayed
        expect(provider.isActive, isTrue);
        expect(provider.phase, equals(TimerPhase.prep));
        expect(find.text('Get Ready'), findsOneWidget);

        // Clean up - cancel session to stop timer
        provider.cancelSession();
      });

      testWidgets('quick session builder starts custom session', (tester) async {
        // Use larger screen size to avoid overflow errors
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await provider.loadData();

        await tester.pumpWidget(buildTestApp(
          provider: provider,
          child: const BowTrainingScreen(),
        ));
        await tester.pumpAndSettle();

        // Start a custom session
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );
        provider.startCustomSession(config);
        await tester.pumpAndSettle();

        // Verify custom session is active
        expect(provider.isActive, isTrue);
        expect(provider.isCustomSession, isTrue);
        expect(provider.customTotalReps, equals(5)); // 5 min / 60 sec cycle = 5 reps

        // Clean up - cancel session to stop timer
        provider.cancelSession();
      });
    });

    group('Timer Display Updates During Hold Phase', () {
      testWidgets('timer display updates during hold phase', (tester) async {
        fakeAsync((async) {
          // Start a custom session for predictable timing
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Verify prep phase
          expect(provider.phase, equals(TimerPhase.prep));
          expect(provider.secondsRemaining, equals(kPrepCountdownSeconds));

          // Advance through prep phase
          async.elapse(Duration(seconds: kPrepCountdownSeconds));

          // Should now be in hold phase
          expect(provider.phase, equals(TimerPhase.hold));
          expect(provider.secondsRemaining, equals(30)); // 30:30 ratio

          // Advance time and verify countdown
          async.elapse(const Duration(seconds: 5));
          expect(provider.secondsRemaining, equals(25));

          async.elapse(const Duration(seconds: 10));
          expect(provider.secondsRemaining, equals(15));

          // Verify formatted time displays correctly
          expect(provider.formattedTime, equals('00:15'));
        });
      });

      testWidgets('phase progress updates correctly', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Skip prep
          async.elapse(Duration(seconds: kPrepCountdownSeconds));

          // At start of hold, progress should be 0
          expect(provider.phaseProgress, closeTo(0.0, 0.05));

          // At halfway, progress should be ~0.5
          async.elapse(const Duration(seconds: 15));
          expect(provider.phaseProgress, closeTo(0.5, 0.05));

          // Near end, progress should be ~1.0
          async.elapse(const Duration(seconds: 14));
          expect(provider.phaseProgress, closeTo(0.97, 0.05));
        });
      });

      testWidgets('hold time is tracked correctly', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Skip prep
          async.elapse(Duration(seconds: kPrepCountdownSeconds));

          // Track hold time during hold phase
          async.elapse(const Duration(seconds: 30));

          // Hold time should be tracked
          expect(provider.totalHoldSecondsActual, equals(30));
        });
      });
    });

    group('Rest Phase Shows Correct UI', () {
      testWidgets('rest phase shows correct UI after hold completes',
          (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Skip prep
          async.elapse(Duration(seconds: kPrepCountdownSeconds));

          // Complete first hold
          async.elapse(const Duration(seconds: 30));

          // Should now be in rest phase
          expect(provider.phase, equals(TimerPhase.rest));
          expect(provider.secondsRemaining, equals(30)); // 30 sec rest
          expect(provider.phaseDisplayName, equals('Rest'));
        });
      });

      testWidgets('rest phase transitions back to hold', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Skip prep and first hold
          async.elapse(Duration(seconds: kPrepCountdownSeconds + 30));

          // Complete rest
          async.elapse(const Duration(seconds: 30));

          // Should be back in hold phase for rep 2
          expect(provider.phase, equals(TimerPhase.hold));
          expect(provider.customRep, equals(2));
        });
      });
    });

    group('Pause Button Pauses Timer and Shows Paused State', () {
      testWidgets('pause button pauses timer', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Skip prep
          async.elapse(Duration(seconds: kPrepCountdownSeconds));

          // Verify running state
          expect(provider.timerState, equals(TimerState.running));
          expect(provider.secondsRemaining, equals(30));

          // Advance a bit
          async.elapse(const Duration(seconds: 5));
          expect(provider.secondsRemaining, equals(25));

          // Pause the timer
          provider.pauseTimer();

          expect(provider.timerState, equals(TimerState.paused));

          // Verify time doesn't advance when paused
          async.elapse(const Duration(seconds: 10));
          expect(provider.secondsRemaining, equals(25)); // Still 25
        });
      });

      testWidgets('paused state is reflected in provider', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Pause
          provider.pauseTimer();

          expect(provider.timerState, equals(TimerState.paused));
          expect(provider.isActive, isTrue); // Still active, just paused
        });
      });

      testWidgets('pause during different phases works', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Pause during prep
          provider.pauseTimer();
          expect(provider.timerState, equals(TimerState.paused));
          expect(provider.phase, equals(TimerPhase.prep));

          // Resume
          provider.resumeTimer();

          // Skip to rest phase
          async.elapse(Duration(seconds: kPrepCountdownSeconds + 30));

          // Pause during rest
          provider.pauseTimer();
          expect(provider.timerState, equals(TimerState.paused));
          expect(provider.phase, equals(TimerPhase.rest));
        });
      });
    });

    group('Resume Button Continues Session', () {
      testWidgets('resume button continues session from paused state',
          (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Skip prep
          async.elapse(Duration(seconds: kPrepCountdownSeconds));

          // Advance and pause
          async.elapse(const Duration(seconds: 10));
          final timeBeforePause = provider.secondsRemaining;
          provider.pauseTimer();

          // Wait while paused
          async.elapse(const Duration(seconds: 5));
          expect(provider.secondsRemaining, equals(timeBeforePause));

          // Resume
          provider.resumeTimer();
          expect(provider.timerState, equals(TimerState.running));

          // Verify timer continues
          async.elapse(const Duration(seconds: 5));
          expect(provider.secondsRemaining, equals(timeBeforePause - 5));
        });
      });

      testWidgets('multiple pause/resume cycles work correctly', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Skip prep
          async.elapse(Duration(seconds: kPrepCountdownSeconds));

          // First pause/resume cycle
          async.elapse(const Duration(seconds: 5));
          provider.pauseTimer();
          async.elapse(const Duration(seconds: 3));
          provider.resumeTimer();

          // Second pause/resume cycle
          async.elapse(const Duration(seconds: 5));
          provider.pauseTimer();
          async.elapse(const Duration(seconds: 3));
          provider.resumeTimer();

          // Verify correct time elapsed (10 seconds of actual running)
          expect(provider.secondsRemaining, equals(20));
        });
      });
    });

    group('Complete Session Shows Summary/Completion Screen', () {
      testWidgets('completing all reps shows completion phase', (tester) async {
        fakeAsync((async) {
          // Use short session for faster test
          const config = CustomSessionConfig(
            durationMinutes: 1, // 1 rep at 30:30
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Skip prep
          async.elapse(Duration(seconds: kPrepCountdownSeconds));

          // Complete the single hold (since it's 1 min, only 1 rep)
          async.elapse(const Duration(seconds: 30));

          // Session should be complete
          expect(provider.phase, equals(TimerPhase.complete));
          expect(provider.timerState, equals(TimerState.stopped));
        });
      });

      testWidgets('completion screen shows correct stats', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 1,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Complete session
          async.elapse(Duration(seconds: kPrepCountdownSeconds + 30));

          // Verify completion stats
          expect(provider.phase, equals(TimerPhase.complete));
          expect(provider.completedExercisesCount, equals(1)); // 1 rep completed
          expect(provider.totalHoldSecondsActual, equals(30));
        });
      });

      testWidgets('OLY session completion shows exercise completion count',
          (tester) async {
        fakeAsync((async) async {
          await provider.loadData();
          final template = provider.sessionTemplates.first;
          await provider.startSession(template);

          // Skip prep
          async.elapse(Duration(seconds: kPrepCountdownSeconds));

          // Exercise 1: 3 reps x (5s hold + 3s rest) = 24s total
          // Rep 1
          async.elapse(const Duration(seconds: 5)); // hold
          async.elapse(const Duration(seconds: 3)); // rest
          // Rep 2
          async.elapse(const Duration(seconds: 5)); // hold
          async.elapse(const Duration(seconds: 3)); // rest
          // Rep 3
          async.elapse(const Duration(seconds: 5)); // hold
          // After final rep, moves to exercise break

          // Exercise break (3 seconds)
          async.elapse(const Duration(seconds: 3));

          // Exercise 2: 2 reps x (4s hold + 2s rest)
          // Rep 1
          async.elapse(const Duration(seconds: 4)); // hold
          async.elapse(const Duration(seconds: 2)); // rest
          // Rep 2
          async.elapse(const Duration(seconds: 4)); // hold (final)

          // Session should be complete
          expect(provider.phase, equals(TimerPhase.complete));
          expect(provider.completedExercisesCount, equals(2)); // 2 exercises
        });
      });
    });

    group('Cancel Mid-Session Returns to Home', () {
      testWidgets('cancel session clears state', (tester) async {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );
        provider.startCustomSession(config);

        // Verify session is active
        expect(provider.isActive, isTrue);
        expect(provider.isCustomSession, isTrue);

        // Cancel session
        provider.cancelSession();

        // Verify state is cleared
        expect(provider.isActive, isFalse);
        expect(provider.phase, equals(TimerPhase.idle));
        expect(provider.timerState, equals(TimerState.stopped));
        expect(provider.isCustomSession, isFalse);
        expect(provider.customConfig, isNull);
      });

      testWidgets('cancel dialog is shown in UI', (tester) async {
        // Use larger screen size to avoid overflow errors
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await provider.loadData();

        await tester.pumpWidget(buildTestApp(
          provider: provider,
          child: const BowTrainingScreen(),
        ));

        // Start session
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );
        provider.startCustomSession(config);
        await tester.pumpAndSettle();

        // Verify Cancel button is visible in active timer view
        expect(find.text('Cancel'), findsOneWidget);

        // Clean up - cancel session to stop timer
        provider.cancelSession();
      });

      testWidgets('cancel mid-hold resets all tracking', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Skip prep and advance into hold
          async.elapse(Duration(seconds: kPrepCountdownSeconds + 15));

          // Verify some tracking occurred
          expect(provider.totalHoldSecondsActual, equals(15));

          // Cancel
          provider.cancelSession();

          // All tracking should be reset
          expect(provider.totalHoldSecondsActual, equals(0));
          expect(provider.secondsRemaining, equals(0));
          expect(provider.customRep, equals(0));
        });
      });
    });

    group('OLY Session Flow', () {
      testWidgets('OLY session loads exercises correctly', (tester) async {
        fakeAsync((async) async {
          await provider.loadData();
          final template = provider.sessionTemplates.first;
          await provider.startSession(template);

          expect(provider.isActive, isTrue);
          expect(provider.isCustomSession, isFalse);
          expect(provider.exercises.length, equals(2)); // 2 mock exercises
          expect(provider.totalExercises, equals(2));
        });
      });

      testWidgets('OLY session tracks exercise number correctly', (tester) async {
        fakeAsync((async) async {
          await provider.loadData();
          final template = provider.sessionTemplates.first;
          await provider.startSession(template);

          expect(provider.currentExerciseNumber, equals(1));

          // Skip prep
          async.elapse(Duration(seconds: kPrepCountdownSeconds));

          // Complete first exercise (3 reps)
          for (int rep = 0; rep < 3; rep++) {
            async.elapse(const Duration(seconds: 5)); // hold
            if (rep < 2) {
              async.elapse(const Duration(seconds: 3)); // rest (except last rep)
            }
          }

          // Exercise break
          async.elapse(const Duration(seconds: 3));

          // Should now be on exercise 2
          expect(provider.currentExerciseNumber, equals(2));
        });
      });

      testWidgets('exercise break phase shows correctly', (tester) async {
        fakeAsync((async) async {
          await provider.loadData();
          final template = provider.sessionTemplates.first;
          await provider.startSession(template);

          // Skip prep
          async.elapse(Duration(seconds: kPrepCountdownSeconds));

          // Complete first exercise reps
          for (int rep = 0; rep < 3; rep++) {
            async.elapse(const Duration(seconds: 5)); // hold
            if (rep < 2) {
              async.elapse(const Duration(seconds: 3)); // rest
            }
          }

          // Should be in exercise break
          expect(provider.phase, equals(TimerPhase.exerciseBreak));
          expect(provider.phaseDisplayName, equals('Next Exercise'));
        });
      });
    });

    group('Session Progress', () {
      testWidgets('session progress updates correctly for custom session',
          (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 2, // 2 reps at 30:30
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          expect(provider.customTotalReps, equals(2));

          // Skip prep
          async.elapse(Duration(seconds: kPrepCountdownSeconds));

          // At start, progress is 0
          expect(provider.sessionProgress, closeTo(0.0, 0.01));

          // Complete first rep
          async.elapse(const Duration(seconds: 30)); // hold
          async.elapse(const Duration(seconds: 30)); // rest

          // After 1 of 2 reps, progress should be 0.5
          expect(provider.sessionProgress, closeTo(0.5, 0.01));
        });
      });

      testWidgets('rep counter updates during session', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 3, // 3 reps at 30:30
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          expect(provider.customRep, equals(1)); // Starts at rep 1

          // Skip prep and complete first cycle
          async.elapse(Duration(seconds: kPrepCountdownSeconds + 60));

          expect(provider.customRep, equals(2));

          // Complete second cycle
          async.elapse(const Duration(seconds: 60));

          expect(provider.customRep, equals(3));
        });
      });
    });

    group('Skip Phase', () {
      testWidgets('skip phase advances to next phase', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // In prep phase
          expect(provider.phase, equals(TimerPhase.prep));

          // Skip prep
          provider.skipPhase();

          // Should now be in hold
          expect(provider.phase, equals(TimerPhase.hold));
          expect(provider.secondsRemaining, equals(30));
        });
      });

      testWidgets('skip from hold goes to rest', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Skip prep
          async.elapse(Duration(seconds: kPrepCountdownSeconds));

          // In hold phase
          expect(provider.phase, equals(TimerPhase.hold));

          // Skip hold
          provider.skipPhase();

          // Should now be in rest
          expect(provider.phase, equals(TimerPhase.rest));
        });
      });
    });

    group('Movement Stimulus', () {
      testWidgets('movement cue is generated when stimulus is set',
          (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.lots, // Always show cues
          );
          provider.startCustomSession(config);

          // Skip prep to enter hold
          async.elapse(Duration(seconds: kPrepCountdownSeconds));

          // Movement cue should be generated during hold
          expect(provider.phase, equals(TimerPhase.hold));
          expect(provider.movementCue, isNotNull);
        });
      });

      testWidgets('no movement cue when stimulus is none', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Skip prep
          async.elapse(Duration(seconds: kPrepCountdownSeconds));

          expect(provider.movementCue, isNull);
        });
      });

      testWidgets('movement cue clears during rest', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.lots,
          );
          provider.startCustomSession(config);

          // Skip prep and complete hold
          async.elapse(Duration(seconds: kPrepCountdownSeconds + 30));

          // Should be in rest, cue should be cleared
          expect(provider.phase, equals(TimerPhase.rest));
          expect(provider.movementCue, isNull);
        });
      });
    });

    group('State Persistence', () {
      testWidgets('export state captures all session data', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.some,
          );
          provider.startCustomSession(config);

          // Skip prep
          async.elapse(Duration(seconds: kPrepCountdownSeconds));

          // Advance into hold
          async.elapse(const Duration(seconds: 10));

          final state = provider.exportState();

          expect(state, isNotNull);
          expect(state!['phase'], equals(TimerPhase.hold.index));
          expect(state['timerState'], equals(TimerState.running.index));
          expect(state['secondsRemaining'], equals(20));
          expect(state['isCustomSession'], isTrue);
          expect(state['customDurationMinutes'], equals(5));
        });
      });

      testWidgets('restore state resumes session correctly', (tester) async {
        fakeAsync((async) {
          // Start first session
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Skip prep and advance
          async.elapse(Duration(seconds: kPrepCountdownSeconds + 15));

          // Export state
          final state = provider.exportState()!;

          // Create new provider and restore
          final newProvider = createTestProvider(db);
          final restored = newProvider.restoreState(state);

          expect(restored, isTrue);
          expect(newProvider.phase, equals(TimerPhase.hold));
          expect(newProvider.secondsRemaining, equals(15));
          expect(newProvider.isCustomSession, isTrue);

          newProvider.dispose();
        });
      });
    });

    group('Paused Session Display', () {
      testWidgets('paused session title returns correct value', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          expect(provider.pausedSessionTitle, equals('Custom Session'));
        });
      });

      testWidgets('paused session subtitle shows rep progress', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          expect(provider.pausedSessionSubtitle, equals('1/5 reps'));
        });
      });
    });

    group('Edge Cases', () {
      testWidgets('pause when not running does nothing', (tester) async {
        // Provider not started
        provider.pauseTimer();
        expect(provider.timerState, equals(TimerState.stopped));
      });

      testWidgets('resume when not paused does nothing', (tester) async {
        fakeAsync((async) {
          const config = CustomSessionConfig(
            durationMinutes: 5,
            ratio: HoldRestRatio.ratio30_30,
            movementStimulus: MovementStimulus.none,
          );
          provider.startCustomSession(config);

          // Already running, resume should do nothing
          provider.resumeTimer();
          expect(provider.timerState, equals(TimerState.running));
        });
      });

      testWidgets('skip when stopped does nothing', (tester) async {
        provider.skipPhase();
        expect(provider.phase, equals(TimerPhase.idle));
      });

      testWidgets('cancel when not active has no effect', (tester) async {
        provider.cancelSession();
        expect(provider.isActive, isFalse);
        expect(provider.phase, equals(TimerPhase.idle));
      });
    });
  });
}
