import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'round_types_seed.dart';
import 'oly_training_seed.dart';
import '../utils/unique_id.dart';

part 'database.g.dart';

// ============================================================================
// TABLES
// ============================================================================

/// Round types (WA720, Portsmouth, etc.)
class RoundTypes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()(); // wa_outdoor, wa_indoor, agb_imperial, etc.
  IntColumn get distance => integer()(); // meters
  IntColumn get faceSize => integer()(); // cm
  IntColumn get arrowsPerEnd => integer()(); // 3 or 6
  IntColumn get totalEnds => integer()();
  IntColumn get maxScore => integer()();
  BoolColumn get isIndoor => boolean()();
  IntColumn get faceCount =>
      integer().withDefault(const Constant(1))(); // 1 or 3 for tri-spot
  TextColumn get scoringType =>
      text().withDefault(const Constant('10-zone'))(); // 10-zone or 5-zone

  @override
  Set<Column> get primaryKey => {id};
}

/// Scoring sessions
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get roundTypeId => text().references(RoundTypes, #id)();
  TextColumn get sessionType =>
      text().withDefault(const Constant('practice'))(); // practice, competition
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get totalScore => integer().withDefault(const Constant(0))();
  IntColumn get totalXs => integer().withDefault(const Constant(0))();
  TextColumn get bowId => text().nullable().references(Bows, #id)();
  TextColumn get quiverId => text().nullable().references(Quivers, #id)();
  BoolColumn get shaftTaggingEnabled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete for undo

  @override
  Set<Column> get primaryKey => {id};
}

/// Ends within a session
class Ends extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  IntColumn get endNumber => integer()();
  IntColumn get endScore => integer().withDefault(const Constant(0))();
  IntColumn get endXs => integer().withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('active'))(); // active, committed
  DateTimeColumn get committedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Arrows within an end
class Arrows extends Table {
  TextColumn get id => text()();
  TextColumn get endId => text().references(Ends, #id)();
  IntColumn get faceIndex =>
      integer().withDefault(const Constant(0))(); // 0 for single, 0-2 for tri-spot
  RealColumn get x => real()(); // normalized -1 to +1 from center
  RealColumn get y => real()(); // normalized -1 to +1 from center
  RealColumn get xMm => real().withDefault(const Constant(0))(); // mm from center (new precision)
  RealColumn get yMm => real().withDefault(const Constant(0))(); // mm from center (new precision)
  IntColumn get score => integer()();
  BoolColumn get isX => boolean().withDefault(const Constant(false))();
  IntColumn get sequence => integer()(); // order shot within end
  IntColumn get shaftNumber => integer().nullable()(); // optional shaft ID
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Imported scores (from CSV or manual entry)
class ImportedScores extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get roundName => text()();
  IntColumn get score => integer()();
  IntColumn get xCount => integer().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get sessionType =>
      text().withDefault(const Constant('competition'))();
  TextColumn get source =>
      text().withDefault(const Constant('manual'))(); // csv, manual, web
  DateTimeColumn get importedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// User preferences
class UserPreferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Bows (equipment)
class Bows extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get bowType => text()(); // recurve, compound
  TextColumn get settings => text().nullable()(); // JSON for tiller, brace height, etc.
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete for undo

  @override
  Set<Column> get primaryKey => {id};
}

/// Quivers (sets of arrows)
class Quivers extends Table {
  TextColumn get id => text()();
  TextColumn get bowId => text().nullable().references(Bows, #id)();
  TextColumn get name => text()();
  IntColumn get shaftCount => integer().withDefault(const Constant(12))();
  TextColumn get settings => text().nullable()(); // JSON for arrow specs
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete for undo

  @override
  Set<Column> get primaryKey => {id};
}

/// Shafts (individual arrows within a quiver)
class Shafts extends Table {
  TextColumn get id => text()();
  TextColumn get quiverId => text().references(Quivers, #id)();
  IntColumn get number => integer()(); // 1-12 (or up to shaftCount)
  TextColumn get diameter => text().nullable()(); // e.g., "1816", "2314"
  TextColumn get notes => text().nullable()(); // "Bent nock", "Replaced 2024-01"
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get retiredAt => dateTime().nullable()(); // soft delete

  @override
  Set<Column> get primaryKey => {id};
}

/// Daily volume tracking (arrow count per day)
class VolumeEntries extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()(); // Date of training (no time component used)
  IntColumn get arrowCount => integer()(); // Number of arrows shot that day
  TextColumn get title => text().nullable()(); // Optional title (competition name, event, etc.)
  TextColumn get notes => text().nullable()(); // Optional notes about the session
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Milestones for handicap graph timeline markers
class Milestones extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()(); // Date of milestone
  TextColumn get title => text()(); // Short title (e.g., "First Competition")
  TextColumn get description => text().nullable()(); // Optional longer description
  TextColumn get color => text().withDefault(const Constant('#FFD700'))(); // Hex color for the line
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Imported volume data batches (preserves original raw data)
class VolumeImports extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()(); // User-provided name or filename
  TextColumn get rawData => text()(); // Original CSV/text data as-is
  TextColumn get columnMapping => text().nullable()(); // JSON: {"date": 0, "arrows": 1, "notes": 2}
  IntColumn get rowCount => integer()(); // Number of data rows
  IntColumn get importedCount => integer().withDefault(const Constant(0))(); // Rows successfully imported
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// OLY BOW TRAINING SYSTEM
// ============================================================================

/// Exercise types for OLY bow training with intensity multipliers
class OlyExerciseTypes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()(); // "Static reversals", "Back end movement", etc.
  TextColumn get description => text().nullable()(); // Detailed instructions
  RealColumn get intensity => real().withDefault(const Constant(1.0))(); // Intensity multiplier
  TextColumn get category => text().withDefault(const Constant('static'))(); // static, movement, aimed, hold
  TextColumn get firstIntroducedAt => text().nullable()(); // Which session level introduces this
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// OLY session templates (S1.0 through S2.5)
class OlySessionTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get version => text()(); // "1.0", "1.5", "2.5", etc.
  TextColumn get name => text()(); // "Session 1.0", "Session 1.5", etc.
  TextColumn get focus => text().nullable()(); // "Intro", "Increased holds", "Aiming intro"
  IntColumn get durationMinutes => integer()(); // Approximate duration in minutes
  IntColumn get volumeLoad => integer()(); // Calculated volume load
  IntColumn get adjustedVolumeLoad => integer()(); // Volume load adjusted for intensity
  RealColumn get workRatio => real()(); // Work ratio (work time / rest time)
  RealColumn get adjustedWorkRatio => real()(); // Adjusted work ratio
  TextColumn get requirements => text().nullable()(); // "Minimum 3 weeks at previous level"
  TextColumn get equipment => text().withDefault(const Constant('Bow, elbow sling, stabilisers'))();
  TextColumn get notes => text().nullable()(); // Additional notes for the session
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Exercises within each OLY session template
class OlySessionExercises extends Table {
  TextColumn get id => text()();
  TextColumn get sessionTemplateId => text().references(OlySessionTemplates, #id)();
  TextColumn get exerciseTypeId => text().references(OlyExerciseTypes, #id)();
  IntColumn get exerciseOrder => integer()(); // Order within session
  IntColumn get reps => integer()(); // Number of repetitions
  IntColumn get workSeconds => integer()(); // Hold time per rep
  IntColumn get restSeconds => integer()(); // Rest time between reps
  TextColumn get details => text().nullable()(); // Specific instructions like "Push arm forward 3x5s"
  RealColumn get intensityOverride => real().nullable()(); // Override exercise type intensity if different

  @override
  Set<Column> get primaryKey => {id};
}

/// Session logs for OLY bow training (with feedback)
class OlyTrainingLogs extends Table {
  TextColumn get id => text()();
  TextColumn get sessionTemplateId => text().nullable()(); // Which OLY session was done
  TextColumn get sessionVersion => text()(); // Session version like "1.5"
  TextColumn get sessionName => text()(); // Name at time of session

  // Planned vs actual
  IntColumn get plannedDurationSeconds => integer()();
  IntColumn get actualDurationSeconds => integer()();
  IntColumn get plannedExercises => integer()();
  IntColumn get completedExercises => integer()();
  IntColumn get totalHoldSeconds => integer()();
  IntColumn get totalRestSeconds => integer()();

  // Feedback (1-10 scales)
  IntColumn get feedbackShaking => integer().nullable()(); // 1=none, 10=severe
  IntColumn get feedbackStructure => integer().nullable()(); // 1=perfect, 10=collapsing
  IntColumn get feedbackRest => integer().nullable()(); // 1=too much rest, 10=not enough

  // Progression suggestion
  TextColumn get progressionSuggestion => text().nullable()(); // "progress", "repeat", "regress"
  TextColumn get suggestedNextVersion => text().nullable()(); // e.g., "1.6"

  TextColumn get notes => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// User training progress tracking
class UserTrainingProgress extends Table {
  TextColumn get id => text()();
  TextColumn get currentLevel => text().withDefault(const Constant('1.0'))();
  IntColumn get sessionsAtCurrentLevel => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSessionAt => dateTime().nullable()();
  TextColumn get lastSessionVersion => text().nullable()();
  IntColumn get totalSessionsCompleted => integer().withDefault(const Constant(0))();
  BoolColumn get hasCompletedAssessment => boolean().withDefault(const Constant(false))();
  IntColumn get assessmentMaxHoldSeconds => integer().nullable()();
  DateTimeColumn get assessmentDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// BREATH TRAINING SYSTEM
// ============================================================================

/// Breath training session logs
class BreathTrainingLogs extends Table {
  TextColumn get id => text()();
  TextColumn get sessionType => text()(); // 'breathHold', 'pacedBreathing', 'patrickBreath'
  IntColumn get totalHoldSeconds => integer().nullable()(); // For breath hold sessions
  IntColumn get bestHoldThisSession => integer().nullable()(); // Best single hold
  IntColumn get bestExhaleSeconds => integer().nullable()(); // For Patrick breath
  IntColumn get rounds => integer().nullable()(); // Number of rounds completed
  TextColumn get difficulty => text().nullable()(); // 'beginner', 'intermediate', 'advanced'
  IntColumn get durationMinutes => integer().nullable()(); // For paced breathing
  DateTimeColumn get completedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// DATABASE
// ============================================================================

@DriftDatabase(tables: [
  RoundTypes,
  Sessions,
  Ends,
  Arrows,
  ImportedScores,
  UserPreferences,
  Bows,
  Quivers,
  Shafts,
  VolumeEntries,
  // OLY Bow Training System
  OlyExerciseTypes,
  OlySessionTemplates,
  OlySessionExercises,
  OlyTrainingLogs,
  UserTrainingProgress,
  // Breath Training System
  BreathTrainingLogs,
  // Milestones for handicap graph
  Milestones,
  // Volume imports for raw data preservation
  VolumeImports,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Constructor for testing with custom executor
  AppDatabase.withExecutor(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedRoundTypes();
        await _seedOlyTrainingData();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1) {
          // Add new equipment tables
          await m.createTable(bows);
          await m.createTable(quivers);
          await m.createTable(shafts);

          // Add new columns to sessions
          await m.addColumn(sessions, sessions.bowId);
          await m.addColumn(sessions, sessions.quiverId);
          await m.addColumn(sessions, sessions.shaftTaggingEnabled);
        }
        if (from <= 2) {
          // Add volume tracking table
          await m.createTable(volumeEntries);
        }
        if (from <= 3) {
          // Add OLY bow training tables
          await m.createTable(olyExerciseTypes);
          await m.createTable(olySessionTemplates);
          await m.createTable(olySessionExercises);
          await m.createTable(olyTrainingLogs);
          await m.createTable(userTrainingProgress);
          await _seedOlyTrainingData();
        }
        if (from <= 4) {
          // Add title column to volume entries
          await m.addColumn(volumeEntries, volumeEntries.title);
        }
        if (from <= 5) {
          // Add scoring type column to round types (10-zone default, 5-zone for imperial)
          await m.addColumn(roundTypes, roundTypes.scoringType);
          // Update existing imperial rounds to use 5-zone scoring
          await customStatement('''
            UPDATE round_types
            SET scoring_type = '5-zone'
            WHERE category = 'agb_imperial'
          ''');
        }
        if (from <= 6) {
          // Add milestones table for handicap graph
          await m.createTable(milestones);
        }
        if (from <= 7) {
          // Add volume imports table for raw data preservation
          await m.createTable(volumeImports);
        }
        if (from <= 8) {
          // Add arrow specifications to quivers
          await m.addColumn(quivers, quivers.settings);
        }
        if (from <= 9) {
          // Add breath training logs table
          await m.createTable(breathTrainingLogs);
        }
        if (from <= 10) {
          // Add soft delete columns for undo functionality
          await m.addColumn(sessions, sessions.deletedAt);
          await m.addColumn(bows, bows.deletedAt);
          await m.addColumn(quivers, quivers.deletedAt);
        }
      },
    );
  }

  /// Seed all standard round types (WA, AGB, NFAA)
  Future<void> _seedRoundTypes() async {
    final allRounds = getAllRoundTypesSeed();
    for (final rt in allRounds) {
      await into(roundTypes).insert(rt, mode: InsertMode.insertOrIgnore);
    }
  }

  // ===========================================================================
  // ROUND TYPES
  // ===========================================================================

  Future<List<RoundType>> getAllRoundTypes() => select(roundTypes).get();

  Future<RoundType?> getRoundType(String id) =>
      (select(roundTypes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<RoundType>> getRoundTypesByCategory(String category) =>
      (select(roundTypes)..where((t) => t.category.equals(category))).get();

  // ===========================================================================
  // SESSIONS
  // ===========================================================================

  Future<List<Session>> getAllSessions() =>
      (select(sessions)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .get();

  Future<List<Session>> getCompletedSessions() => (select(sessions)
        ..where((t) => t.completedAt.isNotNull() & t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
      .get();

  Future<List<Session>> getSessionsByDateRange(DateTime start, DateTime end) =>
      (select(sessions)
            ..where((t) =>
                t.startedAt.isBiggerOrEqualValue(start) &
                t.startedAt.isSmallerOrEqualValue(end) &
                t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .get();

  Future<Session?> getSession(String id) =>
      (select(sessions)
            ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .getSingleOrNull();

  Future<Session?> getIncompleteSession() =>
      (select(sessions)
            ..where((t) => t.completedAt.isNull() & t.deletedAt.isNull()))
          .getSingleOrNull();

  Future<int> insertSession(SessionsCompanion session) =>
      into(sessions).insert(session);

  Future<bool> updateSession(SessionsCompanion session) =>
      update(sessions).replace(session);

  Future<int> completeSession(String sessionId, int totalScore, int totalXs) =>
      (update(sessions)..where((t) => t.id.equals(sessionId))).write(
        SessionsCompanion(
          completedAt: Value(DateTime.now()),
          totalScore: Value(totalScore),
          totalXs: Value(totalXs),
        ),
      );

  /// Soft delete session (for undo support)
  Future<int> softDeleteSession(String sessionId) =>
      (update(sessions)..where((t) => t.id.equals(sessionId)))
          .write(SessionsCompanion(deletedAt: Value(DateTime.now())));

  /// Restore soft-deleted session (undo)
  Future<int> restoreSession(String sessionId) =>
      (update(sessions)..where((t) => t.id.equals(sessionId)))
          .write(const SessionsCompanion(deletedAt: Value(null)));

  /// Permanently delete session (after undo window expires)
  Future<int> deleteSession(String sessionId) async {
    return transaction(() async {
      // Get end IDs for batch delete
      final sessionEnds = await getEndsForSession(sessionId);
      final endIds = sessionEnds.map((e) => e.id).toList();

      // Batch delete all arrows for all ends
      if (endIds.isNotEmpty) {
        await (delete(arrows)..where((t) => t.endId.isIn(endIds))).go();
      }
      // Delete ends
      await (delete(ends)..where((t) => t.sessionId.equals(sessionId))).go();
      // Delete session
      return (delete(sessions)..where((t) => t.id.equals(sessionId))).go();
    });
  }

  /// Purge soft-deleted sessions older than the given timestamp
  Future<int> purgeSoftDeletedSessions(DateTime before) async {
    final toDelete = await (select(sessions)
          ..where((t) =>
              t.deletedAt.isNotNull() &
              t.deletedAt.isSmallerThanValue(before)))
        .get();

    int count = 0;
    for (final session in toDelete) {
      await deleteSession(session.id);
      count++;
    }
    return count;
  }

  // ===========================================================================
  // ENDS
  // ===========================================================================

  Future<List<End>> getEndsForSession(String sessionId) => (select(ends)
        ..where((t) => t.sessionId.equals(sessionId))
        ..orderBy([(t) => OrderingTerm.asc(t.endNumber)]))
      .get();

  Future<End?> getEnd(String id) =>
      (select(ends)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<End?> getCurrentEnd(String sessionId) => (select(ends)
        ..where((t) => t.sessionId.equals(sessionId) & t.status.equals('active'))
        ..limit(1))
      .getSingleOrNull();

  Future<int> insertEnd(EndsCompanion end) => into(ends).insert(end);

  Future<int> updateEndScore(String endId, int score, int xs) =>
      (update(ends)..where((t) => t.id.equals(endId))).write(
        EndsCompanion(
          endScore: Value(score),
          endXs: Value(xs),
        ),
      );

  Future<int> commitEnd(String endId, int score, int xs) =>
      (update(ends)..where((t) => t.id.equals(endId))).write(
        EndsCompanion(
          status: const Value('committed'),
          endScore: Value(score),
          endXs: Value(xs),
          committedAt: Value(DateTime.now()),
        ),
      );

  // ===========================================================================
  // ARROWS
  // ===========================================================================

  Future<List<Arrow>> getArrowsForEnd(String endId) => (select(arrows)
        ..where((t) => t.endId.equals(endId))
        ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
      .get();

  Future<List<Arrow>> getArrowsForSession(String sessionId) async {
    final sessionEnds = await getEndsForSession(sessionId);
    final endIds = sessionEnds.map((e) => e.id).toList();
    if (endIds.isEmpty) return [];
    return (select(arrows)
          ..where((t) => t.endId.isIn(endIds))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<int> insertArrow(ArrowsCompanion arrow) => into(arrows).insert(arrow);

  Future<int> deleteArrow(String arrowId) =>
      (delete(arrows)..where((t) => t.id.equals(arrowId))).go();

  Future<int> deleteLastArrowInEnd(String endId) async {
    final endArrows = await getArrowsForEnd(endId);
    if (endArrows.isEmpty) return 0;
    final lastArrow = endArrows.last;
    return deleteArrow(lastArrow.id);
  }

  Future<int> updateArrow(String arrowId, ArrowsCompanion updates) =>
      (update(arrows)..where((t) => t.id.equals(arrowId)))
          .write(updates);

  Future<int> deleteArrowsForSession(String sessionId) async {
    final sessionEnds = await getEndsForSession(sessionId);
    final endIds = sessionEnds.map((e) => e.id).toList();
    if (endIds.isEmpty) return 0;
    return (delete(arrows)..where((t) => t.endId.isIn(endIds))).go();
  }

  // ===========================================================================
  // IMPORTED SCORES
  // ===========================================================================

  Future<List<ImportedScore>> getAllImportedScores() => (select(importedScores)
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .get();

  Future<int> insertImportedScore(ImportedScoresCompanion score) =>
      into(importedScores).insert(score, mode: InsertMode.insertOrIgnore);

  Future<int> deleteImportedScore(String id) =>
      (delete(importedScores)..where((t) => t.id.equals(id))).go();

  /// Check for duplicate by date and score
  Future<bool> isDuplicateScore(DateTime date, int score) async {
    final existing = await (select(importedScores)
          ..where((t) =>
              t.date.equals(date) &
              t.score.equals(score)))
        .getSingleOrNull();
    return existing != null;
  }

  /// Check for duplicate by date, score, and round name
  Future<bool> isDuplicateScoreWithRound(DateTime date, int score, String roundName) async {
    final existing = await (select(importedScores)
          ..where((t) =>
              t.date.equals(date) &
              t.score.equals(score) &
              t.roundName.equals(roundName)))
        .getSingleOrNull();
    return existing != null;
  }

  // ===========================================================================
  // USER PREFERENCES
  // ===========================================================================

  Future<String?> getPreference(String key) async {
    final pref =
        await (select(userPreferences)..where((t) => t.key.equals(key)))
            .getSingleOrNull();
    return pref?.value;
  }

  Future<void> setPreference(String key, String value) =>
      into(userPreferences).insertOnConflictUpdate(
        UserPreferencesCompanion.insert(key: key, value: value),
      );

  Future<bool> getBoolPreference(String key, {bool defaultValue = false}) async {
    final value = await getPreference(key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  Future<void> setBoolPreference(String key, bool value) =>
      setPreference(key, value.toString());

  // ===========================================================================
  // BOWS
  // ===========================================================================

  Future<List<Bow>> getAllBows() =>
      (select(bows)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<Bow?> getBow(String id) =>
      (select(bows)
            ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .getSingleOrNull();

  Future<Bow?> getDefaultBow() =>
      (select(bows)
            ..where((t) => t.isDefault.equals(true) & t.deletedAt.isNull()))
          .getSingleOrNull();

  Future<int> insertBow(BowsCompanion bow) => into(bows).insert(bow);

  Future<bool> updateBow(BowsCompanion bow) => update(bows).replace(bow);

  Future<int> setDefaultBow(String bowId) async {
    // Clear all defaults
    await (update(bows)).write(const BowsCompanion(isDefault: Value(false)));
    // Set new default
    return (update(bows)..where((t) => t.id.equals(bowId)))
        .write(const BowsCompanion(isDefault: Value(true)));
  }

  /// Soft delete bow (for undo support)
  Future<int> softDeleteBow(String bowId) =>
      (update(bows)..where((t) => t.id.equals(bowId)))
          .write(BowsCompanion(deletedAt: Value(DateTime.now())));

  /// Restore soft-deleted bow (undo)
  Future<int> restoreBow(String bowId) =>
      (update(bows)..where((t) => t.id.equals(bowId)))
          .write(const BowsCompanion(deletedAt: Value(null)));

  /// Permanently delete bow
  Future<int> deleteBow(String bowId) =>
      (delete(bows)..where((t) => t.id.equals(bowId))).go();

  /// Purge soft-deleted bows older than the given timestamp
  Future<int> purgeSoftDeletedBows(DateTime before) async {
    final toDelete = await (select(bows)
          ..where((t) =>
              t.deletedAt.isNotNull() &
              t.deletedAt.isSmallerThanValue(before)))
        .get();

    int count = 0;
    for (final bow in toDelete) {
      await deleteBow(bow.id);
      count++;
    }
    return count;
  }

  // ===========================================================================
  // QUIVERS
  // ===========================================================================

  Future<List<Quiver>> getAllQuivers() =>
      (select(quivers)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<Quiver>> getQuiversForBow(String bowId) =>
      (select(quivers)
            ..where((t) => t.bowId.equals(bowId) & t.deletedAt.isNull()))
          .get();

  Future<Quiver?> getQuiver(String id) =>
      (select(quivers)
            ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .getSingleOrNull();

  Future<Quiver?> getDefaultQuiver() =>
      (select(quivers)
            ..where((t) => t.isDefault.equals(true) & t.deletedAt.isNull()))
          .getSingleOrNull();

  Future<int> insertQuiver(QuiversCompanion quiver) =>
      into(quivers).insert(quiver);

  Future<bool> updateQuiver(QuiversCompanion quiver) =>
      update(quivers).replace(quiver);

  Future<int> setDefaultQuiver(String quiverId) async {
    await (update(quivers))
        .write(const QuiversCompanion(isDefault: Value(false)));
    return (update(quivers)..where((t) => t.id.equals(quiverId)))
        .write(const QuiversCompanion(isDefault: Value(true)));
  }

  /// Soft delete quiver (for undo support)
  Future<int> softDeleteQuiver(String quiverId) =>
      (update(quivers)..where((t) => t.id.equals(quiverId)))
          .write(QuiversCompanion(deletedAt: Value(DateTime.now())));

  /// Restore soft-deleted quiver (undo)
  Future<int> restoreQuiver(String quiverId) =>
      (update(quivers)..where((t) => t.id.equals(quiverId)))
          .write(const QuiversCompanion(deletedAt: Value(null)));

  /// Permanently delete quiver
  Future<int> deleteQuiver(String quiverId) =>
      (delete(quivers)..where((t) => t.id.equals(quiverId))).go();

  /// Purge soft-deleted quivers older than the given timestamp
  Future<int> purgeSoftDeletedQuivers(DateTime before) async {
    final toDelete = await (select(quivers)
          ..where((t) =>
              t.deletedAt.isNotNull() &
              t.deletedAt.isSmallerThanValue(before)))
        .get();

    int count = 0;
    for (final quiver in toDelete) {
      await deleteQuiver(quiver.id);
      count++;
    }
    return count;
  }

  // ===========================================================================
  // SHAFTS
  // ===========================================================================

  Future<List<Shaft>> getShaftsForQuiver(String quiverId) => (select(shafts)
        ..where((t) => t.quiverId.equals(quiverId) & t.retiredAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.number)]))
      .get();

  Future<List<Shaft>> getAllShaftsForQuiver(String quiverId) => (select(shafts)
        ..where((t) => t.quiverId.equals(quiverId))
        ..orderBy([(t) => OrderingTerm.asc(t.number)]))
      .get();

  Future<Shaft?> getShaft(String id) =>
      (select(shafts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertShaft(ShaftsCompanion shaft) => into(shafts).insert(shaft);

  Future<bool> updateShaft(ShaftsCompanion shaft) =>
      update(shafts).replace(shaft);

  Future<int> retireShaft(String shaftId) =>
      (update(shafts)..where((t) => t.id.equals(shaftId)))
          .write(ShaftsCompanion(retiredAt: Value(DateTime.now())));

  Future<int> unretireShaft(String shaftId) =>
      (update(shafts)..where((t) => t.id.equals(shaftId)))
          .write(const ShaftsCompanion(retiredAt: Value(null)));

  // ===========================================================================
  // VOLUME ENTRIES
  // ===========================================================================

  Future<List<VolumeEntry>> getAllVolumeEntries() => (select(volumeEntries)
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .get();

  Future<List<VolumeEntry>> getVolumeEntriesInRange(
      DateTime start, DateTime end) =>
      (select(volumeEntries)
            ..where((t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerOrEqualValue(end))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .get();

  Future<VolumeEntry?> getVolumeEntryForDate(DateTime date) async {
    // Normalize to start of day
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return (select(volumeEntries)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(dayStart) &
              t.date.isSmallerThanValue(dayEnd))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> insertVolumeEntry(VolumeEntriesCompanion entry) =>
      into(volumeEntries).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateVolumeEntry(VolumeEntriesCompanion entry) =>
      update(volumeEntries).replace(entry);

  Future<int> deleteVolumeEntry(String id) =>
      (delete(volumeEntries)..where((t) => t.id.equals(id))).go();

  /// Upsert volume entry for a specific date
  Future<void> setVolumeForDate(DateTime date, int arrowCount, {String? title, String? notes}) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final existing = await getVolumeEntryForDate(dayStart);

    if (existing != null) {
      await updateVolumeEntry(
        VolumeEntriesCompanion(
          id: Value(existing.id),
          date: Value(dayStart),
          arrowCount: Value(arrowCount),
          title: Value(title),
          notes: Value(notes),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await insertVolumeEntry(
        VolumeEntriesCompanion.insert(
          id: UniqueId.generate(),
          date: dayStart,
          arrowCount: arrowCount,
          title: Value(title),
          notes: Value(notes),
        ),
      );
    }
  }

  /// Check for duplicate volume entry by date
  Future<bool> isDuplicateVolumeEntry(DateTime date) async {
    final existing = await getVolumeEntryForDate(date);
    return existing != null;
  }

  // ===========================================================================
  // OLY BOW TRAINING - EXERCISE TYPES
  // ===========================================================================

  Future<List<OlyExerciseType>> getAllOlyExerciseTypes() =>
      (select(olyExerciseTypes)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  Future<OlyExerciseType?> getOlyExerciseType(String id) =>
      (select(olyExerciseTypes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertOlyExerciseType(OlyExerciseTypesCompanion exerciseType) =>
      into(olyExerciseTypes).insert(exerciseType, mode: InsertMode.insertOrIgnore);

  // ===========================================================================
  // OLY BOW TRAINING - SESSION TEMPLATES
  // ===========================================================================

  Future<List<OlySessionTemplate>> getAllOlySessionTemplates() =>
      (select(olySessionTemplates)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  Future<OlySessionTemplate?> getOlySessionTemplate(String id) =>
      (select(olySessionTemplates)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<OlySessionTemplate?> getOlySessionTemplateByVersion(String version) =>
      (select(olySessionTemplates)..where((t) => t.version.equals(version))).getSingleOrNull();

  Future<int> insertOlySessionTemplate(OlySessionTemplatesCompanion template) =>
      into(olySessionTemplates).insert(template, mode: InsertMode.insertOrIgnore);

  // ===========================================================================
  // OLY BOW TRAINING - SESSION EXERCISES
  // ===========================================================================

  Future<List<OlySessionExercise>> getOlySessionExercises(String sessionTemplateId) =>
      (select(olySessionExercises)
            ..where((t) => t.sessionTemplateId.equals(sessionTemplateId))
            ..orderBy([(t) => OrderingTerm.asc(t.exerciseOrder)]))
          .get();

  Future<int> insertOlySessionExercise(OlySessionExercisesCompanion exercise) =>
      into(olySessionExercises).insert(exercise, mode: InsertMode.insertOrIgnore);

  // ===========================================================================
  // OLY BOW TRAINING - TRAINING LOGS
  // ===========================================================================

  Future<List<OlyTrainingLog>> getAllOlyTrainingLogs() =>
      (select(olyTrainingLogs)..orderBy([(t) => OrderingTerm.desc(t.completedAt)])).get();

  Future<List<OlyTrainingLog>> getRecentOlyTrainingLogs({int limit = 10}) =>
      (select(olyTrainingLogs)
            ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
            ..limit(limit))
          .get();

  Future<OlyTrainingLog?> getOlyTrainingLog(String id) =>
      (select(olyTrainingLogs)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertOlyTrainingLog(OlyTrainingLogsCompanion log) =>
      into(olyTrainingLogs).insert(log);

  Future<bool> updateOlyTrainingLog(OlyTrainingLogsCompanion log) =>
      update(olyTrainingLogs).replace(log);

  // ===========================================================================
  // OLY BOW TRAINING - USER PROGRESS
  // ===========================================================================

  Future<UserTrainingProgressData?> getUserTrainingProgress() =>
      (select(userTrainingProgress)..limit(1)).getSingleOrNull();

  Future<int> insertUserTrainingProgress(UserTrainingProgressCompanion progress) =>
      into(userTrainingProgress).insert(progress);

  Future<bool> updateUserTrainingProgress(UserTrainingProgressCompanion progress) =>
      update(userTrainingProgress).replace(progress);

  Future<void> ensureUserTrainingProgressExists() async {
    final existing = await getUserTrainingProgress();
    if (existing == null) {
      await insertUserTrainingProgress(
        UserTrainingProgressCompanion.insert(
          id: 'user_progress',
        ),
      );
    }
  }

  /// Update user level (e.g., after max hold test)
  Future<void> updateUserLevel(String level) async {
    final existing = await getUserTrainingProgress();
    if (existing == null) {
      await insertUserTrainingProgress(
        UserTrainingProgressCompanion.insert(
          id: 'user_progress',
          currentLevel: Value(level),
          hasCompletedAssessment: const Value(true),
          assessmentDate: Value(DateTime.now()),
        ),
      );
    } else {
      await updateUserTrainingProgress(
        UserTrainingProgressCompanion(
          id: Value(existing.id),
          currentLevel: Value(level),
          sessionsAtCurrentLevel: const Value(0),
          hasCompletedAssessment: const Value(true),
          assessmentDate: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> updateProgressAfterSession({
    required String completedVersion,
    required String? suggestedNextVersion,
    required String progressionSuggestion,
  }) async {
    final existing = await getUserTrainingProgress();
    if (existing == null) return;

    final newSessionsAtLevel = suggestedNextVersion == existing.currentLevel
        ? existing.sessionsAtCurrentLevel + 1
        : 1;

    await updateUserTrainingProgress(
      UserTrainingProgressCompanion(
        id: Value(existing.id),
        currentLevel: Value(suggestedNextVersion ?? existing.currentLevel),
        sessionsAtCurrentLevel: Value(newSessionsAtLevel),
        lastSessionAt: Value(DateTime.now()),
        lastSessionVersion: Value(completedVersion),
        totalSessionsCompleted: Value(existing.totalSessionsCompleted + 1),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ===========================================================================
  // OLY TRAINING DATA SEED
  // ===========================================================================

  /// Public method to ensure OLY training data exists (re-seeds if missing)
  Future<void> ensureOlyTrainingDataExists() async {
    final templates = await getAllOlySessionTemplates();
    if (templates.isEmpty) {
      await _seedOlyTrainingData();
    }
  }

  Future<void> _seedOlyTrainingData() async {
    await _seedOlyExerciseTypes();
    await _seedOlySessionTemplates();
  }

  Future<void> _seedOlyExerciseTypes() async {
    final exerciseTypes = getOlyExerciseTypesSeed();
    for (final et in exerciseTypes) {
      await insertOlyExerciseType(et);
    }
  }

  Future<void> _seedOlySessionTemplates() async {
    final sessions = getOlySessionTemplatesSeed();
    for (final session in sessions) {
      await insertOlySessionTemplate(session.template);
      for (final exercise in session.exercises) {
        await insertOlySessionExercise(exercise);
      }
    }
  }

  // ===========================================================================
  // MILESTONES
  // ===========================================================================

  Future<List<Milestone>> getAllMilestones() => (select(milestones)
        ..orderBy([(t) => OrderingTerm.asc(t.date)]))
      .get();

  Future<List<Milestone>> getMilestonesInRange(DateTime start, DateTime end) =>
      (select(milestones)
            ..where((t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerOrEqualValue(end))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .get();

  Future<Milestone?> getMilestone(String id) =>
      (select(milestones)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertMilestone(MilestonesCompanion milestone) =>
      into(milestones).insert(milestone);

  Future<bool> updateMilestone(MilestonesCompanion milestone) =>
      update(milestones).replace(milestone);

  Future<int> deleteMilestone(String id) =>
      (delete(milestones)..where((t) => t.id.equals(id))).go();

  // ===========================================================================
  // VOLUME IMPORTS (raw data preservation)
  // ===========================================================================

  Future<List<VolumeImport>> getAllVolumeImports() => (select(volumeImports)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  Future<VolumeImport?> getVolumeImport(String id) =>
      (select(volumeImports)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertVolumeImport(VolumeImportsCompanion import_) =>
      into(volumeImports).insert(import_);

  Future<bool> updateVolumeImport(VolumeImportsCompanion import_) =>
      update(volumeImports).replace(import_);

  Future<int> deleteVolumeImport(String id) =>
      (delete(volumeImports)..where((t) => t.id.equals(id))).go();

  Future<int> updateVolumeImportCount(String id, int importedCount) =>
      (update(volumeImports)..where((t) => t.id.equals(id))).write(
        VolumeImportsCompanion(importedCount: Value(importedCount)),
      );

  // ===========================================================================
  // BREATH TRAINING LOGS
  // ===========================================================================

  Future<List<BreathTrainingLog>> getAllBreathTrainingLogs() =>
      (select(breathTrainingLogs)..orderBy([(t) => OrderingTerm.desc(t.completedAt)])).get();

  Future<List<BreathTrainingLog>> getBreathTrainingLogsSince(DateTime since) =>
      (select(breathTrainingLogs)
            ..where((t) => t.completedAt.isBiggerOrEqualValue(since))
            ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
          .get();

  Future<BreathTrainingLog?> getBreathTrainingLog(String id) =>
      (select(breathTrainingLogs)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertBreathTrainingLog(BreathTrainingLogsCompanion log) =>
      into(breathTrainingLogs).insert(log);

  /// Get best breath hold in seconds since a date
  Future<int?> getBestBreathHold({DateTime? since}) async {
    final query = select(breathTrainingLogs)
      ..where((t) => t.sessionType.equals('breathHold'));
    if (since != null) {
      query.where((t) => t.completedAt.isBiggerOrEqualValue(since));
    }
    final logs = await query.get();
    if (logs.isEmpty) return null;

    int? best;
    for (final log in logs) {
      final hold = log.bestHoldThisSession;
      if (hold != null && (best == null || hold > best)) {
        best = hold;
      }
    }
    return best;
  }

  /// Get best exhale time in seconds since a date
  Future<int?> getBestExhaleTime({DateTime? since}) async {
    final query = select(breathTrainingLogs)
      ..where((t) => t.sessionType.equals('patrickBreath'));
    if (since != null) {
      query.where((t) => t.completedAt.isBiggerOrEqualValue(since));
    }
    final logs = await query.get();
    if (logs.isEmpty) return null;

    int? best;
    for (final log in logs) {
      final exhale = log.bestExhaleSeconds;
      if (exhale != null && (best == null || exhale > best)) {
        best = exhale;
      }
    }
    return best;
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'archery_super_app',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
