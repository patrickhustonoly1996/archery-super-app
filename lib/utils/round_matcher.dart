import '../db/database.dart';

/// Utility for fuzzy matching round names from imported scores
/// to standardized round types in the database.
///
/// Handles variations in naming conventions:
/// - "WA 720 70m" vs "WA720 70m" vs "720 round 70m"
/// - "Portsmouth" vs "Portsmouth Round"
/// - Case insensitivity, extra spaces, etc.
class RoundMatcher {
  final List<RoundType> _roundTypes;
  final Map<String, RoundType> _cache = {};

  RoundMatcher(this._roundTypes);

  /// Find the best matching round type for a given name.
  /// Returns null if no match found.
  RoundType? findMatch(String roundName) {
    // Check cache first
    final normalized = _normalize(roundName);
    if (_cache.containsKey(normalized)) {
      return _cache[normalized];
    }

    // Try exact match (case-insensitive)
    for (final round in _roundTypes) {
      if (_normalize(round.name) == normalized) {
        _cache[normalized] = round;
        return round;
      }
    }

    // Try contains match (for partial names)
    for (final round in _roundTypes) {
      final roundNorm = _normalize(round.name);
      if (normalized.contains(roundNorm) || roundNorm.contains(normalized)) {
        _cache[normalized] = round;
        return round;
      }
    }

    // Try fuzzy match with common variations
    final match = _fuzzyMatch(roundName);
    if (match != null) {
      _cache[normalized] = match;
    }
    return match;
  }

  /// Get the max score for a round by name.
  /// Returns the stored maxScore or calculates from arrows × 10.
  int? getMaxScore(String roundName) {
    final round = findMatch(roundName);
    if (round == null) return null;

    // Use stored maxScore if available
    if (round.maxScore != null) {
      return round.maxScore;
    }

    // Calculate from arrows (assuming 10-point max per arrow)
    return round.totalArrows * 10;
  }

  /// Normalize a string for comparison.
  /// Lowercase, remove extra spaces, common prefixes/suffixes.
  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('round', '')
        .replaceAll('archery', '')
        .trim();
  }

  /// Fuzzy match using common variations.
  RoundType? _fuzzyMatch(String roundName) {
    final normalized = _normalize(roundName);

    // Common patterns to try
    final patterns = _buildPatterns(normalized);

    for (final pattern in patterns) {
      for (final round in _roundTypes) {
        final roundNorm = _normalize(round.name);
        if (roundNorm.contains(pattern) || pattern.contains(roundNorm)) {
          return round;
        }
      }
    }

    return null;
  }

  /// Build search patterns from a round name.
  List<String> _buildPatterns(String normalized) {
    final patterns = <String>[normalized];

    // Extract key parts like distance, arrow count
    final distanceMatch = RegExp(r'(\d+)\s*m').firstMatch(normalized);
    if (distanceMatch != null) {
      patterns.add(distanceMatch.group(1)!);
    }

    // Common round name variations
    final variations = {
      'portsmouth': ['portsmouth', 'ports'],
      'vegas': ['vegas', 'vegas 300'],
      'wa720': ['wa 720', 'wa720', '720'],
      'wa1440': ['wa 1440', 'wa1440', '1440', 'fita'],
      'york': ['york'],
      'hereford': ['hereford'],
      'albion': ['albion'],
      'national': ['national'],
      'windsor': ['windsor'],
      'western': ['western'],
      'american': ['american'],
      'warwick': ['warwick'],
      'worcester': ['worcester'],
    };

    for (final entry in variations.entries) {
      for (final variant in entry.value) {
        if (normalized.contains(variant)) {
          patterns.add(entry.key);
          break;
        }
      }
    }

    return patterns;
  }
}

/// Extension to create a matcher from a list of round types
extension RoundTypeListExtension on List<RoundType> {
  RoundMatcher toMatcher() => RoundMatcher(this);
}
