import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../models/field_course.dart' as model;
import '../models/field_course_target.dart' as model;
import '../models/sight_mark.dart';
import '../utils/unique_id.dart';

/// Provider for field archery course management
class FieldCourseProvider extends ChangeNotifier {
  final AppDatabase _db;

  FieldCourseProvider(this._db);

  // Cached courses
  List<model.FieldCourse> _courses = [];
  List<model.FieldCourse> get courses => _courses;

  // Currently selected course
  model.FieldCourse? _selectedCourse;
  model.FieldCourse? get selectedCourse => _selectedCourse;

  // Track used pegs during course creation
  final Set<String> _usedPegConfigs = {};
  Set<String> get usedPegConfigs => _usedPegConfigs;

  /// Load all field courses
  Future<void> loadCourses() async {
    final dbCourses = await _db.getAllFieldCourses();
    final coursesWithTargets = <FieldCourse>[];

    for (final dbCourse in dbCourses) {
      final targets = await _db.getmodel.FieldCourseTargets(dbCourse.id);
      coursesWithTargets.add(_dbCourseToModel(dbCourse, targets));
    }

    _courses = coursesWithTargets;
    notifyListeners();
  }

  /// Load courses by venue
  Future<List<model.FieldCourse>> getCoursesByVenue(String venueId) async {
    final dbCourses = await _db.getFieldCoursesByVenue(venueId);
    final coursesWithTargets = <FieldCourse>[];

    for (final dbCourse in dbCourses) {
      final targets = await _db.getmodel.FieldCourseTargets(dbCourse.id);
      coursesWithTargets.add(_dbCourseToModel(dbCourse, targets));
    }

    return coursesWithTargets;
  }

  /// Load courses by round type
  Future<List<model.FieldCourse>> getCoursesByRoundType(model.FieldRoundType roundType) async {
    final dbCourses = await _db.getFieldCoursesByRoundType(roundType.name);
    final coursesWithTargets = <FieldCourse>[];

    for (final dbCourse in dbCourses) {
      final targets = await _db.getmodel.FieldCourseTargets(dbCourse.id);
      coursesWithTargets.add(_dbCourseToModel(dbCourse, targets));
    }

    return coursesWithTargets;
  }

  /// Select a course for use
  Future<void> selectCourse(String courseId) async {
    final dbCourse = await _db.getFieldCourse(courseId);
    if (dbCourse == null) {
      _selectedCourse = null;
      notifyListeners();
      return;
    }

    final targets = await _db.getmodel.FieldCourseTargets(courseId);
    _selectedCourse = _dbCourseToModel(dbCourse, targets);
    notifyListeners();
  }

  /// Clear selected course
  void clearSelection() {
    _selectedCourse = null;
    notifyListeners();
  }

  /// Create a new field course
  Future<String> createCourse({
    required String name,
    required model.FieldRoundType roundType,
    String? venueId,
    int targetCount = 28,
    String? notes,
  }) async {
    final id = UniqueId.withPrefix('fc');

    await _db.insertFieldCourse(FieldCoursesCompanion.insert(
      id: id,
      name: name,
      venueId: Value(venueId),
      roundType: roundType.name,
      targetCount: Value(targetCount),
      notes: Value(notes),
    ));

    await loadCourses();
    return id;
  }

  /// Update an existing course
  Future<void> updateCourse({
    required String id,
    String? name,
    String? venueId,
    String? notes,
  }) async {
    final existing = await _db.getFieldCourse(id);
    if (existing == null) return;

    await _db.updateFieldCourse(FieldCoursesCompanion(
      id: Value(id),
      name: Value(name ?? existing.name),
      venueId: Value(venueId ?? existing.venueId),
      roundType: Value(existing.roundType),
      targetCount: Value(existing.targetCount),
      notes: Value(notes ?? existing.notes),
      createdAt: Value(existing.createdAt),
      updatedAt: Value(DateTime.now()),
    ));

    await loadCourses();
  }

  /// Delete a course (soft delete)
  Future<void> deleteCourse(String id) async {
    await _db.softDeleteFieldCourse(id);
    await loadCourses();
  }

  /// Restore a deleted course
  Future<void> restoreCourse(String id) async {
    await _db.restoreFieldCourse(id);
    await loadCourses();
  }

  /// Permanently delete a course
  Future<void> permanentlyDeleteCourse(String id) async {
    await _db.deleteFieldCourse(id);
    await loadCourses();
  }

  // ===========================================================================
  // TARGET MANAGEMENT
  // ===========================================================================

  /// Add a target to a course
  Future<String> addTarget({
    required String courseId,
    required int targetNumber,
    required model.PegConfiguration pegConfig,
    required int faceSize,
    String? notes,
  }) async {
    final id = UniqueId.withPrefix('fct');

    // Determine arrows required based on peg type
    final course = _courses.firstWhere(
      (c) => c.id == courseId,
      orElse: () => throw Exception('Course not found'),
    );

    int arrowsRequired;
    switch (course.roundType) {
      case model.FieldRoundType.animal:
        arrowsRequired = 3; // Max 3 arrows (walk-up)
        break;
      case model.FieldRoundType.marked3dStandard:
        arrowsRequired = 2;
        break;
      case model.FieldRoundType.marked3dHunting:
        arrowsRequired = 1;
        break;
      default:
        arrowsRequired = 4; // Field, Hunter, Expert
    }

    await _db.insertmodel.FieldCourseTarget(model.FieldCourseTargetsCompanion.insert(
      id: id,
      courseId: courseId,
      targetNumber: targetNumber,
      pegConfig: pegConfig.toJson(),
      faceSize: faceSize,
      primaryDistance: pegConfig.primaryDistance,
      unit: Value(pegConfig.unit.name),
      isWalkUp: Value(pegConfig.type == model.PegType.walkUp),
      isWalkDown: Value(pegConfig.type == model.PegType.walkDown),
      arrowsRequired: Value(arrowsRequired),
      notes: Value(notes),
    ));

    // Mark peg config as used
    _usedPegConfigs.add(pegConfig.displayString);

    await loadCourses();
    return id;
  }

  /// Update a target
  Future<void> updateTarget({
    required String id,
    model.PegConfiguration? pegConfig,
    int? faceSize,
    String? notes,
  }) async {
    final existing = await _db.getmodel.FieldCourseTarget(id);
    if (existing == null) return;

    final newPegConfig = pegConfig != null
        ? pegConfig.toJson()
        : existing.pegConfig;
    final parsedConfig = model.PegConfiguration.fromJson(newPegConfig);

    await _db.updatemodel.FieldCourseTarget(model.FieldCourseTargetsCompanion(
      id: Value(id),
      courseId: Value(existing.courseId),
      targetNumber: Value(existing.targetNumber),
      pegConfig: Value(newPegConfig),
      faceSize: Value(faceSize ?? existing.faceSize),
      primaryDistance: Value(parsedConfig.primaryDistance),
      unit: Value(parsedConfig.unit.name),
      isWalkUp: Value(parsedConfig.type == model.PegType.walkUp),
      isWalkDown: Value(parsedConfig.type == model.PegType.walkDown),
      arrowsRequired: Value(existing.arrowsRequired),
      notes: Value(notes ?? existing.notes),
    ));

    await loadCourses();
  }

  /// Delete a target
  Future<void> deleteTarget(String id) async {
    await _db.deletemodel.FieldCourseTarget(id);
    await loadCourses();
  }

  // ===========================================================================
  // PEG AVAILABILITY TRACKING
  // ===========================================================================

  /// Reset used pegs (for starting a new course creation)
  void resetUsedPegs() {
    _usedPegConfigs.clear();
    notifyListeners();
  }

  /// Load used pegs from existing course targets
  Future<void> loadUsedPegsForCourse(String courseId) async {
    _usedPegConfigs.clear();
    final targets = await _db.getmodel.FieldCourseTargets(courseId);
    for (final target in targets) {
      final config = model.PegConfiguration.fromJson(target.pegConfig);
      _usedPegConfigs.add(config.displayString);
    }
    notifyListeners();
  }

  /// Check if a peg config is available
  bool isPegAvailable(model.PegConfiguration config) {
    return !_usedPegConfigs.contains(config.displayString);
  }

  /// Mark a peg as used
  void markPegUsed(model.PegConfiguration config) {
    _usedPegConfigs.add(config.displayString);
    notifyListeners();
  }

  /// Unmark a peg as used (when removing a target)
  void unmarkPegUsed(model.PegConfiguration config) {
    _usedPegConfigs.remove(config.displayString);
    notifyListeners();
  }

  /// Get available standard IFAA presets for field rounds
  List<model.PegConfiguration> getAvailableFieldPresets() {
    final presets = <model.PegConfiguration>[];
    final unit = DistanceUnit.yards;

    // Walk-down presets
    for (final distances in model.IFAAPegPresets.fieldWalkDowns) {
      final config = model.PegConfiguration.walkDown(distances, unit);
      if (isPegAvailable(config)) {
        presets.add(config);
      }
    }

    // Fan presets
    for (final distances in model.IFAAPegPresets.fieldFans) {
      final config = model.PegConfiguration.fan(distances, unit);
      if (isPegAvailable(config)) {
        presets.add(config);
      }
    }

    return presets;
  }

  /// Get available standard IFAA presets for animal rounds
  List<model.PegConfiguration> getAvailableAnimalPresets() {
    final presets = <model.PegConfiguration>[];
    final unit = DistanceUnit.yards;

    for (final distances in model.IFAAPegPresets.animalWalkUps) {
      final config = model.PegConfiguration.walkUp(distances, unit);
      if (isPegAvailable(config)) {
        presets.add(config);
      }
    }

    return presets;
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  FieldCourse _dbCourseToModel(
    FieldCourse dbCourse,
    List<model.FieldCourseTarget> dbTargets,
  ) {
    final targets = dbTargets.map(_dbTargetToModel).toList();

    return FieldCourse(
      id: dbCourse.id,
      name: dbCourse.name,
      venueId: dbCourse.venueId,
      roundType: model.FieldRoundType.fromString(dbCourse.roundType),
      targetCount: dbCourse.targetCount,
      notes: dbCourse.notes,
      targets: targets,
      createdAt: dbCourse.createdAt,
      updatedAt: dbCourse.updatedAt,
      deletedAt: dbCourse.deletedAt,
    );
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
