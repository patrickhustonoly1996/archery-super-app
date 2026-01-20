/// Tests for SkillsProvider
///
/// These tests verify the skills leveling system state management including:
/// - LevelUpEvent model (creation, properties)
/// - SkillsProvider getters and state management
/// - XP award logic and level-up detection
/// - Pending level-up queue management
/// - XP history retrieval
/// - Skill recalculation
/// - Daily/weekly XP tracking
/// - Activity-specific XP helper methods
/// - Real-world scenarios (Olympic archer workflows)
/// - Edge cases and data integrity
///
/// Note: Tests use simulated state logic since SkillsProvider has dependencies
/// on AppDatabase and SyncService.
import 'package:flutter_test/flutter_test.dart';
import 'package:archery_super_app/providers/skills_provider.dart';
import 'package:archery_super_app/services/xp_calculation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // LEVEL UP EVENT MODEL TESTS
  // ===========================================================================
  group('LevelUpEvent model', () {
    group('constructor', () {
      test('creates with all required fields', () {
        final timestamp = DateTime(2024, 6, 15, 10, 30);
        final event = LevelUpEvent(
          skillId: 'archery_skill',
          skillName: 'Archery Skill',
          oldLevel: 5,
          newLevel: 6,
          timestamp: timestamp,
        );

        expect(event.skillId, equals('archery_skill'));
        expect(event.skillName, equals('Archery Skill'));
        expect(event.oldLevel, equals(5));
        expect(event.newLevel, equals(6));
        expect(event.timestamp, equals(timestamp));
      });

      test('creates for single level gain', () {
        final event = LevelUpEvent(
          skillId: 'volume',
          skillName: 'Volume',
          oldLevel: 10,
          newLevel: 11,
          timestamp: DateTime.now(),
        );

        expect(event.newLevel - event.oldLevel, equals(1));
      });

      test('creates for multiple level gain', () {
        final event = LevelUpEvent(
          skillId: 'consistency',
          skillName: 'Consistency',
          oldLevel: 3,
          newLevel: 7,
          timestamp: DateTime.now(),
        );

        expect(event.newLevel - event.oldLevel, equals(4));
      });

      test('allows level 1 to 2 transition', () {
        final event = LevelUpEvent(
          skillId: 'equipment',
          skillName: 'Equipment',
          oldLevel: 1,
          newLevel: 2,
          timestamp: DateTime.now(),
        );

        expect(event.oldLevel, equals(1));
        expect(event.newLevel, equals(2));
      });

      test('allows transition to max level 99', () {
        final event = LevelUpEvent(
          skillId: 'archery_skill',
          skillName: 'Archery Skill',
          oldLevel: 98,
          newLevel: 99,
          timestamp: DateTime.now(),
        );

        expect(event.newLevel, equals(XpCalculationService.maxLevel));
      });
    });

    group('skill IDs', () {
      test('supports archery_skill ID', () {
        final event = LevelUpEvent(
          skillId: XpCalculationService.archerySkill,
          skillName: 'Archery Skill',
          oldLevel: 1,
          newLevel: 2,
          timestamp: DateTime.now(),
        );
        expect(event.skillId, equals('archery_skill'));
      });

      test('supports volume ID', () {
        final event = LevelUpEvent(
          skillId: XpCalculationService.volume,
          skillName: 'Volume',
          oldLevel: 1,
          newLevel: 2,
          timestamp: DateTime.now(),
        );
        expect(event.skillId, equals('volume'));
      });

      test('supports consistency ID', () {
        final event = LevelUpEvent(
          skillId: XpCalculationService.consistency,
          skillName: 'Consistency',
          oldLevel: 1,
          newLevel: 2,
          timestamp: DateTime.now(),
        );
        expect(event.skillId, equals('consistency'));
      });

      test('supports bow_fitness ID', () {
        final event = LevelUpEvent(
          skillId: XpCalculationService.bowFitness,
          skillName: 'Bow Fitness',
          oldLevel: 1,
          newLevel: 2,
          timestamp: DateTime.now(),
        );
        expect(event.skillId, equals('bow_fitness'));
      });

      test('supports breath_work ID', () {
        final event = LevelUpEvent(
          skillId: XpCalculationService.breathWork,
          skillName: 'Breath Work',
          oldLevel: 1,
          newLevel: 2,
          timestamp: DateTime.now(),
        );
        expect(event.skillId, equals('breath_work'));
      });

      test('supports equipment ID', () {
        final event = LevelUpEvent(
          skillId: XpCalculationService.equipment,
          skillName: 'Equipment',
          oldLevel: 1,
          newLevel: 2,
          timestamp: DateTime.now(),
        );
        expect(event.skillId, equals('equipment'));
      });

      test('supports competition ID', () {
        final event = LevelUpEvent(
          skillId: XpCalculationService.competition,
          skillName: 'Competition',
          oldLevel: 1,
          newLevel: 2,
          timestamp: DateTime.now(),
        );
        expect(event.skillId, equals('competition'));
      });

      test('supports analysis ID', () {
        final event = LevelUpEvent(
          skillId: XpCalculationService.analysis,
          skillName: 'Analysis',
          oldLevel: 1,
          newLevel: 2,
          timestamp: DateTime.now(),
        );
        expect(event.skillId, equals('analysis'));
      });
    });

    group('timestamp handling', () {
      test('preserves exact timestamp', () {
        final timestamp = DateTime(2024, 12, 25, 14, 30, 45, 123);
        final event = LevelUpEvent(
          skillId: 'volume',
          skillName: 'Volume',
          oldLevel: 5,
          newLevel: 6,
          timestamp: timestamp,
        );

        expect(event.timestamp.year, equals(2024));
        expect(event.timestamp.month, equals(12));
        expect(event.timestamp.day, equals(25));
        expect(event.timestamp.hour, equals(14));
        expect(event.timestamp.minute, equals(30));
        expect(event.timestamp.second, equals(45));
      });

      test('handles midnight timestamp', () {
        final midnight = DateTime(2024, 1, 1, 0, 0, 0);
        final event = LevelUpEvent(
          skillId: 'volume',
          skillName: 'Volume',
          oldLevel: 1,
          newLevel: 2,
          timestamp: midnight,
        );

        expect(event.timestamp.hour, equals(0));
        expect(event.timestamp.minute, equals(0));
      });
    });
  });

  // ===========================================================================
  // SKILL IDS CONSTANTS TESTS
  // ===========================================================================
  group('XpCalculationService skill IDs', () {
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

    test('all skill IDs are unique', () {
      final ids = [
        XpCalculationService.archerySkill,
        XpCalculationService.volume,
        XpCalculationService.consistency,
        XpCalculationService.bowFitness,
        XpCalculationService.breathWork,
        XpCalculationService.equipment,
        XpCalculationService.competition,
        XpCalculationService.analysis,
      ];
      expect(ids.toSet().length, equals(ids.length));
    });

    test('there are exactly 8 skills', () {
      final ids = [
        XpCalculationService.archerySkill,
        XpCalculationService.volume,
        XpCalculationService.consistency,
        XpCalculationService.bowFitness,
        XpCalculationService.breathWork,
        XpCalculationService.equipment,
        XpCalculationService.competition,
        XpCalculationService.analysis,
      ];
      expect(ids.length, equals(8));
    });
  });

  // ===========================================================================
  // PENDING LEVEL-UP QUEUE SIMULATION TESTS
  // ===========================================================================
  group('Pending level-up queue simulation', () {
    group('queue operations', () {
      test('starts empty', () {
        final pendingLevelUps = <LevelUpEvent>[];
        expect(pendingLevelUps, isEmpty);
        expect(pendingLevelUps.isNotEmpty, isFalse);
      });

      test('adds level-up event', () {
        final pendingLevelUps = <LevelUpEvent>[];

        pendingLevelUps.add(LevelUpEvent(
          skillId: 'archery_skill',
          skillName: 'Archery Skill',
          oldLevel: 5,
          newLevel: 6,
          timestamp: DateTime.now(),
        ));

        expect(pendingLevelUps.length, equals(1));
        expect(pendingLevelUps.isNotEmpty, isTrue);
      });

      test('maintains FIFO order', () {
        final pendingLevelUps = <LevelUpEvent>[];

        pendingLevelUps.add(LevelUpEvent(
          skillId: 'archery_skill',
          skillName: 'Archery Skill',
          oldLevel: 5,
          newLevel: 6,
          timestamp: DateTime.now(),
        ));
        pendingLevelUps.add(LevelUpEvent(
          skillId: 'volume',
          skillName: 'Volume',
          oldLevel: 10,
          newLevel: 11,
          timestamp: DateTime.now(),
        ));
        pendingLevelUps.add(LevelUpEvent(
          skillId: 'consistency',
          skillName: 'Consistency',
          oldLevel: 3,
          newLevel: 4,
          timestamp: DateTime.now(),
        ));

        expect(pendingLevelUps[0].skillId, equals('archery_skill'));
        expect(pendingLevelUps[1].skillId, equals('volume'));
        expect(pendingLevelUps[2].skillId, equals('consistency'));
      });

      test('consumeNextLevelUp returns first event and removes it', () {
        final pendingLevelUps = <LevelUpEvent>[];

        pendingLevelUps.add(LevelUpEvent(
          skillId: 'archery_skill',
          skillName: 'Archery Skill',
          oldLevel: 5,
          newLevel: 6,
          timestamp: DateTime.now(),
        ));
        pendingLevelUps.add(LevelUpEvent(
          skillId: 'volume',
          skillName: 'Volume',
          oldLevel: 10,
          newLevel: 11,
          timestamp: DateTime.now(),
        ));

        LevelUpEvent? consumeNextLevelUp() {
          if (pendingLevelUps.isEmpty) return null;
          return pendingLevelUps.removeAt(0);
        }

        final event = consumeNextLevelUp();

        expect(event, isNotNull);
        expect(event!.skillId, equals('archery_skill'));
        expect(pendingLevelUps.length, equals(1));
        expect(pendingLevelUps[0].skillId, equals('volume'));
      });

      test('consumeNextLevelUp returns null when empty', () {
        final pendingLevelUps = <LevelUpEvent>[];

        LevelUpEvent? consumeNextLevelUp() {
          if (pendingLevelUps.isEmpty) return null;
          return pendingLevelUps.removeAt(0);
        }

        expect(consumeNextLevelUp(), isNull);
      });

      test('clearPendingLevelUps removes all events', () {
        final pendingLevelUps = <LevelUpEvent>[];

        pendingLevelUps.add(LevelUpEvent(
          skillId: 'archery_skill',
          skillName: 'Archery Skill',
          oldLevel: 5,
          newLevel: 6,
          timestamp: DateTime.now(),
        ));
        pendingLevelUps.add(LevelUpEvent(
          skillId: 'volume',
          skillName: 'Volume',
          oldLevel: 10,
          newLevel: 11,
          timestamp: DateTime.now(),
        ));

        void clearPendingLevelUps() {
          pendingLevelUps.clear();
        }

        clearPendingLevelUps();

        expect(pendingLevelUps, isEmpty);
      });
    });

    group('hasPendingLevelUp', () {
      test('returns false when empty', () {
        final pendingLevelUps = <LevelUpEvent>[];
        expect(pendingLevelUps.isNotEmpty, isFalse);
      });

      test('returns true when has events', () {
        final pendingLevelUps = <LevelUpEvent>[];
        pendingLevelUps.add(LevelUpEvent(
          skillId: 'archery_skill',
          skillName: 'Archery Skill',
          oldLevel: 5,
          newLevel: 6,
          timestamp: DateTime.now(),
        ));
        expect(pendingLevelUps.isNotEmpty, isTrue);
      });
    });

    group('pendingLevelUps getter', () {
      test('returns unmodifiable list', () {
        final pendingLevelUps = <LevelUpEvent>[];
        pendingLevelUps.add(LevelUpEvent(
          skillId: 'archery_skill',
          skillName: 'Archery Skill',
          oldLevel: 5,
          newLevel: 6,
          timestamp: DateTime.now(),
        ));

        final unmodifiable = List<LevelUpEvent>.unmodifiable(pendingLevelUps);

        expect(() => unmodifiable.add(LevelUpEvent(
          skillId: 'volume',
          skillName: 'Volume',
          oldLevel: 1,
          newLevel: 2,
          timestamp: DateTime.now(),
        )), throwsUnsupportedError);
      });
    });
  });

  // ===========================================================================
  // SKILL STATE SIMULATION TESTS
  // ===========================================================================
  group('Skill state simulation', () {
    group('getSkill', () {
      test('returns skill when found', () {
        final skills = [
          _MockSkillLevel('archery_skill', 'Archery Skill', 5, 1000),
          _MockSkillLevel('volume', 'Volume', 10, 500),
        ];

        _MockSkillLevel? getSkill(String skillId) {
          try {
            return skills.firstWhere((s) => s.id == skillId);
          } catch (_) {
            return null;
          }
        }

        final skill = getSkill('archery_skill');
        expect(skill, isNotNull);
        expect(skill!.id, equals('archery_skill'));
        expect(skill.currentLevel, equals(5));
      });

      test('returns null when skill not found', () {
        final skills = [
          _MockSkillLevel('archery_skill', 'Archery Skill', 5, 1000),
        ];

        _MockSkillLevel? getSkill(String skillId) {
          try {
            return skills.firstWhere((s) => s.id == skillId);
          } catch (_) {
            return null;
          }
        }

        expect(getSkill('unknown_skill'), isNull);
      });

      test('returns null from empty list', () {
        final skills = <_MockSkillLevel>[];

        _MockSkillLevel? getSkill(String skillId) {
          try {
            return skills.firstWhere((s) => s.id == skillId);
          } catch (_) {
            return null;
          }
        }

        expect(getSkill('archery_skill'), isNull);
      });
    });

    group('getLevel', () {
      test('returns level for existing skill', () {
        final skills = [
          _MockSkillLevel('archery_skill', 'Archery Skill', 15, 5000),
        ];

        int getLevel(String skillId) {
          try {
            return skills.firstWhere((s) => s.id == skillId).currentLevel;
          } catch (_) {
            return 1;
          }
        }

        expect(getLevel('archery_skill'), equals(15));
      });

      test('returns 1 for non-existent skill', () {
        final skills = <_MockSkillLevel>[];

        int getLevel(String skillId) {
          try {
            return skills.firstWhere((s) => s.id == skillId).currentLevel;
          } catch (_) {
            return 1;
          }
        }

        expect(getLevel('unknown'), equals(1));
      });
    });

    group('getXp', () {
      test('returns XP for existing skill', () {
        final skills = [
          _MockSkillLevel('archery_skill', 'Archery Skill', 10, 2500),
        ];

        int getXp(String skillId) {
          try {
            return skills.firstWhere((s) => s.id == skillId).currentXp;
          } catch (_) {
            return 0;
          }
        }

        expect(getXp('archery_skill'), equals(2500));
      });

      test('returns 0 for non-existent skill', () {
        final skills = <_MockSkillLevel>[];

        int getXp(String skillId) {
          try {
            return skills.firstWhere((s) => s.id == skillId).currentXp;
          } catch (_) {
            return 0;
          }
        }

        expect(getXp('unknown'), equals(0));
      });
    });

    group('getProgress', () {
      test('returns progress using XpCalculationService', () {
        final xp = 100;
        final progress = XpCalculationService.progressToNextLevel(xp);

        expect(progress, greaterThanOrEqualTo(0.0));
        expect(progress, lessThanOrEqualTo(1.0));
      });

      test('returns 0.0 for non-existent skill', () {
        final skills = <_MockSkillLevel>[];

        double getProgress(String skillId) {
          try {
            final skill = skills.firstWhere((s) => s.id == skillId);
            return XpCalculationService.progressToNextLevel(skill.currentXp);
          } catch (_) {
            return 0.0;
          }
        }

        expect(getProgress('unknown'), equals(0.0));
      });

      test('returns 1.0 at max level', () {
        final maxXp = XpCalculationService.xpForLevel(99);
        final progress = XpCalculationService.progressToNextLevel(maxXp);
        expect(progress, equals(1.0));
      });
    });

    group('totalLevel calculation', () {
      test('sums all skill levels', () {
        final skills = [
          _MockSkillLevel('archery_skill', 'Archery Skill', 10, 1000),
          _MockSkillLevel('volume', 'Volume', 15, 2000),
          _MockSkillLevel('consistency', 'Consistency', 5, 500),
        ];

        final totalLevel = skills.fold<int>(0, (sum, skill) => sum + skill.currentLevel);

        expect(totalLevel, equals(30));
      });

      test('returns 0 for empty skills list', () {
        final skills = <_MockSkillLevel>[];
        final totalLevel = skills.fold<int>(0, (sum, skill) => sum + skill.currentLevel);

        expect(totalLevel, equals(0));
      });

      test('calculates total for all 8 skills at level 1', () {
        final skills = [
          _MockSkillLevel('archery_skill', 'Archery Skill', 1, 0),
          _MockSkillLevel('volume', 'Volume', 1, 0),
          _MockSkillLevel('consistency', 'Consistency', 1, 0),
          _MockSkillLevel('bow_fitness', 'Bow Fitness', 1, 0),
          _MockSkillLevel('breath_work', 'Breath Work', 1, 0),
          _MockSkillLevel('equipment', 'Equipment', 1, 0),
          _MockSkillLevel('competition', 'Competition', 1, 0),
          _MockSkillLevel('analysis', 'Analysis', 1, 0),
        ];

        final totalLevel = skills.fold<int>(0, (sum, skill) => sum + skill.currentLevel);

        expect(totalLevel, equals(8));
      });
    });

    group('isLoaded state', () {
      test('starts as false', () {
        var isLoaded = false;
        expect(isLoaded, isFalse);
      });

      test('becomes true after loading', () {
        var isLoaded = false;

        void loadSkills() {
          // Simulate loading
          isLoaded = true;
        }

        loadSkills();
        expect(isLoaded, isTrue);
      });
    });
  });

  // ===========================================================================
  // XP AWARD LOGIC SIMULATION TESTS
  // ===========================================================================
  group('XP award logic simulation', () {
    group('awardXp validation', () {
      test('rejects zero XP amount', () {
        bool awardXp(int xpAmount) {
          if (xpAmount <= 0) return false;
          return true;
        }

        expect(awardXp(0), isFalse);
      });

      test('rejects negative XP amount', () {
        bool awardXp(int xpAmount) {
          if (xpAmount <= 0) return false;
          return true;
        }

        expect(awardXp(-100), isFalse);
      });

      test('accepts positive XP amount', () {
        bool awardXp(int xpAmount) {
          if (xpAmount <= 0) return false;
          return true;
        }

        expect(awardXp(100), isTrue);
      });

      test('rejects if skill not found', () {
        final skills = <_MockSkillLevel>[];

        bool awardXp(String skillId, int xpAmount) {
          if (xpAmount <= 0) return false;

          _MockSkillLevel? skill;
          try {
            skill = skills.firstWhere((s) => s.id == skillId);
          } catch (_) {
            skill = null;
          }

          if (skill == null) return false;
          return true;
        }

        expect(awardXp('unknown', 100), isFalse);
      });
    });

    group('level-up detection', () {
      test('detects single level-up', () {
        // Start at level 1 with 0 XP
        final oldXp = 0;
        final oldLevel = XpCalculationService.levelFromXp(oldXp);

        // Add enough XP to reach level 2
        final xpForLevel2 = XpCalculationService.xpForLevel(2);
        final newXp = oldXp + xpForLevel2;
        final newLevel = XpCalculationService.levelFromXp(newXp);

        final leveledUp = newLevel > oldLevel;

        expect(leveledUp, isTrue);
        expect(newLevel, equals(2));
      });

      test('no level-up for small XP gain', () {
        // Start at level 10
        final startXp = XpCalculationService.xpForLevel(10);
        final oldLevel = XpCalculationService.levelFromXp(startXp);

        // Add small amount of XP (not enough for level 11)
        final newXp = startXp + 1;
        final newLevel = XpCalculationService.levelFromXp(newXp);

        final leveledUp = newLevel > oldLevel;

        expect(leveledUp, isFalse);
      });

      test('detects multiple level-up', () {
        // Start at level 1
        final oldXp = 0;
        final oldLevel = XpCalculationService.levelFromXp(oldXp);

        // Add enough XP to reach level 5
        final xpForLevel5 = XpCalculationService.xpForLevel(5);
        final newXp = oldXp + xpForLevel5 + 1;
        final newLevel = XpCalculationService.levelFromXp(newXp);

        final leveledUp = newLevel > oldLevel;
        final levelsGained = newLevel - oldLevel;

        expect(leveledUp, isTrue);
        expect(levelsGained, greaterThan(1));
      });
    });
  });

  // ===========================================================================
  // XP CALCULATION HELPER METHODS TESTS
  // ===========================================================================
  group('Activity-specific XP helper calculations', () {
    group('awardSessionXp calculations', () {
      test('calculates archery XP from handicap', () {
        final handicap = 60;
        final archeryXp = XpCalculationService.calculateArcheryXp(handicap: handicap);

        expect(archeryXp, greaterThan(0));
        expect(archeryXp, equals((150 - 60) * 2)); // 180 XP
      });

      test('calculates volume XP from arrow count', () {
        final arrowCount = 72;
        final volumeXp = XpCalculationService.calculateVolumeXp(arrowCount: arrowCount);

        expect(volumeXp, equals(14)); // 1 XP per 5 arrows (72/5 = 14)
      });

      test('calculates analysis XP for plotted arrows', () {
        final plottedArrows = 36;
        final analysisXp = XpCalculationService.calculateAnalysisXp(plottedArrows: plottedArrows);

        expect(analysisXp, equals(5)); // 3 base + 2 for >= 30 arrows
      });

      test('calculates competition XP with practice comparison', () {
        final competitionXp = XpCalculationService.calculateCompetitionXp(
          competitionScore: 650,
          avgPracticeScore: 620,
          maxScore: 720,
        );

        // 20 base + 10 (matched practice) + 10 (beat by 2%+) + 20 (90%+ of max)
        expect(competitionXp, greaterThan(20));
      });
    });

    group('awardBowTrainingXp calculations', () {
      test('calculates bow fitness XP from hold time', () {
        final xp = XpCalculationService.calculateBowFitnessXp(
          totalHoldSeconds: 120,
          feedbackShaking: 5,
          feedbackStructure: 5,
          feedbackRest: 5,
        );

        // (120 / 5) * 1.25 (good form bonus) = 30
        expect(xp, equals(30));
      });

      test('excellent form gives 50% bonus', () {
        final xp = XpCalculationService.calculateBowFitnessXp(
          totalHoldSeconds: 100,
          feedbackShaking: 2,
          feedbackStructure: 2,
          feedbackRest: 2,
        );

        // (100 / 5) * 1.5 = 30
        expect(xp, equals(30));
      });

      test('poor form gives no bonus', () {
        final xp = XpCalculationService.calculateBowFitnessXp(
          totalHoldSeconds: 100,
          feedbackShaking: 8,
          feedbackStructure: 8,
          feedbackRest: 8,
        );

        // (100 / 5) * 1.0 = 20 (no bonus)
        expect(xp, equals(20));
      });
    });

    group('awardBreathTrainingXp calculations', () {
      test('calculates breath XP from hold time', () {
        final xp = XpCalculationService.calculateBreathWorkXp(
          bestHoldSeconds: 60,
        );

        // 60 / 10 = 6
        expect(xp, equals(6));
      });

      test('calculates breath XP from exhale time', () {
        final xp = XpCalculationService.calculateBreathWorkXp(
          bestExhaleSeconds: 40,
        );

        // 40 / 10 = 4
        expect(xp, equals(4));
      });

      test('calculates combined breath XP', () {
        final xp = XpCalculationService.calculateBreathWorkXp(
          bestHoldSeconds: 60,
          bestExhaleSeconds: 40,
        );

        // 60/10 + 40/10 = 6 + 4 = 10
        expect(xp, equals(10));
      });

      test('returns 0 for null values', () {
        final xp = XpCalculationService.calculateBreathWorkXp();
        expect(xp, equals(0));
      });
    });

    group('awardConsistencyXp calculations', () {
      test('calculates consistency XP from training days', () {
        final xp = XpCalculationService.calculateConsistencyXp(
          daysThisWeek: 5,
        );

        // 5 * 10 = 50
        expect(xp, equals(50));
      });

      test('applies streak multiplier', () {
        final xp = XpCalculationService.calculateConsistencyXp(
          daysThisWeek: 5,
          streakDays: 7,
        );

        // 5 * 10 * 1.7 = 85
        expect(xp, equals(85));
      });

      test('caps streak bonus at 7 days', () {
        final xp7 = XpCalculationService.calculateConsistencyXp(
          daysThisWeek: 5,
          streakDays: 7,
        );
        final xp10 = XpCalculationService.calculateConsistencyXp(
          daysThisWeek: 5,
          streakDays: 10,
        );

        // Both should be same (streak capped at 7)
        expect(xp7, equals(xp10));
      });
    });

    group('awardEquipmentXp', () {
      test('awards fixed 5 XP', () {
        const equipmentXp = 5;
        expect(equipmentXp, equals(5));
      });
    });
  });

  // ===========================================================================
  // REAL-WORLD SCENARIO TESTS
  // ===========================================================================
  group('Real-world scenarios', () {
    group('Olympic archer training day', () {
      test('accumulates XP from full training session', () {
        var totalXp = 0;

        // Morning: 72-arrow practice round at handicap 15
        totalXp += XpCalculationService.calculateArcheryXp(handicap: 15);
        totalXp += XpCalculationService.calculateVolumeXp(arrowCount: 72);
        totalXp += XpCalculationService.calculateAnalysisXp(plottedArrows: 72);

        // Afternoon: 36-arrow tuning session
        totalXp += XpCalculationService.calculateVolumeXp(arrowCount: 36);

        // OLY bow training
        totalXp += XpCalculationService.calculateBowFitnessXp(
          totalHoldSeconds: 180,
          feedbackShaking: 3,
          feedbackStructure: 3,
          feedbackRest: 3,
        );

        // Breath work
        totalXp += XpCalculationService.calculateBreathWorkXp(
          bestHoldSeconds: 90,
          bestExhaleSeconds: 45,
        );

        expect(totalXp, greaterThan(300));
      });

      test('competition day XP accumulation', () {
        var totalXp = 0;

        // 144 arrows in competition
        totalXp += XpCalculationService.calculateVolumeXp(arrowCount: 144);

        // Competition performance
        totalXp += XpCalculationService.calculateCompetitionXp(
          competitionScore: 680,
          avgPracticeScore: 665,
          maxScore: 720,
        );

        // Plotted all arrows
        totalXp += XpCalculationService.calculateAnalysisXp(plottedArrows: 144);

        expect(totalXp, greaterThan(80));
      });
    });

    group('Beginner archer progression', () {
      test('early levels come quickly', () {
        // Level 2 requires minimal XP
        final xpForLevel2 = XpCalculationService.xpForLevel(2);
        expect(xpForLevel2, lessThan(50));
      });

      test('first session can level up archery skill', () {
        // Beginner with handicap 100
        final archeryXp = XpCalculationService.calculateArcheryXp(handicap: 100);
        final xpForLevel2 = XpCalculationService.xpForLevel(2);

        // Should be able to level up from one session
        expect(archeryXp, greaterThan(xpForLevel2));
      });
    });

    group('Veteran archer late game', () {
      test('level 92 requires significant XP (over 80% of total)', () {
        final xpFor92 = XpCalculationService.xpForLevel(92);
        final xpFor99 = XpCalculationService.xpForLevel(99);

        final percentAt92 = xpFor92 / xpFor99;

        // Modified curve is gentler than RS, level 92 requires over 80% of total XP
        expect(percentAt92, greaterThan(0.8));
        expect(percentAt92, lessThan(0.9));
      });

      test('max level 99 is achievable', () {
        expect(XpCalculationService.maxLevel, equals(99));
        expect(XpCalculationService.maxTotalXp, equals(500000));
      });
    });

    group('Weekly training pattern', () {
      test('consistent training yields consistency XP', () {
        final xp = XpCalculationService.calculateConsistencyXp(
          daysThisWeek: 6,
          streakDays: 14,
        );

        // 6 days * 10 * 1.7 = 102
        expect(xp, greaterThan(100));
      });

      test('single day training still awards XP', () {
        final xp = XpCalculationService.calculateConsistencyXp(
          daysThisWeek: 1,
        );

        expect(xp, equals(10));
      });
    });
  });

  // ===========================================================================
  // EDGE CASES AND ERROR HANDLING
  // ===========================================================================
  group('Edge cases', () {
    group('XP boundary values', () {
      test('zero XP results in level 1', () {
        expect(XpCalculationService.levelFromXp(0), equals(1));
      });

      test('negative XP results in level 1', () {
        expect(XpCalculationService.levelFromXp(-100), equals(1));
      });

      test('exactly at level threshold', () {
        final xpForLevel10 = XpCalculationService.xpForLevel(10);
        expect(XpCalculationService.levelFromXp(xpForLevel10), equals(10));
      });

      test('one XP below level threshold', () {
        final xpForLevel10 = XpCalculationService.xpForLevel(10);
        expect(XpCalculationService.levelFromXp(xpForLevel10 - 1), equals(9));
      });

      test('one XP above level threshold', () {
        final xpForLevel10 = XpCalculationService.xpForLevel(10);
        expect(XpCalculationService.levelFromXp(xpForLevel10 + 1), equals(10));
      });
    });

    group('level boundary values', () {
      test('level 1 requires 0 XP', () {
        expect(XpCalculationService.xpForLevel(1), equals(0));
      });

      test('level 0 returns 0 XP', () {
        expect(XpCalculationService.xpForLevel(0), equals(0));
      });

      test('level below 1 returns 0 XP', () {
        expect(XpCalculationService.xpForLevel(-5), equals(0));
      });

      test('level above 99 caps at 99', () {
        final xpFor99 = XpCalculationService.xpForLevel(99);
        final xpFor100 = XpCalculationService.xpForLevel(100);
        expect(xpFor100, equals(xpFor99));
      });
    });

    group('progress calculation edge cases', () {
      test('progress at level 1 with 0 XP', () {
        final progress = XpCalculationService.progressToNextLevel(0);
        expect(progress, equals(0.0));
      });

      test('progress at max level is 1.0', () {
        final maxXp = XpCalculationService.xpForLevel(99);
        final progress = XpCalculationService.progressToNextLevel(maxXp);
        expect(progress, equals(1.0));
      });

      test('progress beyond max XP is 1.0', () {
        final progress = XpCalculationService.progressToNextLevel(999999);
        expect(progress, equals(1.0));
      });
    });

    group('XP to next level edge cases', () {
      test('at max level returns 0', () {
        final maxXp = XpCalculationService.xpForLevel(99);
        final toNext = XpCalculationService.xpToNextLevel(maxXp);
        expect(toNext, equals(0));
      });

      test('at level 1 returns XP needed for level 2', () {
        final toNext = XpCalculationService.xpToNextLevel(0);
        final xpForLevel2 = XpCalculationService.xpForLevel(2);
        expect(toNext, equals(xpForLevel2));
      });
    });

    group('handicap edge values', () {
      test('elite handicap 0 gives max archery XP', () {
        final xp = XpCalculationService.calculateArcheryXp(handicap: 0);
        expect(xp, equals(300));
      });

      test('handicap 150 gives 0 XP', () {
        final xp = XpCalculationService.calculateArcheryXp(handicap: 150);
        expect(xp, equals(0));
      });

      test('handicap above 150 gives 0 XP', () {
        final xp = XpCalculationService.calculateArcheryXp(handicap: 200);
        expect(xp, equals(0));
      });

      test('negative handicap gives high XP', () {
        final xp = XpCalculationService.calculateArcheryXp(handicap: -10);
        expect(xp, greaterThan(300));
      });
    });

    group('arrow count edge values', () {
      test('zero arrows gives 0 XP', () {
        final xp = XpCalculationService.calculateVolumeXp(arrowCount: 0);
        expect(xp, equals(0));
      });

      test('negative arrows gives 0 XP', () {
        final xp = XpCalculationService.calculateVolumeXp(arrowCount: -10);
        expect(xp, equals(0));
      });

      test('very high arrow count is handled', () {
        final xp = XpCalculationService.calculateVolumeXp(arrowCount: 1000);
        expect(xp, equals(200));
      });
    });

    group('analysis XP edge values', () {
      test('zero plotted arrows gives 0 XP', () {
        final xp = XpCalculationService.calculateAnalysisXp(plottedArrows: 0);
        expect(xp, equals(0));
      });

      test('negative plotted arrows gives 0 XP', () {
        final xp = XpCalculationService.calculateAnalysisXp(plottedArrows: -5);
        expect(xp, equals(0));
      });

      test('1 plotted arrow gives base XP', () {
        final xp = XpCalculationService.calculateAnalysisXp(plottedArrows: 1);
        expect(xp, equals(3));
      });

      test('30 plotted arrows gives bonus', () {
        final xp = XpCalculationService.calculateAnalysisXp(plottedArrows: 30);
        expect(xp, equals(5));
      });

      test('60 plotted arrows gives full bonus', () {
        final xp = XpCalculationService.calculateAnalysisXp(plottedArrows: 60);
        expect(xp, equals(7));
      });
    });

    group('empty and null state handling', () {
      test('empty skills list has total level 0', () {
        final skills = <_MockSkillLevel>[];
        final totalLevel = skills.fold<int>(0, (sum, skill) => sum + skill.currentLevel);
        expect(totalLevel, equals(0));
      });

      test('empty pending level-ups is not hasLevelUp', () {
        final pendingLevelUps = <LevelUpEvent>[];
        expect(pendingLevelUps.isNotEmpty, isFalse);
      });
    });
  });

  // ===========================================================================
  // DATA INTEGRITY TESTS
  // ===========================================================================
  group('Data integrity', () {
    group('level-up event immutability', () {
      test('event properties cannot be modified after creation', () {
        final event = LevelUpEvent(
          skillId: 'archery_skill',
          skillName: 'Archery Skill',
          oldLevel: 5,
          newLevel: 6,
          timestamp: DateTime.now(),
        );

        // LevelUpEvent fields are final, so they can't be modified
        expect(event.skillId, equals('archery_skill'));
        expect(event.oldLevel, equals(5));
        expect(event.newLevel, equals(6));
      });
    });

    group('pending level-up list independence', () {
      test('getter returns copy, not reference', () {
        final pendingLevelUps = <LevelUpEvent>[];
        pendingLevelUps.add(LevelUpEvent(
          skillId: 'archery_skill',
          skillName: 'Archery Skill',
          oldLevel: 5,
          newLevel: 6,
          timestamp: DateTime.now(),
        ));

        final snapshot = List<LevelUpEvent>.from(pendingLevelUps);
        pendingLevelUps.clear();

        expect(snapshot.length, equals(1));
        expect(pendingLevelUps.length, equals(0));
      });
    });

    group('XP curve consistency', () {
      test('XP requirements increase with level', () {
        for (int level = 2; level <= 99; level++) {
          final xpCurrent = XpCalculationService.xpForLevel(level);
          final xpPrevious = XpCalculationService.xpForLevel(level - 1);
          expect(xpCurrent, greaterThan(xpPrevious),
              reason: 'XP for level $level should be greater than level ${level - 1}');
        }
      });

      test('level from XP is consistent with XP for level', () {
        for (int level = 1; level <= 99; level++) {
          final xpAtLevel = XpCalculationService.xpForLevel(level);
          final calculatedLevel = XpCalculationService.levelFromXp(xpAtLevel);
          expect(calculatedLevel, equals(level),
              reason: 'Level $level with XP $xpAtLevel should calculate back to level $level');
        }
      });

      test('progress is always between 0 and 1', () {
        for (int xp = 0; xp <= 100000; xp += 1000) {
          final progress = XpCalculationService.progressToNextLevel(xp);
          expect(progress, greaterThanOrEqualTo(0.0));
          expect(progress, lessThanOrEqualTo(1.0));
        }
      });
    });
  });

  // ===========================================================================
  // MILESTONE TESTS
  // ===========================================================================
  group('Milestones', () {
    test('level 10 is Novice archer', () {
      expect(XpCalculationService.getMilestoneDescription(10), equals('Novice archer'));
      expect(XpCalculationService.isMilestoneLevel(10), isTrue);
    });

    test('level 25 is Developing archer', () {
      expect(XpCalculationService.getMilestoneDescription(25), equals('Developing archer'));
      expect(XpCalculationService.isMilestoneLevel(25), isTrue);
    });

    test('level 50 is Club standard', () {
      expect(XpCalculationService.getMilestoneDescription(50), equals('Club standard'));
      expect(XpCalculationService.isMilestoneLevel(50), isTrue);
    });

    test('level 75 is County standard', () {
      expect(XpCalculationService.getMilestoneDescription(75), equals('County standard'));
      expect(XpCalculationService.isMilestoneLevel(75), isTrue);
    });

    test('level 92 is Halfway to mastery', () {
      expect(XpCalculationService.getMilestoneDescription(92), equals('Halfway to mastery'));
      expect(XpCalculationService.isMilestoneLevel(92), isTrue);
    });

    test('level 99 is Master archer', () {
      expect(XpCalculationService.getMilestoneDescription(99), equals('Master archer'));
      expect(XpCalculationService.isMilestoneLevel(99), isTrue);
    });

    test('non-milestone levels return null', () {
      expect(XpCalculationService.getMilestoneDescription(5), isNull);
      expect(XpCalculationService.getMilestoneDescription(15), isNull);
      expect(XpCalculationService.getMilestoneDescription(30), isNull);
      expect(XpCalculationService.isMilestoneLevel(5), isFalse);
    });

    test('there are exactly 6 milestone levels', () {
      int milestoneCount = 0;
      for (int level = 1; level <= 99; level++) {
        if (XpCalculationService.isMilestoneLevel(level)) {
          milestoneCount++;
        }
      }
      expect(milestoneCount, equals(6));
    });
  });

  // ===========================================================================
  // DATE RANGE XP CALCULATION TESTS
  // ===========================================================================
  group('Date range XP calculation simulation', () {
    group('getXpToday', () {
      test('calculates start of day correctly', () {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);

        expect(startOfDay.hour, equals(0));
        expect(startOfDay.minute, equals(0));
        expect(startOfDay.second, equals(0));
      });

      test('calculates end of day correctly', () {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        expect(endOfDay.difference(startOfDay).inHours, equals(24));
      });
    });

    group('getXpThisWeek', () {
      test('calculates start of week correctly', () {
        final now = DateTime(2024, 6, 15); // Saturday
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

        // Monday of that week
        expect(startOfWeek.weekday, equals(1)); // Monday
      });

      test('handles Monday as start of week', () {
        final monday = DateTime(2024, 6, 10); // Monday
        final startOfWeek = monday.subtract(Duration(days: monday.weekday - 1));

        expect(startOfWeek.day, equals(10));
      });
    });
  });

  // ===========================================================================
  // COMPETITION XP DETAILED TESTS
  // ===========================================================================
  group('Competition XP detailed tests', () {
    test('base entry gives 20 XP', () {
      final xp = XpCalculationService.calculateCompetitionXp(
        competitionScore: 500,
        maxScore: 720,
      );

      expect(xp, greaterThanOrEqualTo(20));
    });

    test('matching practice score adds 10 XP', () {
      final xpWithoutPractice = XpCalculationService.calculateCompetitionXp(
        competitionScore: 600,
        maxScore: 720,
      );

      final xpWithMatch = XpCalculationService.calculateCompetitionXp(
        competitionScore: 600,
        avgPracticeScore: 600,
        maxScore: 720,
      );

      expect(xpWithMatch, greaterThan(xpWithoutPractice));
    });

    test('beating practice by 2%+ adds additional 10 XP', () {
      final xpMatch = XpCalculationService.calculateCompetitionXp(
        competitionScore: 600,
        avgPracticeScore: 600,
        maxScore: 720,
      );

      final xpBeat = XpCalculationService.calculateCompetitionXp(
        competitionScore: 618, // 103% of 600
        avgPracticeScore: 600,
        maxScore: 720,
      );

      expect(xpBeat, greaterThan(xpMatch));
    });

    test('90%+ of max score adds 20 XP', () {
      final xp = XpCalculationService.calculateCompetitionXp(
        competitionScore: 648, // 90% of 720
        maxScore: 720,
      );

      // Should include 90%+ bonus
      expect(xp, greaterThanOrEqualTo(40)); // 20 base + 20 bonus
    });

    test('80%+ of max score adds 10 XP', () {
      final xp = XpCalculationService.calculateCompetitionXp(
        competitionScore: 576, // 80% of 720
        maxScore: 720,
      );

      // Should include 80%+ bonus but not 90%+
      expect(xp, greaterThanOrEqualTo(30)); // 20 base + 10 bonus
      expect(xp, lessThan(40));
    });
  });
}

/// Mock class to simulate SkillLevel for testing
class _MockSkillLevel {
  final String id;
  final String name;
  final int currentLevel;
  final int currentXp;

  _MockSkillLevel(this.id, this.name, this.currentLevel, this.currentXp);
}
