import 'package:drift/drift.dart' show Value;
import '../db/database.dart';
import '../models/breath_hold_award.dart';
import '../utils/unique_id.dart';

/// Service for managing breath hold awards
class BreathHoldAwardService {
  final AppDatabase _db;

  BreathHoldAwardService(this._db);

  /// Check for and award any new breath hold achievements based on best hold
  /// Returns list of newly earned award levels
  Future<List<BreathHoldAwardLevel>> checkAndAwardAchievements({
    required int bestHoldSeconds,
    String? sessionLogId,
  }) async {
    if (bestHoldSeconds < 20) {
      return []; // No awards below 20 seconds
    }

    // Get all award levels this hold qualifies for
    final qualifyingLevels = BreathHoldAwardLevel.allAwardsForSeconds(bestHoldSeconds);

    // Get already earned awards
    final earnedAwards = await _db.getAllBreathHoldAwards();
    final earnedThresholds = earnedAwards.map((a) => a.secondsThreshold).toSet();

    // Find new awards to grant
    final newAwards = <BreathHoldAwardLevel>[];
    for (final level in qualifyingLevels) {
      if (!earnedThresholds.contains(level.seconds)) {
        // Award not yet earned - grant it
        await _db.insertBreathHoldAward(
          BreathHoldAwardsCompanion.insert(
            id: UniqueId.generate(),
            secondsThreshold: level.seconds,
            title: level.title,
            sessionLogId: Value(sessionLogId),
            earnedAt: DateTime.now(),
          ),
        );
        newAwards.add(level);
      }
    }

    return newAwards;
  }

  /// Get all earned award levels
  Future<List<BreathHoldAwardLevel>> getEarnedAwardLevels() async {
    final awards = await _db.getAllBreathHoldAwards();
    return awards
        .map((a) => BreathHoldAwardLevel.values.firstWhere(
              (l) => l.seconds == a.secondsThreshold,
              orElse: () => BreathHoldAwardLevel.seconds20,
            ))
        .toList();
  }

  /// Get set of earned thresholds (for grid display)
  Future<Set<int>> getEarnedThresholds() async {
    final awards = await _db.getAllBreathHoldAwards();
    return awards.map((a) => a.secondsThreshold).toSet();
  }

  /// Get the highest earned award level
  Future<BreathHoldAwardLevel?> getHighestAwardLevel() async {
    final award = await _db.getHighestBreathHoldAward();
    if (award == null) return null;
    return BreathHoldAwardLevel.values.firstWhere(
      (l) => l.seconds == award.secondsThreshold,
      orElse: () => BreathHoldAwardLevel.seconds20,
    );
  }

  /// Get next award level to work towards
  Future<BreathHoldAwardLevel?> getNextTargetLevel() async {
    final highest = await getHighestAwardLevel();
    if (highest == null) {
      return BreathHoldAwardLevel.seconds20; // First award
    }
    return highest.nextLevel;
  }
}
