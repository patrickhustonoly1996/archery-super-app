import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../models/arrow_coordinate.dart';
import '../utils/field_correction_calculator.dart';
import '../utils/unique_id.dart';

/// Historical data for a specific course target
class FieldTargetHistory {
  /// Arrow coordinates from the most recent session
  final List<ArrowCoordinate> lastSessionArrows;

  /// Weighted average group centre across all sessions
  final ArrowCoordinate? averageGroupCentre;

  /// Total number of sessions where this target was scored
  final int totalSessions;

  /// Total number of arrows plotted at this target
  final int totalArrows;

  /// Visit count (how many times scored)
  final int visitCount;

  const FieldTargetHistory({
    required this.lastSessionArrows,
    this.averageGroupCentre,
    required this.totalSessions,
    required this.totalArrows,
    required this.visitCount,
  });

  /// Whether there is any historical data
  bool get hasHistory => totalArrows > 0;

  /// Whether there are ghost arrows to show
  bool get hasGhostArrows => lastSessionArrows.isNotEmpty;

  /// Whether there's a meaningful group centre
  bool get hasGroupCentre => averageGroupCentre != null;

  /// Confidence level based on visit count
  String get confidenceLabel {
    if (visitCount >= 5) return 'high';
    if (visitCount >= 2) return 'medium';
    return 'low';
  }

  /// Summary string for UI display
  String get summaryText {
    if (visitCount == 0) return 'First time at this target';
    final arrowWord = totalArrows == 1 ? 'arrow' : 'arrows';
    return '${_ordinal(visitCount + 1)} visit, $totalArrows $arrowWord logged';
  }

  static String _ordinal(int number) {
    if (number >= 11 && number <= 13) return '${number}th';
    switch (number % 10) {
      case 1: return '${number}st';
      case 2: return '${number}nd';
      case 3: return '${number}rd';
      default: return '${number}th';
    }
  }
}

/// Learned angle data for a course target peg
class LearnedAngle {
  final int pegIndex;
  final double angleDegrees;
  final int sessionCount;

  const LearnedAngle({
    required this.pegIndex,
    required this.angleDegrees,
    required this.sessionCount,
  });
}

/// Provider for field archery history overlay and course learning.
///
/// Handles:
/// - Loading historical arrow plots for ghost dot overlay
/// - Calculating average group centre across sessions
/// - Persisting and retrieving learned angles per course target
class FieldHistoryProvider extends ChangeNotifier {
  final AppDatabase _db;

  FieldHistoryProvider(this._db);

  // Cache to avoid repeated queries during a session
  final Map<String, FieldTargetHistory> _historyCache = {};
  final Map<String, List<LearnedAngle>> _angleCache = {};

  /// Get historical data for a specific course target.
  ///
  /// Returns ghost arrows (from last session), average group centre (all sessions),
  /// and visit count.
  Future<FieldTargetHistory?> getHistoryForTarget(
    String courseTargetId,
    String bowId, {
    int faceSizeCm = 65,
  }) async {
    final cacheKey = '$courseTargetId:$bowId';
    if (_historyCache.containsKey(cacheKey)) {
      return _historyCache[cacheKey];
    }

    try {
      // Get all plots for this target across all sessions
      final allPlots = await _db.getFieldArrowPlotsForTarget(courseTargetId, bowId);

      if (allPlots.isEmpty) {
        final history = FieldTargetHistory(
          lastSessionArrows: [],
          totalSessions: 0,
          totalArrows: 0,
          visitCount: 0,
        );
        _historyCache[cacheKey] = history;
        return history;
      }

      // Get plots from most recent session only (for ghost dots)
      final latestPlots = await _db.getLatestSessionFieldArrowPlots(courseTargetId, bowId);

      // Convert to ArrowCoordinates
      final lastSessionArrows = latestPlots
          .where((p) => p.xMm != null && p.yMm != null)
          .map((p) => ArrowCoordinate(
                xMm: p.xMm!,
                yMm: p.yMm!,
                faceSizeCm: faceSizeCm,
              ))
          .toList();

      // Convert all plots to coordinates for group centre calculation
      final allCoordinates = allPlots
          .where((p) => p.xMm != null && p.yMm != null)
          .map((p) => ArrowCoordinate(
                xMm: p.xMm!,
                yMm: p.yMm!,
                faceSizeCm: faceSizeCm,
              ))
          .toList();

      final isPoorShots = allPlots
          .where((p) => p.xMm != null && p.yMm != null)
          .map((p) => p.isPoorShot)
          .toList();

      // Calculate weighted group centre
      final groupCentre = FieldCorrectionCalculator.calculateWeightedGroupCentre(
        coordinates: allCoordinates,
        isPoorShot: isPoorShots,
        faceSizeCm: faceSizeCm,
      );

      // Count unique sessions
      final sessionIds = allPlots.map((p) => p.sessionTargetId).toSet();

      final history = FieldTargetHistory(
        lastSessionArrows: lastSessionArrows,
        averageGroupCentre: groupCentre,
        totalSessions: sessionIds.length,
        totalArrows: allPlots.length,
        visitCount: sessionIds.length,
      );

      _historyCache[cacheKey] = history;
      return history;
    } catch (e) {
      debugPrint('Error loading field target history: $e');
      return null;
    }
  }

  /// Get learned angles for a course target (pre-fill from previous visits).
  Future<List<LearnedAngle>> getLearnedAngles(String courseTargetId) async {
    if (_angleCache.containsKey(courseTargetId)) {
      return _angleCache[courseTargetId]!;
    }

    try {
      final dbAngles = await _db.getFieldCourseTargetAngles(courseTargetId);

      final angles = dbAngles.map((a) => LearnedAngle(
        pegIndex: a.pegIndex,
        angleDegrees: a.angleDegrees,
        sessionCount: a.sessionCount,
      )).toList();

      _angleCache[courseTargetId] = angles;
      return angles;
    } catch (e) {
      debugPrint('Error loading learned angles: $e');
      return [];
    }
  }

  /// Get pre-filled angles as a map (pegIndex -> angleDegrees) for initialization.
  Future<Map<int, double>> getPrefilledAngles(String courseTargetId) async {
    final angles = await getLearnedAngles(courseTargetId);
    return {for (final a in angles) a.pegIndex: a.angleDegrees};
  }

  /// Persist a learned angle for a course target peg.
  ///
  /// Uses running average: new = (old * count + new) / (count + 1)
  Future<void> recordAngle({
    required String courseTargetId,
    required int pegIndex,
    required double angleDegrees,
  }) async {
    try {
      final existing = await _db.getFieldCourseTargetAngle(courseTargetId, pegIndex);

      if (existing != null) {
        // Update running average
        final newCount = existing.sessionCount + 1;
        final newAvg = (existing.angleDegrees * existing.sessionCount + angleDegrees) / newCount;

        await _db.upsertFieldCourseTargetAngle(FieldCourseTargetAnglesCompanion(
          id: Value(existing.id),
          courseTargetId: Value(courseTargetId),
          pegIndex: Value(pegIndex),
          angleDegrees: Value(newAvg),
          sessionCount: Value(newCount),
          lastUpdated: Value(DateTime.now()),
        ));
      } else {
        // New record
        await _db.upsertFieldCourseTargetAngle(FieldCourseTargetAnglesCompanion(
          id: Value(UniqueId.generate()),
          courseTargetId: Value(courseTargetId),
          pegIndex: Value(pegIndex),
          angleDegrees: Value(angleDegrees),
          sessionCount: const Value(1),
          lastUpdated: Value(DateTime.now()),
        ));
      }

      // Invalidate cache
      _angleCache.remove(courseTargetId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error recording angle: $e');
    }
  }

  /// Record angles for all pegs of a completed target.
  Future<void> recordTargetAngles({
    required String courseTargetId,
    required Map<int, double> pegAngles,
  }) async {
    for (final entry in pegAngles.entries) {
      await recordAngle(
        courseTargetId: courseTargetId,
        pegIndex: entry.key,
        angleDegrees: entry.value,
      );
    }
  }

  /// Clear cache (call when switching sessions)
  void clearCache() {
    _historyCache.clear();
    _angleCache.clear();
  }
}
