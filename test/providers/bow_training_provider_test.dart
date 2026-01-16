import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/providers/bow_training_provider.dart';
import 'package:archery_super_app/db/database.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes for testing
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

  MockOlySessionTemplate({
    this.id = 'template_1',
    this.version = '1.0',
    this.name = 'Test Session',
    this.durationMinutes = 10,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  // ===========================================================================
  // PHASE E1: TIMER LOGIC TESTS WITH FAKE TIMERS
  // ===========================================================================

  group('Phase E1: Custom Session - startCustomSession() Initialization', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('startCustomSession initializes correct phase', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);

      expect(provider.phase, equals(TimerPhase.prep));
    });

    test('startCustomSession initializes correct rep count', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);

      expect(provider.customRep, equals(1));
      expect(provider.customTotalReps, equals(5)); // 5 min @ 60s cycle = 5 reps
    });

    test('startCustomSession sets timer to running', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);

      expect(provider.timerState, equals(TimerState.running));
    });

    test('startCustomSession sets prep countdown time', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);

      expect(provider.secondsRemaining, equals(kPrepCountdownSeconds));
    });

    test('startCustomSession marks session as active', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);

      expect(provider.isActive, isTrue);
    });

    test('startCustomSession sets isCustomSession to true', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);

      expect(provider.isCustomSession, isTrue);
    });
  });

  group('Phase E1: Timer Advances Through Prep -> Hold -> Rest Cycle (Custom Session)', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('timer advances from prep to hold phase using fakeAsync', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);
        expect(provider.phase, equals(TimerPhase.prep));

        // Advance past prep countdown (10 seconds)
        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));

        expect(provider.phase, equals(TimerPhase.hold));
      });
    });

    test('timer advances from hold to rest phase', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        // Advance past prep
        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));
        expect(provider.phase, equals(TimerPhase.hold));

        // Advance past hold (30 seconds)
        async.elapse(const Duration(seconds: 30));

        expect(provider.phase, equals(TimerPhase.rest));
      });
    });

    test('timer advances from rest back to hold phase', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        // Advance past prep
        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));

        // Advance past hold
        async.elapse(const Duration(seconds: 30));
        expect(provider.phase, equals(TimerPhase.rest));

        // Advance past rest (30 seconds)
        async.elapse(const Duration(seconds: 30));

        expect(provider.phase, equals(TimerPhase.hold));
      });
    });

    test('complete hold -> rest -> hold cycle', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        // Phase sequence: prep -> hold -> rest -> hold
        expect(provider.phase, equals(TimerPhase.prep));

        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));
        expect(provider.phase, equals(TimerPhase.hold));

        async.elapse(const Duration(seconds: 30));
        expect(provider.phase, equals(TimerPhase.rest));

        async.elapse(const Duration(seconds: 30));
        expect(provider.phase, equals(TimerPhase.hold));
      });
    });
  });

  group('Phase E1: Rep Counting Increments After Each Hold/Rest Cycle', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('rep count starts at 1', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);

      expect(provider.customRep, equals(1));
    });

    test('rep count increments after first hold/rest cycle', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);
        expect(provider.customRep, equals(1));

        // Skip prep
        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));

        // Complete hold (30s) and rest (30s)
        async.elapse(const Duration(seconds: 30)); // now in rest
        async.elapse(const Duration(seconds: 30)); // now in hold, rep incremented

        expect(provider.customRep, equals(2));
      });
    });

    test('rep count increments correctly through multiple cycles', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 3, // 3 reps at 30:30
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);
        expect(provider.customTotalReps, equals(3));
        expect(provider.customRep, equals(1));

        // Skip prep
        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));

        // First cycle - complete hold and rest
        async.elapse(const Duration(seconds: 60));
        expect(provider.customRep, equals(2));

        // Second cycle - complete hold and rest
        async.elapse(const Duration(seconds: 60));
        expect(provider.customRep, equals(3));
      });
    });
  });

  group('Phase E1: Session Completes After All Reps Done (Custom Session)', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('session completes after all reps', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 2, // 2 reps at 30:30
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);
        expect(provider.customTotalReps, equals(2));

        // Skip prep
        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));

        // First rep: hold (30s) + rest (30s) = 60s
        async.elapse(const Duration(seconds: 60));
        expect(provider.customRep, equals(2));
        expect(provider.phase, equals(TimerPhase.hold));

        // Second rep: hold (30s) completes session
        async.elapse(const Duration(seconds: 30));

        expect(provider.phase, equals(TimerPhase.complete));
        expect(provider.timerState, equals(TimerState.stopped));
      });
    });

    test('session is not active after completion', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 1, // 1 rep at 30:30
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        // Skip prep
        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));

        // Complete single rep hold
        async.elapse(const Duration(seconds: 30));

        expect(provider.phase, equals(TimerPhase.complete));
        // After completion, timerState is stopped so isActive is false
        expect(provider.timerState, equals(TimerState.stopped));
      });
    });
  });

  group('Phase E1: pauseTimer() Stops Timer and Preserves State', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('pauseTimer sets timerState to paused', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);
      expect(provider.timerState, equals(TimerState.running));

      provider.pauseTimer();

      expect(provider.timerState, equals(TimerState.paused));
    });

    test('pauseTimer preserves phase', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        // Advance to hold phase
        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));
        expect(provider.phase, equals(TimerPhase.hold));

        provider.pauseTimer();

        expect(provider.phase, equals(TimerPhase.hold));
      });
    });

    test('pauseTimer preserves secondsRemaining', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        // Advance partway through prep
        async.elapse(const Duration(seconds: 5));
        final remainingBeforePause = provider.secondsRemaining;

        provider.pauseTimer();

        expect(provider.secondsRemaining, equals(remainingBeforePause));
      });
    });

    test('pauseTimer preserves rep count', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        // Advance past prep and first cycle
        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 61));
        final repBeforePause = provider.customRep;

        provider.pauseTimer();

        expect(provider.customRep, equals(repBeforePause));
      });
    });

    test('pauseTimer stops timer from advancing', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);
        final initialRemaining = provider.secondsRemaining;

        provider.pauseTimer();
        async.elapse(const Duration(seconds: 5));

        // Time should not have advanced while paused
        expect(provider.secondsRemaining, equals(initialRemaining));
      });
    });

    test('pauseTimer does nothing if already stopped', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);
      provider.cancelSession();
      expect(provider.timerState, equals(TimerState.stopped));

      provider.pauseTimer();

      expect(provider.timerState, equals(TimerState.stopped));
    });

    test('pauseTimer does nothing if already paused', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);
      provider.pauseTimer();
      expect(provider.timerState, equals(TimerState.paused));

      provider.pauseTimer();

      expect(provider.timerState, equals(TimerState.paused));
    });
  });

  group('Phase E1: resumeTimer() Continues From Paused State', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('resumeTimer sets timerState to running', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);
      provider.pauseTimer();
      expect(provider.timerState, equals(TimerState.paused));

      provider.resumeTimer();

      expect(provider.timerState, equals(TimerState.running));
    });

    test('resumeTimer continues from same phase', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        // Advance to hold phase
        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));
        expect(provider.phase, equals(TimerPhase.hold));

        provider.pauseTimer();
        provider.resumeTimer();

        expect(provider.phase, equals(TimerPhase.hold));
      });
    });

    test('resumeTimer allows timer to continue advancing', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        // Advance to hold phase
        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));
        expect(provider.phase, equals(TimerPhase.hold));

        provider.pauseTimer();
        provider.resumeTimer();

        // Advance through hold phase
        async.elapse(const Duration(seconds: 30));

        expect(provider.phase, equals(TimerPhase.rest));
      });
    });

    test('resumeTimer clears wasPausedByBackground flag', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);
      provider.pauseTimer();
      // Note: wasPausedByBackground is set by didChangeAppLifecycleState
      // For this test, we just verify resume clears it

      provider.resumeTimer();

      expect(provider.wasPausedByBackground, isFalse);
    });

    test('resumeTimer does nothing if not paused', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);
      expect(provider.timerState, equals(TimerState.running));

      provider.resumeTimer();

      expect(provider.timerState, equals(TimerState.running));
    });

    test('resumeTimer does nothing if stopped', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);
      provider.cancelSession();
      expect(provider.timerState, equals(TimerState.stopped));

      provider.resumeTimer();

      expect(provider.timerState, equals(TimerState.stopped));
    });
  });

  group('Phase E1: cancelSession() Cleans Up All State', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('cancelSession sets timerState to stopped', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);
      expect(provider.timerState, equals(TimerState.running));

      provider.cancelSession();

      expect(provider.timerState, equals(TimerState.stopped));
    });

    test('cancelSession sets phase to idle', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);
      provider.cancelSession();

      expect(provider.phase, equals(TimerPhase.idle));
    });

    test('cancelSession resets secondsRemaining to 0', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);
      provider.cancelSession();

      expect(provider.secondsRemaining, equals(0));
    });

    test('cancelSession clears custom config', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);
      expect(provider.isCustomSession, isTrue);

      provider.cancelSession();

      expect(provider.isCustomSession, isFalse);
    });

    test('cancelSession sets isActive to false', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);
      expect(provider.isActive, isTrue);

      provider.cancelSession();

      expect(provider.isActive, isFalse);
    });

    test('cancelSession can be called while paused', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);
      provider.pauseTimer();

      provider.cancelSession();

      expect(provider.timerState, equals(TimerState.stopped));
      expect(provider.phase, equals(TimerPhase.idle));
    });

    test('cancelSession resets exercise tracking', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);
      provider.cancelSession();

      expect(provider.currentExerciseIndex, equals(0));
      expect(provider.currentRep, equals(0));
    });

    test('cancelSession clears movement cue', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.lots,
      );

      provider.startCustomSession(config);
      provider.cancelSession();

      expect(provider.movementCue, isNull);
    });
  });

  group('Phase E1: OLY Session - startSession() Initialization', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('startSession initializes correct phase', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(reps: 3, workSeconds: 5, restSeconds: 3),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      expect(provider.phase, equals(TimerPhase.prep));
    });

    test('startSession initializes correct rep count', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(reps: 3, workSeconds: 5, restSeconds: 3),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      expect(provider.currentRep, equals(1));
    });

    test('startSession initializes correct exercise index', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(
          id: 'ex1',
          exerciseOrder: 1,
          reps: 3,
          workSeconds: 5,
          restSeconds: 3,
        ),
        MockOlySessionExercise(
          id: 'ex2',
          exerciseOrder: 2,
          reps: 2,
          workSeconds: 10,
          restSeconds: 5,
        ),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      expect(provider.currentExerciseIndex, equals(0));
    });

    test('startSession sets timer to running', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(reps: 3, workSeconds: 5, restSeconds: 3),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      expect(provider.timerState, equals(TimerState.running));
    });

    test('startSession sets prep countdown time', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(reps: 3, workSeconds: 5, restSeconds: 3),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      expect(provider.secondsRemaining, equals(kPrepCountdownSeconds));
    });

    test('startSession marks session as active', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(reps: 3, workSeconds: 5, restSeconds: 3),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      expect(provider.isActive, isTrue);
    });

    test('startSession stores active session template', () async {
      final template = MockOlySessionTemplate(
        id: 'template_test',
        name: 'Test Session',
      );
      final exercises = [
        MockOlySessionExercise(reps: 3, workSeconds: 5, restSeconds: 3),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      expect(provider.activeSession, equals(template));
    });

    test('startSession does not start if no exercises', () async {
      final template = MockOlySessionTemplate();

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => <OlySessionExercise>[]);

      await provider.startSession(template);

      expect(provider.activeSession, isNull);
      expect(provider.timerState, equals(TimerState.stopped));
    });
  });

  group('Phase E1: OLY Session - Timer Phase Transitions', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('timer advances from prep to hold using skipPhase', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(reps: 2, workSeconds: 5, restSeconds: 3),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);
      expect(provider.phase, equals(TimerPhase.prep));

      // Skip prep to advance to hold
      provider.skipPhase();

      expect(provider.phase, equals(TimerPhase.hold));
    });

    test('timer advances from hold to rest using skipPhase', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(reps: 2, workSeconds: 5, restSeconds: 3),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      // Skip prep
      provider.skipPhase();
      expect(provider.phase, equals(TimerPhase.hold));

      // Skip hold to rest
      provider.skipPhase();

      expect(provider.phase, equals(TimerPhase.rest));
    });

    test('timer advances from rest back to hold using skipPhase', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(reps: 2, workSeconds: 5, restSeconds: 3),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      // Skip prep to hold
      provider.skipPhase();

      // Skip hold to rest
      provider.skipPhase();
      expect(provider.phase, equals(TimerPhase.rest));

      // Skip rest back to hold (next rep)
      provider.skipPhase();

      expect(provider.phase, equals(TimerPhase.hold));
    });
  });

  group('Phase E1: OLY Session - Rep Counting', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('rep count starts at 1', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(reps: 3, workSeconds: 5, restSeconds: 3),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      expect(provider.currentRep, equals(1));
    });

    test('rep count increments after hold/rest cycle using skipPhase', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(reps: 3, workSeconds: 5, restSeconds: 3),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);
      expect(provider.currentRep, equals(1));

      // Skip prep -> hold
      provider.skipPhase();
      // Skip hold -> rest
      provider.skipPhase();
      // Skip rest -> hold (next rep)
      provider.skipPhase();

      expect(provider.currentRep, equals(2));
    });

    test('rep count increments correctly through multiple cycles using skipPhase', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(reps: 3, workSeconds: 5, restSeconds: 3),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      // Skip prep -> hold
      provider.skipPhase();

      // Complete first cycle: hold -> rest -> hold
      provider.skipPhase(); // hold -> rest
      provider.skipPhase(); // rest -> hold
      expect(provider.currentRep, equals(2));

      // Complete second cycle: hold -> rest -> hold
      provider.skipPhase(); // hold -> rest
      provider.skipPhase(); // rest -> hold
      expect(provider.currentRep, equals(3));
    });
  });

  group('Phase E1: OLY Session - Exercise Advancement', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('exercise advances after all reps complete using skipPhase', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(
          id: 'ex1',
          exerciseOrder: 1,
          reps: 2,
          workSeconds: 5,
          restSeconds: 3,
        ),
        MockOlySessionExercise(
          id: 'ex2',
          exerciseOrder: 2,
          reps: 2,
          workSeconds: 10,
          restSeconds: 5,
        ),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);
      expect(provider.currentExerciseIndex, equals(0));

      // Skip prep -> hold
      provider.skipPhase();

      // Complete first exercise (2 reps):
      // Rep 1: hold -> rest
      provider.skipPhase();
      // rest -> hold
      provider.skipPhase();
      // Rep 2: hold -> exerciseBreak (last rep of exercise)
      provider.skipPhase();

      // Should be in exercise break
      expect(provider.phase, equals(TimerPhase.exerciseBreak));
    });

    test('exercise index increments after exercise break using skipPhase', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(
          id: 'ex1',
          exerciseOrder: 1,
          reps: 2,
          workSeconds: 5,
          restSeconds: 3,
        ),
        MockOlySessionExercise(
          id: 'ex2',
          exerciseOrder: 2,
          reps: 2,
          workSeconds: 10,
          restSeconds: 5,
        ),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      // Skip prep -> hold
      provider.skipPhase();

      // Complete first exercise (2 reps)
      provider.skipPhase(); // hold -> rest
      provider.skipPhase(); // rest -> hold
      provider.skipPhase(); // hold -> exerciseBreak
      expect(provider.phase, equals(TimerPhase.exerciseBreak));

      // Skip exercise break -> next exercise hold
      provider.skipPhase();

      expect(provider.currentExerciseIndex, equals(1));
      expect(provider.phase, equals(TimerPhase.hold));
    });

    test('rep resets to 1 when moving to next exercise using skipPhase', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(
          id: 'ex1',
          exerciseOrder: 1,
          reps: 2,
          workSeconds: 5,
          restSeconds: 3,
        ),
        MockOlySessionExercise(
          id: 'ex2',
          exerciseOrder: 2,
          reps: 3,
          workSeconds: 10,
          restSeconds: 5,
        ),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      // Skip prep -> hold
      provider.skipPhase();

      // Complete first exercise
      provider.skipPhase(); // hold -> rest
      provider.skipPhase(); // rest -> hold
      provider.skipPhase(); // hold -> exerciseBreak

      // Skip exercise break -> next exercise
      provider.skipPhase();

      expect(provider.currentExerciseIndex, equals(1));
      expect(provider.currentRep, equals(1));
    });
  });

  group('Phase E1: OLY Session - Session Completion', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('session completes after all exercises done using skipPhase', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(
          id: 'ex1',
          exerciseOrder: 1,
          reps: 2,
          workSeconds: 5,
          restSeconds: 3,
        ),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      // Skip prep -> hold
      provider.skipPhase();

      // Complete single exercise (2 reps):
      // Rep 1: hold -> rest
      provider.skipPhase();
      // rest -> hold
      provider.skipPhase();
      // Rep 2: hold -> complete (last rep of last exercise)
      provider.skipPhase();

      expect(provider.phase, equals(TimerPhase.complete));
      expect(provider.timerState, equals(TimerState.stopped));
    });

    test('completedExercisesCount increments correctly using skipPhase', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(
          id: 'ex1',
          exerciseOrder: 1,
          reps: 2,
          workSeconds: 5,
          restSeconds: 3,
        ),
        MockOlySessionExercise(
          id: 'ex2',
          exerciseOrder: 2,
          reps: 2,
          workSeconds: 5,
          restSeconds: 3,
        ),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);
      expect(provider.completedExercisesCount, equals(0));

      // Skip prep -> hold
      provider.skipPhase();

      // Complete first exercise
      provider.skipPhase(); // hold -> rest
      provider.skipPhase(); // rest -> hold
      provider.skipPhase(); // hold -> exerciseBreak
      expect(provider.completedExercisesCount, equals(1));

      // Skip exercise break
      provider.skipPhase();

      // Complete second exercise
      provider.skipPhase(); // hold -> rest
      provider.skipPhase(); // rest -> hold
      provider.skipPhase(); // hold -> complete
      expect(provider.completedExercisesCount, equals(2));
    });

    test('session with multiple exercises completes correctly using skipPhase', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(
          id: 'ex1',
          exerciseOrder: 1,
          reps: 1,
          workSeconds: 5,
          restSeconds: 0,
        ),
        MockOlySessionExercise(
          id: 'ex2',
          exerciseOrder: 2,
          reps: 1,
          workSeconds: 5,
          restSeconds: 0,
        ),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      // Skip prep -> hold
      provider.skipPhase();

      // Complete first exercise (1 rep, no rest) -> exercise break
      provider.skipPhase();
      expect(provider.phase, equals(TimerPhase.exerciseBreak));

      // Skip exercise break
      provider.skipPhase();
      expect(provider.currentExerciseIndex, equals(1));

      // Complete second exercise (1 rep) -> complete
      provider.skipPhase();

      expect(provider.phase, equals(TimerPhase.complete));
      expect(provider.completedExercisesCount, equals(2));
    });
  });

  group('Phase E1: Skip Phase', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('skipPhase advances from prep to hold', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);
      expect(provider.phase, equals(TimerPhase.prep));

      provider.skipPhase();

      expect(provider.phase, equals(TimerPhase.hold));
    });

    test('skipPhase advances from hold to rest', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        // Skip prep to hold
        provider.skipPhase();
        expect(provider.phase, equals(TimerPhase.hold));

        // Skip hold to rest
        provider.skipPhase();

        expect(provider.phase, equals(TimerPhase.rest));
      });
    });

    test('skipPhase does nothing when stopped', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);
      provider.cancelSession();
      expect(provider.timerState, equals(TimerState.stopped));

      final phaseBefore = provider.phase;
      provider.skipPhase();

      expect(provider.phase, equals(phaseBefore));
    });
  });

  group('Phase E1: Total Hold Seconds Tracking', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('totalHoldSecondsActual starts at 0', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);

      expect(provider.totalHoldSecondsActual, equals(0));
    });

    test('totalHoldSecondsActual increments during hold phase', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        // Skip prep
        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));
        expect(provider.phase, equals(TimerPhase.hold));

        // Hold for 10 seconds
        async.elapse(const Duration(seconds: 10));

        expect(provider.totalHoldSecondsActual, greaterThanOrEqualTo(10));
      });
    });
  });

  group('Phase E1: Formatted Time Display', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('formattedTime shows prep countdown correctly', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);

      expect(provider.formattedTime, equals('00:10'));
    });

    test('formattedTime updates during countdown', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);
        expect(provider.formattedTime, equals('00:10'));

        async.elapse(const Duration(seconds: 5));

        expect(provider.formattedTime, equals('00:05'));
      });
    });

    test('formattedTime shows hold seconds correctly', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);

      // Use skipPhase to avoid timing issues
      provider.skipPhase();

      // Should show 30 seconds for hold phase
      expect(provider.formattedTime, equals('00:30'));
    });
  });

  group('Phase E1: Phase Display Name', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('phaseDisplayName shows Get Ready during prep', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);

      expect(provider.phaseDisplayName, equals('Get Ready'));
    });

    test('phaseDisplayName shows HOLD during hold', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));

        expect(provider.phaseDisplayName, equals('HOLD'));
      });
    });

    test('phaseDisplayName shows Rest during rest', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));
        async.elapse(const Duration(seconds: 30));

        expect(provider.phaseDisplayName, equals('Rest'));
      });
    });

    test('phaseDisplayName shows Complete when done', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 1, // 1 rep
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));
        async.elapse(const Duration(seconds: 30));

        expect(provider.phaseDisplayName, equals('Complete'));
      });
    });
  });

  group('Phase E1: Session Progress Tracking', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('sessionProgress starts at 0', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);

      expect(provider.sessionProgress, equals(0.0));
    });

    test('sessionProgress increases as reps complete', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 2, // 2 reps
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        // Skip prep
        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));

        // Complete first cycle
        async.elapse(const Duration(seconds: 60));

        // After first rep complete, progress should be 0.5 (1/2)
        expect(provider.sessionProgress, closeTo(0.5, 0.1));
      });
    });
  });

  group('Phase E1: Phase Durations From Exercise Config', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('hold phase uses workSeconds from exercise config', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(
          reps: 2,
          workSeconds: 15, // Custom hold duration
          restSeconds: 5,
        ),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      // Skip prep to hold
      provider.skipPhase();
      expect(provider.phase, equals(TimerPhase.hold));
      expect(provider.secondsRemaining, equals(15)); // Should use workSeconds from config
    });

    test('rest phase uses restSeconds from exercise config', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(
          reps: 2,
          workSeconds: 10,
          restSeconds: 8, // Custom rest duration
        ),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      // Skip prep to hold
      provider.skipPhase();
      // Skip hold to rest
      provider.skipPhase();

      expect(provider.phase, equals(TimerPhase.rest));
      expect(provider.secondsRemaining, equals(8)); // Should use restSeconds from config
    });

    test('custom session uses ratio holdSeconds for hold duration', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio25_35, // 25 second hold
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);

      // Skip prep to hold
      provider.skipPhase();

      expect(provider.phase, equals(TimerPhase.hold));
      expect(provider.secondsRemaining, equals(25)); // Should use ratio holdSeconds
    });

    test('custom session uses ratio restSeconds for rest duration', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio25_35, // 35 second rest
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);

      // Skip prep to hold
      provider.skipPhase();
      // Skip hold to rest
      provider.skipPhase();

      expect(provider.phase, equals(TimerPhase.rest));
      expect(provider.secondsRemaining, equals(35)); // Should use ratio restSeconds
    });

    test('different exercises use their own workSeconds', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(
          id: 'ex1',
          exerciseOrder: 1,
          reps: 1,
          workSeconds: 5, // First exercise: 5 seconds
          restSeconds: 0,
        ),
        MockOlySessionExercise(
          id: 'ex2',
          exerciseOrder: 2,
          reps: 1,
          workSeconds: 12, // Second exercise: 12 seconds
          restSeconds: 0,
        ),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      // Skip prep to hold
      provider.skipPhase();
      expect(provider.secondsRemaining, equals(5)); // First exercise workSeconds

      // Skip hold -> exerciseBreak (since only 1 rep)
      provider.skipPhase();
      expect(provider.phase, equals(TimerPhase.exerciseBreak));

      // Skip exerciseBreak -> next exercise hold
      provider.skipPhase();
      expect(provider.phase, equals(TimerPhase.hold));
      expect(provider.secondsRemaining, equals(12)); // Second exercise workSeconds
    });

    test('skipping rest when restSeconds is 0', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(
          reps: 3,
          workSeconds: 5,
          restSeconds: 0, // No rest between reps
        ),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      // Skip prep to hold (rep 1)
      provider.skipPhase();
      expect(provider.phase, equals(TimerPhase.hold));
      expect(provider.currentRep, equals(1));

      // Skip hold - should go directly to next hold (no rest)
      provider.skipPhase();
      expect(provider.phase, equals(TimerPhase.hold)); // Should stay in hold, not rest
      expect(provider.currentRep, equals(2));

      // Skip again
      provider.skipPhase();
      expect(provider.phase, equals(TimerPhase.hold));
      expect(provider.currentRep, equals(3));
    });
  });

  group('Phase E1: Feedback Mode Timing Capture During Hold', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('movement cue is generated during hold with stimulus lots', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.lots, // Always show cue
      );

      provider.startCustomSession(config);

      // Skip prep to hold
      provider.skipPhase();

      expect(provider.phase, equals(TimerPhase.hold));
      expect(provider.movementCue, isNotNull); // Should have a cue
    });

    test('movement cue is null with stimulus none', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none, // No cues
      );

      provider.startCustomSession(config);

      // Skip prep to hold
      provider.skipPhase();

      expect(provider.phase, equals(TimerPhase.hold));
      expect(provider.movementCue, isNull); // Should not have a cue
    });

    test('movement cue is cleared during rest', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.lots,
        );

        provider.startCustomSession(config);

        // Skip prep to hold
        provider.skipPhase();
        expect(provider.movementCue, isNotNull);

        // Skip hold to rest
        provider.skipPhase();

        expect(provider.phase, equals(TimerPhase.rest));
        expect(provider.movementCue, isNull); // Cue cleared during rest
      });
    });

    test('movement cue is regenerated when entering next hold', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.lots,
      );

      provider.startCustomSession(config);

      // Skip prep to hold
      provider.skipPhase();
      final firstCue = provider.movementCue;
      expect(firstCue, isNotNull);

      // Skip hold to rest
      provider.skipPhase();
      expect(provider.movementCue, isNull);

      // Skip rest to next hold
      provider.skipPhase();
      expect(provider.phase, equals(TimerPhase.hold));
      expect(provider.movementCue, isNotNull); // Cue regenerated
    });

    test('totalHoldSecondsActual tracks actual hold time', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);
        expect(provider.totalHoldSecondsActual, equals(0));

        // Skip prep to hold
        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));
        expect(provider.phase, equals(TimerPhase.hold));

        // Hold for 15 seconds
        async.elapse(const Duration(seconds: 15));

        // Should have tracked around 15 seconds (may be +/- 1 due to timing)
        expect(provider.totalHoldSecondsActual, greaterThanOrEqualTo(15));
      });
    });

    test('totalHoldSecondsActual does not increment during rest', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        // Skip prep to hold
        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));

        // Complete full hold (30 seconds)
        async.elapse(const Duration(seconds: 30));
        expect(provider.phase, equals(TimerPhase.rest));

        final holdSecondsAfterFirstHold = provider.totalHoldSecondsActual;

        // Rest for 15 seconds
        async.elapse(const Duration(seconds: 15));

        // Hold seconds should not have increased during rest
        expect(provider.totalHoldSecondsActual, equals(holdSecondsAfterFirstHold));
      });
    });

    test('OLY session does not use movement cues', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(reps: 2, workSeconds: 5, restSeconds: 3),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      // Skip prep to hold
      provider.skipPhase();

      expect(provider.phase, equals(TimerPhase.hold));
      expect(provider.movementCue, isNull); // OLY sessions don't have movement cues
    });
  });

  group('Phase E1: Warm-up Phase Handling', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('custom session without warm-up starts directly at prep', () {
      const config = CustomSessionConfig(
        durationMinutes: 5,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);

      // Should start at prep, not a separate warm-up phase
      expect(provider.phase, equals(TimerPhase.prep));
      expect(provider.secondsRemaining, equals(kPrepCountdownSeconds));
    });

    test('OLY session starts directly at prep', () async {
      final template = MockOlySessionTemplate();
      final exercises = [
        MockOlySessionExercise(reps: 2, workSeconds: 5, restSeconds: 3),
      ];

      when(() => mockDb.getOlySessionExercises(template.id))
          .thenAnswer((_) async => exercises);

      await provider.startSession(template);

      // Should start at prep, not a separate warm-up phase
      expect(provider.phase, equals(TimerPhase.prep));
      expect(provider.secondsRemaining, equals(kPrepCountdownSeconds));
    });

    test('default warm-up config has correct values', () {
      // Verify the default warm-up configuration
      expect(CustomSessionConfig.defaultWarmUp.durationMinutes, equals(5));
      expect(CustomSessionConfig.defaultWarmUp.ratio.holdSeconds, equals(30));
      expect(CustomSessionConfig.defaultWarmUp.ratio.restSeconds, equals(30));
      expect(
        CustomSessionConfig.defaultWarmUp.movementStimulus,
        equals(MovementStimulus.none),
      );
    });

    test('warm-up session behaves like regular custom session', () {
      provider.startCustomSession(CustomSessionConfig.defaultWarmUp);

      // Should start at prep, same as any other session
      expect(provider.phase, equals(TimerPhase.prep));
      expect(provider.isCustomSession, isTrue);

      // Skip prep to hold
      provider.skipPhase();
      expect(provider.phase, equals(TimerPhase.hold));
      expect(provider.secondsRemaining, equals(30)); // 30 second hold from 30:30 ratio

      // Skip hold to rest
      provider.skipPhase();
      expect(provider.phase, equals(TimerPhase.rest));
      expect(provider.secondsRemaining, equals(30)); // 30 second rest from 30:30 ratio
    });

    test('prep phase is always included at session start', () {
      const config = CustomSessionConfig(
        durationMinutes: 1,
        ratio: HoldRestRatio.ratio30_30,
        movementStimulus: MovementStimulus.none,
      );

      provider.startCustomSession(config);

      // Prep is the first phase for all sessions (not skippable by config)
      expect(provider.phase, equals(TimerPhase.prep));
      expect(provider.secondsRemaining, equals(kPrepCountdownSeconds));
    });
  });

  group('Phase E1: Pause/Resume Integration', () {
    late MockAppDatabase mockDb;
    late BowTrainingProvider provider;

    setUp(() {
      mockDb = MockAppDatabase();
      provider = BowTrainingProvider(mockDb);
    });

    tearDown(() {
      provider.dispose();
    });

    test('full pause and resume cycle preserves state', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        // Advance to hold phase
        async.elapse(const Duration(seconds: kPrepCountdownSeconds + 1));
        expect(provider.phase, equals(TimerPhase.hold));

        // Advance partway through hold
        async.elapse(const Duration(seconds: 10));
        final remainingBeforePause = provider.secondsRemaining;
        final repBeforePause = provider.customRep;

        // Pause
        provider.pauseTimer();
        async.elapse(const Duration(seconds: 30)); // Time passes while paused

        // Resume
        provider.resumeTimer();

        // State should be preserved
        expect(provider.phase, equals(TimerPhase.hold));
        expect(provider.secondsRemaining, equals(remainingBeforePause));
        expect(provider.customRep, equals(repBeforePause));
        expect(provider.timerState, equals(TimerState.running));
      });
    });

    test('multiple pause/resume cycles work correctly', () {
      fakeAsync((async) {
        const config = CustomSessionConfig(
          durationMinutes: 5,
          ratio: HoldRestRatio.ratio30_30,
          movementStimulus: MovementStimulus.none,
        );

        provider.startCustomSession(config);

        // First pause/resume
        provider.pauseTimer();
        provider.resumeTimer();
        expect(provider.timerState, equals(TimerState.running));

        // Advance some time
        async.elapse(const Duration(seconds: 5));

        // Second pause/resume
        provider.pauseTimer();
        provider.resumeTimer();
        expect(provider.timerState, equals(TimerState.running));

        // Timer should still be functioning
        async.elapse(const Duration(seconds: kPrepCountdownSeconds));
        expect(provider.phase, equals(TimerPhase.hold));
      });
    });
  });
}
