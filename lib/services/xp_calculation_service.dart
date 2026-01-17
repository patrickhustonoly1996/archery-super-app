import 'dart:math';

/// Service for calculating XP rewards and level progression.
/// Uses a RuneScape-inspired 1-99 leveling system with a modified
/// exponential curve that's gentler in the early/mid game.
class XpCalculationService {
  // Skill IDs
  static const String archerySkill = 'archery_skill';
  static const String volume = 'volume';
  static const String consistency = 'consistency';
  static const String bowFitness = 'bow_fitness';
  static const String breathWork = 'breath_work';
  static const String equipment = 'equipment';
  static const String competition = 'competition';
  static const String analysis = 'analysis';

  static const int maxLevel = 99;
  static const int maxTotalXp = 500000; // Approximate XP for level 99

  // ==========================================================================
  // LEVEL CURVE
  // ==========================================================================

  /// Calculate XP required to reach a given level.
  /// Level 1 = 0 XP
  /// Level 99 requires ~500,000 total XP
  ///
  /// Progression milestones:
  /// - Level 50 = ~15% of total XP
  /// - Level 75 = ~40% of total XP
  /// - Level 92 = ~70% of total XP (the famous RS halfway point)
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    if (level > maxLevel) level = maxLevel;

    // Modified exponential: level^2.5 * 5
    // This creates a gentler curve than RS's level^7 formula
    return (pow(level - 1, 2.5) * 5).floor();
  }

  /// Calculate level from total XP.
  static int levelFromXp(int totalXp) {
    if (totalXp <= 0) return 1;

    for (int level = maxLevel; level >= 1; level--) {
      if (totalXp >= xpForLevel(level)) {
        return level;
      }
    }
    return 1;
  }

  /// Calculate XP needed to reach the next level from current XP.
  static int xpToNextLevel(int currentXp) {
    final currentLevel = levelFromXp(currentXp);
    if (currentLevel >= maxLevel) return 0;

    final nextLevelXp = xpForLevel(currentLevel + 1);
    return nextLevelXp - currentXp;
  }

  /// Calculate progress percentage to next level (0.0 to 1.0).
  static double progressToNextLevel(int currentXp) {
    final currentLevel = levelFromXp(currentXp);
    if (currentLevel >= maxLevel) return 1.0;

    final currentLevelXp = xpForLevel(currentLevel);
    final nextLevelXp = xpForLevel(currentLevel + 1);
    final xpInLevel = currentXp - currentLevelXp;
    final xpNeeded = nextLevelXp - currentLevelXp;

    if (xpNeeded <= 0) return 1.0;
    return (xpInLevel / xpNeeded).clamp(0.0, 1.0);
  }

  // ==========================================================================
  // XP CALCULATIONS BY SKILL
  // ==========================================================================

  /// Calculate XP for archery skill based on handicap.
  /// Lower handicap = better archer = more XP.
  /// Formula: max(0, (150 - handicap) * 10) per completed round
  static int calculateArcheryXp({required int handicap}) {
    // Handicap ranges from 0 (elite) to 150 (beginner)
    // Elite archer (HC 0) gets 1500 XP per round
    // Average club archer (HC 60) gets 900 XP per round
    // Beginner (HC 100+) gets 500 XP or less
    final xp = max(0, (150 - handicap) * 10);
    return xp;
  }

  /// Calculate XP for volume skill.
  /// 1 XP per arrow shot.
  static int calculateVolumeXp({required int arrowCount}) {
    return max(0, arrowCount);
  }

  /// Calculate XP for consistency skill.
  /// 50 XP per training day, plus streak multiplier.
  static int calculateConsistencyXp({
    required int daysThisWeek,
    int streakDays = 0,
  }) {
    // Base: 50 XP per training day
    int xp = daysThisWeek * 50;

    // Streak bonus: +10% per streak day (max 7x = +70%)
    if (streakDays > 0) {
      final streakMultiplier = 1.0 + (min(streakDays, 7) * 0.1);
      xp = (xp * streakMultiplier).floor();
    }

    return xp;
  }

  /// Calculate XP for bow fitness from OLY training.
  /// 1 XP per second of hold time + quality bonus.
  static int calculateBowFitnessXp({
    required int totalHoldSeconds,
    int feedbackShaking = 5,
    int feedbackStructure = 5,
    int feedbackRest = 5,
  }) {
    // Base: 1 XP per second of hold time
    int xp = totalHoldSeconds;

    // Quality bonus based on feedback (lower = better)
    // Feedback is 1-10 scale where 1 = excellent, 10 = poor
    final avgFeedback = (feedbackShaking + feedbackStructure + feedbackRest) / 3;

    if (avgFeedback <= 3) {
      // Excellent form: +50% bonus
      xp = (xp * 1.5).floor();
    } else if (avgFeedback <= 5) {
      // Good form: +25% bonus
      xp = (xp * 1.25).floor();
    }
    // Mediocre or poor form: no bonus

    return xp;
  }

  /// Calculate XP for breath work.
  /// Based on best hold time and exhale time.
  static int calculateBreathWorkXp({
    int? bestHoldSeconds,
    int? bestExhaleSeconds,
  }) {
    int xp = 0;

    // Breath hold: 1 XP per 2 seconds
    if (bestHoldSeconds != null && bestHoldSeconds > 0) {
      xp += bestHoldSeconds ~/ 2;
    }

    // Exhale: 1 XP per 2 seconds (Patrick breath test)
    if (bestExhaleSeconds != null && bestExhaleSeconds > 0) {
      xp += bestExhaleSeconds ~/ 2;
    }

    return xp;
  }

  /// Calculate XP for equipment management.
  /// 25 XP per logged change (tuning session, kit snapshot).
  static int calculateEquipmentXp({
    int tuningSessions = 0,
    int kitSnapshots = 0,
  }) {
    return (tuningSessions + kitSnapshots) * 25;
  }

  /// Calculate XP for competition.
  /// 100 XP base entry + bonus based on performance vs practice.
  static int calculateCompetitionXp({
    required int competitionScore,
    int? avgPracticeScore,
    int maxScore = 720,
  }) {
    // Base: 100 XP for competing
    int xp = 100;

    // Performance bonus if we have practice data to compare
    if (avgPracticeScore != null && avgPracticeScore > 0) {
      final percentOfPractice = competitionScore / avgPracticeScore;

      if (percentOfPractice >= 1.0) {
        // Matched or exceeded practice: +50 XP
        xp += 50;
      }
      if (percentOfPractice >= 1.02) {
        // Beat practice by 2%+: additional +50 XP
        xp += 50;
      }
    }

    // Score percentage bonus
    if (maxScore > 0) {
      final scorePercent = competitionScore / maxScore;
      if (scorePercent >= 0.9) {
        // 90%+ of max score: +100 XP
        xp += 100;
      } else if (scorePercent >= 0.8) {
        // 80%+ of max score: +50 XP
        xp += 50;
      }
    }

    return xp;
  }

  /// Calculate XP for analysis (plotting arrows).
  /// 15 XP per plotted session.
  static int calculateAnalysisXp({
    required int plottedArrows,
  }) {
    if (plottedArrows <= 0) return 0;

    // Base: 15 XP for any plotted session
    int xp = 15;

    // Bonus for thorough plotting
    if (plottedArrows >= 30) {
      // Full session plotted: +10 XP
      xp += 10;
    }
    if (plottedArrows >= 60) {
      // Large session plotted: +10 XP
      xp += 10;
    }

    return xp;
  }

  // ==========================================================================
  // LEVEL MILESTONE INFO
  // ==========================================================================

  /// Get milestone description for a level.
  static String? getMilestoneDescription(int level) {
    switch (level) {
      case 10:
        return 'Novice archer';
      case 25:
        return 'Developing archer';
      case 50:
        return 'Club standard';
      case 75:
        return 'County standard';
      case 92:
        return 'Halfway to mastery';
      case 99:
        return 'Master archer';
      default:
        return null;
    }
  }

  /// Check if a level is a milestone level.
  static bool isMilestoneLevel(int level) {
    return getMilestoneDescription(level) != null;
  }
}
