import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../services/xp_calculation_service.dart';
import '../services/sync_service.dart';
import '../utils/unique_id.dart';
import '../widgets/xp_badge_celebration.dart';

/// Represents a pending level-up for celebration display
class LevelUpEvent {
  final String skillId;
  final String skillName;
  final int oldLevel;
  final int newLevel;
  final DateTime timestamp;

  LevelUpEvent({
    required this.skillId,
    required this.skillName,
    required this.oldLevel,
    required this.newLevel,
    required this.timestamp,
  });
}

/// Manages skills leveling system state.
/// Handles XP awards, level progression, and celebrations.
class SkillsProvider extends ChangeNotifier {
  final AppDatabase _db;

  SkillsProvider(this._db);

  // Cached skill data
  List<SkillLevel> _skills = [];
  int _totalLevel = 0;
  bool _isLoaded = false;

  // Pending level-up events for celebration
  final List<LevelUpEvent> _pendingLevelUps = [];

  // Pending XP award events for badge celebration (significant awards only)
  final List<XpAwardEvent> _pendingXpAwards = [];

  // Getters
  List<SkillLevel> get skills => _skills;
  int get totalLevel => _totalLevel;
  bool get isLoaded => _isLoaded;
  List<LevelUpEvent> get pendingLevelUps => List.unmodifiable(_pendingLevelUps);
  bool get hasPendingLevelUp => _pendingLevelUps.isNotEmpty;
  List<XpAwardEvent> get pendingXpAwards => List.unmodifiable(_pendingXpAwards);
  bool get hasPendingXpAward => _pendingXpAwards.isNotEmpty;

  /// Get a specific skill by ID
  SkillLevel? getSkill(String skillId) {
    try {
      return _skills.firstWhere((s) => s.id == skillId);
    } catch (_) {
      return null;
    }
  }

  /// Get level for a specific skill
  int getLevel(String skillId) {
    return getSkill(skillId)?.currentLevel ?? 1;
  }

  /// Get XP for a specific skill
  int getXp(String skillId) {
    return getSkill(skillId)?.currentXp ?? 0;
  }

  /// Get progress to next level (0.0 to 1.0) for a skill
  double getProgress(String skillId) {
    final skill = getSkill(skillId);
    if (skill == null) return 0.0;
    return XpCalculationService.progressToNextLevel(skill.currentXp);
  }

  /// Load skill data from database
  Future<void> loadSkills() async {
    try {
      // Ensure skills exist in database
      await _db.ensureSkillLevelsExist();

      // Load all skills
      _skills = await _db.getAllSkillLevels();

      // Update levels based on XP (in case of data inconsistency)
      for (final skill in _skills) {
        final calculatedLevel = XpCalculationService.levelFromXp(skill.currentXp);
        if (calculatedLevel != skill.currentLevel) {
          await _db.updateSkillLevel(
            skill.id,
            currentLevel: calculatedLevel,
          );
        }
      }

      // Reload after any updates
      _skills = await _db.getAllSkillLevels();

      // Calculate total level
      _totalLevel = _skills.fold<int>(0, (sum, skill) => sum + skill.currentLevel);

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading skills: $e');
    }
  }

  /// Award XP to a skill
  /// Returns true if a level-up occurred
  Future<bool> awardXp({
    required String skillId,
    required int xpAmount,
    required String source,
    String? sourceId,
    String? reason,
  }) async {
    if (xpAmount <= 0) return false;

    try {
      // Get current state before award
      final skill = getSkill(skillId);
      if (skill == null) {
        debugPrint('Cannot award XP: skill $skillId not found');
        return false;
      }

      final oldLevel = skill.currentLevel;
      final oldXp = skill.currentXp;
      final newXp = oldXp + xpAmount;
      final newLevel = XpCalculationService.levelFromXp(newXp);

      // Award XP in database
      await _db.awardXp(
        skillId: skillId,
        xpAmount: xpAmount,
        source: source,
        sourceId: sourceId,
        reason: reason,
      );

      // Check for level-up
      final leveledUp = newLevel > oldLevel;
      if (leveledUp) {
        // Update level in database
        await _db.updateSkillLevel(
          skillId,
          currentLevel: newLevel,
          lastLevelUpAt: DateTime.now(),
        );

        // Queue level-up celebration
        _pendingLevelUps.add(LevelUpEvent(
          skillId: skillId,
          skillName: skill.name,
          oldLevel: oldLevel,
          newLevel: newLevel,
          timestamp: DateTime.now(),
        ));
      }

      // Reload skills to refresh state
      await loadSkills();

      // Trigger cloud backup in background
      _triggerCloudBackup();

      return leveledUp;
    } catch (e) {
      debugPrint('Error awarding XP: $e');
      return false;
    }
  }

  /// Clear the next pending level-up (after celebration is shown)
  LevelUpEvent? consumeNextLevelUp() {
    if (_pendingLevelUps.isEmpty) return null;
    final event = _pendingLevelUps.removeAt(0);
    notifyListeners();
    return event;
  }

  /// Clear all pending level-ups
  void clearPendingLevelUps() {
    _pendingLevelUps.clear();
    notifyListeners();
  }

  /// Queue an XP award celebration (for significant awards)
  void queueXpAwardCelebration(XpAwardEvent event) {
    _pendingXpAwards.add(event);
    notifyListeners();
  }

  /// Clear the next pending XP award (after celebration is shown)
  XpAwardEvent? consumeNextXpAward() {
    if (_pendingXpAwards.isEmpty) return null;
    final event = _pendingXpAwards.removeAt(0);
    notifyListeners();
    return event;
  }

  /// Clear all pending XP awards
  void clearPendingXpAwards() {
    _pendingXpAwards.clear();
    notifyListeners();
  }

  /// Get XP history for a skill
  Future<List<XpHistoryData>> getXpHistory(String skillId, {int limit = 50}) async {
    try {
      final history = await _db.getXpHistoryForSkill(skillId);
      return history.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting XP history: $e');
      return [];
    }
  }

  /// Get recent XP awards across all skills
  Future<List<XpHistoryData>> getRecentXpAwards({int limit = 20}) async {
    try {
      return await _db.getRecentXpHistory(limit: limit);
    } catch (e) {
      debugPrint('Error getting recent XP: $e');
      return [];
    }
  }

  /// Recalculate all skill levels from XP history.
  /// Useful for data integrity or after restoring from backup.
  Future<void> recalculateAllSkills() async {
    try {
      for (final skill in _skills) {
        final totalXp = await _db.getTotalXpForSkill(skill.id);
        final calculatedLevel = XpCalculationService.levelFromXp(totalXp);

        await _db.updateSkillLevel(
          skill.id,
          currentXp: totalXp,
          currentLevel: calculatedLevel,
        );
      }

      await loadSkills();
      _triggerCloudBackup();
    } catch (e) {
      debugPrint('Error recalculating skills: $e');
    }
  }

  /// Get XP earned today for a skill
  Future<int> getXpToday(String skillId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      return await _db.getXpInRange(skillId, startOfDay, endOfDay);
    } catch (e) {
      return 0;
    }
  }

  /// Get XP earned this week for a skill
  Future<int> getXpThisWeek(String skillId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    try {
      return await _db.getXpInRange(skillId, startOfDay, now);
    } catch (e) {
      return 0;
    }
  }

  // ==========================================================================
  // HELPER METHODS FOR AWARDING XP FROM ACTIVITIES
  // ==========================================================================

  /// Award XP for completing a scoring session
  Future<void> awardSessionXp({
    required String sessionId,
    required int handicap,
    required int arrowCount,
    required bool hasPlottedArrows,
    required bool isCompetition,
    int? competitionScore,
    int? avgPracticeScore,
    int? maxScore,
    String? roundTypeId,
    String? roundName,
  }) async {
    // Archery skill XP (based on handicap)
    final archeryXp = XpCalculationService.calculateArcheryXp(handicap: handicap);
    if (archeryXp > 0) {
      await awardXp(
        skillId: XpCalculationService.archerySkill,
        xpAmount: archeryXp,
        source: 'session',
        sourceId: sessionId,
        reason: 'Completed round (HC $handicap)',
      );
    }

    // Volume XP (1 per arrow)
    final volumeXp = XpCalculationService.calculateVolumeXp(arrowCount: arrowCount);
    if (volumeXp > 0) {
      await awardXp(
        skillId: XpCalculationService.volume,
        xpAmount: volumeXp,
        source: 'session',
        sourceId: sessionId,
        reason: '$arrowCount arrows shot',
      );
    }

    // Analysis XP (if arrows were plotted)
    if (hasPlottedArrows) {
      final analysisXp = XpCalculationService.calculateAnalysisXp(
        plottedArrows: arrowCount,
      );
      if (analysisXp > 0) {
        await awardXp(
          skillId: XpCalculationService.analysis,
          xpAmount: analysisXp,
          source: 'session',
          sourceId: sessionId,
          reason: 'Plotted $arrowCount arrows',
        );
      }
    }

    // Competition XP
    if (isCompetition && competitionScore != null) {
      final compXp = XpCalculationService.calculateCompetitionXp(
        competitionScore: competitionScore,
        avgPracticeScore: avgPracticeScore,
        maxScore: maxScore ?? 720,
      );
      if (compXp > 0) {
        await awardXp(
          skillId: XpCalculationService.competition,
          xpAmount: compXp,
          source: 'competition',
          sourceId: sessionId,
          reason: 'Competition score: $competitionScore',
        );

        // Check for PB using absolute numbers (any improvement over previous best)
        if (roundTypeId != null && roundName != null) {
          final isPb = await recordPbIfNew(
            roundTypeId: roundTypeId,
            roundName: roundName,
            score: competitionScore,
            isCompetition: true,
            skillId: XpCalculationService.competition,
          );

          if (isPb) {
            // Queue celebration for competition PB
            queueXpAwardCelebration(XpAwardEvent(
              skillName: 'Competition',
              xpAmount: compXp,
              reason: 'Personal Best! $competitionScore!',
              achievementType: AchievementType.personalBest,
            ));
          }
        }
        // Note: 90% comp celebration removed - that's just for XP, not reward screens
      }
    } else if (!isCompetition && competitionScore != null && roundTypeId != null && roundName != null) {
      // Practice session PB check
      final isPb = await recordPbIfNew(
        roundTypeId: roundTypeId,
        roundName: roundName,
        score: competitionScore,
        isCompetition: false,
        skillId: XpCalculationService.archerySkill,
      );

      if (isPb) {
        // Queue celebration for practice PB (less elaborate)
        queueXpAwardCelebration(XpAwardEvent(
          skillName: 'Archery',
          xpAmount: archeryXp,
          reason: 'New PB! $competitionScore!',
          achievementType: AchievementType.personalBest,
        ));
      }
    }
  }

  /// Award XP for completing bow training (OLY)
  Future<void> awardBowTrainingXp({
    required String logId,
    required int totalHoldSeconds,
    int feedbackShaking = 5,
    int feedbackStructure = 5,
    int feedbackRest = 5,
  }) async {
    final xp = XpCalculationService.calculateBowFitnessXp(
      totalHoldSeconds: totalHoldSeconds,
      feedbackShaking: feedbackShaking,
      feedbackStructure: feedbackStructure,
      feedbackRest: feedbackRest,
    );

    if (xp > 0) {
      await awardXp(
        skillId: XpCalculationService.bowFitness,
        xpAmount: xp,
        source: 'training',
        sourceId: logId,
        reason: '${totalHoldSeconds}s total hold time',
      );

      // Queue celebration and record achievement for excellent form
      final avgFeedback = (feedbackShaking + feedbackStructure + feedbackRest) / 3;
      if (avgFeedback <= 3 && totalHoldSeconds >= 30) {
        queueXpAwardCelebration(XpAwardEvent(
          skillName: 'Bow Fitness',
          xpAmount: xp,
          reason: 'Excellent form!',
          achievementType: AchievementType.excellentForm,
        ));
        await recordExcellentFormAchievement(
          skillId: XpCalculationService.bowFitness,
        );
      }
    }
  }

  /// Award XP for breath training
  Future<void> awardBreathTrainingXp({
    required String logId,
    int? bestHoldSeconds,
    int? bestExhaleSeconds,
  }) async {
    final xp = XpCalculationService.calculateBreathWorkXp(
      bestHoldSeconds: bestHoldSeconds,
      bestExhaleSeconds: bestExhaleSeconds,
    );

    if (xp > 0) {
      String reason = '';
      if (bestHoldSeconds != null) reason = '${bestHoldSeconds}s hold';
      if (bestExhaleSeconds != null) {
        if (reason.isNotEmpty) reason += ', ';
        reason += '${bestExhaleSeconds}s exhale';
      }

      await awardXp(
        skillId: XpCalculationService.breathWork,
        xpAmount: xp,
        source: 'breath',
        sourceId: logId,
        reason: reason,
      );
    }
  }

  /// Award XP for equipment management
  Future<void> awardEquipmentXp({
    String? sourceId,
    required String reason,
  }) async {
    const xp = 25; // Fixed XP for equipment logging

    await awardXp(
      skillId: XpCalculationService.equipment,
      xpAmount: xp,
      source: 'equipment',
      sourceId: sourceId,
      reason: reason,
    );
  }

  /// Award consistency XP (should be called daily or on session completion)
  Future<void> awardConsistencyXp({
    required int daysThisWeek,
    int streakDays = 0,
  }) async {
    final xp = XpCalculationService.calculateConsistencyXp(
      daysThisWeek: daysThisWeek,
      streakDays: streakDays,
    );

    if (xp > 0) {
      await awardXp(
        skillId: XpCalculationService.consistency,
        xpAmount: xp,
        source: 'consistency',
        reason: '$daysThisWeek days trained${streakDays > 0 ? ', $streakDays day streak' : ''}',
      );

      // Queue celebration and record achievement for streak milestones
      if (streakDays == 7) {
        queueXpAwardCelebration(XpAwardEvent(
          skillName: 'Consistency',
          xpAmount: xp,
          reason: '7 day training streak!',
          achievementType: AchievementType.streak7,
        ));
        await recordStreakAchievement(
          streakDays: 7,
          skillId: XpCalculationService.consistency,
        );
      } else if (streakDays == 14) {
        queueXpAwardCelebration(XpAwardEvent(
          skillName: 'Consistency',
          xpAmount: xp,
          reason: '14 day training streak!',
          achievementType: AchievementType.streak14,
        ));
        await recordStreakAchievement(
          streakDays: 14,
          skillId: XpCalculationService.consistency,
        );
      } else if (streakDays == 30) {
        queueXpAwardCelebration(XpAwardEvent(
          skillName: 'Consistency',
          xpAmount: xp,
          reason: '30 day training streak!',
          achievementType: AchievementType.streak30,
        ));
        await recordStreakAchievement(
          streakDays: 30,
          skillId: XpCalculationService.consistency,
        );
      }
    }
  }

  // ==========================================================================
  // ACHIEVEMENTS
  // ==========================================================================

  /// Get all earned achievements
  Future<List<Achievement>> getAllAchievements() async {
    try {
      return await _db.getAllAchievements();
    } catch (e) {
      debugPrint('Error getting achievements: $e');
      return [];
    }
  }

  /// Get recent achievements (limited)
  Future<List<Achievement>> getRecentAchievements({int limit = 10}) async {
    try {
      return await _db.getRecentAchievements(limit: limit);
    } catch (e) {
      debugPrint('Error getting recent achievements: $e');
      return [];
    }
  }

  /// Record a streak achievement
  Future<void> recordStreakAchievement({
    required int streakDays,
    required String skillId,
  }) async {
    try {
      final type = streakDays >= 30
          ? 'streak30'
          : streakDays >= 14
              ? 'streak14'
              : 'streak7';

      // Check if we already have this streak achievement
      final existing = await _db.getAchievement(type);
      if (existing != null) return; // Don't duplicate

      await _db.insertAchievement(AchievementsCompanion.insert(
        id: UniqueId.generate(),
        achievementType: type,
        skillId: Value(skillId),
        title: '$streakDays DAY STREAK',
        description: Value('$streakDays consecutive training days'),
      ));

      notifyListeners();
    } catch (e) {
      debugPrint('Error recording streak achievement: $e');
    }
  }

  /// Record a personal best achievement (practice or competition)
  /// Returns true if this is a new PB
  Future<bool> recordPbIfNew({
    required String roundTypeId,
    required String roundName,
    required int score,
    required bool isCompetition,
    String? skillId,
  }) async {
    try {
      // Get current best for this round
      final currentBest = await _db.getBestPbForRound(roundTypeId);

      // Check if this is a new PB (any improvement counts!)
      if (currentBest != null && currentBest.score != null) {
        if (score <= currentBest.score!) {
          return false; // Not a PB
        }
      }

      // This is a PB! Record it
      final type = isCompetition ? 'competitionPb' : 'personalBest';
      final title = isCompetition
          ? '${_shortenRoundName(roundName)} COMP PB'
          : '${_shortenRoundName(roundName)} PB';

      await _db.insertAchievement(AchievementsCompanion.insert(
        id: UniqueId.generate(),
        achievementType: type,
        skillId: Value(skillId),
        roundTypeId: Value(roundTypeId),
        score: Value(score),
        title: title,
        description: Value('Score: $score'),
        isCompetitionPb: Value(isCompetition),
      ));

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error recording PB achievement: $e');
      return false;
    }
  }

  /// Record an excellent form achievement
  Future<void> recordExcellentFormAchievement({String? skillId}) async {
    try {
      // We allow multiple excellent form achievements (not unique)
      await _db.insertAchievement(AchievementsCompanion.insert(
        id: UniqueId.generate(),
        achievementType: 'excellentForm',
        skillId: Value(skillId ?? 'bow_fitness'),
        title: 'EXCELLENT FORM',
        description: const Value('Outstanding training form'),
      ));
      notifyListeners();
    } catch (e) {
      debugPrint('Error recording excellent form achievement: $e');
    }
  }

  /// Record a milestone achievement (level milestone)
  Future<void> recordMilestoneAchievement({
    required String skillId,
    required String skillName,
    required int level,
  }) async {
    try {
      final type = 'milestone_${skillId}_$level';

      // Check if we already have this milestone
      final existing = await _db.getAchievement(type);
      if (existing != null) return; // Don't duplicate

      await _db.insertAchievement(AchievementsCompanion.insert(
        id: UniqueId.generate(),
        achievementType: type,
        skillId: Value(skillId),
        title: '${skillName.toUpperCase()} $level',
        description: Value('Reached level $level'),
      ));

      notifyListeners();
    } catch (e) {
      debugPrint('Error recording milestone achievement: $e');
    }
  }

  String _shortenRoundName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('portsmouth')) return 'POR';
    if (lower.contains('worcester')) return 'WOR';
    if (lower.contains('vegas')) return 'VEG';
    if (lower.contains('wa 720') || lower.contains('wa720')) return '720';
    if (lower.contains('wa 1440') || lower.contains('wa1440')) return '1440';
    if (lower.contains('national')) return 'NAT';
    if (lower.contains('york')) return 'YRK';
    if (lower.contains('hereford')) return 'HER';
    if (lower.contains('bristol')) return 'BRI';
    if (lower.contains('st george')) return 'STG';
    if (lower.contains('albion')) return 'ALB';
    if (lower.contains('windsor')) return 'WIN';
    if (lower.contains('western')) return 'WST';
    if (lower.contains('american')) return 'AMR';
    if (name.length >= 3) return name.substring(0, 3).toUpperCase();
    return name.toUpperCase();
  }

  // ==========================================================================
  // CLOUD BACKUP
  // ==========================================================================

  void _triggerCloudBackup() {
    // SyncService handles its own error handling and retry logic
    SyncService().syncAll();
  }
}
