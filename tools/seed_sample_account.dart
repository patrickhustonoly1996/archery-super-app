// ignore_for_file: avoid_print
/// Seed script to create sample account data for "Testy McTestface"
/// Run with: dart run tools/seed_sample_account.dart
///
/// This creates a realistic dataset for a national-level intermediate archer
/// who has been using the app since August 2025.

import 'dart:io';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

// Import the database
import '../lib/db/database.dart';

final random = Random(42); // Fixed seed for reproducibility

// ============================================================================
// MAIN
// ============================================================================

Future<void> main() async {
  print('=== Seeding Sample Account: Testy McTestface ===\n');

  // Find the database file
  final dbPath = await _findDatabasePath();
  if (dbPath == null) {
    print('ERROR: Could not find database file.');
    print('Make sure you have run the app at least once to create the database.');
    exit(1);
  }

  print('Found database at: $dbPath\n');

  // Open the database
  final db = AppDatabase.withExecutor(
    NativeDatabase(File(dbPath)),
  );

  try {
    // Run all seed operations
    await _seedUserProfile(db);
    await _seedEquipment(db);
    await _seedScoringSessions(db);
    await _seedOlyTrainingLogs(db);
    await _seedBreathTrainingLogs(db);
    await _seedSkillLevels(db);
    await _seedSightMarks(db);
    await _seedVolumeEntries(db);
    await _seedMilestones(db);

    print('\n=== Sample account seeding complete! ===');
    print('User: Testy McTestface');
    print('Email: sample@samplemail.com');
    print('Password: Sample (set in Firebase Auth separately)');
  } finally {
    await db.close();
  }
}

Future<String?> _findDatabasePath() async {
  // Common locations for the database
  final possiblePaths = [
    // Windows local app data
    p.join(
      Platform.environment['LOCALAPPDATA'] ?? '',
      'archery_super_app',
      'app.db',
    ),
    // Alternative Windows path
    p.join(
      Platform.environment['APPDATA'] ?? '',
      'archery_super_app',
      'app.db',
    ),
    // Development path (current directory)
    'app.db',
    // macOS/Linux
    p.join(
      Platform.environment['HOME'] ?? '',
      '.local',
      'share',
      'archery_super_app',
      'app.db',
    ),
  ];

  for (final path in possiblePaths) {
    if (path.isNotEmpty && File(path).existsSync()) {
      return path;
    }
  }

  // Ask user for path
  print('Could not automatically find database. Enter path manually:');
  final input = stdin.readLineSync();
  if (input != null && File(input).existsSync()) {
    return input;
  }

  return null;
}

// ============================================================================
// USER PROFILE
// ============================================================================

const profileId = 'sample_user_001';

Future<void> _seedUserProfile(AppDatabase db) async {
  print('Creating user profile...');

  // Check if profile already exists
  final existing = await (db.select(db.userProfiles)
        ..where((t) => t.id.equals(profileId)))
      .getSingleOrNull();

  if (existing != null) {
    print('  Profile already exists, updating...');
    await (db.update(db.userProfiles)..where((t) => t.id.equals(profileId)))
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
    await db.into(db.userProfiles).insert(UserProfilesCompanion.insert(
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
  final fedId = 'fed_sample_001';
  final existingFed = await (db.select(db.federations)
        ..where((t) => t.id.equals(fedId)))
      .getSingleOrNull();

  if (existingFed == null) {
    await db.into(db.federations).insert(FederationsCompanion.insert(
          id: fedId,
          profileId: profileId,
          federationName: 'Archery GB',
          membershipNumber: const Value('AGB-2024-12345'),
          isPrimary: const Value(true),
          expiryDate: Value(DateTime(2026, 9, 30)),
        ));
  }

  print('  Done!');
}

// ============================================================================
// EQUIPMENT
// ============================================================================

const bowId = 'bow_sample_001';
const quiverId = 'quiver_sample_001';
const stabilizerId = 'stab_sample_001';
const tabId = 'tab_sample_001';
const stringId = 'string_sample_001';

Future<void> _seedEquipment(AppDatabase db) async {
  print('Creating equipment...');

  // Create bow
  final existingBow = await (db.select(db.bows)..where((t) => t.id.equals(bowId))).getSingleOrNull();
  if (existingBow == null) {
    await db.into(db.bows).insert(BowsCompanion.insert(
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
  final existingQuiver =
      await (db.select(db.quivers)..where((t) => t.id.equals(quiverId))).getSingleOrNull();
  if (existingQuiver == null) {
    await db.into(db.quivers).insert(QuiversCompanion.insert(
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
      await db.into(db.shafts).insert(ShaftsCompanion.insert(
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
  final existingStab =
      await (db.select(db.stabilizers)..where((t) => t.id.equals(stabilizerId))).getSingleOrNull();
  if (existingStab == null) {
    await db.into(db.stabilizers).insert(StabilizersCompanion.insert(
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
  final existingTab =
      await (db.select(db.fingerTabs)..where((t) => t.id.equals(tabId))).getSingleOrNull();
  if (existingTab == null) {
    await db.into(db.fingerTabs).insert(FingerTabsCompanion.insert(
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
  final existingString =
      await (db.select(db.bowStrings)..where((t) => t.id.equals(stringId))).getSingleOrNull();
  if (existingString == null) {
    await db.into(db.bowStrings).insert(BowStringsCompanion.insert(
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

  print('  Done!');
}

// ============================================================================
// SCORING SESSIONS
// ============================================================================

Future<void> _seedScoringSessions(AppDatabase db) async {
  print('Creating scoring sessions (6-9 months of data)...');

  // Clear existing sample sessions
  await (db.delete(db.arrows)..where((t) => t.endId.like('end_sample_%'))).go();
  await (db.delete(db.ends)..where((t) => t.sessionId.like('session_sample_%'))).go();
  await (db.delete(db.sessions)..where((t) => t.id.like('session_sample_%'))).go();

  int sessionCount = 0;

  // August 2025 - January 2026 (6 months)
  // Outdoor season: Aug-Sep 2025
  // Indoor season: Oct 2025 - Jan 2026

  // Start date: August 1, 2025
  var currentDate = DateTime(2025, 8, 1);
  final endDate = DateTime(2026, 1, 18);

  // Track progression - start with higher handicap (worse), improve over time
  double outdoorHandicap = 35.0; // Starting outdoor handicap
  double indoorHandicap = 28.0; // Starting indoor handicap

  while (currentDate.isBefore(endDate)) {
    final isIndoorSeason = currentDate.month >= 10 || currentDate.month <= 3;
    final dayOfWeek = currentDate.weekday;

    // Practice 3-4 times per week
    final shouldPractice = dayOfWeek == DateTime.tuesday ||
        dayOfWeek == DateTime.thursday ||
        dayOfWeek == DateTime.saturday ||
        (dayOfWeek == DateTime.sunday && random.nextDouble() > 0.5);

    // Competition roughly every 2-3 weeks
    final isCompetitionDay = (dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday) &&
        random.nextDouble() > 0.85;

    if (shouldPractice || isCompetitionDay) {
      sessionCount++;
      final sessionId = 'session_sample_$sessionCount';
      final sessionType = isCompetitionDay ? 'competition' : 'practice';

      // Choose round type based on season and session type
      String roundTypeId;
      int maxScore;
      int arrowsPerEnd;
      int totalEnds;

      if (isIndoorSeason) {
        if (isCompetitionDay) {
          // Competition: Portsmouth or WA 18m
          roundTypeId = random.nextBool() ? 'portsmouth' : 'wa_18_60';
        } else {
          // Practice: shorter rounds or practice round
          roundTypeId = random.nextDouble() > 0.7
              ? 'practice_indoor_3'
              : (random.nextBool() ? 'portsmouth' : 'wa_18_30');
        }
      } else {
        // Outdoor season
        if (isCompetitionDay) {
          // Competition: WA 720 70m or metric
          roundTypeId = random.nextDouble() > 0.3 ? 'wa_720_70m' : 'metric_2';
        } else {
          // Practice
          roundTypeId = random.nextDouble() > 0.6
              ? 'practice_outdoor_6'
              : (random.nextBool() ? 'wa_720_70m' : 'half_metric_70m');
        }
      }

      // Get round details
      final roundType = await (db.select(db.roundTypes)
            ..where((t) => t.id.equals(roundTypeId)))
          .getSingle();

      maxScore = roundType.maxScore;
      arrowsPerEnd = roundType.arrowsPerEnd;
      totalEnds = roundType.totalEnds;

      // For practice rounds, limit ends
      if (roundTypeId.startsWith('practice_')) {
        totalEnds = 10 + random.nextInt(15); // 10-24 ends
        maxScore = totalEnds * arrowsPerEnd * 10;
      }

      // Calculate expected score based on handicap
      final handicap = roundType.isIndoor ? indoorHandicap : outdoorHandicap;
      final targetScore = _calculateScoreFromHandicap(handicap, maxScore);

      // Add some variance
      final variance = (maxScore * 0.03 * (random.nextDouble() - 0.5)).round();
      final actualScore = (targetScore + variance).clamp(0, maxScore);

      // Create session
      final startTime = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        isIndoorSeason ? 19 : 10, // Indoor evening, outdoor morning
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
          if (arrowScore == 10 && random.nextDouble() > 0.6) {
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

      await db.into(db.sessions).insert(SessionsCompanion.insert(
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
        await db.into(db.ends).insert(EndsCompanion.insert(
              id: endId,
              sessionId: sessionId,
              endNumber: e + 1,
              endScore: Value(endScores[e]),
              endXs: Value(endXCounts[e]),
              status: const Value('committed'),
              committedAt: Value(startTime.add(Duration(minutes: 4 * (e + 1)))),
              createdAt: Value(startTime.add(Duration(minutes: 4 * e))),
            ));

        // Create arrows with positions
        var arrowsForEnd = <int>[];
        var endTotal = endScores[e];

        // Distribute score among arrows
        for (int a = 0; a < arrowsPerEnd - 1; a++) {
          final avgRemaining = endTotal / (arrowsPerEnd - a);
          final arrowScore = _generateArrowScore(avgRemaining, handicap).clamp(0, 10);
          arrowsForEnd.add(arrowScore);
          endTotal -= arrowScore;
        }
        arrowsForEnd.add(endTotal.clamp(0, 10));
        arrowsForEnd.shuffle(random);

        for (int a = 0; a < arrowsPerEnd; a++) {
          final arrowId = 'arrow_sample_${sessionCount}_${e}_$a';
          final score = arrowsForEnd[a];
          final isX = score == 10 && a < endXCounts[e];

          // Generate position based on score
          final position = _generateArrowPosition(score, roundType.faceSize);

          await db.into(db.arrows).insert(ArrowsCompanion.insert(
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

      // Improve handicap over time (slow progression)
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

  print('  Created $sessionCount sessions with ends and arrows');
}

int _calculateScoreFromHandicap(double handicap, int maxScore) {
  // Rough conversion: lower handicap = higher percentage of max score
  // Handicap 0 = ~100%, Handicap 50 = ~70%
  final percentage = 1.0 - (handicap / 150);
  return (maxScore * percentage).round();
}

int _generateArrowScore(double targetAvg, double handicap) {
  // Generate a score that tends toward the target average with variance
  final base = targetAvg.round();
  final variance = (3 - handicap / 20).clamp(1, 3).toInt();
  final delta = random.nextInt(variance * 2 + 1) - variance;
  return (base + delta).clamp(0, 10);
}

(double, double) _generateArrowPosition(int score, int faceSize) {
  // Generate normalized position (-1 to 1) based on score
  // Higher score = closer to center
  final maxRadius = 1.0 - (score / 12.0); // 10 = 0.17, 0 = 1.0
  final radius = maxRadius * (0.5 + random.nextDouble() * 0.5);
  final angle = random.nextDouble() * 2 * 3.14159;
  return (radius * cos(angle), radius * sin(angle));
}

// ============================================================================
// OLY TRAINING LOGS
// ============================================================================

Future<void> _seedOlyTrainingLogs(AppDatabase db) async {
  print('Creating OLY training logs...');

  // Clear existing
  await (db.delete(db.olyTrainingLogs)..where((t) => t.id.like('oly_sample_%'))).go();
  await (db.delete(db.userTrainingProgress)..where((t) => t.id.equals('progress_sample'))).go();

  // Get session templates
  final templates = await db.select(db.olySessionTemplates).get();
  if (templates.isEmpty) {
    print('  No OLY templates found, skipping...');
    return;
  }

  // Sort by version
  templates.sort((a, b) => a.version.compareTo(b.version));

  // Progress through sessions from August 2025
  var currentDate = DateTime(2025, 8, 5);
  final endDate = DateTime(2026, 1, 15);
  var currentTemplateIndex = 0;
  var sessionsAtLevel = 0;
  int logCount = 0;

  while (currentDate.isBefore(endDate) && currentTemplateIndex < templates.length) {
    // OLY sessions 2x per week
    if (currentDate.weekday == DateTime.monday || currentDate.weekday == DateTime.wednesday) {
      logCount++;
      final template = templates[currentTemplateIndex];
      final logId = 'oly_sample_$logCount';

      // Simulate feedback improving over sessions at each level
      final progressFactor = sessionsAtLevel / 6.0; // 6 sessions to master
      final shaking = (6 - progressFactor * 3).clamp(1, 10).round();
      final structure = (5 - progressFactor * 2).clamp(1, 10).round();
      final rest = (6 - progressFactor * 2).clamp(1, 10).round();

      final shouldProgress = sessionsAtLevel >= 4 && shaking <= 4 && structure <= 4;
      final suggestion = shouldProgress ? 'progress' : 'repeat';

      await db.into(db.olyTrainingLogs).insert(OlyTrainingLogsCompanion.insert(
            id: logId,
            sessionTemplateId: Value(template.id),
            sessionVersion: template.version,
            sessionName: template.name,
            plannedDurationSeconds: template.durationMinutes * 60,
            actualDurationSeconds: template.durationMinutes * 60 + random.nextInt(300) - 150,
            plannedExercises: 5,
            completedExercises: 5,
            totalHoldSeconds: template.durationMinutes * 30,
            totalRestSeconds: template.durationMinutes * 30,
            feedbackShaking: Value(shaking),
            feedbackStructure: Value(structure),
            feedbackRest: Value(rest),
            progressionSuggestion: Value(suggestion),
            suggestedNextVersion: Value(shouldProgress && currentTemplateIndex + 1 < templates.length
                ? templates[currentTemplateIndex + 1].version
                : template.version),
            startedAt: DateTime(currentDate.year, currentDate.month, currentDate.day, 18, 0),
            completedAt: DateTime(currentDate.year, currentDate.month, currentDate.day, 18, template.durationMinutes),
            notes: Value(sessionsAtLevel == 0 ? 'First session at this level' : null),
          ));

      sessionsAtLevel++;

      // Progress to next level after mastering current
      if (shouldProgress && currentTemplateIndex + 1 < templates.length) {
        currentTemplateIndex++;
        sessionsAtLevel = 0;
      }
    }

    currentDate = currentDate.add(const Duration(days: 1));
  }

  // Create progress record
  final currentTemplate = templates[currentTemplateIndex.clamp(0, templates.length - 1)];
  await db.into(db.userTrainingProgress).insert(UserTrainingProgressCompanion.insert(
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

  print('  Created $logCount OLY training logs, current level: ${currentTemplate.version}');
}

// ============================================================================
// BREATH TRAINING LOGS
// ============================================================================

Future<void> _seedBreathTrainingLogs(AppDatabase db) async {
  print('Creating breath training logs...');

  // Clear existing
  await (db.delete(db.breathTrainingLogs)..where((t) => t.id.like('breath_sample_%'))).go();

  var currentDate = DateTime(2025, 8, 10);
  final endDate = DateTime(2026, 1, 15);
  int logCount = 0;

  // Base hold time improves over time
  var baseHoldSeconds = 35;

  while (currentDate.isBefore(endDate)) {
    // Breath training 1-2x per week
    if (currentDate.weekday == DateTime.tuesday ||
        (currentDate.weekday == DateTime.friday && random.nextBool())) {
      logCount++;
      final logId = 'breath_sample_$logCount';

      // Mix of session types
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
          rounds = 4 + random.nextInt(3);
          bestHold = baseHoldSeconds + random.nextInt(15);
          totalHold = bestHold * rounds - random.nextInt(20);
          difficulty = baseHoldSeconds > 50 ? 'advanced' : (baseHoldSeconds > 40 ? 'intermediate' : 'beginner');
          break;
        case 'pacedBreathing':
          duration = 10 + random.nextInt(10);
          difficulty = 'intermediate';
          break;
        case 'patrickBreath':
          rounds = 3;
          bestHold = baseHoldSeconds + 5 + random.nextInt(10);
          bestExhale = 20 + random.nextInt(15);
          totalHold = bestHold * rounds;
          break;
      }

      await db.into(db.breathTrainingLogs).insert(BreathTrainingLogsCompanion.insert(
            id: logId,
            sessionType: sessionType,
            totalHoldSeconds: Value(totalHold),
            bestHoldThisSession: Value(bestHold),
            bestExhaleSeconds: Value(bestExhale),
            rounds: Value(rounds),
            difficulty: Value(difficulty),
            durationMinutes: Value(duration),
            completedAt: DateTime(currentDate.year, currentDate.month, currentDate.day, 7, 30),
          ));

      // Slow improvement
      if (logCount % 5 == 0 && baseHoldSeconds < 70) {
        baseHoldSeconds += 2;
      }
    }

    currentDate = currentDate.add(const Duration(days: 1));
  }

  print('  Created $logCount breath training logs');
}

// ============================================================================
// SKILL LEVELS
// ============================================================================

Future<void> _seedSkillLevels(AppDatabase db) async {
  print('Updating skill levels...');

  // Update existing skill levels with XP
  final skills = await db.select(db.skillLevels).get();

  for (final skill in skills) {
    int xp;
    int level;

    switch (skill.id) {
      case 'archery':
        xp = 125000; // ~Level 45
        level = 45;
        break;
      case 'volume':
        xp = 85000; // ~Level 38
        level = 38;
        break;
      case 'training':
        xp = 45000; // ~Level 28
        level = 28;
        break;
      case 'breathing':
        xp = 22000; // ~Level 20
        level = 20;
        break;
      default:
        xp = 10000;
        level = 15;
    }

    await (db.update(db.skillLevels)..where((t) => t.id.equals(skill.id))).write(
      SkillLevelsCompanion(
        currentXp: Value(xp),
        currentLevel: Value(level),
        lastLevelUpAt: Value(DateTime(2026, 1, 10)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Add some XP history entries
  await (db.delete(db.xpHistory)..where((t) => t.id.like('xp_sample_%'))).go();

  final xpSources = ['session', 'training', 'breath', 'milestone'];
  var currentDate = DateTime(2025, 8, 1);
  int xpCount = 0;

  while (currentDate.isBefore(DateTime(2026, 1, 18))) {
    if (random.nextDouble() > 0.4) {
      xpCount++;
      final source = xpSources[random.nextInt(xpSources.length)];
      final skillId = source == 'breath' ? 'breathing' : (source == 'training' ? 'training' : 'archery');
      final xpAmount = 50 + random.nextInt(200);

      await db.into(db.xpHistory).insert(XpHistoryCompanion.insert(
            id: 'xp_sample_$xpCount',
            skillId: skillId,
            xpAmount: xpAmount,
            source: source,
            reason: Value('${source.substring(0, 1).toUpperCase()}${source.substring(1)} completed'),
            earnedAt: Value(currentDate),
          ));
    }

    currentDate = currentDate.add(const Duration(days: 1));
  }

  print('  Updated skill levels and added $xpCount XP history entries');
}

// ============================================================================
// SIGHT MARKS
// ============================================================================

Future<void> _seedSightMarks(AppDatabase db) async {
  print('Creating sight marks...');

  // Clear existing sample sight marks
  await (db.delete(db.sightMarks)..where((t) => t.id.like('sight_sample_%'))).go();

  // Typical sight marks for a recurve at 38# with good tune
  final sightMarkData = [
    (18.0, '3.85', true), // 18m indoor
    (25.0, '4.10', true), // 25m
    (30.0, '4.35', false), // 30m
    (40.0, '4.72', false), // 40m
    (50.0, '5.08', false), // 50m
    (60.0, '5.45', false), // 60m
    (70.0, '5.82', false), // 70m
    (90.0, '6.55', false), // 90m
  ];

  for (var i = 0; i < sightMarkData.length; i++) {
    final (distance, value, isIndoor) = sightMarkData[i];
    await db.into(db.sightMarks).insert(SightMarksCompanion.insert(
          id: 'sight_sample_$i',
          bowId: bowId,
          distance: distance,
          sightValue: value,
          unit: const Value('meters'),
          weatherData: Value(isIndoor
              ? '{"temperature":18,"sky":"none","wind":"none"}'
              : '{"temperature":15,"sky":"cloudy","wind":"light"}'),
          shotCount: Value(50 + random.nextInt(100)),
          confidenceScore: Value(0.8 + random.nextDouble() * 0.2),
          recordedAt: Value(DateTime(2025, 9, 1).add(Duration(days: i * 7))),
        ));
  }

  // Add sight mark preferences
  await db.into(db.sightMarkPreferencesTable).insertOnConflictUpdate(
        SightMarkPreferencesTableCompanion.insert(
          bowId: bowId,
          notationStyle: const Value('decimal'),
          decimalPlaces: const Value(2),
        ),
      );

  print('  Created ${sightMarkData.length} sight marks');
}

// ============================================================================
// VOLUME ENTRIES
// ============================================================================

Future<void> _seedVolumeEntries(AppDatabase db) async {
  print('Creating volume entries...');

  // Clear existing
  await (db.delete(db.volumeEntries)..where((t) => t.id.like('vol_sample_%'))).go();

  var currentDate = DateTime(2025, 8, 1);
  final endDate = DateTime(2026, 1, 18);
  int volCount = 0;

  while (currentDate.isBefore(endDate)) {
    final dayOfWeek = currentDate.weekday;

    // Training days
    if (dayOfWeek == DateTime.tuesday ||
        dayOfWeek == DateTime.thursday ||
        dayOfWeek == DateTime.saturday ||
        (dayOfWeek == DateTime.sunday && random.nextDouble() > 0.5)) {
      volCount++;

      // More arrows on weekends
      final isWeekend = dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday;
      final baseArrows = isWeekend ? 100 : 60;
      final arrowCount = baseArrows + random.nextInt(50);

      String? title;
      if (dayOfWeek == DateTime.saturday && random.nextDouble() > 0.85) {
        title = 'Competition';
      }

      await db.into(db.volumeEntries).insert(VolumeEntriesCompanion.insert(
            id: 'vol_sample_$volCount',
            date: currentDate,
            arrowCount: arrowCount,
            title: Value(title),
            notes: Value(title != null ? 'County shoot' : null),
          ));
    }

    currentDate = currentDate.add(const Duration(days: 1));
  }

  print('  Created $volCount volume entries');
}

// ============================================================================
// MILESTONES
// ============================================================================

Future<void> _seedMilestones(AppDatabase db) async {
  print('Creating milestones...');

  // Clear existing
  await (db.delete(db.milestones)..where((t) => t.id.like('mile_sample_%'))).go();

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
    await db.into(db.milestones).insert(MilestonesCompanion.insert(
          id: 'mile_sample_$i',
          date: date,
          title: title,
          description: Value(description),
          color: const Value('#FFD700'),
        ));
  }

  print('  Created ${milestoneData.length} milestones');
}
