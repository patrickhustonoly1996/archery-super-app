import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../models/field_course.dart' as model;
import '../models/field_course_target.dart' as model;
import '../models/field_scoring.dart';
import '../models/sight_mark.dart';
import '../utils/unique_id.dart';

/// State for animal round walk-up scoring
class AnimalRoundState {
  final int currentStation; // 1, 2, or 3
  final List<AnimalArrowScore> arrowsShot;
  final bool isComplete;
  final int? scoringStation; // Which station got the first hit

  const AnimalRoundState({
    this.currentStation = 1,
    this.arrowsShot = const [],
    this.isComplete = false,
    this.scoringStation,
  });

  AnimalRoundState copyWith({
    int? currentStation,
    List<AnimalArrowScore>? arrowsShot,
    bool? isComplete,
    int? scoringStation,
  }) {
    return AnimalRoundState(
      currentStation: currentStation ?? this.currentStation,
      arrowsShot: arrowsShot ?? this.arrowsShot,
      isComplete: isComplete ?? this.isComplete,
      scoringStation: scoringStation ?? this.scoringStation,
    );
  }
}

/// Provider for field archery session management
class FieldSessionProvider extends ChangeNotifier {
  final AppDatabase _db;

  FieldSessionProvider(this._db);

  // Current session state
  String? _sessionId;
  String? get sessionId => _sessionId;

  model.FieldCourse? _course;
  model.FieldCourse? get course => _course;

  model.model.FieldRoundType? _roundType;
  model.model.FieldRoundType? get roundType => _roundType;

  int _currentTargetNumber = 1;
  int get currentTargetNumber => _currentTargetNumber;

  bool _isNewCourseCreation = false;
  bool get isNewCourseCreation => _isNewCourseCreation;

  // Track targets defined during new course creation
  final List<model.FieldCourseTarget> _newCourseTargets = [];
  List<model.FieldCourseTarget> get newCourseTargets => List.unmodifiable(_newCourseTargets);

  // Scored targets for current session
  final List<FieldTargetScore> _scoredTargets = [];
  List<FieldTargetScore> get scoredTargets => List.unmodifiable(_scoredTargets);

  // Animal round state
  AnimalRoundState? _animalState;
  AnimalRoundState? get animalState => _animalState;

  // Running totals
  int get totalScore => _scoredTargets.fold(0, (sum, t) => sum + t.totalScore);
  int get totalXs => _scoredTargets.fold(0, (sum, t) => sum + t.xCount);

  // Session progress
  int get targetCount => _course?.targetCount ?? 28;
  int get completedTargets => _scoredTargets.length;
  bool get isSessionComplete => completedTargets >= targetCount;

  /// Get current target configuration
  model.FieldCourseTarget? get currentTarget {
    if (_course == null) return null;
    return _course!.getTarget(_currentTargetNumber);
  }

  // ===========================================================================
  // SESSION LIFECYCLE
  // ===========================================================================

  /// Start a new field session with an existing course
  Future<void> startSessionWithCourse({
    required model.FieldCourse course,
    required String bowId,
    String? quiverId,
  }) async {
    _sessionId = UniqueId.withPrefix('fs');
    _course = course;
    _roundType = course.roundType;
    _currentTargetNumber = 1;
    _isNewCourseCreation = false;
    _scoredTargets.clear();
    _newCourseTargets.clear();

    if (_roundType == model.FieldRoundType.animal) {
      _animalState = const AnimalRoundState();
    }

    // Create session in database
    await _db.insertSession(SessionsCompanion.insert(
      id: _sessionId!,
      roundTypeId: _getFieldRoundTypeId(course.roundType),
      sessionType: const Value('practice'),
      bowId: Value(bowId),
      quiverId: Value(quiverId),
    ));

    // Create field session metadata
    await _db.insertFieldSessionMeta(FieldSessionMetaCompanion.insert(
      sessionId: _sessionId!,
      courseId: Value(course.id),
      roundType: course.roundType.name,
    ));

    notifyListeners();
  }

  /// Start a new field session with course creation
  Future<void> startSessionNewCourse({
    required model.FieldRoundType roundType,
    required String bowId,
    String? quiverId,
    String? venueId,
    String courseName = 'New Course',
  }) async {
    _sessionId = UniqueId.withPrefix('fs');
    _roundType = roundType;
    _currentTargetNumber = 1;
    _isNewCourseCreation = true;
    _scoredTargets.clear();
    _newCourseTargets.clear();

    if (roundType == model.FieldRoundType.animal) {
      _animalState = const AnimalRoundState();
    }

    // Create placeholder course
    final courseId = UniqueId.withPrefix('fc');
    await _db.insertFieldCourse(FieldCoursesCompanion.insert(
      id: courseId,
      name: courseName,
      venueId: Value(venueId),
      roundType: roundType.name,
    ));

    // Load the course
    final dbCourse = await _db.getFieldCourse(courseId);
    if (dbCourse != null) {
      _course = model.FieldCourse(
        id: dbCourse.id,
        name: dbCourse.name,
        venueId: dbCourse.venueId,
        roundType: model.FieldRoundType.fromString(dbCourse.roundType),
        targetCount: dbCourse.targetCount,
        notes: dbCourse.notes,
        targets: [],
        createdAt: dbCourse.createdAt,
      );
    }

    // Create session in database
    await _db.insertSession(SessionsCompanion.insert(
      id: _sessionId!,
      roundTypeId: _getFieldRoundTypeId(roundType),
      sessionType: const Value('practice'),
      bowId: Value(bowId),
      quiverId: Value(quiverId),
    ));

    // Create field session metadata
    await _db.insertFieldSessionMeta(FieldSessionMetaCompanion.insert(
      sessionId: _sessionId!,
      courseId: Value(courseId),
      roundType: roundType.name,
      isNewCourseCreation: const Value(true),
    ));

    notifyListeners();
  }

  /// Get the round type ID for standard rounds
  String _getFieldRoundTypeId(model.FieldRoundType type) {
    switch (type) {
      case model.FieldRoundType.field:
        return 'ifaa_field';
      case model.FieldRoundType.hunter:
        return 'ifaa_hunter';
      case model.FieldRoundType.expert:
        return 'ifaa_expert';
      case model.FieldRoundType.animal:
        return 'nfaa_animal_28';
      case model.FieldRoundType.marked3dStandard:
        return 'nfaa_field_28';
      case model.FieldRoundType.marked3dHunting:
        return 'nfaa_hunter_28';
    }
  }

  // ===========================================================================
  // TARGET DEFINITION (NEW COURSE CREATION)
  // ===========================================================================

  /// Define a target during new course creation
  Future<void> defineTarget({
    required model.PegConfiguration pegConfig,
    required int faceSize,
    String? notes,
  }) async {
    if (_course == null || !_isNewCourseCreation) return;

    final targetId = UniqueId.withPrefix('fct');

    // Determine arrows required
    int arrowsRequired;
    switch (_roundType!) {
      case model.FieldRoundType.animal:
        arrowsRequired = 3;
        break;
      case model.FieldRoundType.marked3dStandard:
        arrowsRequired = 2;
        break;
      case model.FieldRoundType.marked3dHunting:
        arrowsRequired = 1;
        break;
      default:
        arrowsRequired = 4;
    }

    // Save to database
    await _db.insertmodel.FieldCourseTarget(model.FieldCourseTargetsCompanion.insert(
      id: targetId,
      courseId: _course!.id,
      targetNumber: _currentTargetNumber,
      pegConfig: pegConfig.toJson(),
      faceSize: faceSize,
      primaryDistance: pegConfig.primaryDistance,
      unit: Value(pegConfig.unit.name),
      isWalkUp: Value(pegConfig.type == PegType.walkUp),
      isWalkDown: Value(pegConfig.type == PegType.walkDown),
      arrowsRequired: Value(arrowsRequired),
      notes: Value(notes),
    ));

    // Add to local tracking
    final target = model.FieldCourseTarget(
      id: targetId,
      courseId: _course!.id,
      targetNumber: _currentTargetNumber,
      pegConfig: pegConfig,
      faceSize: faceSize,
      primaryDistance: pegConfig.primaryDistance,
      unit: pegConfig.unit,
      isWalkUp: pegConfig.type == PegType.walkUp,
      isWalkDown: pegConfig.type == PegType.walkDown,
      arrowsRequired: arrowsRequired,
      notes: notes,
    );
    _newCourseTargets.add(target);

    // Update course with new target
    _course = _course!.copyWith(
      targets: List.from(_course!.targets)..add(target),
    );

    notifyListeners();
  }

  // ===========================================================================
  // SCORING - FIELD/HUNTER/EXPERT
  // ===========================================================================

  /// Score arrows for the current target (Field/Hunter/Expert rounds)
  Future<void> scoreTarget({
    required List<FieldArrowScore> arrowScores,
    String? sightMarkUsed,
  }) async {
    if (_sessionId == null || currentTarget == null) return;

    final targetScore = FieldTargetScore(
      id: UniqueId.withPrefix('fts'),
      sessionId: _sessionId!,
      courseTargetId: currentTarget!.id,
      targetNumber: _currentTargetNumber,
      totalScore: FieldTargetScore.calculateTotal(arrowScores),
      xCount: FieldTargetScore.calculateXCount(arrowScores),
      arrowScores: arrowScores,
      sightMarkUsed: sightMarkUsed,
      completedAt: DateTime.now(),
    );

    // Save to database
    await _db.insertFieldSessionTarget(FieldSessionTargetsCompanion.insert(
      id: targetScore.id,
      sessionId: _sessionId!,
      courseTargetId: Value(currentTarget!.id),
      targetNumber: _currentTargetNumber,
      arrowScores: FieldTargetScore.arrowScoresToJson(arrowScores),
      totalScore: Value(targetScore.totalScore),
      xCount: Value(targetScore.xCount),
      sightMarkUsed: Value(sightMarkUsed),
      completedAt: Value(DateTime.now()),
    ));

    _scoredTargets.add(targetScore);
    notifyListeners();
  }

  // ===========================================================================
  // SCORING - ANIMAL ROUND
  // ===========================================================================

  /// Reset animal state for a new target
  void resetAnimalState() {
    _animalState = const AnimalRoundState();
    notifyListeners();
  }

  /// Record an arrow shot in animal round
  Future<void> shootAnimalArrow(AnimalHitZone zone) async {
    if (_animalState == null || _animalState!.isComplete) return;

    final station = _animalState!.currentStation;
    final arrow = AnimalArrowScore(station: station, zone: zone);
    final newArrows = List<AnimalArrowScore>.from(_animalState!.arrowsShot)..add(arrow);

    // Check if this is a hit
    final isHit = zone != AnimalHitZone.miss;
    final isMaxStations = station >= 3;

    if (isHit) {
      // Hit - target is complete
      _animalState = _animalState!.copyWith(
        arrowsShot: newArrows,
        isComplete: true,
        scoringStation: station,
      );
    } else if (isMaxStations) {
      // Miss on station 3 - target is complete (no score)
      _animalState = _animalState!.copyWith(
        arrowsShot: newArrows,
        isComplete: true,
      );
    } else {
      // Miss - advance to next station
      _animalState = _animalState!.copyWith(
        arrowsShot: newArrows,
        currentStation: station + 1,
      );
    }

    notifyListeners();
  }

  /// Complete animal target scoring and save
  Future<void> completeAnimalTarget({String? sightMarkUsed}) async {
    if (_sessionId == null || _animalState == null) return;

    // Calculate score based on first scoring arrow
    int totalScore = 0;
    if (_animalState!.scoringStation != null) {
      final scoringArrow = _animalState!.arrowsShot.firstWhere(
        (a) => a.station == _animalState!.scoringStation && a.zone != AnimalHitZone.miss,
      );
      totalScore = scoringArrow.getScore(isFirstScoringArrow: true);
    }

    final targetId = UniqueId.withPrefix('fts');

    // Save to database
    await _db.insertFieldSessionTarget(FieldSessionTargetsCompanion.insert(
      id: targetId,
      sessionId: _sessionId!,
      courseTargetId: Value(currentTarget?.id),
      targetNumber: _currentTargetNumber,
      arrowScores: AnimalTargetScore.arrowScoresToJson(_animalState!.arrowsShot),
      totalScore: Value(totalScore),
      station: Value(_animalState!.scoringStation),
      wasHit: Value(_animalState!.scoringStation != null),
      sightMarkUsed: Value(sightMarkUsed),
      completedAt: Value(DateTime.now()),
    ));

    // Add to local tracking (using FieldTargetScore for compatibility)
    _scoredTargets.add(FieldTargetScore(
      id: targetId,
      sessionId: _sessionId!,
      courseTargetId: currentTarget?.id ?? '',
      targetNumber: _currentTargetNumber,
      totalScore: totalScore,
      arrowScores: [], // Animal uses different structure
      completedAt: DateTime.now(),
    ));

    notifyListeners();
  }

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  /// Move to the next target
  void nextTarget() {
    if (_currentTargetNumber < targetCount) {
      _currentTargetNumber++;
      if (_roundType == model.FieldRoundType.animal) {
        _animalState = const AnimalRoundState();
      }
      notifyListeners();
    }
  }

  /// Move to the previous target
  void previousTarget() {
    if (_currentTargetNumber > 1) {
      _currentTargetNumber--;
      if (_roundType == model.FieldRoundType.animal) {
        _animalState = const AnimalRoundState();
      }
      notifyListeners();
    }
  }

  /// Jump to a specific target
  void goToTarget(int targetNumber) {
    if (targetNumber >= 1 && targetNumber <= targetCount) {
      _currentTargetNumber = targetNumber;
      if (_roundType == model.FieldRoundType.animal) {
        _animalState = const AnimalRoundState();
      }
      notifyListeners();
    }
  }

  // ===========================================================================
  // SESSION COMPLETION
  // ===========================================================================

  /// Complete the current session
  Future<void> completeSession() async {
    if (_sessionId == null) return;

    // Update session with final score
    await _db.completeSession(_sessionId!, totalScore, totalXs);

    // Update field session meta
    await _db.updateFieldSessionMeta(FieldSessionMetaCompanion(
      sessionId: Value(_sessionId!),
      courseId: Value(_course?.id),
      roundType: Value(_roundType?.name ?? 'field'),
      isNewCourseCreation: Value(_isNewCourseCreation),
      currentTargetNumber: Value(_currentTargetNumber),
    ));

    notifyListeners();
  }

  /// Cancel the current session
  Future<void> cancelSession() async {
    if (_sessionId != null) {
      await _db.softDeleteSession(_sessionId!);

      // If creating a new course and we cancel, delete the course too
      if (_isNewCourseCreation && _course != null) {
        await _db.deleteFieldCourse(_course!.id);
      }
    }

    _resetState();
    notifyListeners();
  }

  void _resetState() {
    _sessionId = null;
    _course = null;
    _roundType = null;
    _currentTargetNumber = 1;
    _isNewCourseCreation = false;
    _scoredTargets.clear();
    _newCourseTargets.clear();
    _animalState = null;
  }

  /// Check if there's an active session
  bool get hasActiveSession => _sessionId != null;

  // ===========================================================================
  // SESSION LOADING
  // ===========================================================================

  /// Load an existing field session
  Future<void> loadSession(String sessionId) async {
    final meta = await _db.getFieldSessionMeta(sessionId);
    if (meta == null) return;

    _sessionId = sessionId;
    _roundType = model.FieldRoundType.fromString(meta.roundType);
    _currentTargetNumber = meta.currentTargetNumber;
    _isNewCourseCreation = meta.isNewCourseCreation;

    // Load course if available
    if (meta.courseId != null) {
      final dbCourse = await _db.getFieldCourse(meta.courseId!);
      if (dbCourse != null) {
        final targets = await _db.getmodel.FieldCourseTargets(meta.courseId!);
        _course = model.FieldCourse(
          id: dbCourse.id,
          name: dbCourse.name,
          venueId: dbCourse.venueId,
          roundType: model.FieldRoundType.fromString(dbCourse.roundType),
          targetCount: dbCourse.targetCount,
          notes: dbCourse.notes,
          targets: targets.map(_dbTargetToModel).toList(),
          createdAt: dbCourse.createdAt,
        );
      }
    }

    // Load scored targets
    final dbTargets = await _db.getFieldSessionTargets(sessionId);
    _scoredTargets.clear();
    for (final dt in dbTargets) {
      _scoredTargets.add(FieldTargetScore(
        id: dt.id,
        sessionId: dt.sessionId,
        courseTargetId: dt.courseTargetId ?? '',
        targetNumber: dt.targetNumber,
        totalScore: dt.totalScore,
        xCount: dt.xCount,
        arrowScores: dt.arrowScores.isNotEmpty
            ? FieldTargetScore.arrowScoresFromJson(dt.arrowScores)
            : [],
        sightMarkUsed: dt.sightMarkUsed,
        completedAt: dt.completedAt,
      ));
    }

    if (_roundType == model.FieldRoundType.animal) {
      _animalState = const AnimalRoundState();
    }

    notifyListeners();
  }

  model.FieldCourseTarget _dbTargetToModel(model.FieldCourseTarget dbTarget) {
    return model.FieldCourseTarget(
      id: dbTarget.id,
      courseId: dbTarget.courseId,
      targetNumber: dbTarget.targetNumber,
      pegConfig: model.PegConfiguration.fromJson(dbTarget.pegConfig),
      faceSize: dbTarget.faceSize,
      primaryDistance: dbTarget.primaryDistance,
      unit: DistanceUnit.fromString(dbTarget.unit),
      isWalkUp: dbTarget.isWalkUp,
      isWalkDown: dbTarget.isWalkDown,
      arrowsRequired: dbTarget.arrowsRequired,
      notes: dbTarget.notes,
    );
  }
}
