import 'dart:math' as math;
import '../db/database.dart';
import '../widgets/radar_chart.dart';
import '../theme/app_theme.dart';

/// Performance metrics for a session or aggregate of sessions
class PerformanceProfile {
  /// Percentage of arrows in gold (9-10)
  final double accuracy;

  /// Percentage of arrows in X ring
  final double xRate;

  /// Score as percentage of max possible (0-100)
  final double scorePercent;

  /// Consistency measure (0-100, higher = more consistent)
  final double consistency;

  /// Group tightness (0-100, higher = tighter groups)
  final double grouping;

  /// Number of arrows in the sample
  final int arrowCount;

  /// Number of sessions in the sample
  final int sessionCount;

  const PerformanceProfile({
    required this.accuracy,
    required this.xRate,
    required this.scorePercent,
    required this.consistency,
    required this.grouping,
    required this.arrowCount,
    required this.sessionCount,
  });

  /// Convert to radar chart data points
  List<RadarDataPoint> toRadarPoints() {
    return [
      RadarDataPoint(
        label: 'Accuracy',
        value: accuracy / 100,
        displayValue: '${accuracy.toStringAsFixed(0)}%',
      ),
      RadarDataPoint(
        label: 'X-Rate',
        value: xRate / 100,
        displayValue: '${xRate.toStringAsFixed(0)}%',
      ),
      RadarDataPoint(
        label: 'Score',
        value: scorePercent / 100,
        displayValue: '${scorePercent.toStringAsFixed(0)}%',
      ),
      RadarDataPoint(
        label: 'Consistency',
        value: consistency / 100,
        displayValue: '${consistency.toStringAsFixed(0)}%',
      ),
      RadarDataPoint(
        label: 'Grouping',
        value: grouping / 100,
        displayValue: '${grouping.toStringAsFixed(0)}%',
      ),
    ];
  }

  /// Convert to radar chart data
  RadarChartData toRadarChartData({String? label}) {
    return RadarChartData(
      label: label,
      points: toRadarPoints(),
      color: AppColors.gold,
      showFill: true,
    );
  }

  /// Empty profile for when there's no data
  static const empty = PerformanceProfile(
    accuracy: 0,
    xRate: 0,
    scorePercent: 0,
    consistency: 0,
    grouping: 0,
    arrowCount: 0,
    sessionCount: 0,
  );

  bool get hasData => arrowCount > 0;
}

/// Calculates performance profiles from session and arrow data
class PerformanceProfileCalculator {
  /// Calculate profile from a single session's arrows
  static PerformanceProfile fromSessionArrows({
    required List<Arrow> arrows,
    required int maxScore,
  }) {
    if (arrows.isEmpty) return PerformanceProfile.empty;

    final totalScore = arrows.fold<int>(0, (sum, a) => sum + a.score);
    final goldArrows = arrows.where((a) => a.score >= 9).length;
    final xArrows = arrows.where((a) => a.isX).length;

    // Calculate accuracy (% in gold)
    final accuracy = (goldArrows / arrows.length) * 100;

    // Calculate X rate
    final xRate = (xArrows / arrows.length) * 100;

    // Calculate score percentage
    final scorePercent = (totalScore / maxScore) * 100;

    // Calculate consistency from score variance
    final consistency = _calculateConsistency(arrows);

    // Calculate grouping from x,y coordinates
    final grouping = _calculateGrouping(arrows);

    return PerformanceProfile(
      accuracy: accuracy,
      xRate: xRate,
      scorePercent: scorePercent.clamp(0, 100),
      consistency: consistency,
      grouping: grouping,
      arrowCount: arrows.length,
      sessionCount: 1,
    );
  }

  /// Calculate profile from multiple sessions
  static Future<PerformanceProfile> fromSessions({
    required AppDatabase db,
    required List<Session> sessions,
    required Map<String, RoundType> roundTypes,
  }) async {
    if (sessions.isEmpty) return PerformanceProfile.empty;

    final allArrows = <Arrow>[];
    int totalMaxScore = 0;
    int totalActualScore = 0;

    for (final session in sessions) {
      final roundType = roundTypes[session.roundTypeId];
      if (roundType == null) continue;

      final arrows = await db.getArrowsForSession(session.id);
      allArrows.addAll(arrows);

      totalMaxScore += roundType.maxScore;
      totalActualScore += session.totalScore;
    }

    if (allArrows.isEmpty) return PerformanceProfile.empty;

    final goldArrows = allArrows.where((a) => a.score >= 9).length;
    final xArrows = allArrows.where((a) => a.isX).length;

    final accuracy = (goldArrows / allArrows.length) * 100;
    final xRate = (xArrows / allArrows.length) * 100;
    final scorePercent = totalMaxScore > 0
        ? (totalActualScore / totalMaxScore) * 100
        : 0.0;
    final consistency = _calculateConsistency(allArrows);
    final grouping = _calculateGrouping(allArrows);

    return PerformanceProfile(
      accuracy: accuracy,
      xRate: xRate,
      scorePercent: scorePercent.clamp(0, 100),
      consistency: consistency,
      grouping: grouping,
      arrowCount: allArrows.length,
      sessionCount: sessions.length,
    );
  }

  /// Calculate consistency from arrow scores
  /// Higher value = more consistent (less variance)
  static double _calculateConsistency(List<Arrow> arrows) {
    if (arrows.length < 2) return 100;

    final scores = arrows.map((a) => a.score.toDouble()).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;

    // Calculate standard deviation
    final squaredDiffs = scores.map((s) => math.pow(s - mean, 2));
    final variance = squaredDiffs.reduce((a, b) => a + b) / scores.length;
    final stdDev = math.sqrt(variance);

    // Convert to 0-100 scale (lower std dev = higher consistency)
    // Max possible std dev for scores 0-10 is about 5
    final normalizedStdDev = (stdDev / 5).clamp(0, 1);
    return (1 - normalizedStdDev) * 100;
  }

  /// Calculate grouping from x,y coordinates
  /// Higher value = tighter groups (smaller spread)
  static double _calculateGrouping(List<Arrow> arrows) {
    if (arrows.length < 2) return 100;

    // Filter out arrows without valid coordinates
    final validArrows = arrows.where((a) => a.x != 0 || a.y != 0).toList();
    if (validArrows.isEmpty) return 50; // Default if no coordinates

    // Calculate centroid
    final centroidX = validArrows.map((a) => a.x).reduce((a, b) => a + b) /
        validArrows.length;
    final centroidY = validArrows.map((a) => a.y).reduce((a, b) => a + b) /
        validArrows.length;

    // Calculate average distance from centroid
    final distances = validArrows.map((a) {
      final dx = a.x - centroidX;
      final dy = a.y - centroidY;
      return math.sqrt(dx * dx + dy * dy);
    });

    final avgDistance = distances.reduce((a, b) => a + b) / validArrows.length;

    // Normalize: x,y are in range -1 to 1, so max distance is sqrt(2) ≈ 1.414
    // A tight group would have avgDistance < 0.1, loose > 0.5
    final normalizedSpread = (avgDistance / 0.5).clamp(0, 1);
    return (1 - normalizedSpread) * 100;
  }

  /// Get performance profile for recent sessions (last N days)
  static Future<PerformanceProfile> getRecentProfile({
    required AppDatabase db,
    int days = 30,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final allSessions = await db.getCompletedSessions();
    final recentSessions = allSessions
        .where((s) => s.startedAt.isAfter(cutoff))
        .toList();

    final roundTypes = await db.getAllRoundTypes();
    final roundTypeMap = {for (var rt in roundTypes) rt.id: rt};

    return fromSessions(
      db: db,
      sessions: recentSessions,
      roundTypes: roundTypeMap,
    );
  }

  /// Get performance profile for best session (by score %)
  static Future<PerformanceProfile?> getBestSessionProfile({
    required AppDatabase db,
  }) async {
    final sessions = await db.getCompletedSessions();
    if (sessions.isEmpty) return null;

    final roundTypes = await db.getAllRoundTypes();
    final roundTypeMap = {for (var rt in roundTypes) rt.id: rt};

    Session? bestSession;
    double bestScorePercent = 0;

    for (final session in sessions) {
      final roundType = roundTypeMap[session.roundTypeId];
      if (roundType == null) continue;

      final scorePercent = (session.totalScore / roundType.maxScore) * 100;
      if (scorePercent > bestScorePercent) {
        bestScorePercent = scorePercent;
        bestSession = session;
      }
    }

    if (bestSession == null) return null;

    final arrows = await db.getArrowsForSession(bestSession.id);
    final roundType = roundTypeMap[bestSession.roundTypeId]!;

    return fromSessionArrows(
      arrows: arrows,
      maxScore: roundType.maxScore,
    );
  }

  /// Get average profile across all sessions
  static Future<PerformanceProfile> getAllTimeProfile({
    required AppDatabase db,
  }) async {
    final sessions = await db.getCompletedSessions();
    final roundTypes = await db.getAllRoundTypes();
    final roundTypeMap = {for (var rt in roundTypes) rt.id: rt};

    return fromSessions(
      db: db,
      sessions: sessions,
      roundTypes: roundTypeMap,
    );
  }
}
