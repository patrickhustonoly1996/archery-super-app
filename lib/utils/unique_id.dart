import 'package:uuid/uuid.dart';

/// Utility for generating universally unique IDs (UUIDs).
///
/// Uses UUID v4 which generates random UUIDs that are statistically
/// guaranteed to be unique across all devices and time.
///
/// Format: Standard UUID v4 (e.g., "550e8400-e29b-41d4-a716-446655440000")
class UniqueId {
  static const _uuid = Uuid();

  /// Generate a unique UUID v4.
  /// This is globally unique and will never collide, even when
  /// created simultaneously across multiple devices.
  static String generate() {
    return _uuid.v4();
  }

  /// Generate a unique ID with a custom prefix.
  /// Useful for distinguishing different entity types in logs.
  /// Format: {prefix}_{uuid}
  static String withPrefix(String prefix) {
    return '${prefix}_${generate()}';
  }
}
