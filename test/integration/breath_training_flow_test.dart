/// Integration tests for the breath training flow.
///
/// Tests the core UX flow for breath training sessions including:
/// - Navigation to breath training home and mode selection
/// - Breath hold: paced breathing -> hold -> recovery cycle
/// - Paced breathing: inhale/exhale cycle display
/// - Pause/resume functionality
/// - Session completion and stats display
///
/// Uses fake_async for timer testing and provider-based state management.
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:archery_super_app/providers/breath_training_provider.dart';
import 'package:archery_super_app/widgets/breathing_visualizer.dart';
import 'package:archery_super_app/theme/app_theme.dart';

// =============================================================================
// TEST HELPERS
// =============================================================================

/// Creates a test BreathTrainingProvider
BreathTrainingProvider createTestProvider() {
  return BreathTrainingProvider();
}

/// Builds test widget tree with provider
Widget buildTestApp({
  required BreathTrainingProvider provider,
  required Widget child,
}) {
  return ChangeNotifierProvider<BreathTrainingProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Breath Training Flow Integration Tests', () {
    late BreathTrainingProvider provider;

    setUp(() {
      provider = createTestProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    // =========================================================================
    // NAVIGATION AND MODE SELECTION
    // =========================================================================

    group('Navigation and Mode Selection', () {
      test('provider initializes in idle state', () {
        expect(provider.state, equals(BreathSessionState.idle));
        expect(provider.sessionType, isNull);
        expect(provider.isActive, isFalse);
      });

      test('can select breath hold mode', () {
        provider.startBreathHoldSession();

        expect(provider.sessionType, equals(BreathSessionType.breathHold));
        expect(provider.isActive, isTrue);
        expect(provider.state, equals(BreathSessionState.pacedBreathing));

        provider.stopSession();
      });

      test('can select paced breathing mode', () {
        provider.startPacedBreathingSession();

        expect(provider.sessionType, equals(BreathSessionType.pacedBreathing));
        expect(provider.isActive, isTrue);
        expect(provider.state, equals(BreathSessionState.pacedBreathing));

        provider.stopSession();
      });

      test('can select patrick breath (long exhale) mode', () {
        provider.startPatrickBreathSession();

        expect(provider.sessionType, equals(BreathSessionType.patrickBreath));
        expect(provider.isActive, isTrue);
        expect(provider.state, equals(BreathSessionState.exhaling));

        provider.stopSession();
      });
    });

    // =========================================================================
    // BREATH HOLD FLOW
    // =========================================================================

    group('Breath Hold: Start -> Timer Counts -> Hold -> Record Shown', () {
      test('breath hold starts with paced breathing phase', () {
        fakeAsync((async) {
          provider.startBreathHoldSession();

          expect(provider.state, equals(BreathSessionState.pacedBreathing));
          expect(provider.breathPhase, equals(BreathPhase.inhale));
          expect(provider.phaseSecondsRemaining, equals(4)); // inhale = 4s

          provider.stopSession();
        });
      });

      test('breath hold timer counts down during paced breathing', () {
        fakeAsync((async) {
          provider.startBreathHoldSession();

          expect(provider.phaseSecondsRemaining, equals(4));

          async.elapse(const Duration(seconds: 2));
          expect(provider.phaseSecondsRemaining, equals(2));

          async.elapse(const Duration(seconds: 2));
          // Should now switch to exhale
          expect(provider.breathPhase, equals(BreathPhase.exhale));
          expect(provider.phaseSecondsRemaining, equals(6)); // exhale = 6s

          provider.stopSession();
        });
      });

      test('breath hold transitions to hold phase after paced breaths', () {
        fakeAsync((async) {
          provider.startBreathHoldSession();

          // Paced breaths per cycle = 3 (inhale + exhale pairs)
          // Each cycle: 4s inhale + 6s exhale = 10s
          // Total: 3 cycles * 10s = 30s

          // Complete 3 breathing cycles
          for (int i = 0; i < 3; i++) {
            async.elapse(const Duration(seconds: 4)); // inhale
            async.elapse(const Duration(seconds: 6)); // exhale
          }

          // Should now be in holding phase
          expect(provider.state, equals(BreathSessionState.holding));
          expect(provider.breathPhase, equals(BreathPhase.hold));
          expect(provider.phaseSecondsRemaining, equals(provider.currentHoldTarget));

          provider.stopSession();
        });
      });

      test('breath hold time is tracked during hold phase', () {
        fakeAsync((async) {
          provider.startBreathHoldSession();

          // Complete paced breathing to enter hold
          for (int i = 0; i < 3; i++) {
            async.elapse(const Duration(seconds: 4)); // inhale
            async.elapse(const Duration(seconds: 6)); // exhale
          }

          expect(provider.state, equals(BreathSessionState.holding));
          expect(provider.totalHoldTime, equals(0));

          // Hold for 5 seconds
          async.elapse(const Duration(seconds: 5));
          expect(provider.totalHoldTime, equals(5));

          // Hold for another 5 seconds
          async.elapse(const Duration(seconds: 5));
          expect(provider.totalHoldTime, equals(10));

          provider.stopSession();
        });
      });

      test('breath hold round completes when hold timer expires', () {
        fakeAsync((async) {
          provider.baseHoldDuration = 5; // Short hold for testing
          provider.totalRounds = 2;
          provider.startBreathHoldSession();

          // Complete paced breathing
          for (int i = 0; i < 3; i++) {
            async.elapse(const Duration(seconds: 4)); // inhale
            async.elapse(const Duration(seconds: 6)); // exhale
          }

          expect(provider.state, equals(BreathSessionState.holding));
          expect(provider.currentRound, equals(0));

          // Complete hold
          async.elapse(Duration(seconds: provider.currentHoldTarget));

          // Should transition to recovery
          expect(provider.state, equals(BreathSessionState.recovery));
          expect(provider.currentRound, equals(1));

          provider.stopSession();
        });
      });

      test('breath hold shows total hold time on completion', () {
        fakeAsync((async) {
          provider.baseHoldDuration = 5;
          provider.totalRounds = 1; // Single round for quick test
          provider.startBreathHoldSession();

          // Complete paced breathing
          for (int i = 0; i < 3; i++) {
            async.elapse(const Duration(seconds: 4));
            async.elapse(const Duration(seconds: 6));
          }

          // Complete hold
          async.elapse(Duration(seconds: provider.currentHoldTarget));

          // Should be complete
          expect(provider.state, equals(BreathSessionState.complete));
          expect(provider.totalHoldTime, equals(5));
          expect(provider.secondaryText, contains('Total hold time: 5s'));
        });
      });
    });

    // =========================================================================
    // PACED BREATHING FLOW
    // =========================================================================

    group('Paced Breathing: Phase Indicator Shows Inhale/Hold/Exhale Cycle', () {
      test('paced breathing starts in inhale phase', () {
        fakeAsync((async) {
          provider.startPacedBreathingSession();

          expect(provider.state, equals(BreathSessionState.pacedBreathing));
          expect(provider.breathPhase, equals(BreathPhase.inhale));
          expect(provider.phaseSecondsRemaining, equals(4));

          provider.stopSession();
        });
      });

      test('paced breathing alternates between inhale and exhale', () {
        fakeAsync((async) {
          provider.startPacedBreathingSession();

          // Start in inhale
          expect(provider.breathPhase, equals(BreathPhase.inhale));

          // Complete inhale
          async.elapse(const Duration(seconds: 4));
          expect(provider.breathPhase, equals(BreathPhase.exhale));
          expect(provider.phaseSecondsRemaining, equals(6));

          // Complete exhale
          async.elapse(const Duration(seconds: 6));
          expect(provider.breathPhase, equals(BreathPhase.inhale));
          expect(provider.phaseSecondsRemaining, equals(4));

          provider.stopSession();
        });
      });

      test('paced breathing status text reflects current phase', () {
        fakeAsync((async) {
          provider.startPacedBreathingSession();

          expect(provider.statusText, equals('Breathe In'));

          async.elapse(const Duration(seconds: 4));
          expect(provider.statusText, equals('Breathe Out'));

          async.elapse(const Duration(seconds: 6));
          expect(provider.statusText, equals('Breathe In'));

          provider.stopSession();
        });
      });

      test('paced breathing tracks elapsed time', () {
        fakeAsync((async) {
          provider.pacedDurationMinutes = 1; // 1 minute session
          provider.startPacedBreathingSession();

          expect(provider.elapsedPacedSeconds, equals(0));

          async.elapse(const Duration(seconds: 10));
          expect(provider.elapsedPacedSeconds, equals(10));

          async.elapse(const Duration(seconds: 20));
          expect(provider.elapsedPacedSeconds, equals(30));

          provider.stopSession();
        });
      });

      test('paced breathing completes after duration expires', () {
        fakeAsync((async) {
          provider.pacedDurationMinutes = 1; // 1 minute session
          provider.startPacedBreathingSession();

          // Run for full minute
          async.elapse(const Duration(seconds: 60));

          expect(provider.state, equals(BreathSessionState.complete));
        });
      });

      test('paced breathing secondary text shows remaining time', () {
        fakeAsync((async) {
          provider.pacedDurationMinutes = 2;
          provider.startPacedBreathingSession();

          // At start, 2 minutes remaining
          expect(provider.secondaryText, contains('2:00 remaining'));

          async.elapse(const Duration(seconds: 30));
          expect(provider.secondaryText, contains('1:30 remaining'));

          async.elapse(const Duration(seconds: 60));
          expect(provider.secondaryText, contains('0:30 remaining'));

          provider.stopSession();
        });
      });
    });

    // =========================================================================
    // PAUSE FUNCTIONALITY
    // =========================================================================

    group('Pause Functionality During Session', () {
      test('pause for navigation stops timer without resetting state', () {
        fakeAsync((async) {
          provider.startBreathHoldSession();

          // Advance a bit
          async.elapse(const Duration(seconds: 2));
          expect(provider.phaseSecondsRemaining, equals(2));

          // Pause
          provider.pauseForNavigation();

          // Time should not advance while paused
          async.elapse(const Duration(seconds: 5));
          expect(provider.phaseSecondsRemaining, equals(2)); // Unchanged

          // State should still be active (not reset)
          expect(provider.state, equals(BreathSessionState.pacedBreathing));
        });
      });

      test('resume session continues from paused state', () {
        fakeAsync((async) {
          provider.startBreathHoldSession();

          async.elapse(const Duration(seconds: 2));
          provider.pauseForNavigation();

          final timeBeforePause = provider.phaseSecondsRemaining;

          // Resume
          provider.resumeSession();

          // Timer should continue
          async.elapse(const Duration(seconds: 1));
          expect(provider.phaseSecondsRemaining, equals(timeBeforePause - 1));

          provider.stopSession();
        });
      });

      test('pause works during hold phase', () {
        fakeAsync((async) {
          provider.baseHoldDuration = 10;
          provider.startBreathHoldSession();

          // Complete paced breathing to enter hold
          for (int i = 0; i < 3; i++) {
            async.elapse(const Duration(seconds: 4));
            async.elapse(const Duration(seconds: 6));
          }

          expect(provider.state, equals(BreathSessionState.holding));

          // Advance into hold
          async.elapse(const Duration(seconds: 3));
          final holdTimeBeforePause = provider.totalHoldTime;
          final remainingBeforePause = provider.phaseSecondsRemaining;

          // Pause
          provider.pauseForNavigation();

          // Time should freeze
          async.elapse(const Duration(seconds: 5));
          expect(provider.totalHoldTime, equals(holdTimeBeforePause));
          expect(provider.phaseSecondsRemaining, equals(remainingBeforePause));

          provider.stopSession();
        });
      });

      test('pause works during paced breathing session', () {
        fakeAsync((async) {
          provider.pacedDurationMinutes = 2;
          provider.startPacedBreathingSession();

          async.elapse(const Duration(seconds: 15));
          final elapsedBeforePause = provider.elapsedPacedSeconds;

          provider.pauseForNavigation();

          async.elapse(const Duration(seconds: 10));
          expect(provider.elapsedPacedSeconds, equals(elapsedBeforePause));

          provider.stopSession();
        });
      });

      test('pause works during patrick breath session', () {
        fakeAsync((async) {
          provider.startPatrickBreathSession();

          async.elapse(const Duration(seconds: 5));
          final exhaleBeforePause = provider.patrickExhaleSeconds;

          provider.pauseForNavigation();

          async.elapse(const Duration(seconds: 5));
          expect(provider.patrickExhaleSeconds, equals(exhaleBeforePause));

          provider.stopSession();
        });
      });
    });

    // =========================================================================
    // SESSION COMPLETION STATS
    // =========================================================================

    group('Complete Session Shows Stats', () {
      test('breath hold completion shows total hold time', () {
        fakeAsync((async) {
          provider.baseHoldDuration = 5;
          provider.totalRounds = 1;
          provider.startBreathHoldSession();

          // Complete paced breathing
          for (int i = 0; i < 3; i++) {
            async.elapse(const Duration(seconds: 4));
            async.elapse(const Duration(seconds: 6));
          }

          // Complete hold
          async.elapse(const Duration(seconds: 5));

          expect(provider.state, equals(BreathSessionState.complete));
          expect(provider.totalHoldTime, equals(5));
          expect(provider.statusText, equals('Complete'));
          expect(provider.secondaryText, equals('Total hold time: 5s'));
        });
      });

      test('breath hold multi-round completion tracks cumulative hold time', () {
        fakeAsync((async) {
          provider.baseHoldDuration = 5;
          provider.totalRounds = 2;
          provider.difficulty = BreathDifficulty.beginner; // +10% per round
          provider.startBreathHoldSession();

          // Round 1: paced + hold (5s)
          for (int i = 0; i < 3; i++) {
            async.elapse(const Duration(seconds: 4));
            async.elapse(const Duration(seconds: 6));
          }
          async.elapse(const Duration(seconds: 5));

          expect(provider.state, equals(BreathSessionState.recovery));
          expect(provider.currentRound, equals(1));

          // Recovery breaths (4 cycles)
          for (int i = 0; i < 4; i++) {
            async.elapse(const Duration(seconds: 4));
            async.elapse(const Duration(seconds: 6));
          }

          // Back to paced breathing for round 2
          expect(provider.state, equals(BreathSessionState.pacedBreathing));

          // Complete paced breathing for round 2
          for (int i = 0; i < 3; i++) {
            async.elapse(const Duration(seconds: 4));
            async.elapse(const Duration(seconds: 6));
          }

          // Round 2 hold (5 * 1.1 = 5.5 -> 6 seconds)
          final round2Hold = provider.currentHoldTarget;
          async.elapse(Duration(seconds: round2Hold));

          expect(provider.state, equals(BreathSessionState.complete));
          expect(provider.totalHoldTime, equals(5 + round2Hold));
        });
      });

      test('paced breathing completion shows elapsed time', () {
        fakeAsync((async) {
          provider.pacedDurationMinutes = 1;
          provider.startPacedBreathingSession();

          async.elapse(const Duration(seconds: 60));

          expect(provider.state, equals(BreathSessionState.complete));
          expect(provider.elapsedPacedSeconds, equals(60));
        });
      });

      test('patrick breath tracks exhale seconds', () {
        fakeAsync((async) {
          provider.startPatrickBreathSession();

          async.elapse(const Duration(seconds: 15));

          expect(provider.patrickExhaleSeconds, equals(15));

          provider.endPatrickBreath();

          expect(provider.state, equals(BreathSessionState.complete));
          expect(provider.patrickExhaleSeconds, equals(15));
        });
      });
    });

    // =========================================================================
    // PROGRESS TRACKING
    // =========================================================================

    group('Progress Tracking', () {
      test('phase progress updates smoothly during breath phases', () {
        fakeAsync((async) {
          provider.startPacedBreathingSession();

          // At start, progress should be 0
          expect(provider.phaseProgress, closeTo(0.0, 0.1));

          // After 2 seconds of 4 second inhale, progress should be ~0.5
          async.elapse(const Duration(seconds: 2));
          expect(provider.phaseProgress, closeTo(0.5, 0.15));

          provider.stopSession();
        });
      });

      test('current hold target increases with difficulty', () {
        provider.baseHoldDuration = 10;
        provider.difficulty = BreathDifficulty.intermediate; // +20% per round

        // Round 0: 10 * 1.0 = 10
        expect(provider.currentHoldTarget, equals(10));

        // Simulate completing a round
        fakeAsync((async) {
          provider.startBreathHoldSession();

          // Complete paced breathing
          for (int i = 0; i < 3; i++) {
            async.elapse(const Duration(seconds: 4));
            async.elapse(const Duration(seconds: 6));
          }

          // Complete hold
          async.elapse(const Duration(seconds: 10));

          // Round 1: 10 * 1.2 = 12
          expect(provider.currentRound, equals(1));
          expect(provider.currentHoldTarget, equals(12));

          provider.stopSession();
        });
      });

      test('difficulty levels have correct progression increments', () {
        provider.baseHoldDuration = 10;

        provider.difficulty = BreathDifficulty.beginner;
        expect(provider.progressionIncrement, equals(0.1));

        provider.difficulty = BreathDifficulty.intermediate;
        expect(provider.progressionIncrement, equals(0.2));

        provider.difficulty = BreathDifficulty.advanced;
        expect(provider.progressionIncrement, equals(0.3));
      });
    });

    // =========================================================================
    // STATE PERSISTENCE
    // =========================================================================

    group('State Persistence', () {
      test('export state captures breath hold session data', () {
        fakeAsync((async) {
          provider.baseHoldDuration = 15;
          provider.totalRounds = 5;
          provider.difficulty = BreathDifficulty.intermediate;
          provider.startBreathHoldSession();

          async.elapse(const Duration(seconds: 5));

          final state = provider.exportState();

          expect(state, isNotNull);
          expect(state!['sessionType'], equals(BreathSessionType.breathHold.index));
          expect(state['state'], equals(BreathSessionState.pacedBreathing.index));
          expect(state['baseHoldDuration'], equals(15));
          expect(state['totalRounds'], equals(5));
          expect(state['difficulty'], equals(BreathDifficulty.intermediate.index));

          provider.stopSession();
        });
      });

      test('export state captures paced breathing session data', () {
        fakeAsync((async) {
          provider.pacedDurationMinutes = 5;
          provider.startPacedBreathingSession();

          async.elapse(const Duration(seconds: 30));

          final state = provider.exportState();

          expect(state, isNotNull);
          expect(state!['sessionType'], equals(BreathSessionType.pacedBreathing.index));
          expect(state['pacedDurationMinutes'], equals(5));
          expect(state['elapsedPacedSeconds'], equals(30));

          provider.stopSession();
        });
      });

      test('restore state resumes breath hold session', () {
        fakeAsync((async) {
          provider.baseHoldDuration = 15;
          provider.totalRounds = 5;
          provider.startBreathHoldSession();

          // Advance to mid-session
          async.elapse(const Duration(seconds: 5));
          final originalState = provider.exportState()!;

          // Create new provider and restore
          final newProvider = createTestProvider();
          final restored = newProvider.restoreState(originalState);

          expect(restored, isTrue);
          expect(newProvider.sessionType, equals(BreathSessionType.breathHold));
          expect(newProvider.state, equals(BreathSessionState.pacedBreathing));
          expect(newProvider.baseHoldDuration, equals(15));
          expect(newProvider.totalRounds, equals(5));

          newProvider.dispose();
          provider.stopSession();
        });
      });

      test('restore state resumes paced breathing session', () {
        fakeAsync((async) {
          provider.pacedDurationMinutes = 5;
          provider.startPacedBreathingSession();

          async.elapse(const Duration(seconds: 45));
          final originalState = provider.exportState()!;

          final newProvider = createTestProvider();
          final restored = newProvider.restoreState(originalState);

          expect(restored, isTrue);
          expect(newProvider.sessionType, equals(BreathSessionType.pacedBreathing));
          expect(newProvider.elapsedPacedSeconds, equals(45));

          newProvider.dispose();
          provider.stopSession();
        });
      });

      test('export returns null when session is idle', () {
        expect(provider.exportState(), isNull);
      });

      test('export returns null when session is complete', () {
        fakeAsync((async) {
          provider.pacedDurationMinutes = 1;
          provider.startPacedBreathingSession();

          async.elapse(const Duration(seconds: 60));

          expect(provider.state, equals(BreathSessionState.complete));
          expect(provider.exportState(), isNull);
        });
      });
    });

    // =========================================================================
    // PAUSED SESSION DISPLAY
    // =========================================================================

    group('Paused Session Display', () {
      test('paused session title returns correct value for breath hold', () {
        provider.startBreathHoldSession();
        expect(provider.pausedSessionTitle, equals('Breath Holds'));
        provider.stopSession();
      });

      test('paused session title returns correct value for paced breathing', () {
        provider.startPacedBreathingSession();
        expect(provider.pausedSessionTitle, equals('Paced Breathing'));
        provider.stopSession();
      });

      test('paused session title returns correct value for patrick breath', () {
        provider.startPatrickBreathSession();
        expect(provider.pausedSessionTitle, equals('Long Exhale'));
        provider.stopSession();
      });

      test('paused session subtitle shows round progress for breath hold', () {
        fakeAsync((async) {
          provider.totalRounds = 5;
          provider.startBreathHoldSession();

          expect(provider.pausedSessionSubtitle, equals('Round 1/5'));

          // Complete a round to advance
          provider.baseHoldDuration = 5;
          for (int i = 0; i < 3; i++) {
            async.elapse(const Duration(seconds: 4));
            async.elapse(const Duration(seconds: 6));
          }
          async.elapse(const Duration(seconds: 5));

          expect(provider.pausedSessionSubtitle, equals('Round 2/5'));

          provider.stopSession();
        });
      });

      test('paused session subtitle shows remaining time for paced breathing', () {
        fakeAsync((async) {
          provider.pacedDurationMinutes = 3;
          provider.startPacedBreathingSession();

          expect(provider.pausedSessionSubtitle, equals('3 min remaining'));

          async.elapse(const Duration(seconds: 90)); // 1.5 minutes

          expect(provider.pausedSessionSubtitle, equals('1 min remaining'));

          provider.stopSession();
        });
      });

      test('paused session subtitle shows elapsed time for patrick breath', () {
        fakeAsync((async) {
          provider.startPatrickBreathSession();

          async.elapse(const Duration(seconds: 12));

          expect(provider.pausedSessionSubtitle, equals('12s elapsed'));

          provider.stopSession();
        });
      });
    });

    // =========================================================================
    // EDGE CASES
    // =========================================================================

    group('Edge Cases', () {
      test('stop session resets to idle', () {
        provider.startBreathHoldSession();
        expect(provider.isActive, isTrue);

        provider.stopSession();

        expect(provider.isActive, isFalse);
        expect(provider.state, equals(BreathSessionState.idle));
        expect(provider.breathPhase, equals(BreathPhase.idle));
      });

      test('reset clears all session state', () {
        fakeAsync((async) {
          provider.baseHoldDuration = 20;
          provider.totalRounds = 7;
          provider.startBreathHoldSession();

          async.elapse(const Duration(seconds: 10));

          provider.reset();

          expect(provider.state, equals(BreathSessionState.idle));
          expect(provider.sessionType, isNull);
          expect(provider.phaseSecondsRemaining, equals(0));
          expect(provider.currentRound, equals(0));
          expect(provider.totalHoldTime, equals(0));
          expect(provider.pacedBreathCount, equals(0));
        });
      });

      test('resume when not paused has no effect', () {
        provider.resumeSession();
        expect(provider.state, equals(BreathSessionState.idle));
      });

      test('resume when complete has no effect', () {
        fakeAsync((async) {
          provider.pacedDurationMinutes = 1;
          provider.startPacedBreathingSession();

          async.elapse(const Duration(seconds: 60));

          expect(provider.state, equals(BreathSessionState.complete));

          provider.resumeSession();
          expect(provider.state, equals(BreathSessionState.complete));
        });
      });

      test('end patrick breath transitions to complete', () {
        fakeAsync((async) {
          provider.startPatrickBreathSession();

          async.elapse(const Duration(seconds: 20));

          provider.endPatrickBreath();

          expect(provider.state, equals(BreathSessionState.complete));
          expect(provider.patrickExhaleSeconds, equals(20));
        });
      });

      test('multiple sessions can be started sequentially', () {
        provider.startBreathHoldSession();
        expect(provider.sessionType, equals(BreathSessionType.breathHold));
        provider.stopSession();

        provider.startPacedBreathingSession();
        expect(provider.sessionType, equals(BreathSessionType.pacedBreathing));
        provider.stopSession();

        provider.startPatrickBreathSession();
        expect(provider.sessionType, equals(BreathSessionType.patrickBreath));
        provider.stopSession();
      });
    });

    // =========================================================================
    // RECOVERY PHASE
    // =========================================================================

    group('Recovery Phase in Breath Hold', () {
      test('recovery phase starts after hold completes', () {
        fakeAsync((async) {
          provider.baseHoldDuration = 5;
          provider.totalRounds = 2;
          provider.startBreathHoldSession();

          // Complete paced breathing
          for (int i = 0; i < 3; i++) {
            async.elapse(const Duration(seconds: 4));
            async.elapse(const Duration(seconds: 6));
          }

          // Complete hold
          async.elapse(const Duration(seconds: 5));

          expect(provider.state, equals(BreathSessionState.recovery));
          expect(provider.breathPhase, equals(BreathPhase.inhale));
        });
      });

      test('recovery phase has 4 breath cycles', () {
        fakeAsync((async) {
          provider.baseHoldDuration = 5;
          provider.totalRounds = 2;
          provider.startBreathHoldSession();

          // Complete paced breathing
          for (int i = 0; i < 3; i++) {
            async.elapse(const Duration(seconds: 4));
            async.elapse(const Duration(seconds: 6));
          }

          // Complete hold
          async.elapse(const Duration(seconds: 5));

          expect(provider.state, equals(BreathSessionState.recovery));

          // Complete recovery breaths (4 cycles)
          for (int i = 0; i < 4; i++) {
            async.elapse(const Duration(seconds: 4)); // inhale
            async.elapse(const Duration(seconds: 6)); // exhale
          }

          // Should transition back to paced breathing for next round
          expect(provider.state, equals(BreathSessionState.pacedBreathing));

          provider.stopSession();
        });
      });

      test('recovery secondary text shows breath count', () {
        fakeAsync((async) {
          provider.baseHoldDuration = 5;
          provider.totalRounds = 2;
          provider.startBreathHoldSession();

          // Complete paced breathing
          for (int i = 0; i < 3; i++) {
            async.elapse(const Duration(seconds: 4));
            async.elapse(const Duration(seconds: 6));
          }

          // Complete hold
          async.elapse(const Duration(seconds: 5));

          expect(provider.secondaryText, equals('Recovery breath 1/4'));

          // Complete first recovery breath
          async.elapse(const Duration(seconds: 4));
          async.elapse(const Duration(seconds: 6));

          expect(provider.secondaryText, equals('Recovery breath 2/4'));

          provider.stopSession();
        });
      });
    });
  });
}
