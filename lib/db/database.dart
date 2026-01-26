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

  /// Distance legs for multi-distance rounds (e.g., York: 100/80/60 yards)
  /// JSON array: [{"distance": 100, "unit": "yd", "arrowCount": 72}, ...]
  /// null for single-distance rounds
  TextColumn get distanceLegs => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Scoring sessions
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get roundTypeId => text().references(RoundTypes, #id)();
  TextColumn get sessionType =>
      text().withDefault(const Constant('practice'))(); // practice, competition
  TextColumn get title => text().nullable()(); // User-provided session title
  TextColumn get locationName => text().nullable()(); // Venue name (e.g., "Evesham Archery Club")
  TextColumn get location => text().nullable()(); // Legacy location field
  RealColumn get latitude => real().nullable()(); // GPS latitude
  RealColumn get longitude => real().nullable()(); // GPS longitude
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
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete for sync

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
  IntColumn get shaftNumber => integer().nullable()(); // Legacy: arrow number for display
  TextColumn get shaftId => text().nullable().references(Shafts, #id)(); // FK to Shafts table
  TextColumn get nockRotation => text().nullable()(); // Clock position: '12', '4', '8' etc.
  IntColumn get rating => integer().withDefault(const Constant(5))(); // Shot quality 1-5 stars (5=good, 3=exclude from analysis)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete for sync

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
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete for sync

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
  TextColumn get settings => text().nullable()(); // JSON for misc settings
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete for undo

  // Equipment details
  TextColumn get riserModel => text().nullable()();
  DateTimeColumn get riserPurchaseDate => dateTime().nullable()();
  TextColumn get limbModel => text().nullable()();
  DateTimeColumn get limbPurchaseDate => dateTime().nullable()();
  RealColumn get poundage => real().nullable()(); // Draw weight in lbs
  RealColumn get drawLength => real().nullable()(); // Draw length in inches

  // Tuning settings
  RealColumn get tillerTop => real().nullable()(); // mm
  RealColumn get tillerBottom => real().nullable()(); // mm
  RealColumn get braceHeight => real().nullable()(); // inches
  RealColumn get nockingPointHeight => real().nullable()(); // mm above square
  RealColumn get buttonPosition => real().nullable()(); // mm from riser
  TextColumn get buttonTension => text().nullable()(); // soft/medium/stiff or number
  RealColumn get clickerPosition => real().nullable()(); // mm

  // Sight geometry (for sight mark predictions)
  RealColumn get eyeToArrowDistance => real().nullable()(); // mm, vertical distance from eye to arrow at anchor

  @override
  Set<Column> get primaryKey => {id};
}

/// Finger tabs
class FingerTabs extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get make => text().nullable()(); // e.g., "AAE", "Fairweather", "Fivics"
  TextColumn get model => text().nullable()(); // e.g., "Elite", "Tab II"
  TextColumn get size => text().nullable()(); // e.g., "M", "L"
  TextColumn get plateType => text().nullable()(); // e.g., "Aluminium", "Brass", "Cordovan"
  TextColumn get fingerSpacer => text().nullable()(); // e.g., "Small", "Medium", "None"
  TextColumn get notes => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete

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
  IntColumn get spine => integer().nullable()(); // Static spine (e.g., 500, 600)
  RealColumn get lengthInches => real().nullable()(); // Arrow length in inches
  IntColumn get pointWeight => integer().nullable()(); // Point weight in grains
  TextColumn get fletchingType => text().nullable()(); // e.g., "vanes", "feathers", "spin wings"
  TextColumn get fletchingColor => text().nullable()(); // e.g., "blue", "red/white"
  TextColumn get nockColor => text().nullable()(); // e.g., "blue", "green"
  TextColumn get notes => text().nullable()(); // "Bent nock", "Replaced 2024-01"
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get retiredAt => dateTime().nullable()(); // soft delete

  // New detailed specs
  RealColumn get totalWeight => real().nullable()(); // Total weight in grains
  TextColumn get pointType => text().nullable()(); // break-off, glue-in, screw-in
  TextColumn get nockBrand => text().nullable()(); // e.g., "Beiter", "Easton"
  TextColumn get fletchingSize => text().nullable()(); // e.g., "1.75 inch", "2 inch"
  RealColumn get fletchingAngle => real().nullable()(); // Helical degrees
  BoolColumn get hasWrap => boolean().nullable()(); // Has arrow wrap
  TextColumn get wrapColor => text().nullable()(); // Wrap color/pattern
  DateTimeColumn get purchaseDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stabilizer setups (linked to a bow)
class Stabilizers extends Table {
  TextColumn get id => text()();
  TextColumn get bowId => text().references(Bows, #id)();
  TextColumn get name => text().nullable()(); // Optional name for this setup

  // Long rod
  TextColumn get longRodModel => text().nullable()();
  RealColumn get longRodLength => real().nullable()(); // inches
  RealColumn get longRodWeight => real().nullable()(); // oz
  DateTimeColumn get longRodPurchaseDate => dateTime().nullable()();

  // Left side rod
  TextColumn get leftSideRodModel => text().nullable()();
  RealColumn get leftSideRodLength => real().nullable()(); // inches
  RealColumn get leftSideRodWeight => real().nullable()(); // oz (rod weight)
  TextColumn get leftWeights => text().nullable()(); // e.g., "2x 1oz"
  RealColumn get leftAngleHorizontal => real().nullable()(); // degrees from center
  RealColumn get leftAngleVertical => real().nullable()(); // degrees down

  // Right side rod
  TextColumn get rightSideRodModel => text().nullable()();
  RealColumn get rightSideRodLength => real().nullable()(); // inches
  RealColumn get rightSideRodWeight => real().nullable()(); // oz (rod weight)
  TextColumn get rightWeights => text().nullable()(); // e.g., "2x 1oz"
  RealColumn get rightAngleHorizontal => real().nullable()(); // degrees from center
  RealColumn get rightAngleVertical => real().nullable()(); // degrees down

  // Legacy fields (kept for migration)
  TextColumn get sideRodModel => text().nullable()();
  RealColumn get sideRodLength => real().nullable()();
  RealColumn get sideRodWeight => real().nullable()();
  DateTimeColumn get sideRodPurchaseDate => dateTime().nullable()();

  // Extender
  RealColumn get extenderLength => real().nullable()(); // inches

  // V-bar
  TextColumn get vbarModel => text().nullable()();
  RealColumn get vbarAngleHorizontal => real().nullable()(); // legacy
  RealColumn get vbarAngleVertical => real().nullable()(); // legacy

  // Long rod weights
  TextColumn get longRodWeights => text().nullable()(); // e.g., "4x 1oz stacked"

  // Legacy
  TextColumn get weightArrangement => text().nullable()();

  // Setup photo for documentation
  TextColumn get setupPhotoPath => text().nullable()();

  // Dampers
  TextColumn get damperModel => text().nullable()();
  TextColumn get damperPositions => text().nullable()(); // e.g., "end of long, between weights"

  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Bow strings (linked to a bow)
class BowStrings extends Table {
  TextColumn get id => text()();
  TextColumn get bowId => text().references(Bows, #id)();
  TextColumn get name => text().nullable()(); // Optional name for this string

  TextColumn get material => text().nullable()(); // e.g., "8125G", "BCY-X", "FF Plus"
  IntColumn get strandCount => integer().nullable()();
  TextColumn get servingMaterial => text().nullable()(); // e.g., "Angel Majesty"
  RealColumn get stringLength => real().nullable()(); // inches (AMO length)
  TextColumn get color => text().nullable()(); // String color

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  DateTimeColumn get retiredAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

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
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete for sync

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
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete for sync

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
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete for sync

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
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete for sync

  @override
  Set<Column> get primaryKey => {id};
}

/// Breath hold achievement awards
/// Awards for sustained breath holds starting at 20s in 5s increments
class BreathHoldAwards extends Table {
  TextColumn get id => text()();
  IntColumn get secondsThreshold => integer()(); // 20, 25, 30, etc.
  TextColumn get title => text()(); // 'Novice Lung', 'Steady Breath', etc.
  TextColumn get sessionLogId => text().nullable().references(BreathTrainingLogs, #id)();
  DateTimeColumn get earnedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// KIT SNAPSHOTS & TUNING SYSTEM
// ============================================================================

/// Kit snapshots - captures equipment configuration at notable moments
class KitSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().nullable()(); // Link to scoring session
  TextColumn get bowId => text().nullable()(); // Original bow (may be deleted)
  TextColumn get quiverId => text().nullable()(); // Original quiver (may be deleted)
  DateTimeColumn get snapshotDate => dateTime()();
  IntColumn get score => integer().nullable()();
  IntColumn get maxScore => integer().nullable()();
  TextColumn get roundName => text().nullable()();
  TextColumn get reason => text().nullable()(); // 'top_20', 'personal_best', 'manual'
  TextColumn get bowName => text().nullable()(); // Snapshot of bow name
  TextColumn get bowType => text().nullable()(); // Snapshot of bow type
  TextColumn get bowSettings => text().nullable()(); // JSON snapshot of BowSpecifications
  TextColumn get quiverName => text().nullable()(); // Snapshot of quiver name
  TextColumn get arrowSettings => text().nullable()(); // JSON snapshot of ArrowSpecifications
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tuning sessions - tracks bow tuning history
class TuningSessions extends Table {
  TextColumn get id => text()();
  TextColumn get bowId => text().nullable().references(Bows, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get bowType => text()(); // 'recurve', 'compound'
  TextColumn get tuningType => text()(); // 'paper', 'bare_shaft', 'walk_back', 'french', etc.
  TextColumn get results => text().nullable()(); // JSON with tuning results
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// SKILLS LEVELING SYSTEM
// ============================================================================

/// Skill definitions and user progress (RuneScape-inspired 1-99 leveling)
class SkillLevels extends Table {
  TextColumn get id => text()(); // 'archery_skill', 'volume', etc.
  TextColumn get name => text()(); // Display name
  TextColumn get description => text().nullable()(); // What this skill tracks
  IntColumn get currentLevel => integer().withDefault(const Constant(1))();
  IntColumn get currentXp => integer().withDefault(const Constant(0))();
  IntColumn get lastCelebratedLevel => integer().withDefault(const Constant(1))(); // Last level we showed celebration for
  DateTimeColumn get lastLevelUpAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Append-only XP history log
class XpHistory extends Table {
  TextColumn get id => text()();
  TextColumn get skillId => text()(); // Links to SkillLevels.id
  IntColumn get xpAmount => integer()();
  TextColumn get source => text()(); // 'session', 'training', 'breath', etc.
  TextColumn get sourceId => text().nullable()(); // sessionId / logId reference
  TextColumn get reason => text().nullable()(); // Human-readable reason
  DateTimeColumn get earnedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// SIGHT MARKS SYSTEM
// ============================================================================

/// Sight mark records per bow per distance
class SightMarks extends Table {
  TextColumn get id => text()();
  TextColumn get bowId => text().references(Bows, #id)();
  RealColumn get distance => real()(); // Distance value
  TextColumn get unit => text().withDefault(const Constant('meters'))(); // 'meters' or 'yards'
  TextColumn get sightValue => text()(); // Stored as string to preserve notation (e.g., "5.14" or "51.4")
  TextColumn get weatherData => text().nullable()(); // JSON: temp, humidity, pressure, wind
  RealColumn get elevationDelta => real().nullable()(); // meters above/below reference
  RealColumn get slopeAngle => real().nullable()(); // degrees (-45 to +45)
  TextColumn get sessionId => text().nullable()(); // Which session it was recorded from
  IntColumn get endNumber => integer().nullable()(); // Which end it was recorded from
  IntColumn get shotCount => integer().nullable()(); // Number of arrows shot with this mark
  RealColumn get confidenceScore => real().nullable()(); // 0.0 to 1.0
  TextColumn get venueId => text().nullable()(); // FK to venues table for location memory
  BoolColumn get isIndoor => boolean().withDefault(const Constant(false))(); // Indoor vs outdoor
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete

  @override
  Set<Column> get primaryKey => {id};
}

/// Sight mark notation preferences per bow
class SightMarkPreferencesTable extends Table {
  TextColumn get bowId => text().references(Bows, #id)();
  TextColumn get notationStyle => text().withDefault(const Constant('decimal'))(); // 'decimal' or 'whole'
  IntColumn get decimalPlaces => integer().withDefault(const Constant(2))(); // 1 or 2
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {bowId};
}

/// Angle correction profiles for learning uphill/downhill adjustments per bow
class AngleCorrectionProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get bowId => text().references(Bows, #id)();
  RealColumn get arrowSpeedFps => real()(); // Stored/estimated arrow speed
  RealColumn get uphillFactor => real()(); // Learned uphill factor per degree
  RealColumn get downhillFactor => real()(); // Learned downhill factor per degree
  IntColumn get uphillDataPoints => integer().withDefault(const Constant(0))();
  IntColumn get downhillDataPoints => integer().withDefault(const Constant(0))();
  RealColumn get confidenceScore => real().withDefault(const Constant(0.3))(); // 0.0 to 1.0
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Shooting venues/locations for sightmark memory
class Venues extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()(); // e.g., "Lilleshall", "Home Field"
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get temperatureRegion => text().withDefault(const Constant('temperate'))(); // temperate, mediterranean, continental, tropical
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// AUTO-PLOT SYSTEM
// ============================================================================

/// Registered target references for camera-based arrow detection
class RegisteredTargets extends Table {
  TextColumn get id => text()();
  TextColumn get targetType => text()(); // '40cm', '80cm', '122cm', 'triple_40cm'
  TextColumn get imagePath => text()(); // Local file path to reference image
  BoolColumn get isTripleSpot => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Auto-Plot usage tracking for entitlement limits
class AutoPlotUsage extends Table {
  TextColumn get id => text()();
  TextColumn get yearMonth => text()(); // '2026-01' format
  IntColumn get scanCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// ENTITLEMENT & EDUCATION SYSTEM
// ============================================================================

/// User subscription and entitlement state
class Entitlements extends Table {
  TextColumn get id => text()();
  TextColumn get tier => text().withDefault(const Constant('archer'))(); // archer, competitor, professional, hustonSchool
  TextColumn get stripeCustomerId => text().nullable()();
  TextColumn get stripeSubscriptionId => text().nullable()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get graceEndsAt => dateTime().nullable()(); // 72hr grace period after expiry
  BoolColumn get isLegacy3dAiming => boolean().withDefault(const Constant(false))(); // Free 3D Aiming access
  TextColumn get legacyEmail => text().nullable()(); // Email matched for legacy access
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Video course progress tracking
class CourseProgress extends Table {
  TextColumn get id => text()();
  TextColumn get courseId => text()(); // 'plotting', '3d_aiming', etc.
  TextColumn get lessonId => text()(); // Specific lesson within course
  IntColumn get progressSeconds => integer().withDefault(const Constant(0))(); // Watch progress
  IntColumn get durationSeconds => integer()(); // Total lesson duration
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastWatchedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// One-time purchases (separate from subscriptions)
class Purchases extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()(); // '3d_aiming_course', etc.
  TextColumn get stripePaymentId => text().nullable()();
  RealColumn get amountPaid => real().nullable()(); // Amount in GBP
  TextColumn get source => text().withDefault(const Constant('stripe'))(); // stripe, legacy, promo
  DateTimeColumn get purchasedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// USER PROFILE SYSTEM
// ============================================================================

/// User profile storing archer information
class UserProfiles extends Table {
  TextColumn get id => text()();
  // Core shooting info (top)
  TextColumn get primaryBowType => text().withDefault(const Constant('recurve'))(); // recurve, compound, barebow, longbow, traditional
  TextColumn get handedness => text().withDefault(const Constant('right'))(); // 'left' or 'right'
  RealColumn get drawLength => real().nullable()(); // Draw length in inches (archer default)
  // Personal info
  TextColumn get name => text().nullable()();
  TextColumn get clubName => text().nullable()();
  IntColumn get yearsShootingStart => integer().nullable()(); // Year started shooting
  RealColumn get shootingFrequency => real().withDefault(const Constant(3.0))(); // Days per week (0-7)
  TextColumn get competitionLevels => text().withDefault(const Constant('[]'))(); // JSON array: ['local', 'regional', 'national', 'international', 'national_team']
  // Classification-related fields
  TextColumn get gender => text().nullable()(); // 'male' or 'female' for classification calculations
  DateTimeColumn get dateOfBirth => dateTime().nullable()(); // For age category calculation
  // Notes (bottom) - for club access codes, etc.
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Federation memberships (e.g., AGB, WA, NFAA)
class Federations extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(UserProfiles, #id)();
  TextColumn get federationName => text()(); // e.g., "Archery GB", "World Archery"
  TextColumn get membershipNumber => text().nullable()();
  TextColumn get cardImagePath => text().nullable()(); // Local file path to membership card image
  DateTimeColumn get expiryDate => dateTime().nullable()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // soft delete for sync

  @override
  Set<Column> get primaryKey => {id};
}

/// AGB Classification achievements
/// Tracks when a user achieves a classification (requires two qualifying scores)
class Classifications extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(UserProfiles, #id)();
  TextColumn get classification => text()(); // 'GMB', 'MB', 'B1', 'B2', 'B3', 'A1', 'A2', 'A3'
  TextColumn get classificationScope => text()(); // 'outdoor' or 'indoor'
  TextColumn get bowstyle => text()(); // 'recurve', 'compound', 'barebow', 'longbow', 'traditional'
  // First qualifying score
  TextColumn get firstSessionId => text().nullable().references(Sessions, #id)();
  DateTimeColumn get firstAchievedAt => dateTime().nullable()();
  IntColumn get firstScore => integer().nullable()();
  TextColumn get firstRoundId => text().nullable()();
  // Second qualifying score
  TextColumn get secondSessionId => text().nullable().references(Sessions, #id)();
  DateTimeColumn get secondAchievedAt => dateTime().nullable()();
  IntColumn get secondScore => integer().nullable()();
  TextColumn get secondRoundId => text().nullable()();
  // Claim status
  BoolColumn get isClaimed => boolean().withDefault(const Constant(false))(); // User has confirmed/claimed this
  DateTimeColumn get claimedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Earned achievements (streaks, PBs, milestones, etc.)
/// Records achievements for display in skills profile
class Achievements extends Table {
  TextColumn get id => text()();
  TextColumn get achievementType => text()(); // 'streak7', 'streak14', 'streak30', 'personalBest', 'competitionPb', 'excellentForm', 'fullPlot', 'milestone'
  TextColumn get skillId => text().nullable()(); // Related skill (optional)
  TextColumn get roundTypeId => text().nullable()(); // For PBs: which round type
  IntColumn get score => integer().nullable()(); // For PBs: the score achieved
  TextColumn get title => text()(); // Display title (e.g., "7 DAY STREAK", "PORTSMOUTH PB")
  TextColumn get description => text().nullable()(); // Details (e.g., "Score: 571")
  BoolColumn get isCompetitionPb => boolean().withDefault(const Constant(false))(); // More elaborate shield for comp PBs
  DateTimeColumn get earnedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// SYNC SYSTEM
// ============================================================================

/// Sync queue - persists pending operations for offline sync
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()(); // 'session', 'bow', 'importedScore', etc.
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // 'create', 'update', 'delete'
  TextColumn get payload => text()(); // JSON serialized entity data
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync metadata - tracks last sync per entity type
class SyncMetadata extends Table {
  TextColumn get entityType => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {entityType};
}

// ============================================================================
// FIELD ARCHERY SYSTEM
// ============================================================================

/// Field archery courses (like golf courses - persistent definitions)
class FieldCourses extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get venueId => text().nullable().references(Venues, #id)();
  TextColumn get roundType => text()(); // field, hunter, expert, animal, marked3dStandard, marked3dHunting
  IntColumn get targetCount => integer().withDefault(const Constant(28))(); // 14 or 28
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Per-target configurations within a field course
class FieldCourseTargets extends Table {
  TextColumn get id => text()();
  TextColumn get courseId => text().references(FieldCourses, #id)();
  IntColumn get targetNumber => integer()(); // 1-28
  TextColumn get pegConfig => text()(); // JSON: peg configuration
  IntColumn get faceSize => integer()(); // cm
  RealColumn get primaryDistance => real()();
  TextColumn get unit => text().withDefault(const Constant('yards'))(); // meters or yards
  BoolColumn get isWalkUp => boolean().withDefault(const Constant(false))();
  BoolColumn get isWalkDown => boolean().withDefault(const Constant(false))();
  IntColumn get arrowsRequired => integer().withDefault(const Constant(4))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Course-specific sight mark learning (per target, per bow)
class FieldCourseSightMarks extends Table {
  TextColumn get id => text()();
  TextColumn get courseTargetId => text().references(FieldCourseTargets, #id)();
  TextColumn get bowId => text().references(Bows, #id)();
  RealColumn get calculatedMark => real()(); // What the standard calculation predicted
  RealColumn get actualMark => real()(); // What the archer actually used
  RealColumn get differential => real()(); // actual - calculated
  RealColumn get confidenceScore => real().nullable()(); // 0-1 based on shot count
  TextColumn get weatherData => text().nullable()(); // JSON weather snapshot
  IntColumn get shotCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Per-target scores in a field session
class FieldSessionTargets extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get courseTargetId => text().nullable().references(FieldCourseTargets, #id)();
  IntColumn get targetNumber => integer()();
  IntColumn get totalScore => integer().withDefault(const Constant(0))();
  IntColumn get xCount => integer().withDefault(const Constant(0))();
  TextColumn get arrowScores => text()(); // JSON array of scores
  TextColumn get sightMarkUsed => text().nullable()();
  IntColumn get station => integer().nullable()(); // For animal rounds: which station scored
  BoolColumn get wasHit => boolean().nullable()(); // For animal rounds
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Field session metadata (extends Sessions table)
class FieldSessionMeta extends Table {
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get courseId => text().nullable().references(FieldCourses, #id)();
  TextColumn get roundType => text()(); // field, hunter, expert, animal, etc.
  BoolColumn get isNewCourseCreation => boolean().withDefault(const Constant(false))();
  IntColumn get currentTargetNumber => integer().withDefault(const Constant(1))();
  TextColumn get usedPegs => text().withDefault(const Constant('[]'))(); // JSON array of used peg configs

  @override
  Set<Column> get primaryKey => {sessionId};
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
  FingerTabs,
  Quivers,
  Shafts,
  Stabilizers,
  BowStrings,
  VolumeEntries,
  // OLY Bow Training System
  OlyExerciseTypes,
  OlySessionTemplates,
  OlySessionExercises,
  OlyTrainingLogs,
  UserTrainingProgress,
  // Breath Training System
  BreathTrainingLogs,
  BreathHoldAwards,
  // Milestones for handicap graph
  Milestones,
  // Volume imports for raw data preservation
  VolumeImports,
  // Kit Snapshots & Tuning System
  KitSnapshots,
  TuningSessions,
  // Skills Leveling System
  SkillLevels,
  XpHistory,
  // Sight Marks System
  SightMarks,
  SightMarkPreferencesTable,
  AngleCorrectionProfiles,
  Venues,
  // Auto-Plot System
  RegisteredTargets,
  AutoPlotUsage,
  // User Profile System
  UserProfiles,
  Federations,
  Classifications,
  Achievements,
  // Entitlement & Education System
  Entitlements,
  CourseProgress,
  Purchases,
  // Sync System
  SyncQueue,
  SyncMetadata,
  // Field Archery System
  FieldCourses,
  FieldCourseTargets,
  FieldCourseSightMarks,
  FieldSessionTargets,
  FieldSessionMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Constructor for testing with custom executor
  AppDatabase.withExecutor(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 31;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedRoundTypes();
        await _seedOlyTrainingData();
        await _seedSkillLevels();
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
        if (from <= 11) {
          // Add kit snapshots and tuning sessions tables
          await m.createTable(kitSnapshots);
          await m.createTable(tuningSessions);
        }
        if (from <= 12) {
          // Add shaft specification columns
          await m.addColumn(shafts, shafts.spine);
          await m.addColumn(shafts, shafts.lengthInches);
          await m.addColumn(shafts, shafts.pointWeight);
          await m.addColumn(shafts, shafts.fletchingType);
          await m.addColumn(shafts, shafts.fletchingColor);
          await m.addColumn(shafts, shafts.nockColor);
          // Add shaftId foreign key to arrows
          await m.addColumn(arrows, arrows.shaftId);
        }
        if (from <= 13) {
          // Equipment expansion - comprehensive tuning details

          // New tables
          await m.createTable(stabilizers);
          await m.createTable(bowStrings);

          // Expand Bows table with equipment details
          await m.addColumn(bows, bows.riserModel);
          await m.addColumn(bows, bows.riserPurchaseDate);
          await m.addColumn(bows, bows.limbModel);
          await m.addColumn(bows, bows.limbPurchaseDate);
          await m.addColumn(bows, bows.poundage);
          await m.addColumn(bows, bows.tillerTop);
          await m.addColumn(bows, bows.tillerBottom);
          await m.addColumn(bows, bows.braceHeight);
          await m.addColumn(bows, bows.nockingPointHeight);
          await m.addColumn(bows, bows.buttonPosition);
          await m.addColumn(bows, bows.buttonTension);
          await m.addColumn(bows, bows.clickerPosition);

          // Expand Shafts table with detailed specs
          await m.addColumn(shafts, shafts.totalWeight);
          await m.addColumn(shafts, shafts.pointType);
          await m.addColumn(shafts, shafts.nockBrand);
          await m.addColumn(shafts, shafts.fletchingSize);
          await m.addColumn(shafts, shafts.fletchingAngle);
          await m.addColumn(shafts, shafts.hasWrap);
          await m.addColumn(shafts, shafts.wrapColor);
          await m.addColumn(shafts, shafts.purchaseDate);
        }
        if (from <= 14) {
          // Skills leveling system
          await m.createTable(skillLevels);
          await m.createTable(xpHistory);
          await _seedSkillLevels();
        }
        if (from <= 15) {
          // Sight marks system
          await m.createTable(sightMarks);
          await m.createTable(sightMarkPreferencesTable);
        }
        if (from <= 16) {
          // Auto-Plot system
          await m.createTable(registeredTargets);
          await m.createTable(autoPlotUsage);
        }
        if (from <= 17) {
          // Nock rotation tracking for arrows
          await m.addColumn(arrows, arrows.nockRotation);
        }
        if (from <= 18) {
          // Eye-to-arrow distance for sight geometry
          await m.addColumn(bows, bows.eyeToArrowDistance);
          // Finger tabs table
          await m.createTable(fingerTabs);
        }
        if (from <= 19) {
          // User profile system
          await m.createTable(userProfiles);
          await m.createTable(federations);
          // Stabilizer left/right side rod fields
          await m.addColumn(stabilizers, stabilizers.leftSideRodModel);
          await m.addColumn(stabilizers, stabilizers.leftSideRodLength);
          await m.addColumn(stabilizers, stabilizers.leftSideRodWeight);
          await m.addColumn(stabilizers, stabilizers.leftWeights);
          await m.addColumn(stabilizers, stabilizers.leftAngleHorizontal);
          await m.addColumn(stabilizers, stabilizers.leftAngleVertical);
          await m.addColumn(stabilizers, stabilizers.rightSideRodModel);
          await m.addColumn(stabilizers, stabilizers.rightSideRodLength);
          await m.addColumn(stabilizers, stabilizers.rightSideRodWeight);
          await m.addColumn(stabilizers, stabilizers.rightWeights);
          await m.addColumn(stabilizers, stabilizers.rightAngleHorizontal);
          await m.addColumn(stabilizers, stabilizers.rightAngleVertical);
          await m.addColumn(stabilizers, stabilizers.longRodWeights);
          await m.addColumn(stabilizers, stabilizers.setupPhotoPath);
        }
        if (from <= 20) {
          // Entitlement & Education system
          await m.createTable(entitlements);
          await m.createTable(courseProgress);
          await m.createTable(purchases);
        }
        if (from <= 21) {
          // Shot rating for analysis filtering
          await m.addColumn(arrows, arrows.rating);
        }
        if (from <= 22) {
          // Sync system tables and columns
          await m.createTable(syncQueue);
          await m.createTable(syncMetadata);

          // Add sync-related columns to existing tables
          // ImportedScores: updatedAt, deletedAt
          await m.addColumn(importedScores, importedScores.updatedAt);
          await m.addColumn(importedScores, importedScores.deletedAt);

          // Ends: updatedAt, deletedAt
          await m.addColumn(ends, ends.updatedAt);
          await m.addColumn(ends, ends.deletedAt);

          // Arrows: updatedAt, deletedAt
          await m.addColumn(arrows, arrows.updatedAt);
          await m.addColumn(arrows, arrows.deletedAt);

          // VolumeEntries: deletedAt (updatedAt already exists)
          await m.addColumn(volumeEntries, volumeEntries.deletedAt);

          // OlyTrainingLogs: createdAt, deletedAt
          await m.addColumn(olyTrainingLogs, olyTrainingLogs.createdAt);
          await m.addColumn(olyTrainingLogs, olyTrainingLogs.deletedAt);

          // BreathTrainingLogs: updatedAt, deletedAt
          await m.addColumn(breathTrainingLogs, breathTrainingLogs.updatedAt);
          await m.addColumn(breathTrainingLogs, breathTrainingLogs.deletedAt);

          // Milestones: updatedAt, deletedAt
          await m.addColumn(milestones, milestones.updatedAt);
          await m.addColumn(milestones, milestones.deletedAt);

          // Federations: deletedAt (updatedAt already exists)
          await m.addColumn(federations, federations.deletedAt);
        }
        if (from <= 23) {
          // AGB Classification system
          await m.createTable(classifications);

          // Add gender and dateOfBirth to user profiles for classification calculations
          await m.addColumn(userProfiles, userProfiles.gender);
          await m.addColumn(userProfiles, userProfiles.dateOfBirth);

          // Fix Worcester round: should use 5-zone scoring, not 10-zone
          await customStatement('''
            UPDATE round_types
            SET scoring_type = '5-zone'
            WHERE id = 'worcester'
          ''');
        }
        if (from <= 24) {
          // Draw length for improved sight mark calculations
          await m.addColumn(userProfiles, userProfiles.drawLength);
          await m.addColumn(bows, bows.drawLength);
          // Breath hold awards table
          await m.createTable(breathHoldAwards);
          // Achievements system for skills profile
          await m.createTable(achievements);
        }
        if (from <= 25) {
          // Venue/location memory system for sightmarks
          await m.createTable(venues);
          await m.addColumn(sightMarks, sightMarks.venueId);
        }
        if (from <= 26) {
          // Fix Worcester round scoring type: uses 5-4-3-2-1 scoring, not 9-7-5-3-1
          await customStatement('''
            UPDATE round_types
            SET scoring_type = 'worcester'
            WHERE id = 'worcester'
          ''');
        }
        if (from <= 27) {
          // Add indoor toggle to sight marks
          await m.addColumn(sightMarks, sightMarks.isIndoor);
        }
        if (from <= 28) {
          // Field Archery System
          await m.createTable(fieldCourses);
          await m.createTable(fieldCourseTargets);
          await m.createTable(fieldCourseSightMarks);
          await m.createTable(fieldSessionTargets);
          await m.createTable(fieldSessionMeta);
        }
        if (from <= 29) {
          // Session title and location improvements
          await m.addColumn(sessions, sessions.title);
          await m.addColumn(sessions, sessions.locationName);
          await m.addColumn(sessions, sessions.latitude);
          await m.addColumn(sessions, sessions.longitude);
        }
        if (from <= 30) {
          // Angle correction profiles for learning uphill/downhill adjustments
          await m.createTable(angleCorrectionProfiles);
          // Track last celebrated level for level-up celebrations
          await m.addColumn(skillLevels, skillLevels.lastCelebratedLevel);
          // Set existing skills' lastCelebratedLevel to their current level
          // (to avoid bombarding users with old level-ups on upgrade)
          await customStatement('''
            UPDATE skill_levels
            SET last_celebrated_level = current_level
          ''');
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

  /// Toggle shaft tagging for a session
  Future<int> setShaftTagging(String sessionId, bool enabled) =>
      (update(sessions)..where((t) => t.id.equals(sessionId))).write(
        SessionsCompanion(shaftTaggingEnabled: Value(enabled)),
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

  /// Uncommit an end (revert to active status for undo)
  Future<int> uncommitEnd(String endId) =>
      (update(ends)..where((t) => t.id.equals(endId))).write(
        const EndsCompanion(
          status: Value('active'),
          committedAt: Value(null),
        ),
      );

  /// Delete an end and its arrows
  Future<int> deleteEnd(String endId) async {
    await (delete(arrows)..where((t) => t.endId.equals(endId))).go();
    return (delete(ends)..where((t) => t.id.equals(endId))).go();
  }

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

  /// Update the sequence number of an arrow (for reordering)
  Future<int> updateArrowSequence(String arrowId, int newSequence) =>
      updateArrow(arrowId, ArrowsCompanion(sequence: Value(newSequence)));

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
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .get();

  Future<int> insertImportedScore(ImportedScoresCompanion score) =>
      into(importedScores).insert(score, mode: InsertMode.insertOrIgnore);

  Future<int> deleteImportedScore(String id) =>
      (delete(importedScores)..where((t) => t.id.equals(id))).go();

  /// Soft delete an imported score (can be restored)
  Future<void> softDeleteImportedScore(String id) async {
    await (update(importedScores)..where((t) => t.id.equals(id))).write(
      ImportedScoresCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  /// Restore a soft-deleted imported score
  Future<void> restoreImportedScore(String id) async {
    await (update(importedScores)..where((t) => t.id.equals(id))).write(
      const ImportedScoresCompanion(deletedAt: Value(null)),
    );
  }

  /// Get an imported score by ID
  Future<ImportedScore?> getImportedScore(String id) =>
      (select(importedScores)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Update an imported score
  Future<bool> updateImportedScore(ImportedScoresCompanion score) =>
      update(importedScores).replace(score);

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

  Future<double> getDoublePreference(String key, {double defaultValue = 0.0}) async {
    final value = await getPreference(key);
    if (value == null) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }

  Future<void> setDoublePreference(String key, double value) =>
      setPreference(key, value.toString());

  Future<int> getIntPreference(String key, {int defaultValue = 0}) async {
    final value = await getPreference(key);
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  Future<void> setIntPreference(String key, int value) =>
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
  // FINGER TABS
  // ===========================================================================

  Future<List<FingerTab>> getAllFingerTabs() =>
      (select(fingerTabs)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<FingerTab?> getFingerTab(String id) =>
      (select(fingerTabs)..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .getSingleOrNull();

  Future<FingerTab?> getDefaultFingerTab() =>
      (select(fingerTabs)..where((t) => t.isDefault.equals(true) & t.deletedAt.isNull()))
          .getSingleOrNull();

  Future<int> insertFingerTab(FingerTabsCompanion tab) => into(fingerTabs).insert(tab);

  Future<bool> updateFingerTab(FingerTabsCompanion tab) => update(fingerTabs).replace(tab);

  Future<int> setDefaultFingerTab(String tabId) async {
    await (update(fingerTabs)).write(const FingerTabsCompanion(isDefault: Value(false)));
    return (update(fingerTabs)..where((t) => t.id.equals(tabId)))
        .write(const FingerTabsCompanion(isDefault: Value(true)));
  }

  Future<int> softDeleteFingerTab(String tabId) =>
      (update(fingerTabs)..where((t) => t.id.equals(tabId)))
          .write(FingerTabsCompanion(deletedAt: Value(DateTime.now())));

  Future<int> restoreFingerTab(String tabId) =>
      (update(fingerTabs)..where((t) => t.id.equals(tabId)))
          .write(const FingerTabsCompanion(deletedAt: Value(null)));

  Future<int> deleteFingerTab(String tabId) =>
      (delete(fingerTabs)..where((t) => t.id.equals(tabId))).go();

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

  /// Create a quiver with shafts atomically in a transaction
  Future<void> createQuiverWithShafts({
    required QuiversCompanion quiver,
    required List<ShaftsCompanion> shaftsList,
  }) async {
    return transaction(() async {
      await into(quivers).insert(quiver);
      for (final shaft in shaftsList) {
        await into(shafts).insert(shaft);
      }
    });
  }

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

  /// Get all arrows shot with shafts from a specific quiver
  Future<List<Arrow>> getArrowsForQuiver(String quiverId) async {
    final quiverShafts = await getAllShaftsForQuiver(quiverId);
    if (quiverShafts.isEmpty) return [];
    final shaftIds = quiverShafts.map((s) => s.id).toList();
    return (select(arrows)
          ..where((t) => t.shaftId.isIn(shaftIds))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  // ===========================================================================
  // VOLUME ENTRIES
  // ===========================================================================

  Future<List<VolumeEntry>> getAllVolumeEntries() => (select(volumeEntries)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .get();

  Future<List<VolumeEntry>> getVolumeEntriesInRange(
      DateTime start, DateTime end) =>
      (select(volumeEntries)
            ..where((t) =>
                t.deletedAt.isNull() &
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
              t.deletedAt.isNull() &
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

  /// Soft delete a volume entry (can be restored)
  Future<void> softDeleteVolumeEntry(String id) async {
    await (update(volumeEntries)..where((t) => t.id.equals(id))).write(
      VolumeEntriesCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  /// Restore a soft-deleted volume entry
  Future<void> restoreVolumeEntry(String id) async {
    await (update(volumeEntries)..where((t) => t.id.equals(id))).write(
      const VolumeEntriesCompanion(deletedAt: Value(null)),
    );
  }

  /// Get a volume entry by ID
  Future<VolumeEntry?> getVolumeEntry(String id) =>
      (select(volumeEntries)..where((t) => t.id.equals(id))).getSingleOrNull();

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

  /// Add arrows from a session to the daily volume count.
  /// Called when a session is completed to auto-track volume.
  Future<void> addSessionArrowsToVolume(String sessionId) async {
    // Get the session to find its date
    final session = await getSession(sessionId);
    if (session == null || session.completedAt == null) return;

    // Count arrows in this session
    final sessionEnds = await getEndsForSession(sessionId);
    int arrowCount = 0;
    for (final end in sessionEnds) {
      final arrows = await getArrowsForEnd(end.id);
      arrowCount += arrows.length;
    }

    if (arrowCount == 0) return;

    // Get the session date (use completedAt for accuracy)
    final sessionDate = session.completedAt!;
    final dayStart = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);

    // Get existing volume for this date and add to it
    final existing = await getVolumeEntryForDate(dayStart);
    final newCount = (existing?.arrowCount ?? 0) + arrowCount;

    await setVolumeForDate(
      dayStart,
      newCount,
      title: existing?.title ?? 'Session arrows',
      notes: existing?.notes,
    );
  }

  /// Get most frequently used round types from recent sessions.
  /// Returns round types ordered by usage frequency in past [days] days.
  Future<List<RoundType>> getMostFrequentRecentRoundTypes({int days = 14, int limit = 5}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));

    // Get recent completed sessions
    final recentSessions = await (select(sessions)
          ..where((t) =>
              t.completedAt.isNotNull() &
              t.deletedAt.isNull() &
              t.startedAt.isBiggerOrEqualValue(cutoff))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();

    // Count round type usage
    final usageCount = <String, int>{};
    final lastUsed = <String, DateTime>{};

    for (final session in recentSessions) {
      usageCount[session.roundTypeId] = (usageCount[session.roundTypeId] ?? 0) + 1;
      // Track most recent use
      if (!lastUsed.containsKey(session.roundTypeId)) {
        lastUsed[session.roundTypeId] = session.startedAt;
      }
    }

    if (usageCount.isEmpty) {
      // No recent sessions - return default indoor round
      final defaultRound = await getRoundType('wa_indoor_40cm_18m');
      return defaultRound != null ? [defaultRound] : [];
    }

    // Sort by frequency (descending), then by recency
    final sortedIds = usageCount.keys.toList()
      ..sort((a, b) {
        final countCompare = usageCount[b]!.compareTo(usageCount[a]!);
        if (countCompare != 0) return countCompare;
        return lastUsed[b]!.compareTo(lastUsed[a]!);
      });

    // Get the round types
    final result = <RoundType>[];
    for (final id in sortedIds.take(limit)) {
      final roundType = await getRoundType(id);
      if (roundType != null) {
        result.add(roundType);
      }
    }

    return result;
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
  // SKILL LEVELS SEED
  // ===========================================================================

  Future<void> _seedSkillLevels() async {
    final skills = [
      SkillLevelsCompanion.insert(
        id: 'archery_skill',
        name: 'Archery Skill',
        description: const Value('Scoring performance based on handicap'),
      ),
      SkillLevelsCompanion.insert(
        id: 'volume',
        name: 'Volume',
        description: const Value('Arrow count tracking'),
      ),
      SkillLevelsCompanion.insert(
        id: 'consistency',
        name: 'Consistency',
        description: const Value('Training frequency and streaks'),
      ),
      SkillLevelsCompanion.insert(
        id: 'bow_fitness',
        name: 'Bow Fitness',
        description: const Value('Hold times and physical conditioning'),
      ),
      SkillLevelsCompanion.insert(
        id: 'breath_work',
        name: 'Breath Work',
        description: const Value('Breath control and hold training'),
      ),
      SkillLevelsCompanion.insert(
        id: 'equipment',
        name: 'Equipment',
        description: const Value('Kit management and tuning'),
      ),
      SkillLevelsCompanion.insert(
        id: 'competition',
        name: 'Competition',
        description: const Value('Competition experience'),
      ),
      SkillLevelsCompanion.insert(
        id: 'analysis',
        name: 'Analysis',
        description: const Value('Arrow plotting and pattern analysis'),
      ),
    ];

    for (final skill in skills) {
      await into(skillLevels).insert(skill, mode: InsertMode.insertOrIgnore);
    }
  }

  /// Public method to ensure skill levels exist (re-seeds if missing)
  Future<void> ensureSkillLevelsExist() async {
    final existing = await getAllSkillLevels();
    if (existing.isEmpty) {
      await _seedSkillLevels();
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

  // ===========================================================================
  // BREATH HOLD AWARDS
  // ===========================================================================

  /// Get all earned breath hold awards ordered by threshold
  Future<List<BreathHoldAward>> getAllBreathHoldAwards() =>
      (select(breathHoldAwards)..orderBy([(t) => OrderingTerm.asc(t.secondsThreshold)])).get();

  /// Get a specific breath hold award by ID
  Future<BreathHoldAward?> getBreathHoldAward(String id) =>
      (select(breathHoldAwards)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Check if an award for a specific threshold has been earned
  Future<BreathHoldAward?> getBreathHoldAwardByThreshold(int seconds) =>
      (select(breathHoldAwards)..where((t) => t.secondsThreshold.equals(seconds))).getSingleOrNull();

  /// Get all awards earned for thresholds up to a given number of seconds
  Future<List<BreathHoldAward>> getBreathHoldAwardsUpTo(int seconds) =>
      (select(breathHoldAwards)
        ..where((t) => t.secondsThreshold.isSmallerOrEqualValue(seconds))
        ..orderBy([(t) => OrderingTerm.asc(t.secondsThreshold)]))
          .get();

  /// Insert a new breath hold award
  Future<int> insertBreathHoldAward(BreathHoldAwardsCompanion award) =>
      into(breathHoldAwards).insert(award);

  /// Get the highest threshold award earned
  Future<BreathHoldAward?> getHighestBreathHoldAward() async {
    final awards = await (select(breathHoldAwards)
          ..orderBy([(t) => OrderingTerm.desc(t.secondsThreshold)])
          ..limit(1))
        .get();
    return awards.isEmpty ? null : awards.first;
  }

  // ===========================================================================
  // KIT SNAPSHOTS
  // ===========================================================================

  Future<List<KitSnapshot>> getAllKitSnapshots() => (select(kitSnapshots)
        ..orderBy([(t) => OrderingTerm.desc(t.snapshotDate)]))
      .get();

  Future<List<KitSnapshot>> getKitSnapshotsForBow(String bowId) =>
      (select(kitSnapshots)
            ..where((t) => t.bowId.equals(bowId))
            ..orderBy([(t) => OrderingTerm.desc(t.snapshotDate)]))
          .get();

  Future<List<KitSnapshot>> getKitSnapshotsForSession(String sessionId) =>
      (select(kitSnapshots)
            ..where((t) => t.sessionId.equals(sessionId)))
          .get();

  Future<KitSnapshot?> getKitSnapshot(String id) =>
      (select(kitSnapshots)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertKitSnapshot(KitSnapshotsCompanion snapshot) =>
      into(kitSnapshots).insert(snapshot);

  Future<bool> updateKitSnapshot(KitSnapshotsCompanion snapshot) =>
      update(kitSnapshots).replace(snapshot);

  Future<int> deleteKitSnapshot(String id) =>
      (delete(kitSnapshots)..where((t) => t.id.equals(id))).go();

  /// Get all completed session scores for percentile calculation
  Future<List<int>> getAllCompletedSessionScores() async {
    final completedSessions = await getCompletedSessions();
    return completedSessions
        .where((s) => s.totalScore > 0)
        .map((s) => s.totalScore)
        .toList();
  }

  /// Get completed session scores for a specific round type
  Future<List<int>> getCompletedSessionScoresForRound(String roundTypeId) async {
    final sessions = await (select(this.sessions)
          ..where((t) =>
              t.roundTypeId.equals(roundTypeId) &
              t.completedAt.isNotNull() &
              t.deletedAt.isNull() &
              t.totalScore.isBiggerThanValue(0)))
        .get();
    return sessions.map((s) => s.totalScore).toList();
  }

  // ===========================================================================
  // TUNING SESSIONS
  // ===========================================================================

  Future<List<TuningSession>> getAllTuningSessions() => (select(tuningSessions)
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .get();

  Future<List<TuningSession>> getTuningSessionsForBow(String bowId) =>
      (select(tuningSessions)
            ..where((t) => t.bowId.equals(bowId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  Future<List<TuningSession>> getTuningSessionsByType(String tuningType) =>
      (select(tuningSessions)
            ..where((t) => t.tuningType.equals(tuningType))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  Future<TuningSession?> getTuningSession(String id) =>
      (select(tuningSessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertTuningSession(TuningSessionsCompanion session) =>
      into(tuningSessions).insert(session);

  Future<bool> updateTuningSession(TuningSessionsCompanion session) =>
      update(tuningSessions).replace(session);

  Future<int> deleteTuningSession(String id) =>
      (delete(tuningSessions)..where((t) => t.id.equals(id))).go();

  /// Get recent tuning sessions (last N)
  Future<List<TuningSession>> getRecentTuningSessions({int limit = 10}) =>
      (select(tuningSessions)
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(limit))
          .get();

  // ===========================================================================
  // SKILL LEVELS
  // ===========================================================================

  Future<List<SkillLevel>> getAllSkillLevels() =>
      (select(skillLevels)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<SkillLevel?> getSkillLevel(String id) =>
      (select(skillLevels)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertSkillLevel(SkillLevelsCompanion skill) =>
      into(skillLevels).insert(skill, mode: InsertMode.insertOrIgnore);

  Future<int> updateSkillLevel(String id, {int? currentXp, int? currentLevel, int? lastCelebratedLevel, DateTime? lastLevelUpAt}) =>
      (update(skillLevels)..where((t) => t.id.equals(id))).write(
        SkillLevelsCompanion(
          currentXp: currentXp != null ? Value(currentXp) : const Value.absent(),
          currentLevel: currentLevel != null ? Value(currentLevel) : const Value.absent(),
          lastCelebratedLevel: lastCelebratedLevel != null ? Value(lastCelebratedLevel) : const Value.absent(),
          lastLevelUpAt: lastLevelUpAt != null ? Value(lastLevelUpAt) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Get total level across all skills
  Future<int> getTotalLevel() async {
    final skills = await getAllSkillLevels();
    return skills.fold<int>(0, (sum, skill) => sum + skill.currentLevel);
  }

  // ===========================================================================
  // XP HISTORY
  // ===========================================================================

  Future<List<XpHistoryData>> getAllXpHistory() =>
      (select(xpHistory)..orderBy([(t) => OrderingTerm.desc(t.earnedAt)])).get();

  Future<List<XpHistoryData>> getXpHistoryForSkill(String skillId) =>
      (select(xpHistory)
            ..where((t) => t.skillId.equals(skillId))
            ..orderBy([(t) => OrderingTerm.desc(t.earnedAt)]))
          .get();

  Future<List<XpHistoryData>> getRecentXpHistory({int limit = 50}) =>
      (select(xpHistory)
            ..orderBy([(t) => OrderingTerm.desc(t.earnedAt)])
            ..limit(limit))
          .get();

  Future<int> insertXpHistory(XpHistoryCompanion history) =>
      into(xpHistory).insert(history);

  /// Award XP to a skill and log it
  Future<void> awardXp({
    required String skillId,
    required int xpAmount,
    required String source,
    String? sourceId,
    String? reason,
  }) async {
    if (xpAmount <= 0) return;

    // Insert XP history record
    await insertXpHistory(
      XpHistoryCompanion.insert(
        id: UniqueId.withPrefix('xp'),
        skillId: skillId,
        xpAmount: xpAmount,
        source: source,
        sourceId: Value(sourceId),
        reason: Value(reason),
      ),
    );

    // Update skill XP total
    final skill = await getSkillLevel(skillId);
    if (skill != null) {
      final newXp = skill.currentXp + xpAmount;
      await updateSkillLevel(skillId, currentXp: newXp);
    }
  }

  /// Get total XP earned for a skill from history
  Future<int> getTotalXpForSkill(String skillId) async {
    final history = await getXpHistoryForSkill(skillId);
    return history.fold<int>(0, (sum, entry) => sum + entry.xpAmount);
  }

  /// Get XP earned in date range for a skill
  Future<int> getXpInRange(String skillId, DateTime start, DateTime end) async {
    final history = await (select(xpHistory)
          ..where((t) =>
              t.skillId.equals(skillId) &
              t.earnedAt.isBiggerOrEqualValue(start) &
              t.earnedAt.isSmallerOrEqualValue(end)))
        .get();
    return history.fold<int>(0, (sum, entry) => sum + entry.xpAmount);
  }

  // ===========================================================================
  // SIGHT MARKS
  // ===========================================================================

  /// Get all sight marks for a bow (excluding soft-deleted)
  Future<List<SightMark>> getSightMarksForBow(String bowId) =>
      (select(sightMarks)
            ..where((t) => t.bowId.equals(bowId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.distance)]))
          .get();

  /// Get all sight marks (excluding soft-deleted)
  Future<List<SightMark>> getAllSightMarks() =>
      (select(sightMarks)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.distance)]))
          .get();

  /// Get sight mark by ID
  Future<SightMark?> getSightMark(String id) =>
      (select(sightMarks)
            ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .getSingleOrNull();

  /// Get sight marks for a specific distance and unit
  Future<List<SightMark>> getSightMarksAtDistance(
    String bowId,
    double distance,
    String unit,
  ) =>
      (select(sightMarks)
            ..where((t) =>
                t.bowId.equals(bowId) &
                t.distance.equals(distance) &
                t.unit.equals(unit) &
                t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
          .get();

  /// Get the most recent sight mark at a distance
  Future<SightMark?> getLatestSightMarkAtDistance(
    String bowId,
    double distance,
    String unit,
  ) =>
      (select(sightMarks)
            ..where((t) =>
                t.bowId.equals(bowId) &
                t.distance.equals(distance) &
                t.unit.equals(unit) &
                t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
            ..limit(1))
          .getSingleOrNull();

  /// Insert a new sight mark
  Future<int> insertSightMark(SightMarksCompanion mark) =>
      into(sightMarks).insert(mark);

  /// Update an existing sight mark
  Future<bool> updateSightMark(SightMarksCompanion mark) =>
      update(sightMarks).replace(mark);

  /// Soft delete a sight mark
  Future<int> softDeleteSightMark(String id) =>
      (update(sightMarks)..where((t) => t.id.equals(id)))
          .write(SightMarksCompanion(deletedAt: Value(DateTime.now())));

  /// Restore a soft-deleted sight mark
  Future<int> restoreSightMark(String id) =>
      (update(sightMarks)..where((t) => t.id.equals(id)))
          .write(const SightMarksCompanion(deletedAt: Value(null)));

  /// Permanently delete a sight mark
  Future<int> deleteSightMark(String id) =>
      (delete(sightMarks)..where((t) => t.id.equals(id))).go();

  /// Delete all sight marks for a bow
  Future<int> deleteSightMarksForBow(String bowId) =>
      (delete(sightMarks)..where((t) => t.bowId.equals(bowId))).go();

  // ===========================================================================
  // SIGHT MARK PREFERENCES
  // ===========================================================================

  /// Get sight mark preferences for a bow
  Future<SightMarkPreferencesTableData?> getSightMarkPreferences(String bowId) =>
      (select(sightMarkPreferencesTable)..where((t) => t.bowId.equals(bowId)))
          .getSingleOrNull();

  /// Insert or update sight mark preferences for a bow
  Future<void> setSightMarkPreferences({
    required String bowId,
    String? notationStyle,
    int? decimalPlaces,
  }) async {
    final existing = await getSightMarkPreferences(bowId);
    if (existing != null) {
      await (update(sightMarkPreferencesTable)..where((t) => t.bowId.equals(bowId)))
          .write(SightMarkPreferencesTableCompanion(
        notationStyle: notationStyle != null ? Value(notationStyle) : const Value.absent(),
        decimalPlaces: decimalPlaces != null ? Value(decimalPlaces) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ));
    } else {
      await into(sightMarkPreferencesTable).insert(
        SightMarkPreferencesTableCompanion.insert(
          bowId: bowId,
          notationStyle: Value(notationStyle ?? 'decimal'),
          decimalPlaces: Value(decimalPlaces ?? 2),
        ),
      );
    }
  }

  /// Delete sight mark preferences for a bow
  Future<int> deleteSightMarkPreferences(String bowId) =>
      (delete(sightMarkPreferencesTable)..where((t) => t.bowId.equals(bowId))).go();

  // ===========================================================================
  // ANGLE CORRECTION PROFILES
  // ===========================================================================

  /// Get angle correction profile for a bow
  Future<AngleCorrectionProfile?> getAngleCorrectionProfile(String bowId) =>
      (select(angleCorrectionProfiles)..where((t) => t.bowId.equals(bowId)))
          .getSingleOrNull();

  /// Get all angle correction profiles
  Future<List<AngleCorrectionProfile>> getAllAngleCorrectionProfiles() =>
      select(angleCorrectionProfiles).get();

  /// Insert a new angle correction profile
  Future<int> insertAngleCorrectionProfile(
          AngleCorrectionProfilesCompanion profile) =>
      into(angleCorrectionProfiles).insert(profile);

  /// Update an existing angle correction profile
  Future<bool> updateAngleCorrectionProfile(
          AngleCorrectionProfilesCompanion profile) =>
      update(angleCorrectionProfiles).replace(profile);

  /// Insert or update angle correction profile
  Future<void> upsertAngleCorrectionProfile({
    required String id,
    required String bowId,
    required double arrowSpeedFps,
    required double uphillFactor,
    required double downhillFactor,
    int uphillDataPoints = 0,
    int downhillDataPoints = 0,
    double confidenceScore = 0.3,
  }) async {
    final existing = await getAngleCorrectionProfile(bowId);
    if (existing != null) {
      await (update(angleCorrectionProfiles)
            ..where((t) => t.bowId.equals(bowId)))
          .write(AngleCorrectionProfilesCompanion(
        arrowSpeedFps: Value(arrowSpeedFps),
        uphillFactor: Value(uphillFactor),
        downhillFactor: Value(downhillFactor),
        uphillDataPoints: Value(uphillDataPoints),
        downhillDataPoints: Value(downhillDataPoints),
        confidenceScore: Value(confidenceScore),
        lastUpdated: Value(DateTime.now()),
      ));
    } else {
      await into(angleCorrectionProfiles).insert(
        AngleCorrectionProfilesCompanion.insert(
          id: id,
          bowId: bowId,
          arrowSpeedFps: arrowSpeedFps,
          uphillFactor: uphillFactor,
          downhillFactor: downhillFactor,
          uphillDataPoints: Value(uphillDataPoints),
          downhillDataPoints: Value(downhillDataPoints),
          confidenceScore: Value(confidenceScore),
        ),
      );
    }
  }

  /// Delete angle correction profile for a bow
  Future<int> deleteAngleCorrectionProfile(String bowId) =>
      (delete(angleCorrectionProfiles)..where((t) => t.bowId.equals(bowId)))
          .go();

  // ===========================================================================
  // VENUES
  // ===========================================================================

  /// Get all venues ordered by most recently used
  Future<List<Venue>> getAllVenues() =>
      (select(venues)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();

  /// Get venue by ID
  Future<Venue?> getVenue(String id) =>
      (select(venues)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Get venue by name (case-insensitive)
  Future<Venue?> getVenueByName(String name) =>
      (select(venues)..where((t) => t.name.lower().equals(name.toLowerCase())))
          .getSingleOrNull();

  /// Find venue near coordinates (within ~500m)
  Future<Venue?> findVenueNearCoordinates(double lat, double lng) async {
    // Simple distance approximation for small distances
    // 0.005 degrees is approximately 500m at UK latitudes
    const tolerance = 0.005;
    final results = await (select(venues)
          ..where((t) =>
              t.latitude.isBetweenValues(lat - tolerance, lat + tolerance) &
              t.longitude.isBetweenValues(lng - tolerance, lng + tolerance)))
        .get();
    return results.firstOrNull;
  }

  /// Insert a new venue
  Future<int> insertVenue(VenuesCompanion venue) =>
      into(venues).insert(venue);

  /// Update an existing venue
  Future<bool> updateVenue(VenuesCompanion venue) =>
      update(venues).replace(venue);

  /// Delete a venue
  Future<int> deleteVenue(String id) =>
      (delete(venues)..where((t) => t.id.equals(id))).go();

  /// Get sight marks for a specific venue
  Future<List<SightMark>> getSightMarksForVenue(String venueId) =>
      (select(sightMarks)
            ..where((t) => t.venueId.equals(venueId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
          .get();

  /// Get sight marks for a venue at a specific distance
  Future<List<SightMark>> getSightMarksForVenueAtDistance(
    String venueId,
    String bowId,
    double distance,
    String unit,
  ) =>
      (select(sightMarks)
            ..where((t) =>
                t.venueId.equals(venueId) &
                t.bowId.equals(bowId) &
                t.distance.equals(distance) &
                t.unit.equals(unit) &
                t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
          .get();

  // ===========================================================================
  // AUTO-PLOT
  // ===========================================================================

  /// Get all registered targets
  Future<List<RegisteredTarget>> getAllRegisteredTargets() =>
      (select(registeredTargets)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  /// Get registered target by ID
  Future<RegisteredTarget?> getRegisteredTarget(String id) =>
      (select(registeredTargets)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Get registered target by type
  Future<RegisteredTarget?> getRegisteredTargetByType(String targetType) =>
      (select(registeredTargets)..where((t) => t.targetType.equals(targetType))).getSingleOrNull();

  /// Insert a new registered target
  Future<int> insertRegisteredTarget(RegisteredTargetsCompanion target) =>
      into(registeredTargets).insert(target);

  /// Delete a registered target
  Future<int> deleteRegisteredTarget(String id) =>
      (delete(registeredTargets)..where((t) => t.id.equals(id))).go();

  /// Get current month's auto-plot usage
  Future<AutoPlotUsageData?> getAutoPlotUsage(String yearMonth) =>
      (select(autoPlotUsage)..where((t) => t.yearMonth.equals(yearMonth))).getSingleOrNull();

  /// Increment auto-plot scan count for current month
  Future<int> incrementAutoPlotUsage() async {
    final yearMonth = _getCurrentYearMonth();
    final existing = await getAutoPlotUsage(yearMonth);

    if (existing != null) {
      return (update(autoPlotUsage)..where((t) => t.yearMonth.equals(yearMonth)))
          .write(AutoPlotUsageCompanion(scanCount: Value(existing.scanCount + 1)));
    } else {
      return into(autoPlotUsage).insert(
        AutoPlotUsageCompanion.insert(
          id: UniqueId.withPrefix('apu'),
          yearMonth: yearMonth,
          scanCount: const Value(1),
        ),
      );
    }
  }

  /// Get current auto-plot scan count for the month
  Future<int> getCurrentAutoPlotScanCount() async {
    final yearMonth = _getCurrentYearMonth();
    final usage = await getAutoPlotUsage(yearMonth);
    return usage?.scanCount ?? 0;
  }

  String _getCurrentYearMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // ===========================================================================
  // USER PROFILES
  // ===========================================================================

  /// Get the user profile (there's only one)
  Future<UserProfile?> getUserProfile() =>
      (select(userProfiles)..limit(1)).getSingleOrNull();

  /// Insert a new user profile
  Future<int> insertUserProfile(UserProfilesCompanion profile) =>
      into(userProfiles).insert(profile);

  /// Update user profile
  Future<bool> updateUserProfile(UserProfilesCompanion profile) =>
      update(userProfiles).replace(profile);

  /// Upsert user profile (create or update)
  Future<void> upsertUserProfile(UserProfilesCompanion profile) async {
    final existing = await getUserProfile();
    if (existing != null) {
      await (update(userProfiles)..where((t) => t.id.equals(existing.id)))
          .write(profile.copyWith(updatedAt: Value(DateTime.now())));
    } else {
      await insertUserProfile(profile);
    }
  }

  /// Delete user profile
  Future<int> deleteUserProfile(String id) =>
      (delete(userProfiles)..where((t) => t.id.equals(id))).go();

  // ===========================================================================
  // FEDERATIONS
  // ===========================================================================

  /// Get all federations for a profile
  Future<List<Federation>> getFederationsForProfile(String profileId) =>
      (select(federations)
            ..where((t) => t.profileId.equals(profileId))
            ..orderBy([(t) => OrderingTerm.desc(t.isPrimary), (t) => OrderingTerm.asc(t.federationName)]))
          .get();

  /// Get federation by ID
  Future<Federation?> getFederation(String id) =>
      (select(federations)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Insert a new federation
  Future<int> insertFederation(FederationsCompanion federation) =>
      into(federations).insert(federation);

  /// Update federation
  Future<bool> updateFederation(FederationsCompanion federation) =>
      update(federations).replace(federation);

  /// Delete federation
  Future<int> deleteFederation(String id) =>
      (delete(federations)..where((t) => t.id.equals(id))).go();

  /// Set a federation as primary (unsets others)
  Future<void> setPrimaryFederation(String federationId, String profileId) async {
    // Unset all as primary
    await (update(federations)..where((t) => t.profileId.equals(profileId)))
        .write(const FederationsCompanion(isPrimary: Value(false)));
    // Set the selected one as primary
    await (update(federations)..where((t) => t.id.equals(federationId)))
        .write(const FederationsCompanion(isPrimary: Value(true)));
  }

  /// Delete all federations for a profile
  Future<int> deleteFederationsForProfile(String profileId) =>
      (delete(federations)..where((t) => t.profileId.equals(profileId))).go();

  // ===========================================================================
  // CLASSIFICATIONS
  // ===========================================================================

  /// Get all classifications for a profile
  Future<List<Classification>> getClassificationsForProfile(String profileId) =>
      (select(classifications)
            ..where((t) => t.profileId.equals(profileId))
            ..orderBy([(t) => OrderingTerm.asc(t.classificationScope), (t) => OrderingTerm.asc(t.classification)]))
          .get();

  /// Get classifications by scope (indoor/outdoor)
  Future<List<Classification>> getClassificationsByScope(String profileId, String scope) =>
      (select(classifications)
            ..where((t) => t.profileId.equals(profileId) & t.classificationScope.equals(scope)))
          .get();

  /// Get classification by ID
  Future<Classification?> getClassification(String id) =>
      (select(classifications)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Get a specific classification for a profile by classification code, scope, and bowstyle
  Future<Classification?> getClassificationForProfileAndCode(
    String profileId,
    String classificationCode,
    String scope,
    String bowstyle,
  ) =>
      (select(classifications)..where((t) =>
          t.profileId.equals(profileId) &
          t.classification.equals(classificationCode) &
          t.classificationScope.equals(scope) &
          t.bowstyle.equals(bowstyle)))
      .getSingleOrNull();

  /// Get the highest claimed classification for a profile and scope
  Future<Classification?> getHighestClaimedClassification(String profileId, String scope) async {
    final claimed = await (select(classifications)
          ..where((t) =>
              t.profileId.equals(profileId) &
              t.classificationScope.equals(scope) &
              t.isClaimed.equals(true)))
        .get();

    if (claimed.isEmpty) return null;

    // Classification order: GMB < MB < B1 < B2 < B3 < A1 < A2 < A3
    // Lower index = higher classification
    const order = ['GMB', 'MB', 'B1', 'B2', 'B3', 'A1', 'A2', 'A3'];
    claimed.sort((a, b) {
      final aIndex = order.indexOf(a.classification);
      final bIndex = order.indexOf(b.classification);
      return aIndex.compareTo(bIndex);
    });

    return claimed.first;
  }

  /// Insert a new classification
  Future<int> insertClassification(ClassificationsCompanion classification) =>
      into(classifications).insert(classification);

  /// Update classification
  Future<bool> updateClassification(ClassificationsCompanion classification) =>
      update(classifications).replace(classification);

  /// Update classification with second score (completing the achievement)
  Future<int> updateClassificationSecondScore({
    required String classificationId,
    required String sessionId,
    required int score,
    required String roundId,
  }) =>
      (update(classifications)..where((t) => t.id.equals(classificationId))).write(
        ClassificationsCompanion(
          secondSessionId: Value(sessionId),
          secondAchievedAt: Value(DateTime.now()),
          secondScore: Value(score),
          secondRoundId: Value(roundId),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Claim a classification (user confirms they want to claim it)
  Future<int> claimClassification(String classificationId) =>
      (update(classifications)..where((t) => t.id.equals(classificationId))).write(
        ClassificationsCompanion(
          isClaimed: const Value(true),
          claimedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Delete classification
  Future<int> deleteClassification(String id) =>
      (delete(classifications)..where((t) => t.id.equals(id))).go();

  /// Delete all classifications for a profile
  Future<int> deleteClassificationsForProfile(String profileId) =>
      (delete(classifications)..where((t) => t.profileId.equals(profileId))).go();

  // ===========================================================================
  // ACHIEVEMENTS
  // ===========================================================================

  /// Get all achievements ordered by date (newest first)
  Future<List<Achievement>> getAllAchievements() =>
      (select(achievements)..orderBy([(t) => OrderingTerm.desc(t.earnedAt)])).get();

  /// Get achievements by type
  Future<List<Achievement>> getAchievementsByType(String type) =>
      (select(achievements)
            ..where((t) => t.achievementType.equals(type))
            ..orderBy([(t) => OrderingTerm.desc(t.earnedAt)]))
          .get();

  /// Get recent achievements (limit count)
  Future<List<Achievement>> getRecentAchievements({int limit = 10}) =>
      (select(achievements)
            ..orderBy([(t) => OrderingTerm.desc(t.earnedAt)])
            ..limit(limit))
          .get();

  /// Check if achievement exists (for deduplication)
  Future<Achievement?> getAchievement(String achievementType, {String? roundTypeId, int? score}) async {
    if (roundTypeId != null && score != null) {
      // For PBs, check exact match
      return (select(achievements)
            ..where((t) =>
                t.achievementType.equals(achievementType) &
                t.roundTypeId.equals(roundTypeId) &
                t.score.equals(score)))
          .getSingleOrNull();
    } else {
      // For streaks/milestones, check by type only
      return (select(achievements)..where((t) => t.achievementType.equals(achievementType)))
          .getSingleOrNull();
    }
  }

  /// Get best PB for a round type
  Future<Achievement?> getBestPbForRound(String roundTypeId) =>
      (select(achievements)
            ..where((t) =>
                t.roundTypeId.equals(roundTypeId) &
                (t.achievementType.equals('personalBest') | t.achievementType.equals('competitionPb')))
            ..orderBy([(t) => OrderingTerm.desc(t.score)])
            ..limit(1))
          .getSingleOrNull();

  /// Insert achievement
  Future<int> insertAchievement(AchievementsCompanion achievement) =>
      into(achievements).insert(achievement, mode: InsertMode.insertOrIgnore);

  /// Delete achievement
  Future<int> deleteAchievement(String id) =>
      (delete(achievements)..where((t) => t.id.equals(id))).go();

  /// Delete all achievements
  Future<int> deleteAllAchievements() => delete(achievements).go();

  // ===========================================================================
  // ENTITLEMENTS
  // ===========================================================================

  /// Get the user's entitlement (there's only one)
  Future<Entitlement?> getEntitlement() =>
      (select(entitlements)..limit(1)).getSingleOrNull();

  /// Insert a new entitlement
  Future<int> insertEntitlement(EntitlementsCompanion entitlement) =>
      into(entitlements).insert(entitlement);

  /// Update entitlement
  Future<bool> updateEntitlement(EntitlementsCompanion entitlement) =>
      update(entitlements).replace(entitlement);

  /// Upsert entitlement (create or update)
  Future<void> upsertEntitlement(EntitlementsCompanion entitlement) async {
    final existing = await getEntitlement();
    if (existing != null) {
      await (update(entitlements)..where((t) => t.id.equals(existing.id)))
          .write(entitlement.copyWith(updatedAt: Value(DateTime.now())));
    } else {
      await insertEntitlement(entitlement);
    }
  }

  /// Delete entitlement
  Future<int> deleteEntitlement(String id) =>
      (delete(entitlements)..where((t) => t.id.equals(id))).go();

  // ===========================================================================
  // COURSE PROGRESS
  // ===========================================================================

  /// Get all course progress entries
  Future<List<CourseProgressData>> getAllCourseProgress() =>
      select(courseProgress).get();

  /// Get progress for a specific course
  Future<List<CourseProgressData>> getCourseProgressForCourse(String courseId) =>
      (select(courseProgress)..where((t) => t.courseId.equals(courseId))).get();

  /// Get progress for a specific lesson
  Future<CourseProgressData?> getLessonProgress(String courseId, String lessonId) =>
      (select(courseProgress)
            ..where((t) => t.courseId.equals(courseId) & t.lessonId.equals(lessonId)))
          .getSingleOrNull();

  /// Insert course progress
  Future<int> insertCourseProgress(CourseProgressCompanion progress) =>
      into(courseProgress).insert(progress);

  /// Update course progress
  Future<bool> updateCourseProgress(CourseProgressCompanion progress) =>
      update(courseProgress).replace(progress);

  /// Upsert lesson progress
  Future<void> upsertLessonProgress({
    required String courseId,
    required String lessonId,
    required int progressSeconds,
    required int durationSeconds,
    bool? isCompleted,
  }) async {
    final existing = await getLessonProgress(courseId, lessonId);
    final now = DateTime.now();
    final completed = isCompleted ?? (progressSeconds >= durationSeconds - 5);

    if (existing != null) {
      await (update(courseProgress)..where((t) => t.id.equals(existing.id)))
          .write(CourseProgressCompanion(
        progressSeconds: Value(progressSeconds),
        isCompleted: Value(completed),
        lastWatchedAt: Value(now),
        completedAt: completed ? Value(now) : const Value.absent(),
      ));
    } else {
      await insertCourseProgress(CourseProgressCompanion.insert(
        id: UniqueId.withPrefix('cp'),
        courseId: courseId,
        lessonId: lessonId,
        progressSeconds: Value(progressSeconds),
        durationSeconds: durationSeconds,
        isCompleted: Value(completed),
        lastWatchedAt: Value(now),
        completedAt: completed ? Value(now) : const Value.absent(),
      ));
    }
  }

  /// Get completed lessons count for a course
  Future<int> getCompletedLessonsCount(String courseId) async {
    final progress = await getCourseProgressForCourse(courseId);
    return progress.where((p) => p.isCompleted).length;
  }

  // ===========================================================================
  // PURCHASES
  // ===========================================================================

  /// Get all purchases
  Future<List<Purchase>> getAllPurchases() =>
      (select(purchases)..orderBy([(t) => OrderingTerm.desc(t.purchasedAt)])).get();

  /// Get purchase by product ID
  Future<Purchase?> getPurchaseByProductId(String productId) =>
      (select(purchases)..where((t) => t.productId.equals(productId))).getSingleOrNull();

  /// Check if product is purchased
  Future<bool> isProductPurchased(String productId) async {
    final purchase = await getPurchaseByProductId(productId);
    return purchase != null;
  }

  /// Insert a purchase
  Future<int> insertPurchase(PurchasesCompanion purchase) =>
      into(purchases).insert(purchase);

  /// Delete a purchase
  Future<int> deletePurchase(String id) =>
      (delete(purchases)..where((t) => t.id.equals(id))).go();

  // ===========================================================================
  // SYNC SYSTEM
  // ===========================================================================

  /// Clear all user data on logout (Bug #1 fix: account switching data leak)
  Future<void> clearAllUserData() async {
    await transaction(() async {
      // Clear all user data tables (order matters for foreign keys)
      await delete(arrows).go();
      await delete(ends).go();
      await delete(sessions).go();
      await delete(importedScores).go();
      await delete(shafts).go();
      await delete(quivers).go();
      await delete(sightMarks).go();
      await delete(sightMarkPreferencesTable).go();
      await delete(stabilizers).go();
      await delete(bowStrings).go();
      await delete(fingerTabs).go();
      await delete(bows).go();
      await delete(volumeEntries).go();
      await delete(volumeImports).go();
      await delete(olyTrainingLogs).go();
      await delete(userTrainingProgress).go();
      await delete(breathTrainingLogs).go();
      await delete(milestones).go();
      await delete(kitSnapshots).go();
      await delete(tuningSessions).go();
      await delete(skillLevels).go();
      await delete(xpHistory).go();
      await delete(registeredTargets).go();
      await delete(autoPlotUsage).go();
      await delete(federations).go();
      await delete(userProfiles).go();
      await delete(entitlements).go();
      await delete(courseProgress).go();
      await delete(purchases).go();
      await delete(syncQueue).go();
      await delete(syncMetadata).go();
      // Re-seed skill levels for the new user
      await _seedSkillLevels();
    });
  }

  /// Enqueue a sync operation for later processing
  Future<int> enqueueSyncOp({
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
  }) =>
      into(syncQueue).insert(
        SyncQueueCompanion.insert(
          id: UniqueId.withPrefix('sq'),
          entityType: entityType,
          entityId: entityId,
          operation: operation,
          payload: payload,
        ),
      );

  /// Get all pending sync operations ordered by creation time
  Future<List<SyncQueueData>> getPendingOperations() =>
      (select(syncQueue)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();

  /// Get pending operations with retry count under limit
  Future<List<SyncQueueData>> getRetryableOperations({int maxRetries = 5}) =>
      (select(syncQueue)
            ..where((t) => t.retryCount.isSmallerThanValue(maxRetries))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// Remove a completed sync operation from the queue
  Future<int> removeSyncOperation(String id) =>
      (delete(syncQueue)..where((t) => t.id.equals(id))).go();

  /// Mark a sync operation as attempted (for retry tracking)
  Future<int> markSyncOperationAttempted(String id, String? error) async {
    // Fetch current retry count and increment
    final op = await (select(syncQueue)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (op == null) return 0;

    return (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        retryCount: Value(op.retryCount + 1),
        lastAttemptAt: Value(DateTime.now()),
        lastError: Value(error),
      ),
    );
  }

  /// Clear all sync operations (after successful full sync)
  Future<int> clearSyncQueue() => delete(syncQueue).go();

  /// Get sync metadata for an entity type
  Future<SyncMetadataData?> getSyncMetadata(String entityType) =>
      (select(syncMetadata)..where((t) => t.entityType.equals(entityType)))
          .getSingleOrNull();

  /// Update sync metadata for an entity type
  Future<void> updateSyncMetadata(String entityType, DateTime syncedAt) async {
    await into(syncMetadata).insertOnConflictUpdate(
      SyncMetadataCompanion.insert(
        entityType: entityType,
        lastSyncedAt: Value(syncedAt),
      ),
    );
  }

  // ===========================================================================
  // FIELD ARCHERY
  // ===========================================================================

  /// Get all field courses
  Future<List<FieldCourse>> getAllFieldCourses() =>
      (select(fieldCourses)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Get field courses by venue
  Future<List<FieldCourse>> getFieldCoursesByVenue(String venueId) =>
      (select(fieldCourses)
            ..where((t) =>
                t.venueId.equals(venueId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Get field courses by round type
  Future<List<FieldCourse>> getFieldCoursesByRoundType(String roundType) =>
      (select(fieldCourses)
            ..where((t) =>
                t.roundType.equals(roundType) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Get a specific field course
  Future<FieldCourse?> getFieldCourse(String id) =>
      (select(fieldCourses)
            ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
          .getSingleOrNull();

  /// Insert a new field course
  Future<int> insertFieldCourse(FieldCoursesCompanion course) =>
      into(fieldCourses).insert(course);

  /// Update a field course
  Future<bool> updateFieldCourse(FieldCoursesCompanion course) =>
      update(fieldCourses).replace(course);

  /// Soft delete a field course
  Future<int> softDeleteFieldCourse(String id) =>
      (update(fieldCourses)..where((t) => t.id.equals(id)))
          .write(FieldCoursesCompanion(deletedAt: Value(DateTime.now())));

  /// Restore a soft-deleted field course
  Future<int> restoreFieldCourse(String id) =>
      (update(fieldCourses)..where((t) => t.id.equals(id)))
          .write(const FieldCoursesCompanion(deletedAt: Value(null)));

  /// Permanently delete a field course and all its targets
  Future<void> deleteFieldCourse(String id) async {
    await transaction(() async {
      // Get target IDs
      final targets = await getFieldCourseTargets(id);
      final targetIds = targets.map((t) => t.id).toList();

      // Delete sight marks for targets
      if (targetIds.isNotEmpty) {
        await (delete(fieldCourseSightMarks)
              ..where((t) => t.courseTargetId.isIn(targetIds)))
            .go();
      }

      // Delete targets
      await (delete(fieldCourseTargets)
            ..where((t) => t.courseId.equals(id)))
          .go();

      // Delete course
      await (delete(fieldCourses)..where((t) => t.id.equals(id))).go();
    });
  }

  /// Get targets for a field course
  Future<List<FieldCourseTarget>> getFieldCourseTargets(String courseId) =>
      (select(fieldCourseTargets)
            ..where((t) => t.courseId.equals(courseId))
            ..orderBy([(t) => OrderingTerm.asc(t.targetNumber)]))
          .get();

  /// Get a specific target
  Future<FieldCourseTarget?> getFieldCourseTarget(String id) =>
      (select(fieldCourseTargets)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Insert a field course target
  Future<int> insertFieldCourseTarget(FieldCourseTargetsCompanion target) =>
      into(fieldCourseTargets).insert(target);

  /// Update a field course target
  Future<bool> updateFieldCourseTarget(FieldCourseTargetsCompanion target) =>
      update(fieldCourseTargets).replace(target);

  /// Delete a field course target
  Future<int> deleteFieldCourseTarget(String id) async {
    // Delete sight marks for this target first
    await (delete(fieldCourseSightMarks)
          ..where((t) => t.courseTargetId.equals(id)))
        .go();
    return (delete(fieldCourseTargets)..where((t) => t.id.equals(id))).go();
  }

  /// Get sight marks for a course target and bow
  Future<List<FieldCourseSightMark>> getFieldCourseSightMarks(
    String courseTargetId,
    String bowId,
  ) =>
      (select(fieldCourseSightMarks)
            ..where((t) =>
                t.courseTargetId.equals(courseTargetId) &
                t.bowId.equals(bowId))
            ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
          .get();

  /// Get the most recent sight mark for a course target and bow
  Future<FieldCourseSightMark?> getLatestFieldCourseSightMark(
    String courseTargetId,
    String bowId,
  ) =>
      (select(fieldCourseSightMarks)
            ..where((t) =>
                t.courseTargetId.equals(courseTargetId) &
                t.bowId.equals(bowId))
            ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
            ..limit(1))
          .getSingleOrNull();

  /// Insert or update a field course sight mark
  Future<void> upsertFieldCourseSightMark(
    FieldCourseSightMarksCompanion mark,
  ) async {
    await into(fieldCourseSightMarks).insertOnConflictUpdate(mark);
  }

  /// Insert a field course sight mark
  Future<int> insertFieldCourseSightMark(
    FieldCourseSightMarksCompanion mark,
  ) =>
      into(fieldCourseSightMarks).insert(mark);

  /// Get all sight marks for a bow across all courses
  Future<List<FieldCourseSightMark>> getAllFieldCourseSightMarksForBow(
    String bowId,
  ) =>
      (select(fieldCourseSightMarks)
            ..where((t) => t.bowId.equals(bowId))
            ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
          .get();

  /// Get field session targets for a session
  Future<List<FieldSessionTarget>> getFieldSessionTargets(String sessionId) =>
      (select(fieldSessionTargets)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([(t) => OrderingTerm.asc(t.targetNumber)]))
          .get();

  /// Get a specific field session target
  Future<FieldSessionTarget?> getFieldSessionTarget(String id) =>
      (select(fieldSessionTargets)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Insert a field session target
  Future<int> insertFieldSessionTarget(FieldSessionTargetsCompanion target) =>
      into(fieldSessionTargets).insert(target);

  /// Update a field session target
  Future<bool> updateFieldSessionTarget(FieldSessionTargetsCompanion target) =>
      update(fieldSessionTargets).replace(target);

  /// Delete field session targets for a session
  Future<int> deleteFieldSessionTargets(String sessionId) =>
      (delete(fieldSessionTargets)..where((t) => t.sessionId.equals(sessionId)))
          .go();

  /// Get field session metadata
  Future<FieldSessionMetaData?> getFieldSessionMeta(String sessionId) =>
      (select(fieldSessionMeta)..where((t) => t.sessionId.equals(sessionId)))
          .getSingleOrNull();

  /// Insert field session metadata
  Future<int> insertFieldSessionMeta(FieldSessionMetaCompanion meta) =>
      into(fieldSessionMeta).insert(meta);

  /// Update field session metadata
  Future<bool> updateFieldSessionMeta(FieldSessionMetaCompanion meta) =>
      update(fieldSessionMeta).replace(meta);

  /// Delete field session metadata
  Future<int> deleteFieldSessionMeta(String sessionId) =>
      (delete(fieldSessionMeta)..where((t) => t.sessionId.equals(sessionId)))
          .go();

  /// Get all field courses for sync
  Future<List<FieldCourse>> getAllFieldCoursesForSync() =>
      (select(fieldCourses)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// Get all field course targets for sync
  Future<List<FieldCourseTarget>> getAllFieldCourseTargetsForSync() =>
      select(fieldCourseTargets).get();

  /// Get all field course sight marks for sync
  Future<List<FieldCourseSightMark>> getAllFieldCourseSightMarksForSync() =>
      select(fieldCourseSightMarks).get();

  /// Get all field session targets for sync
  Future<List<FieldSessionTarget>> getAllFieldSessionTargetsForSync() =>
      select(fieldSessionTargets).get();

  /// Get all field session meta for sync
  Future<List<FieldSessionMetaData>> getAllFieldSessionMetaForSync() =>
      select(fieldSessionMeta).get();

  // ===========================================================================
  // SYNC (continued)
  // ===========================================================================

  /// Get all data for sync (including soft-deleted items)
  Future<List<Session>> getAllSessionsForSync() =>
      (select(sessions)..orderBy([(t) => OrderingTerm.desc(t.startedAt)])).get();

  Future<List<Bow>> getAllBowsForSync() =>
      (select(bows)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<List<Quiver>> getAllQuiversForSync() =>
      (select(quivers)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<List<Shaft>> getAllShaftsForSync() =>
      select(shafts).get();

  Future<List<ImportedScore>> getAllImportedScoresForSync() =>
      (select(importedScores)..orderBy([(t) => OrderingTerm.desc(t.date)])).get();

  Future<List<VolumeEntry>> getAllVolumeEntriesForSync() =>
      (select(volumeEntries)..orderBy([(t) => OrderingTerm.desc(t.date)])).get();

  Future<List<OlyTrainingLog>> getAllOlyTrainingLogsForSync() =>
      (select(olyTrainingLogs)..orderBy([(t) => OrderingTerm.desc(t.completedAt)])).get();

  Future<List<BreathTrainingLog>> getAllBreathTrainingLogsForSync() =>
      (select(breathTrainingLogs)..orderBy([(t) => OrderingTerm.desc(t.completedAt)])).get();

  Future<List<Milestone>> getAllMilestonesForSync() =>
      (select(milestones)..orderBy([(t) => OrderingTerm.asc(t.date)])).get();

  Future<List<SightMark>> getAllSightMarksForSync() =>
      (select(sightMarks)..orderBy([(t) => OrderingTerm.asc(t.distance)])).get();

  Future<List<Federation>> getAllFederationsForSync() =>
      select(federations).get();

  Future<List<End>> getAllEndsForSync() =>
      (select(ends)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();

  Future<List<Arrow>> getAllArrowsForSync() =>
      (select(arrows)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
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
