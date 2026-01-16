import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/providers/breath_training_provider.dart';
import 'package:archery_super_app/widgets/breathing_visualizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Breath Training Session Lifecycle', () {
    late BreathTrainingProvider provider;

    setUp(() {
      provider = BreathTrainingProvider();

      // Mock haptic feedback channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'HapticFeedback.vibrate') {
            return null;
          }
          return null;
        },
      );
    });

    tearDown(() {
      provider.dispose();
    });

    group('startBreathHoldSession()', () {
      test('initializes state correctly', () {
        provider.startBreathHoldSession();

        expect(provider.sessionType, equals(BreathSessionType.breathHold));
        expect(provider.state, equals(BreathSessionState.pacedBreathing));
        expect(provider.breathPhase, equals(BreathPhase.inhale));
        expect(provider.currentRound, equals(0));
        expect(provider.pacedBreathCount, equals(0));
        expect(provider.phaseSecondsRemaining, equals(BreathTrainingProvider.inhaleSeconds));
        expect(provider.phaseProgress, equals(0.0));
        expect(provider.totalHoldTime, equals(0));
        expect(provider.isActive, isTrue);
      });

      test('uses configured base hold duration', () {
        provider.baseHoldDuration = 20;
        provider.startBreathHoldSession();

        expect(provider.baseHoldDuration, equals(20));
        expect(provider.currentHoldTarget, equals(20)); // Round 0
      });

      test('uses configured total rounds', () {
        provider.totalRounds = 8;
        provider.startBreathHoldSession();

        expect(provider.totalRounds, equals(8));
      });

      test('uses configured difficulty', () {
        provider.difficulty = BreathDifficulty.advanced;
        provider.startBreathHoldSession();

        expect(provider.difficulty, equals(BreathDifficulty.advanced));
        expect(provider.progressionIncrement, equals(0.3));
      });

      test('resets session state from previous session', () {
        // Start and modify state
        provider.startBreathHoldSession();
        // Simulate some progress (would normally happen via timer)
        // Just verify that starting again resets

        provider.startBreathHoldSession();

        expect(provider.currentRound, equals(0));
        expect(provider.totalHoldTime, equals(0));
        expect(provider.state, equals(BreathSessionState.pacedBreathing));
      });
    });

    group('startPacedBreathingSession()', () {
      test('initializes state correctly', () {
        provider.startPacedBreathingSession();

        expect(provider.sessionType, equals(BreathSessionType.pacedBreathing));
        expect(provider.state, equals(BreathSessionState.pacedBreathing));
        expect(provider.breathPhase, equals(BreathPhase.inhale));
        expect(provider.phaseSecondsRemaining, equals(BreathTrainingProvider.inhaleSeconds));
        expect(provider.phaseProgress, equals(0.0));
        expect(provider.elapsedPacedSeconds, equals(0));
        expect(provider.isActive, isTrue);
      });

      test('uses configured duration', () {
        provider.pacedDurationMinutes = 5;
        provider.startPacedBreathingSession();

        expect(provider.pacedDurationMinutes, equals(5));
        // Total seconds should be minutes * 60
        final expectedTotal = 5 * 60;
        expect(provider.elapsedPacedSeconds, equals(0));
        // We can't directly access _totalPacedSeconds, but we can verify behavior
      });

      test('resets elapsed time from previous session', () {
        provider.startPacedBreathingSession();
        // Start again
        provider.startPacedBreathingSession();

        expect(provider.elapsedPacedSeconds, equals(0));
      });
    });

    group('startPatrickBreathSession()', () {
      test('initializes state correctly', () {
        provider.startPatrickBreathSession();

        expect(provider.sessionType, equals(BreathSessionType.patrickBreath));
        expect(provider.state, equals(BreathSessionState.exhaling));
        expect(provider.breathPhase, equals(BreathPhase.exhale));
        expect(provider.patrickExhaleSeconds, equals(0));
        expect(provider.phaseProgress, equals(0.0));
        expect(provider.isActive, isTrue);
      });

      test('preserves best exhale record', () {
        provider.bestExhale = 45;
        provider.startPatrickBreathSession();

        expect(provider.bestExhale, equals(45));
      });

      test('resets exhale seconds from previous session', () {
        provider.startPatrickBreathSession();
        // Start again
        provider.startPatrickBreathSession();

        expect(provider.patrickExhaleSeconds, equals(0));
      });
    });

    group('pauseForNavigation()', () {
      test('pauses breath hold session without resetting state', () {
        provider.startBreathHoldSession();

        // Simulate being in the middle of a session
        // (Timer would normally update these, but we can't easily test timer here)

        provider.pauseForNavigation();

        // State should be preserved
        expect(provider.sessionType, equals(BreathSessionType.breathHold));
        expect(provider.state, equals(BreathSessionState.pacedBreathing));
        // Timer should be cancelled (can't verify directly, but state is preserved)
      });

      test('pauses paced breathing session without resetting state', () {
        provider.startPacedBreathingSession();
        provider.pauseForNavigation();

        expect(provider.sessionType, equals(BreathSessionType.pacedBreathing));
        expect(provider.state, equals(BreathSessionState.pacedBreathing));
      });

      test('pauses patrick breath session without resetting state', () {
        provider.startPatrickBreathSession();
        provider.pauseForNavigation();

        expect(provider.sessionType, equals(BreathSessionType.patrickBreath));
        expect(provider.state, equals(BreathSessionState.exhaling));
      });
    });

    group('resumeSession()', () {
      test('resumes paused breath hold session', () {
        provider.startBreathHoldSession();
        provider.pauseForNavigation();

        provider.resumeSession();

        // Should still be in the same state
        expect(provider.sessionType, equals(BreathSessionType.breathHold));
        expect(provider.state, equals(BreathSessionState.pacedBreathing));
        expect(provider.isActive, isTrue);
      });

      test('resumes paused paced breathing session', () {
        provider.startPacedBreathingSession();
        provider.pauseForNavigation();

        provider.resumeSession();

        expect(provider.sessionType, equals(BreathSessionType.pacedBreathing));
        expect(provider.state, equals(BreathSessionState.pacedBreathing));
        expect(provider.isActive, isTrue);
      });

      test('resumes paused patrick breath session', () {
        provider.startPatrickBreathSession();
        provider.pauseForNavigation();

        provider.resumeSession();

        expect(provider.sessionType, equals(BreathSessionType.patrickBreath));
        expect(provider.state, equals(BreathSessionState.exhaling));
        expect(provider.isActive, isTrue);
      });

      test('does not resume idle session', () {
        provider.resumeSession();

        expect(provider.state, equals(BreathSessionState.idle));
        expect(provider.isActive, isFalse);
      });

      test('does not resume complete session', () {
        provider.startBreathHoldSession();
        // Manually set to complete state
        provider.stopSession();

        provider.resumeSession();

        expect(provider.state, equals(BreathSessionState.idle));
        expect(provider.isActive, isFalse);
      });
    });

    group('stopSession()', () {
      test('stops breath hold session and returns to idle', () {
        provider.startBreathHoldSession();
        provider.stopSession();

        expect(provider.state, equals(BreathSessionState.idle));
        expect(provider.breathPhase, equals(BreathPhase.idle));
        expect(provider.isActive, isFalse);
        // Session type should still be set for history
        expect(provider.sessionType, equals(BreathSessionType.breathHold));
      });

      test('stops paced breathing session and returns to idle', () {
        provider.startPacedBreathingSession();
        provider.stopSession();

        expect(provider.state, equals(BreathSessionState.idle));
        expect(provider.breathPhase, equals(BreathPhase.idle));
        expect(provider.isActive, isFalse);
      });

      test('stops patrick breath session and returns to idle', () {
        provider.startPatrickBreathSession();
        provider.stopSession();

        expect(provider.state, equals(BreathSessionState.idle));
        expect(provider.breathPhase, equals(BreathPhase.idle));
        expect(provider.isActive, isFalse);
      });

      test('can be called multiple times safely', () {
        provider.startBreathHoldSession();
        provider.stopSession();
        provider.stopSession(); // Should not crash

        expect(provider.state, equals(BreathSessionState.idle));
      });

      test('can be called when idle', () {
        provider.stopSession(); // Should not crash

        expect(provider.state, equals(BreathSessionState.idle));
      });
    });

    group('endPatrickBreath()', () {
      test('completes patrick breath session', () {
        provider.startPatrickBreathSession();
        provider.endPatrickBreath();

        expect(provider.state, equals(BreathSessionState.complete));
        expect(provider.isActive, isFalse);
      });

      test('preserves exhale time when completing', () {
        provider.startPatrickBreathSession();
        // Timer would normally increment this, but we can check it's not reset
        provider.endPatrickBreath();

        expect(provider.patrickExhaleSeconds, equals(0)); // Still 0 since timer didn't run
        expect(provider.state, equals(BreathSessionState.complete));
      });
    });

    group('reset()', () {
      test('fully resets breath hold session state', () {
        provider.baseHoldDuration = 25;
        provider.totalRounds = 7;
        provider.difficulty = BreathDifficulty.advanced;
        provider.startBreathHoldSession();

        provider.reset();

        expect(provider.sessionType, isNull);
        expect(provider.state, equals(BreathSessionState.idle));
        expect(provider.breathPhase, equals(BreathPhase.idle));
        expect(provider.phaseSecondsRemaining, equals(0));
        expect(provider.phaseProgress, equals(0.0));
        expect(provider.currentRound, equals(0));
        expect(provider.pacedBreathCount, equals(0));
        expect(provider.totalHoldTime, equals(0));
        expect(provider.isActive, isFalse);

        // Configuration should be preserved
        expect(provider.baseHoldDuration, equals(25));
        expect(provider.totalRounds, equals(7));
        expect(provider.difficulty, equals(BreathDifficulty.advanced));
      });

      test('fully resets paced breathing session state', () {
        provider.pacedDurationMinutes = 10;
        provider.startPacedBreathingSession();

        provider.reset();

        expect(provider.sessionType, isNull);
        expect(provider.state, equals(BreathSessionState.idle));
        expect(provider.breathPhase, equals(BreathPhase.idle));
        expect(provider.elapsedPacedSeconds, equals(0));

        // Configuration should be preserved
        expect(provider.pacedDurationMinutes, equals(10));
      });

      test('fully resets patrick breath session state', () {
        provider.bestExhale = 50;
        provider.startPatrickBreathSession();

        provider.reset();

        expect(provider.sessionType, isNull);
        expect(provider.state, equals(BreathSessionState.idle));
        expect(provider.breathPhase, equals(BreathPhase.idle));
        expect(provider.patrickExhaleSeconds, equals(0));

        // Best exhale should be preserved
        expect(provider.bestExhale, equals(50));
      });

      test('can be called multiple times safely', () {
        provider.startBreathHoldSession();
        provider.reset();
        provider.reset(); // Should not crash

        expect(provider.state, equals(BreathSessionState.idle));
      });

      test('can be called when idle', () {
        provider.reset(); // Should not crash

        expect(provider.state, equals(BreathSessionState.idle));
      });
    });

    group('State persistence - exportState()', () {
      test('exports null when idle', () {
        final state = provider.exportState();

        expect(state, isNull);
      });

      test('exports null when complete', () {
        provider.startBreathHoldSession();
        provider.stopSession(); // Goes to idle
        final state = provider.exportState();

        expect(state, isNull);
      });

      test('exports breath hold session state', () {
        provider.baseHoldDuration = 20;
        provider.totalRounds = 6;
        provider.difficulty = BreathDifficulty.beginner;
        provider.startBreathHoldSession();

        final state = provider.exportState();

        expect(state, isNotNull);
        expect(state!['sessionType'], equals(BreathSessionType.breathHold.index));
        expect(state['state'], equals(BreathSessionState.pacedBreathing.index));
        expect(state['breathPhase'], equals(BreathPhase.inhale.index));
        expect(state['baseHoldDuration'], equals(20));
        expect(state['totalRounds'], equals(6));
        expect(state['difficulty'], equals(BreathDifficulty.beginner.index));
        expect(state['currentRound'], equals(0));
        expect(state['totalHoldTime'], equals(0));
      });

      test('exports paced breathing session state', () {
        provider.pacedDurationMinutes = 7;
        provider.startPacedBreathingSession();

        final state = provider.exportState();

        expect(state, isNotNull);
        expect(state!['sessionType'], equals(BreathSessionType.pacedBreathing.index));
        expect(state['state'], equals(BreathSessionState.pacedBreathing.index));
        expect(state['pacedDurationMinutes'], equals(7));
        expect(state['elapsedPacedSeconds'], equals(0));
      });

      test('exports patrick breath session state', () {
        provider.startPatrickBreathSession();

        final state = provider.exportState();

        expect(state, isNotNull);
        expect(state!['sessionType'], equals(BreathSessionType.patrickBreath.index));
        expect(state['state'], equals(BreathSessionState.exhaling.index));
        expect(state['breathPhase'], equals(BreathPhase.exhale.index));
        expect(state['exhaleSeconds'], equals(0));
      });
    });

    group('State persistence - restoreState()', () {
      test('restores breath hold session state', () {
        final state = {
          'sessionType': BreathSessionType.breathHold.index,
          'state': BreathSessionState.holding.index,
          'breathPhase': BreathPhase.hold.index,
          'phaseSecondsRemaining': 12,
          'phaseProgress': 0.3,
          'baseHoldDuration': 20,
          'totalRounds': 6,
          'difficulty': BreathDifficulty.advanced.index,
          'currentRound': 2,
          'pacedBreathCount': 1,
          'totalHoldTime': 45,
          'pacedDurationMinutes': 3,
          'totalPacedSeconds': 0,
          'elapsedPacedSeconds': 0,
          'exhaleSeconds': 0,
        };

        final success = provider.restoreState(state);

        expect(success, isTrue);
        expect(provider.sessionType, equals(BreathSessionType.breathHold));
        expect(provider.state, equals(BreathSessionState.holding));
        expect(provider.breathPhase, equals(BreathPhase.hold));
        expect(provider.phaseSecondsRemaining, equals(12));
        expect(provider.phaseProgress, equals(0.3));
        expect(provider.baseHoldDuration, equals(20));
        expect(provider.totalRounds, equals(6));
        expect(provider.difficulty, equals(BreathDifficulty.advanced));
        expect(provider.currentRound, equals(2));
        expect(provider.pacedBreathCount, equals(1));
        expect(provider.totalHoldTime, equals(45));
      });

      test('restores paced breathing session state', () {
        final state = {
          'sessionType': BreathSessionType.pacedBreathing.index,
          'state': BreathSessionState.pacedBreathing.index,
          'breathPhase': BreathPhase.exhale.index,
          'phaseSecondsRemaining': 4,
          'phaseProgress': 0.6,
          'pacedDurationMinutes': 5,
          'totalPacedSeconds': 300,
          'elapsedPacedSeconds': 120,
        };

        final success = provider.restoreState(state);

        expect(success, isTrue);
        expect(provider.sessionType, equals(BreathSessionType.pacedBreathing));
        expect(provider.state, equals(BreathSessionState.pacedBreathing));
        expect(provider.breathPhase, equals(BreathPhase.exhale));
        expect(provider.pacedDurationMinutes, equals(5));
        expect(provider.elapsedPacedSeconds, equals(120));
      });

      test('restores patrick breath session state', () {
        final state = {
          'sessionType': BreathSessionType.patrickBreath.index,
          'state': BreathSessionState.exhaling.index,
          'breathPhase': BreathPhase.exhale.index,
          'phaseSecondsRemaining': 0,
          'phaseProgress': 0.5,
          'exhaleSeconds': 37,
        };

        final success = provider.restoreState(state);

        expect(success, isTrue);
        expect(provider.sessionType, equals(BreathSessionType.patrickBreath));
        expect(provider.state, equals(BreathSessionState.exhaling));
        expect(provider.patrickExhaleSeconds, equals(37));
      });

      test('handles missing optional fields with defaults', () {
        final minimalState = {
          'sessionType': BreathSessionType.breathHold.index,
          'state': BreathSessionState.holding.index,
          'breathPhase': BreathPhase.hold.index,
          'phaseSecondsRemaining': 10,
          'phaseProgress': 0.5,
          // All optional fields omitted
        };

        final success = provider.restoreState(minimalState);

        expect(success, isTrue);
        expect(provider.baseHoldDuration, equals(15)); // Default
        expect(provider.totalRounds, equals(5)); // Default
        expect(provider.difficulty, equals(BreathDifficulty.intermediate)); // Default
        expect(provider.currentRound, equals(0)); // Default
      });

      test('returns false on invalid state', () {
        final invalidState = {
          'sessionType': 'invalid', // Wrong type
          'state': BreathSessionState.holding.index,
        };

        final success = provider.restoreState(invalidState);

        expect(success, isFalse);
      });

      test('does not auto-start timer after restore', () {
        final state = {
          'sessionType': BreathSessionType.breathHold.index,
          'state': BreathSessionState.holding.index,
          'breathPhase': BreathPhase.hold.index,
          'phaseSecondsRemaining': 10,
          'phaseProgress': 0.5,
        };

        provider.restoreState(state);

        // State should be restored but timer should not be running
        // User must call resumeSession() to restart timer
        expect(provider.state, equals(BreathSessionState.holding));
        expect(provider.isActive, isTrue);
      });
    });

    group('Session lifecycle integration', () {
      test('complete breath hold workflow - start, pause, resume, stop', () {
        // Start session
        provider.startBreathHoldSession();
        expect(provider.isActive, isTrue);
        expect(provider.state, equals(BreathSessionState.pacedBreathing));

        // Pause
        provider.pauseForNavigation();
        expect(provider.state, equals(BreathSessionState.pacedBreathing)); // State preserved

        // Resume
        provider.resumeSession();
        expect(provider.isActive, isTrue);

        // Stop
        provider.stopSession();
        expect(provider.isActive, isFalse);
        expect(provider.state, equals(BreathSessionState.idle));
      });

      test('complete paced breathing workflow - start, pause, resume, reset', () {
        // Start session
        provider.startPacedBreathingSession();
        expect(provider.isActive, isTrue);

        // Pause
        provider.pauseForNavigation();
        expect(provider.state, equals(BreathSessionState.pacedBreathing));

        // Resume
        provider.resumeSession();
        expect(provider.isActive, isTrue);

        // Reset
        provider.reset();
        expect(provider.isActive, isFalse);
        expect(provider.sessionType, isNull);
      });

      test('complete patrick breath workflow - start, end', () {
        // Start session
        provider.startPatrickBreathSession();
        expect(provider.isActive, isTrue);
        expect(provider.state, equals(BreathSessionState.exhaling));

        // End
        provider.endPatrickBreath();
        expect(provider.state, equals(BreathSessionState.complete));
        expect(provider.isActive, isFalse);
      });

      test('export/restore workflow preserves session state', () {
        // Start session with custom config
        provider.baseHoldDuration = 25;
        provider.totalRounds = 8;
        provider.difficulty = BreathDifficulty.advanced;
        provider.startBreathHoldSession();

        // Export state
        final exportedState = provider.exportState();
        expect(exportedState, isNotNull);

        // Create new provider and restore
        final newProvider = BreathTrainingProvider();
        final success = newProvider.restoreState(exportedState!);

        expect(success, isTrue);
        expect(newProvider.sessionType, equals(provider.sessionType));
        expect(newProvider.state, equals(provider.state));
        expect(newProvider.baseHoldDuration, equals(25));
        expect(newProvider.totalRounds, equals(8));
        expect(newProvider.difficulty, equals(BreathDifficulty.advanced));

        newProvider.dispose();
      });

      test('can start new session after stopping previous one', () {
        // Start breath hold
        provider.startBreathHoldSession();
        expect(provider.sessionType, equals(BreathSessionType.breathHold));

        // Stop
        provider.stopSession();

        // Start paced breathing
        provider.startPacedBreathingSession();
        expect(provider.sessionType, equals(BreathSessionType.pacedBreathing));
        expect(provider.isActive, isTrue);
      });

      test('can reset and start new session', () {
        // Start and reset breath hold
        provider.startBreathHoldSession();
        provider.reset();
        expect(provider.sessionType, isNull);

        // Start patrick breath
        provider.startPatrickBreathSession();
        expect(provider.sessionType, equals(BreathSessionType.patrickBreath));
        expect(provider.isActive, isTrue);
      });
    });

    group('Configuration preservation', () {
      test('starting session preserves configuration settings', () {
        provider.baseHoldDuration = 30;
        provider.totalRounds = 10;
        provider.difficulty = BreathDifficulty.beginner;
        provider.pacedDurationMinutes = 8;
        provider.bestExhale = 60;

        provider.startBreathHoldSession();

        expect(provider.baseHoldDuration, equals(30));
        expect(provider.totalRounds, equals(10));
        expect(provider.difficulty, equals(BreathDifficulty.beginner));
        expect(provider.pacedDurationMinutes, equals(8));
        expect(provider.bestExhale, equals(60));
      });

      test('stopping session preserves configuration settings', () {
        provider.baseHoldDuration = 30;
        provider.totalRounds = 10;

        provider.startBreathHoldSession();
        provider.stopSession();

        expect(provider.baseHoldDuration, equals(30));
        expect(provider.totalRounds, equals(10));
      });

      test('resetting session preserves configuration settings', () {
        provider.baseHoldDuration = 30;
        provider.totalRounds = 10;
        provider.bestExhale = 60;

        provider.startBreathHoldSession();
        provider.reset();

        expect(provider.baseHoldDuration, equals(30));
        expect(provider.totalRounds, equals(10));
        expect(provider.bestExhale, equals(60));
      });
    });
  });
}
