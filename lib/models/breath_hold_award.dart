/// Breath Hold Awards - achievement badges for sustained breath holds
/// Awards start at 20 seconds and increase in 5 second increments

/// All possible breath hold award levels
enum BreathHoldAwardLevel {
  seconds20(20, 'Novice Lung', 'First real hold'),
  seconds25(25, 'Steady Breath', 'Building capacity'),
  seconds30(30, 'Calm Mind', 'Half minute'),
  seconds35(35, 'Iron Will', 'Mental fortitude'),
  seconds40(40, 'Deep Diver', 'Serious hold'),
  seconds45(45, 'Still Waters', 'Approaching elite'),
  seconds50(50, 'Oxygen Master', 'Elite territory'),
  seconds55(55, 'Breath Sage', 'Near mastery'),
  seconds60(60, 'Minute Mark', 'One full minute'),
  seconds65(65, 'Beyond Limits', 'Exceptional'),
  seconds70(70, 'Zen State', 'Deep control'),
  seconds75(75, 'Transcendent', 'Rare achievement'),
  seconds80(80, 'Air Bender', 'Extraordinary'),
  seconds85(85, 'Void Walker', 'Elite athlete'),
  seconds90(90, 'Ninety Seconds', 'Champion level');

  final int seconds;
  final String title;
  final String description;

  const BreathHoldAwardLevel(this.seconds, this.title, this.description);

  /// Get the award level for a given number of seconds
  /// Returns null if the hold doesn't qualify for any award
  static BreathHoldAwardLevel? fromSeconds(int holdSeconds) {
    if (holdSeconds < 20) return null;

    // Find the highest award level achieved
    BreathHoldAwardLevel? highest;
    for (final level in values) {
      if (holdSeconds >= level.seconds) {
        highest = level;
      }
    }
    return highest;
  }

  /// Get all award levels up to and including a given number of seconds
  static List<BreathHoldAwardLevel> allAwardsForSeconds(int holdSeconds) {
    return values.where((level) => holdSeconds >= level.seconds).toList();
  }

  /// Get the next award level after this one
  BreathHoldAwardLevel? get nextLevel {
    final currentIndex = index;
    if (currentIndex >= values.length - 1) return null;
    return values[currentIndex + 1];
  }

  /// Seconds needed to reach the next level
  int? get secondsToNextLevel {
    final next = nextLevel;
    if (next == null) return null;
    return next.seconds - seconds;
  }
}

/// Represents an earned breath hold award
class BreathHoldAward {
  final String id;
  final BreathHoldAwardLevel level;
  final DateTime earnedAt;
  final String? sessionLogId;

  const BreathHoldAward({
    required this.id,
    required this.level,
    required this.earnedAt,
    this.sessionLogId,
  });

  /// Create from database row
  factory BreathHoldAward.fromDb(Map<String, dynamic> row) {
    return BreathHoldAward(
      id: row['id'] as String,
      level: BreathHoldAwardLevel.values.firstWhere(
        (l) => l.seconds == row['seconds_threshold'],
      ),
      earnedAt: DateTime.parse(row['earned_at'] as String),
      sessionLogId: row['session_log_id'] as String?,
    );
  }
}
