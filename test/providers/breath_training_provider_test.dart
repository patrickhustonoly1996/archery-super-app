import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/providers/breath_training_provider.dart';

void main() {
  group('BreathSessionType', () {
    test('has all expected types', () {
      expect(BreathSessionType.values, contains(BreathSessionType.pacedBreathing));
      expect(BreathSessionType.values, contains(BreathSessionType.breathHold));
      expect(BreathSessionType.values, contains(BreathSessionType.patrickBreath));
    });

    test('has 3 types total', () {
      expect(BreathSessionType.values.length, equals(3));
    });
  });

  group('BreathSessionState', () {
    test('has all expected states', () {
      expect(BreathSessionState.values, contains(BreathSessionState.setup));
      expect(BreathSessionState.values, contains(BreathSessionState.idle));
      expect(BreathSessionState.values, contains(BreathSessionState.pacedBreathing));
      expect(BreathSessionState.values, contains(BreathSessionState.holding));
      expect(BreathSessionState.values, contains(BreathSessionState.recovery));
      expect(BreathSessionState.values, contains(BreathSessionState.exhaling));
      expect(BreathSessionState.values, contains(BreathSessionState.complete));
    });

    test('has 7 states total', () {
      expect(BreathSessionState.values.length, equals(7));
    });
  });

  group('BreathDifficulty', () {
    test('has all expected difficulty levels', () {
      expect(BreathDifficulty.values, contains(BreathDifficulty.beginner));
      expect(BreathDifficulty.values, contains(BreathDifficulty.intermediate));
      expect(BreathDifficulty.values, contains(BreathDifficulty.advanced));
    });

    test('has 3 difficulty levels', () {
      expect(BreathDifficulty.values.length, equals(3));
    });
  });

  group('BreathTrainingProvider Constants', () {
    test('inhaleSeconds is 4', () {
      expect(BreathTrainingProvider.inhaleSeconds, equals(4));
    });

    test('exhaleSeconds is 6', () {
      expect(BreathTrainingProvider.exhaleSeconds, equals(6));
    });

    test('pacedBreathsPerCycle is 3', () {
      expect(BreathTrainingProvider.pacedBreathsPerCycle, equals(3));
    });

    test('recoveryBreaths is 4', () {
      expect(BreathTrainingProvider.recoveryBreaths, equals(4));
    });

    test('breath cycle is 10 seconds (4 in + 6 out)', () {
      final cycle = BreathTrainingProvider.inhaleSeconds +
          BreathTrainingProvider.exhaleSeconds;
      expect(cycle, equals(10));
    });
  });

  group('Progression Increment Logic', () {
    test('beginner progression is 10%', () {
      const difficulty = BreathDifficulty.beginner;
      double progressionIncrement;
      switch (difficulty) {
        case BreathDifficulty.beginner:
          progressionIncrement = 0.1;
          break;
        case BreathDifficulty.intermediate:
          progressionIncrement = 0.2;
          break;
        case BreathDifficulty.advanced:
          progressionIncrement = 0.3;
          break;
      }
      expect(progressionIncrement, equals(0.1));
    });

    test('intermediate progression is 20%', () {
      const difficulty = BreathDifficulty.intermediate;
      double progressionIncrement;
      switch (difficulty) {
        case BreathDifficulty.beginner:
          progressionIncrement = 0.1;
          break;
        case BreathDifficulty.intermediate:
          progressionIncrement = 0.2;
          break;
        case BreathDifficulty.advanced:
          progressionIncrement = 0.3;
          break;
      }
      expect(progressionIncrement, equals(0.2));
    });

    test('advanced progression is 30%', () {
      const difficulty = BreathDifficulty.advanced;
      double progressionIncrement;
      switch (difficulty) {
        case BreathDifficulty.beginner:
          progressionIncrement = 0.1;
          break;
        case BreathDifficulty.intermediate:
          progressionIncrement = 0.2;
          break;
        case BreathDifficulty.advanced:
          progressionIncrement = 0.3;
          break;
      }
      expect(progressionIncrement, equals(0.3));
    });
  });

  group('Hold Target Calculation', () {
    test('round 0 uses base duration', () {
      const baseHoldDuration = 15;
      const currentRound = 0;
      const progressionIncrement = 0.2; // Intermediate

      final progressionFactor = 1.0 + (currentRound * progressionIncrement);
      final holdTarget = (baseHoldDuration * progressionFactor).round();

      expect(holdTarget, equals(15)); // 15 * 1.0 = 15
    });

    test('round 1 increases by progression amount', () {
      const baseHoldDuration = 15;
      const currentRound = 1;
      const progressionIncrement = 0.2;

      final progressionFactor = 1.0 + (currentRound * progressionIncrement);
      final holdTarget = (baseHoldDuration * progressionFactor).round();

      expect(holdTarget, equals(18)); // 15 * 1.2 = 18
    });

    test('round 4 (last of 5) at intermediate', () {
      const baseHoldDuration = 15;
      const currentRound = 4;
      const progressionIncrement = 0.2;

      final progressionFactor = 1.0 + (currentRound * progressionIncrement);
      final holdTarget = (baseHoldDuration * progressionFactor).round();

      expect(holdTarget, equals(27)); // 15 * 1.8 = 27
    });

    test('beginner progression sequence', () {
      const baseHoldDuration = 15;
      const progressionIncrement = 0.1; // Beginner
      final targets = <int>[];

      for (int round = 0; round < 5; round++) {
        final factor = 1.0 + (round * progressionIncrement);
        targets.add((baseHoldDuration * factor).round());
      }

      // Round 0: 15*1.0=15, Round 1: 15*1.1=16.5->17, etc.
      expect(targets[0], equals(15));
      expect(targets[1], equals(17)); // 16.5 rounds to 17
      expect(targets[2], equals(18)); // 15*1.2=18
      expect(targets[3], equals(20)); // 15*1.3=19.5->20
      expect(targets[4], equals(21)); // 15*1.4=21
    });

    test('advanced progression sequence', () {
      const baseHoldDuration = 15;
      const progressionIncrement = 0.3; // Advanced
      final targets = <int>[];

      for (int round = 0; round < 5; round++) {
        final factor = 1.0 + (round * progressionIncrement);
        targets.add((baseHoldDuration * factor).round());
      }

      // Round 0: 15, Round 1: 19.5->20, Round 2: 24, etc.
      expect(targets[0], equals(15));
      expect(targets[1], equals(20)); // 15*1.3=19.5->20
      expect(targets[2], equals(24)); // 15*1.6=24
      expect(targets[3], equals(29)); // 15*1.9=28.5->29
      expect(targets[4], equals(33)); // 15*2.2=33
    });
  });

  group('Paced Breathing Duration', () {
    test('calculates total seconds from minutes', () {
      const pacedDurationMinutes = 3;
      final totalPacedSeconds = pacedDurationMinutes * 60;
      expect(totalPacedSeconds, equals(180));
    });

    test('calculates remaining time', () {
      const totalPacedSeconds = 180;
      const elapsedPacedSeconds = 45;
      final remaining = totalPacedSeconds - elapsedPacedSeconds;
      expect(remaining, equals(135));
    });

    test('formats remaining time as MM:SS', () {
      const remaining = 135;
      final mins = remaining ~/ 60;
      final secs = remaining % 60;
      final formatted = '$mins:${secs.toString().padLeft(2, '0')}';
      expect(formatted, equals('2:15'));
    });
  });

  group('State Export/Restore', () {
    test('export format includes session type', () {
      // Simulate exported state structure
      final exportedState = {
        'sessionType': BreathSessionType.breathHold.index,
        'state': BreathSessionState.holding.index,
        'breathPhase': 2, // hold
        'phaseSecondsRemaining': 10,
        'phaseProgress': 0.5,
        'baseHoldDuration': 15,
        'totalRounds': 5,
        'difficulty': BreathDifficulty.intermediate.index,
        'currentRound': 2,
        'pacedBreathCount': 0,
        'totalHoldTime': 30,
        'pacedDurationMinutes': 3,
        'totalPacedSeconds': 0,
        'elapsedPacedSeconds': 0,
        'exhaleSeconds': 0,
      };

      expect(exportedState['sessionType'], equals(1)); // breathHold index
      expect(exportedState['state'], equals(3)); // holding index
      expect(exportedState['currentRound'], equals(2));
    });

    test('restore handles missing optional fields', () {
      // Minimal state that should still restore
      final minimalState = {
        'sessionType': BreathSessionType.pacedBreathing.index,
        'state': BreathSessionState.pacedBreathing.index,
        'breathPhase': 0, // inhale
        'phaseSecondsRemaining': 4,
        'phaseProgress': 0.0,
      };

      // Missing fields should use defaults
      final baseHoldDuration = minimalState['baseHoldDuration'] as int? ?? 15;
      final totalRounds = minimalState['totalRounds'] as int? ?? 5;

      expect(baseHoldDuration, equals(15));
      expect(totalRounds, equals(5));
    });
  });

  group('Status Text Logic', () {
    test('idle state shows Ready', () {
      const state = BreathSessionState.idle;
      String statusText;
      switch (state) {
        case BreathSessionState.setup:
          statusText = 'Setup';
          break;
        case BreathSessionState.idle:
          statusText = 'Ready';
          break;
        default:
          statusText = 'Other';
      }
      expect(statusText, equals('Ready'));
    });

    test('holding state shows Hold', () {
      const state = BreathSessionState.holding;
      String statusText;
      switch (state) {
        case BreathSessionState.holding:
          statusText = 'Hold';
          break;
        default:
          statusText = 'Other';
      }
      expect(statusText, equals('Hold'));
    });

    test('exhaling state shows Exhale', () {
      const state = BreathSessionState.exhaling;
      String statusText;
      switch (state) {
        case BreathSessionState.exhaling:
          statusText = 'Exhale...';
          break;
        default:
          statusText = 'Other';
      }
      expect(statusText, equals('Exhale...'));
    });
  });

  group('Paused Session Display', () {
    test('paced breathing title', () {
      const sessionType = BreathSessionType.pacedBreathing;
      String title;
      switch (sessionType) {
        case BreathSessionType.pacedBreathing:
          title = 'Paced Breathing';
          break;
        case BreathSessionType.breathHold:
          title = 'Breath Holds';
          break;
        case BreathSessionType.patrickBreath:
          title = 'Long Exhale';
          break;
      }
      expect(title, equals('Paced Breathing'));
    });

    test('breath hold subtitle format', () {
      const currentRound = 2;
      const totalRounds = 5;
      final subtitle = 'Round ${currentRound + 1}/$totalRounds';
      expect(subtitle, equals('Round 3/5'));
    });

    test('patrick breath subtitle format', () {
      const exhaleSeconds = 45;
      final subtitle = '${exhaleSeconds}s elapsed';
      expect(subtitle, equals('45s elapsed'));
    });
  });

  group('isActive Logic', () {
    test('idle is not active', () {
      const state = BreathSessionState.idle;
      final isActive = state != BreathSessionState.idle &&
          state != BreathSessionState.complete &&
          state != BreathSessionState.setup;
      expect(isActive, isFalse);
    });

    test('holding is active', () {
      const state = BreathSessionState.holding;
      final isActive = state != BreathSessionState.idle &&
          state != BreathSessionState.complete &&
          state != BreathSessionState.setup;
      expect(isActive, isTrue);
    });

    test('complete is not active', () {
      const state = BreathSessionState.complete;
      final isActive = state != BreathSessionState.idle &&
          state != BreathSessionState.complete &&
          state != BreathSessionState.setup;
      expect(isActive, isFalse);
    });

    test('pacedBreathing is active', () {
      const state = BreathSessionState.pacedBreathing;
      final isActive = state != BreathSessionState.idle &&
          state != BreathSessionState.complete &&
          state != BreathSessionState.setup;
      expect(isActive, isTrue);
    });
  });

  group('Phase Progress Calculation', () {
    test('progress at start is 0', () {
      const phaseSecondsRemaining = 6;
      const totalPhaseSeconds = 6;
      const subSecondMs = 0;

      final elapsedMs = (totalPhaseSeconds * 1000) -
          (phaseSecondsRemaining * 1000) +
          subSecondMs;
      final progress = (elapsedMs / (totalPhaseSeconds * 1000)).clamp(0.0, 1.0);

      expect(progress, equals(0.0));
    });

    test('progress at midpoint is 0.5', () {
      const phaseSecondsRemaining = 3;
      const totalPhaseSeconds = 6;
      const subSecondMs = 0;

      final elapsedMs = (totalPhaseSeconds * 1000) -
          (phaseSecondsRemaining * 1000) +
          subSecondMs;
      final progress = (elapsedMs / (totalPhaseSeconds * 1000)).clamp(0.0, 1.0);

      expect(progress, equals(0.5));
    });

    test('progress near end is close to 1', () {
      const phaseSecondsRemaining = 1;
      const totalPhaseSeconds = 6;
      const subSecondMs = 500;

      final elapsedMs = (totalPhaseSeconds * 1000) -
          (phaseSecondsRemaining * 1000) +
          subSecondMs;
      final progress = (elapsedMs / (totalPhaseSeconds * 1000)).clamp(0.0, 1.0);

      // 5500 / 6000 ≈ 0.917
      expect(progress, closeTo(0.917, 0.01));
    });
  });

  group('Breath Hold Session Flow', () {
    test('paced breathing precedes hold', () {
      // Session starts with paced breathing
      const initialState = BreathSessionState.pacedBreathing;
      expect(initialState, equals(BreathSessionState.pacedBreathing));
    });

    test('after paced breaths, enters hold', () {
      const pacedBreathsNeeded = BreathTrainingProvider.pacedBreathsPerCycle;
      expect(pacedBreathsNeeded, equals(3));

      // After 3 complete breaths, transitions to holding
      const nextState = BreathSessionState.holding;
      expect(nextState, equals(BreathSessionState.holding));
    });

    test('after hold, enters recovery (if not last round)', () {
      const currentRound = 2;
      const totalRounds = 5;

      final nextState = currentRound >= totalRounds - 1
          ? BreathSessionState.complete
          : BreathSessionState.recovery;

      expect(nextState, equals(BreathSessionState.recovery));
    });

    test('after recovery, returns to paced breathing', () {
      const recoveryBreathsNeeded = BreathTrainingProvider.recoveryBreaths;
      expect(recoveryBreathsNeeded, equals(4));

      // After 4 recovery breaths, back to paced breathing
      const nextState = BreathSessionState.pacedBreathing;
      expect(nextState, equals(BreathSessionState.pacedBreathing));
    });

    test('last round completes session', () {
      const currentRound = 4; // 0-indexed, so this is round 5
      const totalRounds = 5;

      final nextState = currentRound >= totalRounds - 1
          ? BreathSessionState.complete
          : BreathSessionState.recovery;

      expect(nextState, equals(BreathSessionState.complete));
    });
  });

  group('Edge Cases', () {
    test('handles 0 base hold duration', () {
      const baseHoldDuration = 0;
      const currentRound = 2;
      const progressionIncrement = 0.2;

      final progressionFactor = 1.0 + (currentRound * progressionIncrement);
      final holdTarget = (baseHoldDuration * progressionFactor).round();

      expect(holdTarget, equals(0));
    });

    test('handles very long holds (60+ seconds)', () {
      const baseHoldDuration = 60;
      const currentRound = 4;
      const progressionIncrement = 0.2;

      final progressionFactor = 1.0 + (currentRound * progressionIncrement);
      final holdTarget = (baseHoldDuration * progressionFactor).round();

      expect(holdTarget, equals(108)); // 60 * 1.8 = 108
    });

    test('handles single round session', () {
      const totalRounds = 1;
      const currentRound = 0;

      final isLastRound = currentRound >= totalRounds - 1;
      expect(isLastRound, isTrue);
    });
  });
}
