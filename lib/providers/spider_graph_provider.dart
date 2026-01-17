import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../db/database.dart';
import '../utils/handicap_calculator.dart';

/// Target values for the spider graph spokes
class SpiderTargets {
  final int handicap;          // Target handicap (1 = best)
  final int arrowsPerWeek;     // Target arrows per week
  final int trainingDaysPerWeek; // Target days per week
  final int holdMinutesPerWeek;  // Target bow hold minutes per week
  final int formScore;          // Target form score (lower = better)
  final int stabilityScore;     // Target stability score (lower = better)
  final int breathHoldSeconds;  // Target breath hold
  final int breathExhaleSeconds; // Target exhale time

  const SpiderTargets({
    required this.handicap,
    required this.arrowsPerWeek,
    required this.trainingDaysPerWeek,
    required this.holdMinutesPerWeek,
    required this.formScore,
    required this.stabilityScore,
    required this.breathHoldSeconds,
    required this.breathExhaleSeconds,
  });
}

/// Data for all 8 spider graph spokes (0-100 for each, null if no data)
class SpiderData {
  final double? scoreLevel;      // Handicap-based score
  final double? trainingVolume;  // Arrows per week
  final double? trainingFrequency; // Days trained
  final double? bowFitness;      // Hold time
  final double? formQuality;     // Structure feedback
  final double? stability;       // Shaking feedback
  final double? breathHold;      // Breath hold time
  final double? breathExhale;    // Exhale time

  const SpiderData({
    this.scoreLevel,
    this.trainingVolume,
    this.trainingFrequency,
    this.bowFitness,
    this.formQuality,
    this.stability,
    this.breathHold,
    this.breathExhale,
  });

  factory SpiderData.empty() => const SpiderData();

  /// Get list of values in order for radar chart
  List<double?> get values => [
    scoreLevel,
    trainingVolume,
    trainingFrequency,
    bowFitness,
    formQuality,
    stability,
    breathHold,
    breathExhale,
  ];

  /// Get spoke labels
  static const List<String> labels = [
    'Score',
    'Volume',
    'Frequency',
    'Bow Fitness',
    'Form',
    'Stability',
    'Breath Hold',
    'Exhale',
  ];

  /// Check if any data exists
  bool get hasData => values.any((v) => v != null);

  /// Count of spokes with data
  int get dataCount => values.where((v) => v != null).length;
}

/// Provider for spider graph data calculations
class SpiderGraphProvider extends ChangeNotifier {
  final AppDatabase _db;

  // Default targets (Patrick's goals)
  static const defaultTargets = SpiderTargets(
    handicap: 1,
    arrowsPerWeek: 600,
    trainingDaysPerWeek: 7,
    holdMinutesPerWeek: 20,
    formScore: 2,
    stabilityScore: 2,
    breathHoldSeconds: 60,
    breathExhaleSeconds: 60,
  );

  // Elite targets
  static const eliteTargets = SpiderTargets(
    handicap: 1,
    arrowsPerWeek: 800,
    trainingDaysPerWeek: 7,
    holdMinutesPerWeek: 37,
    formScore: 2,
    stabilityScore: 2,
    breathHoldSeconds: 60,
    breathExhaleSeconds: 60,
  );

  SpiderTargets _targets = defaultTargets;
  SpiderTargets get targets => _targets;

  int _timeWindowDays = 7;
  int get timeWindowDays => _timeWindowDays;

  SpiderData _data = SpiderData.empty();
  SpiderData get data => _data;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _useEliteTargets = false;
  bool get useEliteTargets => _useEliteTargets;

  SpiderGraphProvider(this._db);

  /// Set time window and reload
  void setTimeWindow(int days) {
    if (days != _timeWindowDays) {
      _timeWindowDays = days;
      loadData();
    }
  }

  /// Toggle between default and elite targets
  void setEliteMode(bool elite) {
    _useEliteTargets = elite;
    _targets = elite ? eliteTargets : defaultTargets;
    loadData();
  }

  /// Load all spider graph data
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final cutoff = DateTime.now().subtract(Duration(days: _timeWindowDays));

      // Load all data in parallel
      final results = await Future.wait([
        _calculateScoreLevel(cutoff),
        _calculateTrainingVolume(cutoff),
        _calculateTrainingFrequency(cutoff),
        _calculateBowFitness(cutoff),
        _calculateFormQuality(cutoff),
        _calculateStability(cutoff),
        _calculateBreathHold(cutoff),
        _calculateBreathExhale(cutoff),
      ]);

      _data = SpiderData(
        scoreLevel: results[0],
        trainingVolume: results[1],
        trainingFrequency: results[2],
        bowFitness: results[3],
        formQuality: results[4],
        stability: results[5],
        breathHold: results[6],
        breathExhale: results[7],
      );
    } catch (e) {
      debugPrint('Error loading spider graph data: $e');
      _data = SpiderData.empty();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Score Level: Best handicap in period (lower = better, HC 1 = 100%)
  Future<double?> _calculateScoreLevel(DateTime since) async {
    // Get completed sessions and imported scores
    final sessions = await _db.getCompletedSessions();
    final recentSessions = sessions.where((s) => s.startedAt.isAfter(since)).toList();

    final importedScores = await _db.getAllImportedScores();
    final recentImported = importedScores.where((s) => s.date.isAfter(since)).toList();

    int? bestHandicap;

    // Calculate handicap from sessions
    for (final session in recentSessions) {
      final handicap = HandicapCalculator.calculateHandicap(
        session.roundTypeId,
        session.totalScore,
      );
      if (handicap != null && (bestHandicap == null || handicap < bestHandicap)) {
        bestHandicap = handicap;
      }
    }

    // Calculate handicap from imported scores
    for (final score in recentImported) {
      // Need to map round name to round type ID
      final roundTypeId = _mapRoundNameToId(score.roundName);
      if (roundTypeId != null) {
        final handicap = HandicapCalculator.calculateHandicap(roundTypeId, score.score);
        if (handicap != null && (bestHandicap == null || handicap < bestHandicap)) {
          bestHandicap = handicap;
        }
      }
    }

    if (bestHandicap == null) return null;

    // Lower handicap = better. HC 1 = 100%, HC 100 = ~0%
    // Formula: (100 - handicap) / 99 * 100, clamped to 0-100
    return math.max(0, (100 - bestHandicap) / 99 * 100);
  }

  /// Training Volume: Arrows per week
  Future<double?> _calculateTrainingVolume(DateTime since) async {
    final entries = await _db.getVolumeEntriesInRange(since, DateTime.now());

    if (entries.isEmpty) return null;

    final totalArrows = entries.fold<int>(0, (sum, e) => sum + e.arrowCount);

    // Scale to weekly if time window is different
    final days = DateTime.now().difference(since).inDays;
    final weeklyArrows = days > 0 ? totalArrows * 7 / days : totalArrows.toDouble();

    return math.min(100, (weeklyArrows / _targets.arrowsPerWeek) * 100);
  }

  /// Training Frequency: Days with any training activity
  Future<double?> _calculateTrainingFrequency(DateTime since) async {
    final trainingDays = <DateTime>{};

    // Count days with volume entries
    final volumeEntries = await _db.getVolumeEntriesInRange(since, DateTime.now());
    for (final entry in volumeEntries) {
      trainingDays.add(DateTime(entry.date.year, entry.date.month, entry.date.day));
    }

    // Count days with completed sessions
    final sessions = await _db.getCompletedSessions();
    for (final session in sessions) {
      if (session.startedAt.isAfter(since)) {
        trainingDays.add(DateTime(
          session.startedAt.year,
          session.startedAt.month,
          session.startedAt.day,
        ));
      }
    }

    // Count days with bow training
    final olyLogs = await _db.getAllOlyTrainingLogs();
    for (final log in olyLogs) {
      if (log.completedAt.isAfter(since)) {
        trainingDays.add(DateTime(
          log.completedAt.year,
          log.completedAt.month,
          log.completedAt.day,
        ));
      }
    }

    // Count days with breath training
    final breathLogs = await _db.getBreathTrainingLogsSince(since);
    for (final log in breathLogs) {
      trainingDays.add(DateTime(
        log.completedAt.year,
        log.completedAt.month,
        log.completedAt.day,
      ));
    }

    if (trainingDays.isEmpty) return null;

    // Scale to weekly
    final days = DateTime.now().difference(since).inDays;
    final weeklyDays = days > 0
        ? trainingDays.length * 7 / days
        : trainingDays.length.toDouble();

    return math.min(100, (weeklyDays / _targets.trainingDaysPerWeek) * 100);
  }

  /// Bow Fitness: Total hold time per week from OLY training
  Future<double?> _calculateBowFitness(DateTime since) async {
    final logs = await _db.getAllOlyTrainingLogs();
    final recentLogs = logs.where((l) => l.completedAt.isAfter(since)).toList();

    if (recentLogs.isEmpty) return null;

    final totalHoldSeconds = recentLogs.fold<int>(
      0,
      (sum, log) => sum + log.totalHoldSeconds,
    );
    final totalHoldMinutes = totalHoldSeconds / 60;

    // Scale to weekly
    final days = DateTime.now().difference(since).inDays;
    final weeklyMinutes = days > 0
        ? totalHoldMinutes * 7 / days
        : totalHoldMinutes;

    return math.min(100, (weeklyMinutes / _targets.holdMinutesPerWeek) * 100);
  }

  /// Form Quality: Average structure feedback (lower = better)
  Future<double?> _calculateFormQuality(DateTime since) async {
    final logs = await _db.getAllOlyTrainingLogs();
    final recentLogs = logs
        .where((l) => l.completedAt.isAfter(since) && l.feedbackStructure != null)
        .toList();

    if (recentLogs.isEmpty) return null;

    final avgStructure = recentLogs
        .map((l) => l.feedbackStructure!)
        .reduce((a, b) => a + b) / recentLogs.length;

    // Inverted: Lower score = better. Score 2 = 100%, Score 10 = 0%
    return math.max(0, (10 - avgStructure) / 8 * 100);
  }

  /// Stability: Average shaking feedback (lower = better)
  Future<double?> _calculateStability(DateTime since) async {
    final logs = await _db.getAllOlyTrainingLogs();
    final recentLogs = logs
        .where((l) => l.completedAt.isAfter(since) && l.feedbackShaking != null)
        .toList();

    if (recentLogs.isEmpty) return null;

    final avgShaking = recentLogs
        .map((l) => l.feedbackShaking!)
        .reduce((a, b) => a + b) / recentLogs.length;

    // Inverted: Lower score = better. Score 2 = 100%, Score 10 = 0%
    return math.max(0, (10 - avgShaking) / 8 * 100);
  }

  /// Breath Hold: Best breath hold time
  Future<double?> _calculateBreathHold(DateTime since) async {
    final bestHold = await _db.getBestBreathHold(since: since);
    if (bestHold == null) return null;

    return math.min(100, (bestHold / _targets.breathHoldSeconds) * 100);
  }

  /// Breath Exhale: Best exhale time (Patrick breath)
  Future<double?> _calculateBreathExhale(DateTime since) async {
    final bestExhale = await _db.getBestExhaleTime(since: since);
    if (bestExhale == null) return null;

    return math.min(100, (bestExhale / _targets.breathExhaleSeconds) * 100);
  }

  /// Map round name to round type ID for handicap calculation
  String? _mapRoundNameToId(String roundName) {
    final normalized = roundName.toLowerCase().trim();

    // Common mappings
    final mappings = <String, String>{
      'wa 720': 'wa_720_70m',
      'wa720': 'wa_720_70m',
      'wa 720 70m': 'wa_720_70m',
      'wa 720 60m': 'wa_720_60m',
      'wa 720 50m': 'wa_720_50m',
      'wa 1440': 'wa_1440_90m',
      'wa1440': 'wa_1440_90m',
      'fita': 'wa_1440_90m',
      'wa 18': 'wa_18m',
      'wa18': 'wa_18m',
      'wa 25': 'wa_25m',
      'wa25': 'wa_25m',
      'portsmouth': 'portsmouth',
      'vegas': 'vegas',
      'vegas 300': 'vegas_300',
      'worcester': 'worcester',
      'york': 'york',
      'hereford': 'hereford',
      'national': 'national',
      'bristol i': 'bristol_i',
      'bristol ii': 'bristol_ii',
      'bristol iii': 'bristol_iii',
      'bristol iv': 'bristol_iv',
      'bristol v': 'bristol_v',
      'half metric': 'half_metric_70m',
      'bray 1': 'bray_1',
      'bray 2': 'bray_2',
      'stafford': 'stafford',
    };

    for (final entry in mappings.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }
}
