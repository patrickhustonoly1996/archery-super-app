import 'dart:math';

/// Utility for generating unique IDs that won't collide even when
/// created in quick succession (same millisecond).
///
/// Format: {timestamp}_{counter}_{random4digits}
/// Example: 1737014400000_001_4729
///
/// The counter guarantees uniqueness within the same process,
/// while the random suffix adds entropy for cross-process safety.
class UniqueId {
  static final _random = Random();
  static int _counter = 0;
  static int _lastTimestamp = 0;

  /// Generate a unique ID combining timestamp, counter, and random suffix.
  /// This prevents ID collisions that can occur with pure timestamp-based IDs.
  static String generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Reset counter when timestamp changes, increment otherwise
    if (timestamp != _lastTimestamp) {
      _counter = 0;
      _lastTimestamp = timestamp;
    } else {
      _counter++;
    }

    final counterStr = _counter.toString().padLeft(3, '0');
    final randomSuffix = _random.nextInt(9999).toString().padLeft(4, '0');
    return '${timestamp}_${counterStr}_$randomSuffix';
  }

  /// Generate a unique ID with a custom prefix.
  /// Useful for distinguishing different entity types in logs.
  static String withPrefix(String prefix) {
    return '${prefix}_${generate()}';
  }
}
