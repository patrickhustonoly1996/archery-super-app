import 'dart:math';
import 'package:drift/drift.dart';
import '../db/database.dart';

/// Seeds the database with sample data for demo purposes.
/// Creates a profile for "Testy McTestface" with 6+ months of realistic data.
class SampleDataSeeder {
  final AppDatabase _db;
  final Random _random = Random(42); // Fixed seed for reproducibility

  SampleDataSeeder(this._db);

  // Equipment IDs
  static const bowId = 'bow_sample_001';
  static const quiverId = 'quiver_sample_001';
  static const stabilizerId = 'stab_sample_001';
  static const tabId = 'tab_sample_001';
  static const stringId = 'string_sample_001';
  static const profileId = 'sample_user_001';

  /// Seeds all sample data. Call this once after creating the Firebase user.
  Future<void> seedAll() async {
    await seedUserProfile();
    await seedEquipment();
    await seedScoringSessions();
    await seedOlyTrainingLogs();
    await seedBreathTrainingLogs();
    await seedSkillLevels();
    await seedSightMarks();
    await seedVolumeEntries();
    await seedMilestones();
  }

  /// Clears all sample data
  Future<void> clearSampleData() async {
    // Clear in reverse dependency order
    await (_db.delete(_db.arrows)..where((t) => t.endId.like('end_sample_%'))).go();
    await (_db.delete(_db.ends)..where((t) => t.sessionId.like('session_sample_%'))).go();
    await (_db.delete(_db.sessions)..where((t) => t.id.like('session_sample_%'))).go();
    await (_db.delete(_db.olyTrainingLogs)..where((t) => t.id.like('oly_sample_%'))).go();
    await (_db.delete(_db.userTrainingProgress)..where((t) => t.id.equals('progress_sample'))).go();
    await (_db.delete(_db.breathTrainingLogs)..where((t) => t.id.like('breath_sample_%'))).go();
    await (_db.delete(_db.xpHistory)..where((t) => t.id.like('xp_sample_%'))).go();
    await (_db.delete(_db.sightMarks)..where((t) => t.id.like('sight_sample_%'))).go();
    await (_db.delete(_db.volumeEntries)..where((t) => t.id.like('vol_sample_%'))).go();
    await (_db.delete(_db.milestones)..where((t) => t.id.like('mile_sample_%'))).go();
    await (_db.delete(_db.shafts)..where((t) => t.id.like('shaft_sample_%'))).go();
    await (_db.delete(_db.quivers)..where((t) => t.id.equals(quiverId))).go();
    await (_db.delete(_db.stabilizers)..where((t) => t.id.equals(stabilizerId))).go();
    await (_db.delete(_db.fingerTabs)..where((t) => t.id.equals(tabId))).go();
    await (_db.delete(_db.bowStrings)..where((t) => t.id.equals(stringId))).go();
    await (_db.delete(_db.bows)..where((t) => t.id.equals(bowId))).go();
    await (_db.delete(_db.federations)..where((t) => t.profileId.equals(profileId))).go();
    await (_db.delete(_db.userProfiles)..where((t) => t.id.equals(profileId))).go();
  }

  Future<void> seedUserProfile() async {
    // Check if profile already exists
    final existing = await (_db.select(_db.userProfiles)
          ..where((t) => t.id.equals(profileId)))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.userProfiles)..where((t) => t.id.equals(profileId)))
          .write(UserProfilesCompanion(
        name: const Value('Testy McTestface'),
        primaryBowType: const Value('recurve'),
        handedness: const Value('right'),
        clubName: const Value('Sample Archery Club'),
        yearsShootingStart: const Value(2022),
        shootingFrequency: const Value(4.0),
        competitionLevels: const Value('["local", "regional", "national"]'),
        notes: const Value('Demo account for tech PM review'),
        updatedAt: Value(DateTime.now()),
      ));
    } else {
      await _db.into(_db.userProfiles).insert(UserProfilesCompanion.insert(
            id: profileId,
            name: const Value('Testy McTestface'),
            primaryBowType: const Value('recurve'),
            handedness: const Value('right'),
            clubName: const Value('Sample Archery Club'),
            yearsShootingStart: const Value(2022),
            shootingFrequency: const Value(4.0),
            competitionLevels: const Value('["local", "regional", "national"]'),
            notes: const Value('Demo account for tech PM review'),
          ));
    }

    // Add AGB federation membership
    const fedId = 'fed_sample_001';
    final existingFed = await (_db.select(_db.federations)
          ..where((t) => t.id.equals(fedId)))
        .getSingleOrNull();

    if (existingFed == null) {
      await _db.into(_db.federations).insert(FederationsCompanion.insert(
            id: fedId,
            profileId: profileId,
            federationName: 'Archery GB',
            membershipNumber: const Value('AGB-2024-12345'),
            isPrimary: const Value(true),
            expiryDate: Value(DateTime(2026, 9, 30)),
          ));
    }
  }

  Future<void> seedEquipment() async {
    // Create bow
    final existingBow = await (_db.select(_db.bows)
          ..where((t) => t.id.equals(bowId)))
        .getSingleOrNull();
    if (existingBow == null) {
      await _db.into(_db.bows).insert(BowsCompanion.insert(
            id: bowId,
            name: 'Competition Setup',
            bowType: 'recurve',
            isDefault: const Value(true),
            riserModel: const Value('Hoyt Formula Xi 25"'),
            riserPurchaseDate: Value(DateTime(2023, 3, 15)),
            limbModel: const Value('Uukha VX1000 Medium'),
            limbPurchaseDate: Value(DateTime(2024, 1, 10)),
            poundage: const Value(38.0),
            tillerTop: const Value(3.0),
            tillerBottom: const Value(5.0),
            braceHeight: const Value(8.75),
            nockingPointHeight: const Value(6.5),
            buttonPosition: const Value(3.0),
            buttonTension: const Value('medium'),
            clickerPosition: const Value(12.5),
            eyeToArrowDistance: const Value(95.0),
          ));
    }

    // Create quiver
    final existingQuiver = await (_db.select(_db.quivers)
          ..where((t) => t.id.equals(quiverId)))
        .getSingleOrNull();
    if (existingQuiver == null) {
      await _db.into(_db.quivers).insert(QuiversCompanion.insert(
            id: quiverId,
            bowId: Value(bowId),
            name: 'Easton X10 Set',
            shaftCount: const Value(12),
            isDefault: const Value(true),
            settings: const Value(
                '{"shaft":{"model":"Easton X10","spine":550,"diameter":"4.5mm","cutLength":27.5},"point":{"type":"break-off","weight":120},"nock":{"type":"pin","model":"Beiter","color":"white"},"fletching":{"type":"spin_wings","model":"Kurly Vane","size":"1.75","angle":1.5,"color":"black"}}'),
          ));

      // Create 12 shafts
      for (int i = 1; i <= 12; i++) {
        await _db.into(_db.shafts).insert(ShaftsCompanion.insert(
              id: 'shaft_sample_$i',
              quiverId: quiverId,
              number: i,
              spine: const Value(550),
              lengthInches: const Value(27.5),
              pointWeight: const Value(120),
              fletchingType: const Value('spin_wings'),
              fletchingColor: const Value('black'),
              nockColor: const Value('white'),
              totalWeight: const Value(315),
            ));
      }
    }

    // Create stabilizers
    final existingStab = await (_db.select(_db.stabilizers)
          ..where((t) => t.id.equals(stabilizerId)))
        .getSingleOrNull();
    if (existingStab == null) {
      await _db.into(_db.stabilizers).insert(StabilizersCompanion.insert(
            id: stabilizerId,
            bowId: bowId,
            name: const Value('Competition Setup'),
            longRodModel: const Value('Doinker Platinum Hi-Mod'),
            longRodLength: const Value(30.0),
            longRodWeight: const Value(4.0),
            leftSideRodModel: const Value('Doinker Platinum Hi-Mod'),
            leftSideRodLength: const Value(12.0),
            leftSideRodWeight: const Value(2.0),
            leftWeights: const Value('2x 1oz'),
            leftAngleHorizontal: const Value(35.0),
            leftAngleVertical: const Value(10.0),
            rightSideRodModel: const Value('Doinker Platinum Hi-Mod'),
            rightSideRodLength: const Value(12.0),
            rightSideRodWeight: const Value(2.0),
            rightWeights: const Value('2x 1oz'),
            rightAngleHorizontal: const Value(35.0),
            rightAngleVertical: const Value(10.0),
            extenderLength: const Value(4.0),
            vbarModel: const Value('Doinker V-Bar'),
            longRodWeights: const Value('4x 1oz stacked'),
            damperModel: const Value('Doinker A-Bomb'),
            damperPositions: const Value('end of long, between side weights'),
          ));
    }

    // Create finger tab
    final existingTab = await (_db.select(_db.fingerTabs)
          ..where((t) => t.id.equals(tabId)))
        .getSingleOrNull();
    if (existingTab == null) {
      await _db.into(_db.fingerTabs).insert(FingerTabsCompanion.insert(
            id: tabId,
            name: 'Competition Tab',
            make: const Value('AAE'),
            model: const Value('Elite'),
            size: const Value('L'),
            plateType: const Value('Aluminium'),
            fingerSpacer: const Value('Medium'),
            isDefault: const Value(true),
          ));
    }

    // Create bow string
    final existingString = await (_db.select(_db.bowStrings)
          ..where((t) => t.id.equals(stringId)))
        .getSingleOrNull();
    if (existingString == null) {
      await _db.into(_db.bowStrings).insert(BowStringsCompanion.insert(
            id: stringId,
            bowId: bowId,
            name: const Value('BCY-X String'),
            material: const Value('BCY-X'),
            strandCount: const Value(18),
            servingMaterial: const Value('Angel Majesty'),
            stringLength: const Value(68.5),
            color: const Value('Black/Gold'),
            isActive: const Value(true),
            purchaseDate: Value(DateTime(2025, 6, 1)),
          ));
    }
  }

  Future<void> seedScoringSessions() async {
    // Clear existing sample sessions
    await (_db.delete(_db.arrows)..where((t) => t.endId.like('end_sample_%'))).go();
    await (_db.delete(_db.ends)..where((t) => t.sessionId.like('session_sample_%'))).go();
    await (_db.delete(_db.sessions)..where((t) => t.id.like('session_sample_%'))).go();

    int sessionCount = 0;

    // August 2025 - January 2026 (6 months)
    var currentDate = DateTime(2025, 8, 1);
    final endDate = DateTime(2026, 1, 18);

    // Track progression
    double outdoorHandicap = 35.0;
    double indoorHandicap = 28.0;

    while (currentDate.isBefore(endDate)) {
      final isIndoorSeason = currentDate.month >= 10 || currentDate.month <= 3;
      final dayOfWeek = currentDate.weekday;

      // Practice 3-4 times per week
      final shouldPractice = dayOfWeek == DateTime.tuesday ||
          dayOfWeek == DateTime.thursday ||
          dayOfWeek == DateTime.saturday ||
          (dayOfWeek == DateTime.sunday && _random.nextDouble() > 0.5);

      // Competition roughly every 2-3 weeks
      final isCompetitionDay =
          (dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday) &&
              _random.nextDouble() > 0.85;

      if (shouldPractice || isCompetitionDay) {
        sessionCount++;
        final sessionId = 'session_sample_$sessionCount';
        final sessionType = isCompetitionDay ? 'competition' : 'practice';

        // Choose round type
        String roundTypeId;
        if (isIndoorSeason) {
          if (isCompetitionDay) {
            roundTypeId = _random.nextBool() ? 'portsmouth' : 'wa_18_60';
          } else {
            roundTypeId = _random.nextDouble() > 0.7
                ? 'practice_indoor_3'
                : (_random.nextBool() ? 'portsmouth' : 'wa_18_30');
          }
        } else {
          if (isCompetitionDay) {
            roundTypeId = _random.nextDouble() > 0.3 ? 'wa_720_70m' : 'metric_2';
          } else {
            roundTypeId = _random.nextDouble() > 0.6
                ? 'practice_outdoor_6'
                : (_random.nextBool() ? 'wa_720_70m' : 'half_metric_70m');
          }
        }

        // Get round details
        final roundType = await (_db.select(_db.roundTypes)
              ..where((t) => t.id.equals(roundTypeId)))
            .getSingle();

        int maxScore = roundType.maxScore;
        int arrowsPerEnd = roundType.arrowsPerEnd;
        int totalEnds = roundType.totalEnds;

        // For practice rounds, limit ends
        if (roundTypeId.startsWith('practice_')) {
          totalEnds = 10 + _random.nextInt(15);
          maxScore = totalEnds * arrowsPerEnd * 10;
        }

        // Calculate expected score
        final handicap = roundType.isIndoor ? indoorHandicap : outdoorHandicap;
        final targetScore = _calculateScoreFromHandicap(handicap, maxScore);
        final variance = (maxScore * 0.03 * (_random.nextDouble() - 0.5)).round();
        final actualScore = (targetScore + variance).clamp(0, maxScore);

        // Create session
        final startTime = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          isIndoorSeason ? 19 : 10,
          0,
        );
        final endTime = startTime.add(Duration(hours: isCompetitionDay ? 3 : 2));

        // Calculate score breakdown
        var remainingScore = actualScore;
        var totalXs = 0;
        final endScores = <int>[];
        final endXCounts = <int>[];

        for (int e = 0; e < totalEnds; e++) {
          final avgPerArrow = remainingScore / ((totalEnds - e) * arrowsPerEnd);
          var endScore = 0;
          var endXCount = 0;

          for (int a = 0; a < arrowsPerEnd; a++) {
            final arrowScore = _generateArrowScore(avgPerArrow, handicap);
            endScore += arrowScore;
            if (arrowScore == 10 && _random.nextDouble() > 0.6) {
              endXCount++;
            }
          }
          endScore = endScore.clamp(0, arrowsPerEnd * 10);
          remainingScore -= endScore;
          endScores.add(endScore);
          endXCounts.add(endXCount);
          totalXs += endXCount;
        }

        final computedTotal = endScores.reduce((a, b) => a + b);

        await _db.into(_db.sessions).insert(SessionsCompanion.insert(
              id: sessionId,
              roundTypeId: roundTypeId,
              sessionType: Value(sessionType),
              location: Value(isIndoorSeason ? 'Indoor Range' : 'Outdoor Field'),
              startedAt: Value(startTime),
              completedAt: Value(endTime),
              totalScore: Value(computedTotal),
              totalXs: Value(totalXs),
              bowId: Value(bowId),
              quiverId: Value(quiverId),
            ));

        // Create ends and arrows
        for (int e = 0; e < totalEnds; e++) {
          final endId = 'end_sample_${sessionCount}_$e';
          await _db.into(_db.ends).insert(EndsCompanion.insert(
                id: endId,
                sessionId: sessionId,
                endNumber: e + 1,
                endScore: Value(endScores[e]),
                endXs: Value(endXCounts[e]),
                status: const Value('committed'),
                committedAt: Value(startTime.add(Duration(minutes: 4 * (e + 1)))),
                createdAt: Value(startTime.add(Duration(minutes: 4 * e))),
              ));

          // Create arrows
          var arrowsForEnd = <int>[];
          var endTotal = endScores[e];

          for (int a = 0; a < arrowsPerEnd - 1; a++) {
            final avgRemaining = endTotal / (arrowsPerEnd - a);
            final arrowScore = _generateArrowScore(avgRemaining, handicap).clamp(0, 10);
            arrowsForEnd.add(arrowScore);
            endTotal -= arrowScore;
          }
          arrowsForEnd.add(endTotal.clamp(0, 10));
          arrowsForEnd.shuffle(_random);

          for (int a = 0; a < arrowsPerEnd; a++) {
            final arrowId = 'arrow_sample_${sessionCount}_${e}_$a';
            final score = arrowsForEnd[a];
            final isX = score == 10 && a < endXCounts[e];
            final position = _generateArrowPosition(score, roundType.faceSize);

            await _db.into(_db.arrows).insert(ArrowsCompanion.insert(
                  id: arrowId,
                  endId: endId,
                  x: position.$1,
                  y: position.$2,
                  xMm: Value(position.$1 * roundType.faceSize / 2),
                  yMm: Value(position.$2 * roundType.faceSize / 2),
                  score: score,
                  isX: Value(isX),
                  sequence: a + 1,
                  shaftNumber: Value((a % 6) + 1),
                ));
          }
        }

        // Improve handicap over time
        if (isCompetitionDay) {
          if (roundType.isIndoor) {
            indoorHandicap = (indoorHandicap - 0.3).clamp(18.0, 35.0);
          } else {
            outdoorHandicap = (outdoorHandicap - 0.4).clamp(25.0, 40.0);
          }
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  int _calculateScoreFromHandicap(double handicap, int maxScore) {
    final percentage = 1.0 - (handicap / 150);
    return (maxScore * percentage).round();
  }

  int _generateArrowScore(double targetAvg, double handicap) {
    final base = targetAvg.round();
    final variance = (3 - handicap / 20).clamp(1, 3).toInt();
    final delta = _random.nextInt(variance * 2 + 1) - variance;
    return (base + delta).clamp(0, 10);
  }

  (double, double) _generateArrowPosition(int score, int faceSize) {
    final maxRadius = 1.0 - (score / 12.0);
    final radius = maxRadius * (0.5 + _random.nextDouble() * 0.5);
    final angle = _random.nextDouble() * 2 * 3.14159;
    return (radius * cos(angle), radius * sin(angle));
  }

  Future<void> seedOlyTrainingLogs() async {
    await (_db.delete(_db.olyTrainingLogs)..where((t) => t.id.like('oly_sample_%'))).go();
    await (_db.delete(_db.userTrainingProgress)..where((t) => t.id.equals('progress_sample'))).go();

    final templates = await _db.select(_db.olySessionTemplates).get();
    if (templates.isEmpty) return;

    templates.sort((a, b) => a.version.compareTo(b.version));

    var currentDate = DateTime(2025, 8, 5);
    final endDate = DateTime(2026, 1, 15);
    var currentTemplateIndex = 0;
    var sessionsAtLevel = 0;
    int logCount = 0;

    while (currentDate.isBefore(endDate) && currentTemplateIndex < templates.length) {
      if (currentDate.weekday == DateTime.monday || currentDate.weekday == DateTime.wednesday) {
        logCount++;
        final template = templates[currentTemplateIndex];
        final logId = 'oly_sample_$logCount';

        final progressFactor = sessionsAtLevel / 6.0;
        final shaking = (6 - progressFactor * 3).clamp(1, 10).round();
        final structure = (5 - progressFactor * 2).clamp(1, 10).round();
        final rest = (6 - progressFactor * 2).clamp(1, 10).round();

        final shouldProgress = sessionsAtLevel >= 4 && shaking <= 4 && structure <= 4;
        final suggestion = shouldProgress ? 'progress' : 'repeat';

        await _db.into(_db.olyTrainingLogs).insert(OlyTrainingLogsCompanion.insert(
              id: logId,
              sessionTemplateId: Value(template.id),
              sessionVersion: template.version,
              sessionName: template.name,
              plannedDurationSeconds: template.durationMinutes * 60,
              actualDurationSeconds: template.durationMinutes * 60 + _random.nextInt(300) - 150,
              plannedExercises: 5,
              completedExercises: 5,
              totalHoldSeconds: template.durationMinutes * 30,
              totalRestSeconds: template.durationMinutes * 30,
              feedbackShaking: Value(shaking),
              feedbackStructure: Value(structure),
              feedbackRest: Value(rest),
              progressionSuggestion: Value(suggestion),
              suggestedNextVersion: Value(
                  shouldProgress && currentTemplateIndex + 1 < templates.length
                      ? templates[currentTemplateIndex + 1].version
                      : template.version),
              startedAt:
                  DateTime(currentDate.year, currentDate.month, currentDate.day, 18, 0),
              completedAt: DateTime(currentDate.year, currentDate.month, currentDate.day,
                  18, template.durationMinutes),
              notes: Value(sessionsAtLevel == 0 ? 'First session at this level' : null),
            ));

        sessionsAtLevel++;

        if (shouldProgress && currentTemplateIndex + 1 < templates.length) {
          currentTemplateIndex++;
          sessionsAtLevel = 0;
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    final currentTemplate = templates[currentTemplateIndex.clamp(0, templates.length - 1)];
    await _db.into(_db.userTrainingProgress).insert(UserTrainingProgressCompanion.insert(
          id: 'progress_sample',
          currentLevel: Value(currentTemplate.version),
          sessionsAtCurrentLevel: Value(sessionsAtLevel),
          lastSessionAt: Value(currentDate.subtract(const Duration(days: 2))),
          lastSessionVersion: Value(currentTemplate.version),
          totalSessionsCompleted: Value(logCount),
          hasCompletedAssessment: const Value(true),
          assessmentMaxHoldSeconds: const Value(45),
          assessmentDate: Value(DateTime(2025, 8, 1)),
        ));
  }

  Future<void> seedBreathTrainingLogs() async {
    await (_db.delete(_db.breathTrainingLogs)..where((t) => t.id.like('breath_sample_%'))).go();

    var currentDate = DateTime(2025, 8, 10);
    final endDate = DateTime(2026, 1, 15);
    int logCount = 0;
    var baseHoldSeconds = 35;

    while (currentDate.isBefore(endDate)) {
      if (currentDate.weekday == DateTime.tuesday ||
          (currentDate.weekday == DateTime.friday && _random.nextBool())) {
        logCount++;
        final logId = 'breath_sample_$logCount';

        final sessionTypes = ['breathHold', 'pacedBreathing', 'patrickBreath'];
        final sessionType = sessionTypes[logCount % 3];

        int? totalHold;
        int? bestHold;
        int? bestExhale;
        int? rounds;
        int? duration;
        String? difficulty;

        switch (sessionType) {
          case 'breathHold':
            rounds = 4 + _random.nextInt(3);
            bestHold = baseHoldSeconds + _random.nextInt(15);
            totalHold = bestHold * rounds - _random.nextInt(20);
            difficulty = baseHoldSeconds > 50
                ? 'advanced'
                : (baseHoldSeconds > 40 ? 'intermediate' : 'beginner');
            break;
          case 'pacedBreathing':
            duration = 10 + _random.nextInt(10);
            difficulty = 'intermediate';
            break;
          case 'patrickBreath':
            rounds = 3;
            bestHold = baseHoldSeconds + 5 + _random.nextInt(10);
            bestExhale = 20 + _random.nextInt(15);
            totalHold = bestHold * rounds;
            break;
        }

        await _db.into(_db.breathTrainingLogs).insert(BreathTrainingLogsCompanion.insert(
              id: logId,
              sessionType: sessionType,
              totalHoldSeconds: Value(totalHold),
              bestHoldThisSession: Value(bestHold),
              bestExhaleSeconds: Value(bestExhale),
              rounds: Value(rounds),
              difficulty: Value(difficulty),
              durationMinutes: Value(duration),
              completedAt:
                  DateTime(currentDate.year, currentDate.month, currentDate.day, 7, 30),
            ));

        if (logCount % 5 == 0 && baseHoldSeconds < 70) {
          baseHoldSeconds += 2;
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  Future<void> seedSkillLevels() async {
    final skills = await _db.select(_db.skillLevels).get();

    for (final skill in skills) {
      int xp;
      int level;

      switch (skill.id) {
        case 'archery':
          xp = 125000;
          level = 45;
          break;
        case 'volume':
          xp = 85000;
          level = 38;
          break;
        case 'training':
          xp = 45000;
          level = 28;
          break;
        case 'breathing':
          xp = 22000;
          level = 20;
          break;
        default:
          xp = 10000;
          level = 15;
      }

      await (_db.update(_db.skillLevels)..where((t) => t.id.equals(skill.id))).write(
        SkillLevelsCompanion(
          currentXp: Value(xp),
          currentLevel: Value(level),
          lastLevelUpAt: Value(DateTime(2026, 1, 10)),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }

    await (_db.delete(_db.xpHistory)..where((t) => t.id.like('xp_sample_%'))).go();

    final xpSources = ['session', 'training', 'breath', 'milestone'];
    var currentDate = DateTime(2025, 8, 1);
    int xpCount = 0;

    while (currentDate.isBefore(DateTime(2026, 1, 18))) {
      if (_random.nextDouble() > 0.4) {
        xpCount++;
        final source = xpSources[_random.nextInt(xpSources.length)];
        final skillId = source == 'breath'
            ? 'breathing'
            : (source == 'training' ? 'training' : 'archery');
        final xpAmount = 50 + _random.nextInt(200);

        await _db.into(_db.xpHistory).insert(XpHistoryCompanion.insert(
              id: 'xp_sample_$xpCount',
              skillId: skillId,
              xpAmount: xpAmount,
              source: source,
              reason: Value(
                  '${source.substring(0, 1).toUpperCase()}${source.substring(1)} completed'),
              earnedAt: Value(currentDate),
            ));
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  Future<void> seedSightMarks() async {
    await (_db.delete(_db.sightMarks)..where((t) => t.id.like('sight_sample_%'))).go();

    final sightMarkData = [
      (18.0, '3.85', true),
      (25.0, '4.10', true),
      (30.0, '4.35', false),
      (40.0, '4.72', false),
      (50.0, '5.08', false),
      (60.0, '5.45', false),
      (70.0, '5.82', false),
      (90.0, '6.55', false),
    ];

    for (var i = 0; i < sightMarkData.length; i++) {
      final (distance, value, isIndoor) = sightMarkData[i];
      await _db.into(_db.sightMarks).insert(SightMarksCompanion.insert(
            id: 'sight_sample_$i',
            bowId: bowId,
            distance: distance,
            sightValue: value,
            unit: const Value('meters'),
            weatherData: Value(isIndoor
                ? '{"temperature":18,"sky":"none","wind":"none"}'
                : '{"temperature":15,"sky":"cloudy","wind":"light"}'),
            shotCount: Value(50 + _random.nextInt(100)),
            confidenceScore: Value(0.8 + _random.nextDouble() * 0.2),
            recordedAt: Value(DateTime(2025, 9, 1).add(Duration(days: i * 7))),
          ));
    }

    await _db.into(_db.sightMarkPreferencesTable).insertOnConflictUpdate(
          SightMarkPreferencesTableCompanion.insert(
            bowId: bowId,
            notationStyle: const Value('decimal'),
            decimalPlaces: const Value(2),
          ),
        );
  }

  Future<void> seedVolumeEntries() async {
    await (_db.delete(_db.volumeEntries)..where((t) => t.id.like('vol_sample_%'))).go();

    var currentDate = DateTime(2025, 8, 1);
    final endDate = DateTime(2026, 1, 18);
    int volCount = 0;

    while (currentDate.isBefore(endDate)) {
      final dayOfWeek = currentDate.weekday;

      if (dayOfWeek == DateTime.tuesday ||
          dayOfWeek == DateTime.thursday ||
          dayOfWeek == DateTime.saturday ||
          (dayOfWeek == DateTime.sunday && _random.nextDouble() > 0.5)) {
        volCount++;

        final isWeekend = dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday;
        final baseArrows = isWeekend ? 100 : 60;
        final arrowCount = baseArrows + _random.nextInt(50);

        String? title;
        if (dayOfWeek == DateTime.saturday && _random.nextDouble() > 0.85) {
          title = 'Competition';
        }

        await _db.into(_db.volumeEntries).insert(VolumeEntriesCompanion.insert(
              id: 'vol_sample_$volCount',
              date: currentDate,
              arrowCount: arrowCount,
              title: Value(title),
              notes: Value(title != null ? 'County shoot' : null),
            ));
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  Future<void> seedMilestones() async {
    await (_db.delete(_db.milestones)..where((t) => t.id.like('mile_sample_%'))).go();

    final milestoneData = [
      (DateTime(2025, 8, 15), 'Started using app', 'First session logged'),
      (DateTime(2025, 9, 5), 'First outdoor PB', 'WA720 70m: 635'),
      (DateTime(2025, 10, 12), 'Indoor season start', 'Switched to Portsmouth practice'),
      (DateTime(2025, 11, 8), 'Portsmouth PB', '556 at county shoot'),
      (DateTime(2025, 12, 3), 'New limbs fitted', 'Upgraded to Uukha VX1000'),
      (DateTime(2026, 1, 5), 'Best breath hold', '68 seconds personal best'),
    ];

    for (var i = 0; i < milestoneData.length; i++) {
      final (date, title, description) = milestoneData[i];
      await _db.into(_db.milestones).insert(MilestonesCompanion.insert(
            id: 'mile_sample_$i',
            date: date,
            title: title,
            description: Value(description),
            color: const Value('#FFD700'),
          ));
    }
  }
}
