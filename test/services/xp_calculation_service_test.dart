/// Tests for XpCalculationService
///
/// These tests verify the XP reward and level progression system including:
/// - Level curve calculations (xpForLevel, levelFromXp)
/// - Progress tracking (xpToNextLevel, progressToNextLevel)
/// - XP calculations for all skill types:
///   - Archery (handicap-based)
///   - Volume (arrow count)
///   - Consistency (training days + streak)
///   - Bow Fitness (hold time + quality)
///   - Breath Work (hold + exhale times)
///   - Equipment (tuning sessions + snapshots)
///   - Competition (score + practice comparison)
///   - Analysis (plotted arrows)
/// - Level milestones and descriptions
///
/// The system uses a RuneScape-inspired 1-99 leveling system with:
/// - Level 1 = 0 XP
/// - Level 99 = ~500,000 XP
/// - Formula: (level - 1)^2.5 * 5
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/services/xp_calculation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('XpCalculationService', () {
    // ========================================================================
    // SKILL CONSTANTS
    // ========================================================================
    group('skill constants', () {
      test('archerySkill constant is correct', () {
        expect(XpCalculationService.archerySkill, equals('archery_skill'));
      });

      test('volume constant is correct', () {
        expect(XpCalculationService.volume, equals('volume'));
      });

      test('consistency constant is correct', () {
        expect(XpCalculationService.consistency, equals('consistency'));
      });

      test('bowFitness constant is correct', () {
        expect(XpCalculationService.bowFitness, equals('bow_fitness'));
      });

      test('breathWork constant is correct', () {
        expect(XpCalculationService.breathWork, equals('breath_work'));
      });

      test('equipment constant is correct', () {
        expect(XpCalculationService.equipment, equals('equipment'));
      });

      test('competition constant is correct', () {
        expect(XpCalculationService.competition, equals('competition'));
      });

      test('analysis constant is correct', () {
        expect(XpCalculationService.analysis, equals('analysis'));
      });

      test('maxLevel is 99', () {
        expect(XpCalculationService.maxLevel, equals(99));
      });

      test('maxTotalXp is 500000', () {
        expect(XpCalculationService.maxTotalXp, equals(500000));
      });
    });

    // ========================================================================
    // LEVEL CURVE - xpForLevel
    // ========================================================================
    group('xpForLevel', () {
      test('level 1 requires 0 XP', () {
        expect(XpCalculationService.xpForLevel(1), equals(0));
      });

      test('level 0 returns 0 XP (clamped)', () {
        expect(XpCalculationService.xpForLevel(0), equals(0));
      });

      test('negative level returns 0 XP (clamped)', () {
        expect(XpCalculationService.xpForLevel(-1), equals(0));
        expect(XpCalculationService.xpForLevel(-100), equals(0));
      });

      test('level 2 requires correct XP', () {
        // (2-1)^2.5 * 5 = 1^2.5 * 5 = 5
        expect(XpCalculationService.xpForLevel(2), equals(5));
      });

      test('level 3 requires correct XP', () {
        // (3-1)^2.5 * 5 = 2^2.5 * 5 ≈ 5.656 * 5 ≈ 28
        final xp = XpCalculationService.xpForLevel(3);
        expect(xp, greaterThan(20));
        expect(xp, lessThan(35));
      });

      test('level 10 requires correct XP', () {
        // (10-1)^2.5 * 5 = 9^2.5 * 5 = 243 * 5 = 1215
        final xp = XpCalculationService.xpForLevel(10);
        expect(xp, equals(1215));
      });

      test('level 50 is approximately 15% of max XP', () {
        final level50Xp = XpCalculationService.xpForLevel(50);
        final maxXp = XpCalculationService.maxTotalXp;
        final percentage = level50Xp / maxXp;
        // Should be around 15% according to comments
        expect(percentage, greaterThan(0.10));
        expect(percentage, lessThan(0.25));
      });

      test('level 75 is approximately 40% of max XP', () {
        final level75Xp = XpCalculationService.xpForLevel(75);
        final maxXp = XpCalculationService.maxTotalXp;
        final percentage = level75Xp / maxXp;
        // Should be around 40% according to comments
        expect(percentage, greaterThan(0.30));
        expect(percentage, lessThan(0.50));
      });

      test('level 92 is approximately 70% of max XP (RS halfway point)', () {
        final level92Xp = XpCalculationService.xpForLevel(92);
        final maxXp = XpCalculationService.maxTotalXp;
        final percentage = level92Xp / maxXp;
        // Should be around 70% according to comments
        expect(percentage, greaterThan(0.60));
        expect(percentage, lessThan(0.80));
      });

      test('level 99 requires approximately maxTotalXp', () {
        final xp = XpCalculationService.xpForLevel(99);
        // Should be close to 500,000
        expect(xp, greaterThan(400000));
        expect(xp, lessThan(600000));
      });

      test('level above 99 is clamped to level 99 XP', () {
        final level99Xp = XpCalculationService.xpForLevel(99);
        expect(XpCalculationService.xpForLevel(100), equals(level99Xp));
        expect(XpCalculationService.xpForLevel(150), equals(level99Xp));
      });

      test('XP requirements increase with level', () {
        int previousXp = 0;
        for (int level = 2; level <= 99; level++) {
          final currentXp = XpCalculationService.xpForLevel(level);
          expect(currentXp, greaterThan(previousXp),
              reason: 'Level $level should require more XP than level ${level - 1}');
          previousXp = currentXp;
        }
      });

      test('XP gap between levels increases at higher levels', () {
        // Gap between level 10 and 11
        final gap10to11 = XpCalculationService.xpForLevel(11) -
            XpCalculationService.xpForLevel(10);

        // Gap between level 90 and 91
        final gap90to91 = XpCalculationService.xpForLevel(91) -
            XpCalculationService.xpForLevel(90);

        expect(gap90to91, greaterThan(gap10to11));
      });
    });

    // ========================================================================
    // LEVEL CURVE - levelFromXp
    // ========================================================================
    group('levelFromXp', () {
      test('0 XP returns level 1', () {
        expect(XpCalculationService.levelFromXp(0), equals(1));
      });

      test('negative XP returns level 1', () {
        expect(XpCalculationService.levelFromXp(-1), equals(1));
        expect(XpCalculationService.levelFromXp(-1000), equals(1));
      });

      test('1 XP returns level 1', () {
        expect(XpCalculationService.levelFromXp(1), equals(1));
      });

      test('5 XP returns level 2', () {
        expect(XpCalculationService.levelFromXp(5), equals(2));
      });

      test('XP just below level 2 threshold returns level 1', () {
        expect(XpCalculationService.levelFromXp(4), equals(1));
      });

      test('level 10 XP threshold returns level 10', () {
        final level10Xp = XpCalculationService.xpForLevel(10);
        expect(XpCalculationService.levelFromXp(level10Xp), equals(10));
      });

      test('XP between levels returns lower level', () {
        final level10Xp = XpCalculationService.xpForLevel(10);
        final level11Xp = XpCalculationService.xpForLevel(11);
        final midXp = (level10Xp + level11Xp) ~/ 2;
        expect(XpCalculationService.levelFromXp(midXp), equals(10));
      });

      test('level 99 XP threshold returns level 99', () {
        final level99Xp = XpCalculationService.xpForLevel(99);
        expect(XpCalculationService.levelFromXp(level99Xp), equals(99));
      });

      test('XP above level 99 returns level 99', () {
        expect(XpCalculationService.levelFromXp(1000000), equals(99));
      });

      test('levelFromXp is inverse of xpForLevel', () {
        for (int level = 1; level <= 99; level++) {
          final xp = XpCalculationService.xpForLevel(level);
          expect(XpCalculationService.levelFromXp(xp), equals(level),
              reason: 'levelFromXp should return $level for xpForLevel($level)');
        }
      });

      test('XP slightly above threshold still returns correct level', () {
        for (int level = 2; level <= 50; level++) {
          final xp = XpCalculationService.xpForLevel(level) + 1;
          expect(XpCalculationService.levelFromXp(xp), equals(level),
              reason: 'XP=${xp} (threshold+1) should be level $level');
        }
      });
    });

    // ========================================================================
    // LEVEL CURVE - xpToNextLevel
    // ========================================================================
    group('xpToNextLevel', () {
      test('at level 1 with 0 XP, returns XP needed for level 2', () {
        final xpNeeded = XpCalculationService.xpToNextLevel(0);
        final level2Xp = XpCalculationService.xpForLevel(2);
        expect(xpNeeded, equals(level2Xp));
      });

      test('at level 2 threshold, returns XP needed for level 3', () {
        final level2Xp = XpCalculationService.xpForLevel(2);
        final level3Xp = XpCalculationService.xpForLevel(3);
        final xpNeeded = XpCalculationService.xpToNextLevel(level2Xp);
        expect(xpNeeded, equals(level3Xp - level2Xp));
      });

      test('mid-level returns remaining XP to next level', () {
        final level10Xp = XpCalculationService.xpForLevel(10);
        final level11Xp = XpCalculationService.xpForLevel(11);
        final midXp = level10Xp + 100;
        final xpNeeded = XpCalculationService.xpToNextLevel(midXp);
        expect(xpNeeded, equals(level11Xp - midXp));
      });

      test('at level 99, returns 0 (max level)', () {
        final level99Xp = XpCalculationService.xpForLevel(99);
        expect(XpCalculationService.xpToNextLevel(level99Xp), equals(0));
      });

      test('above level 99 XP, returns 0', () {
        expect(XpCalculationService.xpToNextLevel(1000000), equals(0));
      });

      test('xpToNextLevel decreases as you gain XP within a level', () {
        final level10Xp = XpCalculationService.xpForLevel(10);
        final level11Xp = XpCalculationService.xpForLevel(11);

        final xpNeededAtStart = XpCalculationService.xpToNextLevel(level10Xp);
        final xpNeededAtMid = XpCalculationService.xpToNextLevel(level10Xp + 100);
        final xpNeededNearEnd = XpCalculationService.xpToNextLevel(level11Xp - 10);

        expect(xpNeededAtMid, lessThan(xpNeededAtStart));
        expect(xpNeededNearEnd, lessThan(xpNeededAtMid));
        expect(xpNeededNearEnd, equals(10));
      });
    });

    // ========================================================================
    // LEVEL CURVE - progressToNextLevel
    // ========================================================================
    group('progressToNextLevel', () {
      test('at level 1 with 0 XP, progress is 0.0', () {
        expect(XpCalculationService.progressToNextLevel(0), equals(0.0));
      });

      test('at level threshold, progress is 0.0', () {
        final level10Xp = XpCalculationService.xpForLevel(10);
        expect(XpCalculationService.progressToNextLevel(level10Xp), equals(0.0));
      });

      test('halfway through level returns approximately 0.5', () {
        final level10Xp = XpCalculationService.xpForLevel(10);
        final level11Xp = XpCalculationService.xpForLevel(11);
        final midXp = level10Xp + (level11Xp - level10Xp) ~/ 2;
        final progress = XpCalculationService.progressToNextLevel(midXp);
        expect(progress, greaterThan(0.45));
        expect(progress, lessThan(0.55));
      });

      test('just before level up returns close to 1.0', () {
        final level11Xp = XpCalculationService.xpForLevel(11);
        final progress = XpCalculationService.progressToNextLevel(level11Xp - 1);
        expect(progress, greaterThan(0.95));
        expect(progress, lessThan(1.0));
      });

      test('at level 99, progress is 1.0', () {
        final level99Xp = XpCalculationService.xpForLevel(99);
        expect(XpCalculationService.progressToNextLevel(level99Xp), equals(1.0));
      });

      test('above level 99 XP, progress is 1.0', () {
        expect(XpCalculationService.progressToNextLevel(1000000), equals(1.0));
      });

      test('progress is clamped between 0.0 and 1.0', () {
        for (int xp = 0; xp < 100000; xp += 1000) {
          final progress = XpCalculationService.progressToNextLevel(xp);
          expect(progress, greaterThanOrEqualTo(0.0));
          expect(progress, lessThanOrEqualTo(1.0));
        }
      });

      test('progress increases monotonically within a level', () {
        final level10Xp = XpCalculationService.xpForLevel(10);
        final level11Xp = XpCalculationService.xpForLevel(11);

        double previousProgress = 0.0;
        for (int xp = level10Xp; xp < level11Xp; xp += 10) {
          final progress = XpCalculationService.progressToNextLevel(xp);
          expect(progress, greaterThanOrEqualTo(previousProgress));
          previousProgress = progress;
        }
      });
    });

    // ========================================================================
    // XP CALCULATIONS - Archery Skill
    // ========================================================================
    group('calculateArcheryXp', () {
      test('elite archer (handicap 0) gets 1500 XP', () {
        expect(
          XpCalculationService.calculateArcheryXp(handicap: 0),
          equals(1500),
        );
      });

      test('average club archer (handicap 60) gets 900 XP', () {
        expect(
          XpCalculationService.calculateArcheryXp(handicap: 60),
          equals(900),
        );
      });

      test('beginner (handicap 100) gets 500 XP', () {
        expect(
          XpCalculationService.calculateArcheryXp(handicap: 100),
          equals(500),
        );
      });

      test('handicap 150 gives 0 XP', () {
        expect(
          XpCalculationService.calculateArcheryXp(handicap: 150),
          equals(0),
        );
      });

      test('handicap above 150 gives 0 XP (clamped)', () {
        expect(
          XpCalculationService.calculateArcheryXp(handicap: 200),
          equals(0),
        );
      });

      test('XP decreases linearly with handicap', () {
        final xp0 = XpCalculationService.calculateArcheryXp(handicap: 0);
        final xp50 = XpCalculationService.calculateArcheryXp(handicap: 50);
        final xp100 = XpCalculationService.calculateArcheryXp(handicap: 100);

        // Linear decrease: each handicap point reduces XP by 10
        expect(xp0 - xp50, equals(500));
        expect(xp50 - xp100, equals(500));
      });

      test('common handicap values give expected XP', () {
        expect(XpCalculationService.calculateArcheryXp(handicap: 10), equals(1400));
        expect(XpCalculationService.calculateArcheryXp(handicap: 25), equals(1250));
        expect(XpCalculationService.calculateArcheryXp(handicap: 40), equals(1100));
        expect(XpCalculationService.calculateArcheryXp(handicap: 75), equals(750));
        expect(XpCalculationService.calculateArcheryXp(handicap: 90), equals(600));
      });
    });

    // ========================================================================
    // XP CALCULATIONS - Volume Skill
    // ========================================================================
    group('calculateVolumeXp', () {
      test('0 arrows gives 0 XP', () {
        expect(XpCalculationService.calculateVolumeXp(arrowCount: 0), equals(0));
      });

      test('1 arrow gives 1 XP', () {
        expect(XpCalculationService.calculateVolumeXp(arrowCount: 1), equals(1));
      });

      test('100 arrows gives 100 XP', () {
        expect(XpCalculationService.calculateVolumeXp(arrowCount: 100), equals(100));
      });

      test('negative arrow count gives 0 XP', () {
        expect(XpCalculationService.calculateVolumeXp(arrowCount: -10), equals(0));
      });

      test('typical practice session arrow counts', () {
        // Short session: 30 arrows
        expect(XpCalculationService.calculateVolumeXp(arrowCount: 30), equals(30));
        // Medium session: 60 arrows
        expect(XpCalculationService.calculateVolumeXp(arrowCount: 60), equals(60));
        // Long session: 120 arrows
        expect(XpCalculationService.calculateVolumeXp(arrowCount: 120), equals(120));
        // Competition round: 72 arrows (720 round)
        expect(XpCalculationService.calculateVolumeXp(arrowCount: 72), equals(72));
      });
    });

    // ========================================================================
    // XP CALCULATIONS - Consistency Skill
    // ========================================================================
    group('calculateConsistencyXp', () {
      test('0 days gives 0 XP', () {
        expect(
          XpCalculationService.calculateConsistencyXp(daysThisWeek: 0),
          equals(0),
        );
      });

      test('1 day gives 50 XP base', () {
        expect(
          XpCalculationService.calculateConsistencyXp(daysThisWeek: 1),
          equals(50),
        );
      });

      test('7 days gives 350 XP base (no streak)', () {
        expect(
          XpCalculationService.calculateConsistencyXp(daysThisWeek: 7),
          equals(350),
        );
      });

      test('streak bonus adds 10% per day up to 7 days', () {
        // 1 day with 1 day streak: 50 * 1.1 = 55
        expect(
          XpCalculationService.calculateConsistencyXp(
            daysThisWeek: 1,
            streakDays: 1,
          ),
          equals(55),
        );

        // 1 day with 3 day streak: 50 * 1.3 = 65
        expect(
          XpCalculationService.calculateConsistencyXp(
            daysThisWeek: 1,
            streakDays: 3,
          ),
          equals(65),
        );

        // 1 day with 7 day streak: 50 * 1.7 = 85
        expect(
          XpCalculationService.calculateConsistencyXp(
            daysThisWeek: 1,
            streakDays: 7,
          ),
          equals(85),
        );
      });

      test('streak bonus caps at 7 days (70%)', () {
        // Streak of 10 should be same as streak of 7
        final xp7DayStreak = XpCalculationService.calculateConsistencyXp(
          daysThisWeek: 1,
          streakDays: 7,
        );
        final xp10DayStreak = XpCalculationService.calculateConsistencyXp(
          daysThisWeek: 1,
          streakDays: 10,
        );
        expect(xp10DayStreak, equals(xp7DayStreak));
      });

      test('0 streak days gives no bonus', () {
        expect(
          XpCalculationService.calculateConsistencyXp(
            daysThisWeek: 3,
            streakDays: 0,
          ),
          equals(150),
        );
      });

      test('full week with max streak gives expected XP', () {
        // 7 days * 50 = 350, then * 1.7 = 595
        expect(
          XpCalculationService.calculateConsistencyXp(
            daysThisWeek: 7,
            streakDays: 7,
          ),
          equals(595),
        );
      });

      test('typical training patterns', () {
        // Casual: 2 days/week, no streak
        expect(
          XpCalculationService.calculateConsistencyXp(daysThisWeek: 2),
          equals(100),
        );

        // Dedicated: 4 days/week with 3 day streak
        expect(
          XpCalculationService.calculateConsistencyXp(
            daysThisWeek: 4,
            streakDays: 3,
          ),
          equals(260), // 200 * 1.3 = 260
        );

        // Elite: 6 days/week with 7 day streak
        expect(
          XpCalculationService.calculateConsistencyXp(
            daysThisWeek: 6,
            streakDays: 7,
          ),
          equals(510), // 300 * 1.7 = 510
        );
      });
    });

    // ========================================================================
    // XP CALCULATIONS - Bow Fitness Skill
    // ========================================================================
    group('calculateBowFitnessXp', () {
      test('0 hold seconds gives 0 XP', () {
        expect(
          XpCalculationService.calculateBowFitnessXp(totalHoldSeconds: 0),
          equals(0),
        );
      });

      test('base XP is 1 per second with no bonus (high feedback)', () {
        // With high feedback values (poor form), no bonus applies
        expect(
          XpCalculationService.calculateBowFitnessXp(
            totalHoldSeconds: 100,
            feedbackShaking: 7,
            feedbackStructure: 7,
            feedbackRest: 7,
          ),
          equals(100),
        );
      });

      test('default feedback values give good form bonus', () {
        // Default feedback is 5,5,5 which averages to 5 (good form = +25%)
        expect(
          XpCalculationService.calculateBowFitnessXp(totalHoldSeconds: 100),
          equals(125), // 100 * 1.25
        );
      });

      test('excellent form (avg feedback <= 3) gives 50% bonus', () {
        // 100 seconds * 1.5 = 150
        expect(
          XpCalculationService.calculateBowFitnessXp(
            totalHoldSeconds: 100,
            feedbackShaking: 2,
            feedbackStructure: 3,
            feedbackRest: 3,
          ),
          equals(150),
        );
      });

      test('good form (avg feedback <= 5) gives 25% bonus', () {
        // 100 seconds * 1.25 = 125
        expect(
          XpCalculationService.calculateBowFitnessXp(
            totalHoldSeconds: 100,
            feedbackShaking: 4,
            feedbackStructure: 5,
            feedbackRest: 5,
          ),
          equals(125),
        );
      });

      test('mediocre form (avg feedback > 5) gives no bonus', () {
        // 100 seconds, no multiplier
        expect(
          XpCalculationService.calculateBowFitnessXp(
            totalHoldSeconds: 100,
            feedbackShaking: 7,
            feedbackStructure: 6,
            feedbackRest: 8,
          ),
          equals(100),
        );
      });

      test('poor form (high feedback values) gives no bonus', () {
        expect(
          XpCalculationService.calculateBowFitnessXp(
            totalHoldSeconds: 100,
            feedbackShaking: 10,
            feedbackStructure: 10,
            feedbackRest: 10,
          ),
          equals(100),
        );
      });

      test('perfect form (all 1s) gives 50% bonus', () {
        expect(
          XpCalculationService.calculateBowFitnessXp(
            totalHoldSeconds: 100,
            feedbackShaking: 1,
            feedbackStructure: 1,
            feedbackRest: 1,
          ),
          equals(150),
        );
      });

      test('typical OLY training session XP', () {
        // 10 minute session = 600 seconds with decent form
        expect(
          XpCalculationService.calculateBowFitnessXp(
            totalHoldSeconds: 600,
            feedbackShaking: 4,
            feedbackStructure: 4,
            feedbackRest: 4,
          ),
          equals(750), // 600 * 1.25 = 750
        );
      });

      test('boundary case at exactly avg 3 gives 50% bonus', () {
        expect(
          XpCalculationService.calculateBowFitnessXp(
            totalHoldSeconds: 100,
            feedbackShaking: 3,
            feedbackStructure: 3,
            feedbackRest: 3,
          ),
          equals(150),
        );
      });

      test('boundary case at exactly avg 5 gives 25% bonus', () {
        expect(
          XpCalculationService.calculateBowFitnessXp(
            totalHoldSeconds: 100,
            feedbackShaking: 5,
            feedbackStructure: 5,
            feedbackRest: 5,
          ),
          equals(125),
        );
      });
    });

    // ========================================================================
    // XP CALCULATIONS - Breath Work Skill
    // ========================================================================
    group('calculateBreathWorkXp', () {
      test('null values give 0 XP', () {
        expect(XpCalculationService.calculateBreathWorkXp(), equals(0));
      });

      test('0 seconds give 0 XP', () {
        expect(
          XpCalculationService.calculateBreathWorkXp(
            bestHoldSeconds: 0,
            bestExhaleSeconds: 0,
          ),
          equals(0),
        );
      });

      test('breath hold gives 1 XP per 2 seconds', () {
        expect(
          XpCalculationService.calculateBreathWorkXp(bestHoldSeconds: 10),
          equals(5),
        );
        expect(
          XpCalculationService.calculateBreathWorkXp(bestHoldSeconds: 60),
          equals(30),
        );
      });

      test('exhale gives 1 XP per 2 seconds', () {
        expect(
          XpCalculationService.calculateBreathWorkXp(bestExhaleSeconds: 20),
          equals(10),
        );
        expect(
          XpCalculationService.calculateBreathWorkXp(bestExhaleSeconds: 40),
          equals(20),
        );
      });

      test('combined hold and exhale XP', () {
        // 30 second hold = 15 XP, 20 second exhale = 10 XP
        expect(
          XpCalculationService.calculateBreathWorkXp(
            bestHoldSeconds: 30,
            bestExhaleSeconds: 20,
          ),
          equals(25),
        );
      });

      test('odd seconds truncate down', () {
        // 7 seconds / 2 = 3 XP
        expect(
          XpCalculationService.calculateBreathWorkXp(bestHoldSeconds: 7),
          equals(3),
        );
        // 15 seconds / 2 = 7 XP
        expect(
          XpCalculationService.calculateBreathWorkXp(bestExhaleSeconds: 15),
          equals(7),
        );
      });

      test('negative values give 0 XP', () {
        expect(
          XpCalculationService.calculateBreathWorkXp(bestHoldSeconds: -10),
          equals(0),
        );
        expect(
          XpCalculationService.calculateBreathWorkXp(bestExhaleSeconds: -10),
          equals(0),
        );
      });

      test('typical Patrick breath test results', () {
        // Good: 60 second hold, 30 second exhale
        expect(
          XpCalculationService.calculateBreathWorkXp(
            bestHoldSeconds: 60,
            bestExhaleSeconds: 30,
          ),
          equals(45), // 30 + 15
        );

        // Excellent: 90 second hold, 45 second exhale
        expect(
          XpCalculationService.calculateBreathWorkXp(
            bestHoldSeconds: 90,
            bestExhaleSeconds: 45,
          ),
          equals(67), // 45 + 22
        );
      });
    });

    // ========================================================================
    // XP CALCULATIONS - Equipment Skill
    // ========================================================================
    group('calculateEquipmentXp', () {
      test('no sessions or snapshots gives 0 XP', () {
        expect(XpCalculationService.calculateEquipmentXp(), equals(0));
      });

      test('1 tuning session gives 25 XP', () {
        expect(
          XpCalculationService.calculateEquipmentXp(tuningSessions: 1),
          equals(25),
        );
      });

      test('1 kit snapshot gives 25 XP', () {
        expect(
          XpCalculationService.calculateEquipmentXp(kitSnapshots: 1),
          equals(25),
        );
      });

      test('combined tuning and snapshots', () {
        expect(
          XpCalculationService.calculateEquipmentXp(
            tuningSessions: 2,
            kitSnapshots: 3,
          ),
          equals(125), // (2 + 3) * 25
        );
      });

      test('typical equipment management week', () {
        // One tuning session, one kit snapshot
        expect(
          XpCalculationService.calculateEquipmentXp(
            tuningSessions: 1,
            kitSnapshots: 1,
          ),
          equals(50),
        );

        // Competition prep: multiple tuning sessions
        expect(
          XpCalculationService.calculateEquipmentXp(
            tuningSessions: 5,
            kitSnapshots: 2,
          ),
          equals(175), // (5 + 2) * 25
        );
      });
    });

    // ========================================================================
    // XP CALCULATIONS - Competition Skill
    // ========================================================================
    group('calculateCompetitionXp', () {
      test('base XP for entering competition is 100', () {
        // 500/720 = 69%, below 80% threshold, no percentage bonus
        expect(
          XpCalculationService.calculateCompetitionXp(
            competitionScore: 500,
            maxScore: 720,
          ),
          equals(100),
        );
      });

      test('matching practice score gives +50 bonus plus percentage bonus', () {
        // 600/720 = 83%, gets 80%+ bonus (+50)
        // 600/600 = 100%, gets match bonus (+50)
        // Total: 100 + 50 (match) + 50 (80%+) = 200
        expect(
          XpCalculationService.calculateCompetitionXp(
            competitionScore: 600,
            avgPracticeScore: 600,
            maxScore: 720,
          ),
          equals(200),
        );
      });

      test('exceeding practice by 2%+ gives additional +50 bonus', () {
        // 612 is 2% above 600
        // 612/720 = 85%, gets 80%+ bonus (+50)
        // 612/600 = 102%, gets match (+50) + exceed (+50)
        // Total: 100 + 50 + 50 + 50 = 250
        expect(
          XpCalculationService.calculateCompetitionXp(
            competitionScore: 612,
            avgPracticeScore: 600,
            maxScore: 720,
          ),
          equals(250),
        );
      });

      test('beating practice by <2% only gets matching bonus', () {
        // 605 is less than 2% above 600 (1.008%)
        // 605/720 = 84%, gets 80%+ bonus (+50)
        // 605/600 = 100.8%, gets match (+50) only
        // Total: 100 + 50 + 50 = 200
        expect(
          XpCalculationService.calculateCompetitionXp(
            competitionScore: 605,
            avgPracticeScore: 600,
            maxScore: 720,
          ),
          equals(200),
        );
      });

      test('below practice score gets no practice bonus but may get score bonus', () {
        // 550/720 = 76%, below 80% threshold
        // 550/600 = 92%, below 100%, no match bonus
        // Total: 100 (base only)
        expect(
          XpCalculationService.calculateCompetitionXp(
            competitionScore: 550,
            avgPracticeScore: 600,
            maxScore: 720,
          ),
          equals(100),
        );
      });

      test('90%+ of max score gives +100 bonus', () {
        // 648 is 90% of 720
        expect(
          XpCalculationService.calculateCompetitionXp(
            competitionScore: 648,
            maxScore: 720,
          ),
          equals(200), // 100 base + 100 for 90%+
        );
      });

      test('80-90% of max score gives +50 bonus', () {
        // 600 is 83% of 720
        expect(
          XpCalculationService.calculateCompetitionXp(
            competitionScore: 600,
            maxScore: 720,
          ),
          equals(150), // 100 base + 50 for 80%+
        );
      });

      test('below 80% of max score gets no percentage bonus', () {
        // 500 is 69% of 720
        expect(
          XpCalculationService.calculateCompetitionXp(
            competitionScore: 500,
            maxScore: 720,
          ),
          equals(100), // base only
        );
      });

      test('all bonuses can stack', () {
        // 680/720 = 94%+ (90% bonus)
        // 680/650 = 104%+ (matching + exceeding bonus)
        expect(
          XpCalculationService.calculateCompetitionXp(
            competitionScore: 680,
            avgPracticeScore: 650,
            maxScore: 720,
          ),
          equals(300), // 100 + 50 + 50 + 100
        );
      });

      test('null practice score skips practice comparison', () {
        // 600/720 = 83%, gets 80%+ bonus (+50)
        expect(
          XpCalculationService.calculateCompetitionXp(
            competitionScore: 600,
            avgPracticeScore: null,
            maxScore: 720,
          ),
          equals(150), // 100 base + 50 for 80%+
        );
      });

      test('zero practice score skips practice comparison', () {
        // 600/720 = 83%, gets 80%+ bonus (+50)
        expect(
          XpCalculationService.calculateCompetitionXp(
            competitionScore: 600,
            avgPracticeScore: 0,
            maxScore: 720,
          ),
          equals(150), // 100 base + 50 for 80%+
        );
      });

      test('zero max score skips percentage bonus', () {
        expect(
          XpCalculationService.calculateCompetitionXp(
            competitionScore: 600,
            maxScore: 0,
          ),
          equals(100), // base only
        );
      });

      test('typical competition scenarios', () {
        // Beginner at local shoot: modest score, no practice data
        // 400/720 = 56%, below 80% threshold
        expect(
          XpCalculationService.calculateCompetitionXp(
            competitionScore: 400,
            maxScore: 720,
          ),
          equals(100),
        );

        // Club archer: solid performance matching practice
        // 580/720 = 80.5%, gets 80%+ bonus (+50)
        // 580/575 = 100.9%, gets match bonus (+50)
        // Total: 100 + 50 + 50 = 200
        expect(
          XpCalculationService.calculateCompetitionXp(
            competitionScore: 580,
            avgPracticeScore: 575,
            maxScore: 720,
          ),
          equals(200),
        );

        // Elite archer: 90%+ score and beat practice
        // 680/720 = 94%, gets 90%+ bonus (+100)
        // 680/665 = 102.3%, gets match (+50) + exceed (+50)
        // Total: 100 + 50 + 50 + 100 = 300
        expect(
          XpCalculationService.calculateCompetitionXp(
            competitionScore: 680,
            avgPracticeScore: 665,
            maxScore: 720,
          ),
          equals(300),
        );
      });
    });

    // ========================================================================
    // XP CALCULATIONS - Analysis Skill
    // ========================================================================
    group('calculateAnalysisXp', () {
      test('0 plotted arrows gives 0 XP', () {
        expect(
          XpCalculationService.calculateAnalysisXp(plottedArrows: 0),
          equals(0),
        );
      });

      test('negative plotted arrows gives 0 XP', () {
        expect(
          XpCalculationService.calculateAnalysisXp(plottedArrows: -10),
          equals(0),
        );
      });

      test('any plotted arrows gives base 15 XP', () {
        expect(
          XpCalculationService.calculateAnalysisXp(plottedArrows: 1),
          equals(15),
        );
        expect(
          XpCalculationService.calculateAnalysisXp(plottedArrows: 10),
          equals(15),
        );
        expect(
          XpCalculationService.calculateAnalysisXp(plottedArrows: 29),
          equals(15),
        );
      });

      test('30+ arrows gives +10 bonus', () {
        expect(
          XpCalculationService.calculateAnalysisXp(plottedArrows: 30),
          equals(25), // 15 + 10
        );
        expect(
          XpCalculationService.calculateAnalysisXp(plottedArrows: 50),
          equals(25),
        );
      });

      test('60+ arrows gives additional +10 bonus', () {
        expect(
          XpCalculationService.calculateAnalysisXp(plottedArrows: 60),
          equals(35), // 15 + 10 + 10
        );
        expect(
          XpCalculationService.calculateAnalysisXp(plottedArrows: 100),
          equals(35),
        );
      });

      test('typical plotting session XP', () {
        // Quick look: 6 arrows
        expect(
          XpCalculationService.calculateAnalysisXp(plottedArrows: 6),
          equals(15),
        );

        // Half session: 36 arrows
        expect(
          XpCalculationService.calculateAnalysisXp(plottedArrows: 36),
          equals(25),
        );

        // Full 720 round: 72 arrows
        expect(
          XpCalculationService.calculateAnalysisXp(plottedArrows: 72),
          equals(35),
        );
      });
    });

    // ========================================================================
    // LEVEL MILESTONES
    // ========================================================================
    group('getMilestoneDescription', () {
      test('level 10 is Novice archer', () {
        expect(
          XpCalculationService.getMilestoneDescription(10),
          equals('Novice archer'),
        );
      });

      test('level 25 is Developing archer', () {
        expect(
          XpCalculationService.getMilestoneDescription(25),
          equals('Developing archer'),
        );
      });

      test('level 50 is Club standard', () {
        expect(
          XpCalculationService.getMilestoneDescription(50),
          equals('Club standard'),
        );
      });

      test('level 75 is County standard', () {
        expect(
          XpCalculationService.getMilestoneDescription(75),
          equals('County standard'),
        );
      });

      test('level 92 is Halfway to mastery', () {
        expect(
          XpCalculationService.getMilestoneDescription(92),
          equals('Halfway to mastery'),
        );
      });

      test('level 99 is Master archer', () {
        expect(
          XpCalculationService.getMilestoneDescription(99),
          equals('Master archer'),
        );
      });

      test('non-milestone levels return null', () {
        expect(XpCalculationService.getMilestoneDescription(1), isNull);
        expect(XpCalculationService.getMilestoneDescription(5), isNull);
        expect(XpCalculationService.getMilestoneDescription(15), isNull);
        expect(XpCalculationService.getMilestoneDescription(30), isNull);
        expect(XpCalculationService.getMilestoneDescription(91), isNull);
        expect(XpCalculationService.getMilestoneDescription(98), isNull);
      });
    });

    group('isMilestoneLevel', () {
      test('milestone levels return true', () {
        expect(XpCalculationService.isMilestoneLevel(10), isTrue);
        expect(XpCalculationService.isMilestoneLevel(25), isTrue);
        expect(XpCalculationService.isMilestoneLevel(50), isTrue);
        expect(XpCalculationService.isMilestoneLevel(75), isTrue);
        expect(XpCalculationService.isMilestoneLevel(92), isTrue);
        expect(XpCalculationService.isMilestoneLevel(99), isTrue);
      });

      test('non-milestone levels return false', () {
        expect(XpCalculationService.isMilestoneLevel(1), isFalse);
        expect(XpCalculationService.isMilestoneLevel(9), isFalse);
        expect(XpCalculationService.isMilestoneLevel(11), isFalse);
        expect(XpCalculationService.isMilestoneLevel(24), isFalse);
        expect(XpCalculationService.isMilestoneLevel(26), isFalse);
        expect(XpCalculationService.isMilestoneLevel(49), isFalse);
        expect(XpCalculationService.isMilestoneLevel(51), isFalse);
        expect(XpCalculationService.isMilestoneLevel(74), isFalse);
        expect(XpCalculationService.isMilestoneLevel(76), isFalse);
        expect(XpCalculationService.isMilestoneLevel(91), isFalse);
        expect(XpCalculationService.isMilestoneLevel(93), isFalse);
        expect(XpCalculationService.isMilestoneLevel(98), isFalse);
      });

      test('exactly 6 milestone levels exist', () {
        int milestoneCount = 0;
        for (int level = 1; level <= 99; level++) {
          if (XpCalculationService.isMilestoneLevel(level)) {
            milestoneCount++;
          }
        }
        expect(milestoneCount, equals(6));
      });
    });

    // ========================================================================
    // INTEGRATION/SCENARIO TESTS
    // ========================================================================
    group('real-world scenarios', () {
      group('beginner archer journey', () {
        test('first week of archery', () {
          // Shoots 60 arrows, poor handicap
          final archeryXp = XpCalculationService.calculateArcheryXp(handicap: 120);
          final volumeXp = XpCalculationService.calculateVolumeXp(arrowCount: 60);
          final consistencyXp = XpCalculationService.calculateConsistencyXp(
            daysThisWeek: 1,
          );

          final totalXp = archeryXp + volumeXp + consistencyXp;
          expect(archeryXp, equals(300));
          expect(volumeXp, equals(60));
          expect(consistencyXp, equals(50));
          expect(totalXp, equals(410));

          // Should be early levels
          final level = XpCalculationService.levelFromXp(totalXp);
          expect(level, greaterThanOrEqualTo(3));
          expect(level, lessThanOrEqualTo(6));
        });
      });

      group('club archer weekly session', () {
        test('typical training week', () {
          // 3 practice sessions, 180 arrows total, HC 60
          final archeryXp = XpCalculationService.calculateArcheryXp(handicap: 60);
          final volumeXp = XpCalculationService.calculateVolumeXp(arrowCount: 180);
          final consistencyXp = XpCalculationService.calculateConsistencyXp(
            daysThisWeek: 3,
            streakDays: 2,
          );
          final bowFitnessXp = XpCalculationService.calculateBowFitnessXp(
            totalHoldSeconds: 300,
            feedbackShaking: 5,
            feedbackStructure: 5,
            feedbackRest: 5,
          );

          expect(archeryXp, equals(900));
          expect(volumeXp, equals(180));
          expect(consistencyXp, equals(180)); // 150 * 1.2
          expect(bowFitnessXp, equals(375)); // 300 * 1.25
        });
      });

      group('elite archer competition day', () {
        test('Olympic-level performance', () {
          // HC 10, 72 arrows, excellent competition
          final archeryXp = XpCalculationService.calculateArcheryXp(handicap: 10);
          final volumeXp = XpCalculationService.calculateVolumeXp(arrowCount: 72);
          final competitionXp = XpCalculationService.calculateCompetitionXp(
            competitionScore: 680,
            avgPracticeScore: 665,
            maxScore: 720,
          );
          final analysisXp = XpCalculationService.calculateAnalysisXp(
            plottedArrows: 72,
          );

          expect(archeryXp, equals(1400));
          expect(volumeXp, equals(72));
          expect(competitionXp, equals(300)); // max bonuses
          expect(analysisXp, equals(35)); // 60+ bonus
        });
      });

      group('level progression milestones', () {
        test('reaching each milestone requires reasonable XP', () {
          // Level 10 (Novice) should be achievable in first few weeks
          final level10Xp = XpCalculationService.xpForLevel(10);
          expect(level10Xp, lessThan(2000));

          // Level 25 (Developing) - a few months
          final level25Xp = XpCalculationService.xpForLevel(25);
          expect(level25Xp, lessThan(15000));

          // Level 50 (Club standard) - dedicated practice
          // (49^2.5 * 5 = ~84,000)
          final level50Xp = XpCalculationService.xpForLevel(50);
          expect(level50Xp, lessThan(90000));

          // Level 75 (County standard) - serious commitment
          final level75Xp = XpCalculationService.xpForLevel(75);
          expect(level75Xp, lessThan(250000));

          // Level 99 (Master) - years of dedication
          final level99Xp = XpCalculationService.xpForLevel(99);
          expect(level99Xp, greaterThan(400000));
        });
      });
    });

    // ========================================================================
    // EDGE CASES
    // ========================================================================
    group('edge cases', () {
      test('very large XP values handled correctly', () {
        expect(XpCalculationService.levelFromXp(999999999), equals(99));
        expect(XpCalculationService.progressToNextLevel(999999999), equals(1.0));
        expect(XpCalculationService.xpToNextLevel(999999999), equals(0));
      });

      test('boundary level values', () {
        // Test levels 1, 2, 98, 99
        expect(XpCalculationService.xpForLevel(1), equals(0));
        expect(XpCalculationService.xpForLevel(2), equals(5));

        final level98Xp = XpCalculationService.xpForLevel(98);
        final level99Xp = XpCalculationService.xpForLevel(99);
        expect(level99Xp, greaterThan(level98Xp));
      });

      test('int overflow prevention in xpForLevel', () {
        // Even level 99 with pow(98, 2.5) * 5 should not overflow
        final xp = XpCalculationService.xpForLevel(99);
        expect(xp, greaterThan(0));
        expect(xp, lessThan(1000000000)); // Reasonable upper bound
      });

      test('decimal precision in progress calculation', () {
        // Progress should be a clean decimal value
        final level10Xp = XpCalculationService.xpForLevel(10);
        final level11Xp = XpCalculationService.xpForLevel(11);
        final quarterWay = level10Xp + (level11Xp - level10Xp) ~/ 4;

        final progress = XpCalculationService.progressToNextLevel(quarterWay);
        expect(progress, greaterThan(0.0));
        expect(progress, lessThan(0.5));
      });

      test('zero and negative values across all calculations', () {
        // All calculations should handle zero/negative gracefully
        expect(XpCalculationService.calculateArcheryXp(handicap: 0), greaterThanOrEqualTo(0));
        expect(XpCalculationService.calculateVolumeXp(arrowCount: 0), equals(0));
        expect(XpCalculationService.calculateConsistencyXp(daysThisWeek: 0), equals(0));
        expect(XpCalculationService.calculateBowFitnessXp(totalHoldSeconds: 0), equals(0));
        expect(XpCalculationService.calculateBreathWorkXp(), equals(0));
        expect(XpCalculationService.calculateEquipmentXp(), equals(0));
        expect(XpCalculationService.calculateCompetitionXp(competitionScore: 0, maxScore: 720), equals(100));
        expect(XpCalculationService.calculateAnalysisXp(plottedArrows: 0), equals(0));
      });
    });

    // ========================================================================
    // DATA INTEGRITY
    // ========================================================================
    group('data integrity', () {
      test('xpForLevel returns consistent results', () {
        // Call multiple times with same input
        for (int i = 0; i < 10; i++) {
          expect(XpCalculationService.xpForLevel(50), equals(XpCalculationService.xpForLevel(50)));
        }
      });

      test('levelFromXp returns consistent results', () {
        for (int i = 0; i < 10; i++) {
          expect(XpCalculationService.levelFromXp(50000), equals(XpCalculationService.levelFromXp(50000)));
        }
      });

      test('all skill calculations are deterministic', () {
        for (int i = 0; i < 5; i++) {
          expect(
            XpCalculationService.calculateArcheryXp(handicap: 45),
            equals(XpCalculationService.calculateArcheryXp(handicap: 45)),
          );
          expect(
            XpCalculationService.calculateConsistencyXp(daysThisWeek: 5, streakDays: 3),
            equals(XpCalculationService.calculateConsistencyXp(daysThisWeek: 5, streakDays: 3)),
          );
          expect(
            XpCalculationService.calculateBowFitnessXp(
              totalHoldSeconds: 200,
              feedbackShaking: 4,
              feedbackStructure: 3,
              feedbackRest: 5,
            ),
            equals(XpCalculationService.calculateBowFitnessXp(
              totalHoldSeconds: 200,
              feedbackShaking: 4,
              feedbackStructure: 3,
              feedbackRest: 5,
            )),
          );
        }
      });

      test('level curve is strictly monotonic', () {
        int previousXp = -1;
        for (int level = 1; level <= 99; level++) {
          final xp = XpCalculationService.xpForLevel(level);
          expect(xp, greaterThan(previousXp),
              reason: 'Level $level XP ($xp) should be > level ${level - 1} XP ($previousXp)');
          previousXp = xp;
        }
      });

      test('no gaps in level assignments', () {
        // Every XP value from 0 to level 99 should map to exactly one level
        final level99Xp = XpCalculationService.xpForLevel(99);

        for (int xp = 0; xp <= level99Xp + 100; xp += 100) {
          final level = XpCalculationService.levelFromXp(xp);
          expect(level, greaterThanOrEqualTo(1));
          expect(level, lessThanOrEqualTo(99));
        }
      });
    });
  });
}
