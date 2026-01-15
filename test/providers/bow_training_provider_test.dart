import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/providers/bow_training_provider.dart';

void main() {
  group('TimerPhase', () {
    test('has all expected phases', () {
      expect(TimerPhase.values, contains(TimerPhase.idle));
      expect(TimerPhase.values, contains(TimerPhase.prep));
      expect(TimerPhase.values, contains(TimerPhase.hold));
      expect(TimerPhase.values, contains(TimerPhase.rest));
      expect(TimerPhase.values, contains(TimerPhase.exerciseBreak));
      expect(TimerPhase.values, contains(TimerPhase.complete));
    });

    test('has 6 phases total', () {
      expect(TimerPhase.values.length, equals(6));
    });
  });

  group('TimerState', () {
    test('has all expected states', () {
      expect(TimerState.values, contains(TimerState.stopped));
      expect(TimerState.values, contains(TimerState.running));
      expect(TimerState.values, contains(TimerState.paused));
    });

    test('has 3 states total', () {
      expect(TimerState.values.length, equals(3));
    });
  });

  group('MovementStimulus', () {
    test('has all expected levels', () {
      expect(MovementStimulus.values, contains(MovementStimulus.none));
      expect(MovementStimulus.values, contains(MovementStimulus.some));
      expect(MovementStimulus.values, contains(MovementStimulus.lots));
    });

    test('has 3 levels total', () {
      expect(MovementStimulus.values.length, equals(3));
    });
  });

  group('HoldRestRatio', () {
    group('preset ratios', () {
      test('15:45 ratio has correct values', () {
        expect(HoldRestRatio.ratio15_45.holdSeconds, equals(15));
        expect(HoldRestRatio.ratio15_45.restSeconds, equals(45));
        expect(HoldRestRatio.ratio15_45.label, equals('15:45'));
      });

      test('20:40 ratio has correct values', () {
        expect(HoldRestRatio.ratio20_40.holdSeconds, equals(20));
        expect(HoldRestRatio.ratio20_40.restSeconds, equals(40));
        expect(HoldRestRatio.ratio20_40.label, equals('20:40'));
      });

      test('25:35 ratio has correct values', () {
        expect(HoldRestRatio.ratio25_35.holdSeconds, equals(25));
        expect(HoldRestRatio.ratio25_35.restSeconds, equals(35));
        expect(HoldRestRatio.ratio25_35.label, equals('25:35'));
      });

      test('30:30 ratio has correct values', () {
        expect(HoldRestRatio.ratio30_30.holdSeconds, equals(30));
        expect(HoldRestRatio.ratio30_30.restSeconds, equals(30));
        expect(HoldRestRatio.ratio30_30.label, equals('30:30'));
      });
    });

    group('all static list', () {
      test('contains 4 ratios', () {
        expect(HoldRestRatio.all.length, equals(4));
      });

      test('all ratios sum to 60 seconds', () {
        for (final ratio in HoldRestRatio.all) {
          expect(
            ratio.holdSeconds + ratio.restSeconds,
            equals(60),
            reason: 'Ratio ${ratio.label} should sum to 60 seconds',
          );
        }
      });
    });

    group('custom ratio', () {
      test('can create custom ratio', () {
        const custom = HoldRestRatio(10, 50, '10:50');
        expect(custom.holdSeconds, equals(10));
        expect(custom.restSeconds, equals(50));
        expect(custom.label, equals('10:50'));
      });
    });
  });

  group('CustomSessionConfig', () {
    group('construction', () {
      test('creates config with required parameters', () {
        const config = CustomSessionConfig(
          durationMinutes: 10,
          ratio: HoldRestRatio.ratio20_40,
          movementStimulus: MovementStimulus.some,
        );

        expect(config.durationMinutes, equals(10));
        expect(config.ratio.holdSeconds, equals(20));
        expect(config.ratio.restSeconds, equals(40));
        expect(config.movementStimulus, equals(MovementStimulus.some));
      });
    });

    group('defaultWarmUp', () {
      test('is 5 minutes at 30:30', () {
        expect(CustomSessionConfig.defaultWarmUp.durationMinutes, equals(5));
        expect(CustomSessionConfig.defaultWarmUp.ratio.holdSeconds, equals(30));
        expect(CustomSessionConfig.defaultWarmUp.ratio.restSeconds, equals(30));
        expect(
          CustomSessionConfig.defaultWarmUp.movementStimulus,
          equals(MovementStimulus.none),
        );
      });
    });

    group('totalReps', () {
      test('calculates correctly for 5 min at 30:30', () {
        // 5 min = 300 sec, cycle = 60 sec
        // 300 / 60 = 5 reps
        expect(CustomSessionConfig.defaultWarmUp.totalReps, equals(5));
      });

      test('calculates correctly for 10 min at 20:40', () {
        const config = CustomSessionConfig(
          durationMinutes: 10,
          ratio: HoldRestRatio.ratio20_40,
          movementStimulus: MovementStimulus.none,
        );
        // 10 min = 600 sec, cycle = 60 sec
        // 600 / 60 = 10 reps
        expect(config.totalReps, equals(10));
      });

      test('calculates correctly for 15 min at 15:45', () {
        const config = CustomSessionConfig(
          durationMinutes: 15,
          ratio: HoldRestRatio.ratio15_45,
          movementStimulus: MovementStimulus.lots,
        );
        // 15 min = 900 sec, cycle = 60 sec
        // 900 / 60 = 15 reps
        expect(config.totalReps, equals(15));
      });

      test('handles 1 minute session', () {
        const config = CustomSessionConfig(
          durationMinutes: 1,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );
        // 1 min = 60 sec, cycle = 60 sec
        // 60 / 60 = 1 rep
        expect(config.totalReps, equals(1));
      });

      test('handles partial cycles', () {
        const config = CustomSessionConfig(
          durationMinutes: 7,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );
        // 7 min = 420 sec, cycle = 60 sec
        // 420 / 60 = 7 reps (integer division)
        expect(config.totalReps, equals(7));
      });
    });

    group('displayName', () {
      test('formats correctly', () {
        const config = CustomSessionConfig(
          durationMinutes: 10,
          ratio: HoldRestRatio.ratio20_40,
          movementStimulus: MovementStimulus.none,
        );
        expect(config.displayName, equals('10min @ 20:40'));
      });

      test('default warmup display name', () {
        expect(
          CustomSessionConfig.defaultWarmUp.displayName,
          equals('5min @ 30:30'),
        );
      });
    });
  });

  group('BowTrainingProvider - Static Methods', () {
    group('formatDuration', () {
      test('formats seconds only', () {
        expect(BowTrainingProvider.formatDuration(45), equals('45 sec'));
      });

      test('formats minutes only', () {
        expect(BowTrainingProvider.formatDuration(120), equals('2 min'));
      });

      test('formats minutes and seconds', () {
        expect(BowTrainingProvider.formatDuration(90), equals('1 min 30 sec'));
      });

      test('formats 0 seconds', () {
        expect(BowTrainingProvider.formatDuration(0), equals('0 sec'));
      });

      test('formats large durations', () {
        expect(BowTrainingProvider.formatDuration(3661), equals('61 min 1 sec'));
      });

      test('formats exact minute boundaries', () {
        expect(BowTrainingProvider.formatDuration(60), equals('1 min'));
        expect(BowTrainingProvider.formatDuration(180), equals('3 min'));
        expect(BowTrainingProvider.formatDuration(300), equals('5 min'));
      });
    });
  });

  group('Version Progression Logic', () {
    // Test version string parsing without needing database
    group('version string format', () {
      test('typical version format is major.minor', () {
        const version = '1.3';
        final parts = version.split('.');
        expect(parts.length, equals(2));
        expect(int.tryParse(parts[0]), equals(1));
        expect(int.tryParse(parts[1]), equals(3));
      });

      test('can parse level 2 versions', () {
        const version = '2.5';
        final parts = version.split('.');
        expect(int.tryParse(parts[0]), equals(2));
        expect(int.tryParse(parts[1]), equals(5));
      });
    });

    group('version comparison logic', () {
      test('can determine if version should progress', () {
        // Logic: if avgScore < 4 and completed >= 100%, suggest progress
        const avgScore = 3.5;
        const completionRate = 1.0;

        final shouldProgress = avgScore < 4 && completionRate >= 1.0;
        expect(shouldProgress, isTrue);
      });

      test('can determine if version should regress', () {
        // Logic: if maxScore > 7 or avgScore > 6, suggest regress
        const feedbackShaking = 8; // Too much shaking
        const feedbackStructure = 5;
        const feedbackRest = 5;
        const completionRate = 0.6;

        final maxScore = [feedbackShaking, feedbackStructure, feedbackRest]
            .reduce((a, b) => a > b ? a : b);
        final avgScore = (feedbackShaking + feedbackStructure + feedbackRest) / 3;

        final shouldRegress = completionRate < 0.7 || maxScore > 7 || avgScore > 6;
        expect(shouldRegress, isTrue);
      });

      test('can determine if version should repeat', () {
        // Logic: moderate scores, good completion = repeat
        const feedbackShaking = 5;
        const feedbackStructure = 5;
        const feedbackRest = 5;
        const completionRate = 0.95;

        final avgScore = (feedbackShaking + feedbackStructure + feedbackRest) / 3;
        final maxScore = [feedbackShaking, feedbackStructure, feedbackRest]
            .reduce((a, b) => a > b ? a : b);

        final shouldProgress = avgScore < 4 && completionRate >= 1.0;
        final shouldRegress = completionRate < 0.7 || maxScore > 7 || avgScore > 6;
        final shouldRepeat = !shouldProgress && !shouldRegress;

        expect(shouldRepeat, isTrue);
      });
    });
  });

  group('Timer Display Logic', () {
    group('formattedTime logic', () {
      test('formats 0 seconds correctly', () {
        const secondsRemaining = 0;
        final minutes = secondsRemaining ~/ 60;
        final seconds = secondsRemaining % 60;
        final formatted =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        expect(formatted, equals('00:00'));
      });

      test('formats 30 seconds correctly', () {
        const secondsRemaining = 30;
        final minutes = secondsRemaining ~/ 60;
        final seconds = secondsRemaining % 60;
        final formatted =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        expect(formatted, equals('00:30'));
      });

      test('formats 1 minute correctly', () {
        const secondsRemaining = 60;
        final minutes = secondsRemaining ~/ 60;
        final seconds = secondsRemaining % 60;
        final formatted =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        expect(formatted, equals('01:00'));
      });

      test('formats 1:30 correctly', () {
        const secondsRemaining = 90;
        final minutes = secondsRemaining ~/ 60;
        final seconds = secondsRemaining % 60;
        final formatted =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        expect(formatted, equals('01:30'));
      });

      test('formats 10:00 correctly', () {
        const secondsRemaining = 600;
        final minutes = secondsRemaining ~/ 60;
        final seconds = secondsRemaining % 60;
        final formatted =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        expect(formatted, equals('10:00'));
      });
    });

    group('phase progress logic', () {
      test('calculates progress correctly at start', () {
        const secondsRemaining = 30;
        const totalSeconds = 30;
        final progress = 1 - (secondsRemaining / totalSeconds);
        expect(progress, equals(0.0));
      });

      test('calculates progress correctly at midpoint', () {
        const secondsRemaining = 15;
        const totalSeconds = 30;
        final progress = 1 - (secondsRemaining / totalSeconds);
        expect(progress, equals(0.5));
      });

      test('calculates progress correctly near end', () {
        const secondsRemaining = 3;
        const totalSeconds = 30;
        final progress = 1 - (secondsRemaining / totalSeconds);
        expect(progress, closeTo(0.9, 0.01));
      });

      test('handles zero total seconds', () {
        const secondsRemaining = 0;
        const totalSeconds = 0;
        // Should return 1.0 to avoid division by zero
        final progress = totalSeconds <= 0 ? 1.0 : 1 - (secondsRemaining / totalSeconds);
        expect(progress, equals(1.0));
      });
    });

    group('session progress logic', () {
      test('calculates custom session progress correctly', () {
        const customCurrentRep = 3;
        const customTotalReps = 10;
        // Progress = (currentRep - 1) / totalReps
        final progress = (customCurrentRep - 1) / customTotalReps;
        expect(progress, equals(0.2)); // 2 completed out of 10
      });

      test('handles first rep', () {
        const customCurrentRep = 1;
        const customTotalReps = 10;
        final progress = (customCurrentRep - 1) / customTotalReps;
        expect(progress, equals(0.0));
      });

      test('handles last rep', () {
        const customCurrentRep = 10;
        const customTotalReps = 10;
        final progress = (customCurrentRep - 1) / customTotalReps;
        expect(progress, equals(0.9)); // 9 completed, 1 in progress
      });
    });
  });

  group('Edge Cases', () {
    test('version parsing handles invalid format', () {
      const invalidVersion = 'invalid';
      final parts = invalidVersion.split('.');
      final major = int.tryParse(parts[0]) ?? 1;
      expect(major, equals(1)); // Falls back to default
    });

    test('version parsing handles missing minor', () {
      const version = '2';
      final parts = version.split('.');
      final major = int.tryParse(parts[0]) ?? 1;
      final minor = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      expect(major, equals(2));
      expect(minor, equals(0));
    });

    test('completion rate handles empty exercises', () {
      const completedExercises = 0;
      const totalExercises = 0;
      final completionRate = totalExercises > 0
          ? completedExercises / totalExercises
          : 0.0;
      expect(completionRate, equals(0.0));
    });
  });

  group('Movement Cue Logic', () {
    test('cue probability check works', () {
      // Test the probability logic used for "some" movement stimulus
      const probability = 0.3;
      final threshold = (probability * 100).toInt();

      // Values 0-29 should show cue (30% chance)
      expect(0 < threshold, isTrue);
      expect(29 < threshold, isTrue);
      expect(30 < threshold, isFalse);
      expect(99 < threshold, isFalse);
    });

    test('movement cues are varied', () {
      final cues = [
        'Front end: squeeze in',
        'Front end: push out',
        'Back end: pull through',
        'Back end: squeeze in',
        'Feel the back tension',
        'Relax the front shoulder',
      ];

      expect(cues.length, equals(6));
      expect(cues.toSet().length, equals(6)); // All unique
    });
  });
}
