import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../models/field_course.dart';
import '../models/field_course_target.dart';
import '../models/sight_mark.dart';
import '../models/weather_conditions.dart';
import '../utils/unique_id.dart';
import '../utils/sight_mark_calculator.dart';
import 'sight_marks_provider.dart';

/// Course-specific sight mark with learned differential
class FieldPredictedSightMark {
  final double baseCalculation; // Standard sight mark calculation
  final double? courseDifferential; // Learned offset for this target
  final double predictedMark; // baseCalculation + courseDifferential
  final SightMarkConfidence confidence;
  final int shotCount; // Number of times shot at this target

  const FieldPredictedSightMark({
    required this.baseCalculation,
    this.courseDifferential,
    required this.predictedMark,
    required this.confidence,
    this.shotCount = 0,
  });

  /// Whether we have course-specific learning
  bool get hasCourseLearning => courseDifferential != null && shotCount > 0;

  /// Display value
  String get displayValue => predictedMark.toStringAsFixed(2);

  /// Differential display (e.g., "+0.15" or "-0.08")
  String? get differentialDisplay {
    if (courseDifferential == null) return null;
    final sign = courseDifferential! >= 0 ? '+' : '';
    return '$sign${courseDifferential!.toStringAsFixed(2)}';
  }
}

/// Provider for course-specific sight mark learning
class FieldSightMarkProvider extends ChangeNotifier {
  final AppDatabase _db;
  final SightMarksProvider _baseSightMarks;

  FieldSightMarkProvider(this._db, this._baseSightMarks);

  // Cache of course sight marks by target ID and bow ID
  final Map<String, Map<String, FieldCourseSightMark>> _courseMarks = {};

  /// Get predicted sight mark for a course target
  ///
  /// Combines base sight mark calculation with course-specific differential
  /// learned from previous shots at this target.
  Future<FieldPredictedSightMark?> getPredictedMark({
    required String courseTargetId,
    required String bowId,
    required double distance,
    required DistanceUnit unit,
  }) async {
    // Get base prediction from standard sight marks
    final basePrediction = _baseSightMarks.getPredictedMark(
      bowId: bowId,
      distance: distance,
      unit: unit,
    );

    if (basePrediction == null) {
      return null;
    }

    // Look for course-specific learning
    final courseMark = await _getLatestCourseMark(courseTargetId, bowId);

    if (courseMark == null) {
      // No course-specific data - use base prediction
      return FieldPredictedSightMark(
        baseCalculation: basePrediction.predictedValue,
        courseDifferential: null,
        predictedMark: basePrediction.predictedValue,
        confidence: basePrediction.confidence,
        shotCount: 0,
      );
    }

    // Apply course differential to base calculation
    final predictedMark = basePrediction.predictedValue + courseMark.differential;

    // Confidence increases with shot count
    final confidence = _calculateConfidence(
      basePrediction.confidence,
      courseMark.shotCount,
    );

    return FieldPredictedSightMark(
      baseCalculation: basePrediction.predictedValue,
      courseDifferential: courseMark.differential,
      predictedMark: predictedMark,
      confidence: confidence,
      shotCount: courseMark.shotCount,
    );
  }

  /// Record actual sight mark used at a target
  ///
  /// This updates the course-specific differential for future predictions.
  Future<void> recordActualMark({
    required String courseTargetId,
    required String bowId,
    required double actualMark,
    required double distance,
    required DistanceUnit unit,
    WeatherConditions? weather,
  }) async {
    // Get base calculation
    final basePrediction = _baseSightMarks.getPredictedMark(
      bowId: bowId,
      distance: distance,
      unit: unit,
    );

    final calculatedMark = basePrediction?.predictedValue ?? actualMark;
    final differential = actualMark - calculatedMark;

    // Get existing course mark if any
    final existing = await _getLatestCourseMark(courseTargetId, bowId);

    if (existing != null) {
      // Update existing - running average of differential
      final newShotCount = existing.shotCount + 1;
      // Weighted average: give more weight to recent data
      final weight = 0.3; // 30% weight to new data
      final newDifferential =
          existing.differential * (1 - weight) + differential * weight;

      await _db.insertFieldCourseSightMark(FieldCourseSightMarksCompanion.insert(
        id: UniqueId.withPrefix('fcsm'),
        courseTargetId: courseTargetId,
        bowId: bowId,
        calculatedMark: calculatedMark,
        actualMark: actualMark,
        differential: newDifferential,
        confidenceScore: Value(_confidenceFromShotCount(newShotCount)),
        weatherData: Value(weather?.toJson()),
        shotCount: Value(newShotCount),
      ));
    } else {
      // Create new course sight mark
      await _db.insertFieldCourseSightMark(FieldCourseSightMarksCompanion.insert(
        id: UniqueId.withPrefix('fcsm'),
        courseTargetId: courseTargetId,
        bowId: bowId,
        calculatedMark: calculatedMark,
        actualMark: actualMark,
        differential: differential,
        confidenceScore: Value(0.3), // Low confidence for first shot
        weatherData: Value(weather?.toJson()),
        shotCount: const Value(1),
      ));
    }

    // Clear cache
    _clearCache(courseTargetId, bowId);
    notifyListeners();
  }

  /// Get differential for a target when switching bows
  ///
  /// Returns the learned differential that can be applied to the new bow's
  /// base calculation. This captures course-specific factors (elevation,
  /// terrain, lighting) that persist across equipment changes.
  Future<double?> getTargetDifferentialForNewBow({
    required String courseTargetId,
    required String originalBowId,
    required String newBowId,
    required double distance,
    required DistanceUnit unit,
  }) async {
    // Get the learned differential from the original bow
    final originalMark = await _getLatestCourseMark(courseTargetId, originalBowId);
    if (originalMark == null || originalMark.shotCount < 2) {
      // Not enough data to transfer
      return null;
    }

    // The differential represents course-specific factors, so it can be
    // applied to the new bow's base calculation
    return originalMark.differential;
  }

  /// Get all course differentials for a bow (useful for analysis)
  Future<List<FieldCourseSightMark>> getAllMarksForBow(String bowId) async {
    return await _db.getAllFieldCourseSightMarksForBow(bowId);
  }

  /// Get marks for a specific course
  Future<List<FieldCourseSightMark>> getMarksForCourse(
    String courseId,
    String bowId,
  ) async {
    final targets = await _db.getFieldCourseTargets(courseId);
    final marks = <FieldCourseSightMark>[];

    for (final target in targets) {
      final mark = await _getLatestCourseMark(target.id, bowId);
      if (mark != null) {
        marks.add(mark);
      }
    }

    return marks;
  }

  /// Analyze sight mark differentials for a course
  Future<CourseSightMarkAnalysis?> analyzeCourse(
    String courseId,
    String bowId,
  ) async {
    final marks = await getMarksForCourse(courseId, bowId);
    if (marks.isEmpty) return null;

    final differentials = marks.map((m) => m.differential).toList();
    final avgDifferential =
        differentials.reduce((a, b) => a + b) / differentials.length;
    final totalShots = marks.fold(0, (sum, m) => sum + m.shotCount);

    // Calculate standard deviation
    final variance = differentials.fold(
            0.0, (sum, d) => sum + (d - avgDifferential) * (d - avgDifferential)) /
        differentials.length;
    final stdDev = variance > 0 ? variance.sqrt() : 0.0;

    return CourseSightMarkAnalysis(
      courseId: courseId,
      bowId: bowId,
      targetCount: marks.length,
      totalShots: totalShots,
      averageDifferential: avgDifferential,
      standardDeviation: stdDev,
      minDifferential: differentials.reduce((a, b) => a < b ? a : b),
      maxDifferential: differentials.reduce((a, b) => a > b ? a : b),
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  Future<FieldCourseSightMark?> _getLatestCourseMark(
    String courseTargetId,
    String bowId,
  ) async {
    // Check cache first
    if (_courseMarks[courseTargetId]?[bowId] != null) {
      return _courseMarks[courseTargetId]![bowId];
    }

    // Load from database
    final mark = await _db.getLatestFieldCourseSightMark(courseTargetId, bowId);
    if (mark != null) {
      _courseMarks[courseTargetId] ??= {};
      _courseMarks[courseTargetId]![bowId] = mark;
    }

    return mark;
  }

  void _clearCache(String courseTargetId, String bowId) {
    _courseMarks[courseTargetId]?.remove(bowId);
  }

  SightMarkConfidence _calculateConfidence(
    SightMarkConfidence baseConfidence,
    int shotCount,
  ) {
    // Course-specific learning boosts confidence
    if (shotCount >= 5 && baseConfidence != SightMarkConfidence.low) {
      return SightMarkConfidence.high;
    }
    if (shotCount >= 2) {
      return baseConfidence == SightMarkConfidence.low
          ? SightMarkConfidence.medium
          : baseConfidence;
    }
    return baseConfidence;
  }

  double _confidenceFromShotCount(int shotCount) {
    if (shotCount >= 10) return 0.95;
    if (shotCount >= 5) return 0.85;
    if (shotCount >= 3) return 0.7;
    if (shotCount >= 2) return 0.5;
    return 0.3;
  }
}

/// Extension for variance calculation
extension on double {
  double sqrt() {
    if (this <= 0) return 0;
    var x = this;
    var root = x / 2;
    for (var i = 0; i < 10; i++) {
      root = (root + x / root) / 2;
    }
    return root;
  }
}

/// Analysis result for course sight marks
class CourseSightMarkAnalysis {
  final String courseId;
  final String bowId;
  final int targetCount;
  final int totalShots;
  final double averageDifferential;
  final double standardDeviation;
  final double minDifferential;
  final double maxDifferential;

  const CourseSightMarkAnalysis({
    required this.courseId,
    required this.bowId,
    required this.targetCount,
    required this.totalShots,
    required this.averageDifferential,
    required this.standardDeviation,
    required this.minDifferential,
    required this.maxDifferential,
  });

  /// Whether the course has consistent differentials
  bool get isConsistent => standardDeviation < 0.2;

  /// Overall course adjustment suggestion
  String get suggestionText {
    if (averageDifferential.abs() < 0.05) {
      return 'Sightmarks match calculations well';
    }
    final direction = averageDifferential > 0 ? 'higher' : 'lower';
    return 'Typically ${averageDifferential.abs().toStringAsFixed(2)} $direction';
  }
}
