import '../db/database.dart';

/// Match imported round name to round type ID
///
/// Performs flexible fuzzy matching on common round names.
/// Uses score (when available) to distinguish between full rounds
/// and half rounds (e.g., 720 vs half round).
///
/// Returns null if no match found.
///
/// This is the single source of truth for round name matching,
/// used by history screen and handicap chart.
String? matchRoundName(String roundName, {int? score}) {
  final lower = roundName.toLowerCase().trim();

  // WA Outdoor - 720 rounds
  // But if score <= 360, it's probably a half round (36 arrows), not a bad 720
  if (lower.contains('720')) {
    if (score != null && score <= 360) {
      return 'half_metric_70m'; // Score too low for 720
    }
    if (lower.contains('70') || lower.contains('gent') || lower.contains('men')) return 'wa_720_70m';
    if (lower.contains('60') || lower.contains('ladi') || lower.contains('women')) return 'wa_720_60m';
    if (lower.contains('50')) return 'wa_720_50m';
    return 'wa_720_70m'; // Default to 70m
  }

  // WA Outdoor - 1440 rounds (FITA)
  if (lower.contains('1440') || lower.contains('fita')) {
    if (lower.contains('90') || lower.contains('gent') || lower.contains('men')) return 'wa_1440_90m';
    if (lower.contains('70') || lower.contains('ladi') || lower.contains('women')) return 'wa_1440_70m';
    if (lower.contains('60')) return 'wa_1440_60m';
    return 'wa_1440_90m';
  }

  // 70m rounds - use score to decide full 720 vs half round
  if (lower.contains('70m') || lower.contains('70 m') || lower.contains('h2h') ||
      lower.contains('head') || lower.contains('match') || lower.contains('half')) {
    if (score != null && score > 360) {
      return 'wa_720_70m';
    }
    return 'half_metric_70m';
  }

  // Generic "70" without "m" - use score to decide
  if (lower.contains('70') && !lower.contains('1440') && !lower.contains('720')) {
    if (score != null && score > 360) {
      return 'wa_720_70m';
    }
    return 'half_metric_70m';
  }

  // WA Indoor
  if (lower.contains('18m') || lower.contains('18 m') ||
      (lower.contains('wa') && lower.contains('18'))) return 'wa_18m';
  if (lower.contains('25m') || lower.contains('25 m') ||
      (lower.contains('wa') && lower.contains('25'))) return 'wa_25m';

  // AGB Indoor
  if (lower.contains('portsmouth') || lower.contains('portsm')) return 'portsmouth';
  if (lower.contains('worcester')) return 'worcester';
  if (lower.contains('vegas')) return 'vegas';
  if (lower.contains('bray')) {
    if (lower.contains('ii') || lower.contains('2')) return 'bray_2';
    return 'bray_1';
  }
  if (lower.contains('stafford')) return 'stafford';

  // AGB Outdoor Imperial
  if (lower == 'york' || lower.contains('york')) return 'york';
  if (lower.contains('hereford')) return 'hereford';
  if (lower.contains('st george') || lower.contains('st. george')) return 'st_george';
  if (lower.contains('bristol')) {
    if (lower.contains('v') && !lower.contains('iv')) return 'bristol_v';
    if (lower.contains('iv')) return 'bristol_iv';
    if (lower.contains('iii')) return 'bristol_iii';
    if (lower.contains('ii')) return 'bristol_ii';
    if (lower.contains('i')) return 'bristol_i';
  }

  // National rounds
  if (lower.contains('national')) {
    if (lower.contains('long')) return 'long_national';
    if (lower.contains('short')) return 'short_national';
    return 'national';
  }

  // AGB Metric
  if (lower.contains('metric')) {
    if (lower.contains('v') && !lower.contains('iv')) return 'metric_v';
    if (lower.contains('iv')) return 'metric_iv';
    if (lower.contains('iii')) return 'metric_iii';
    if (lower.contains('ii')) return 'metric_ii';
    if (lower.contains('i')) return 'metric_i';
  }

  // Fallbacks
  if (lower.contains('indoor')) return 'portsmouth';
  if (lower.contains('outdoor')) return 'wa_720_70m';

  return null;
}

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
  /// Returns the stored maxScore from the round configuration.
  int? getMaxScore(String roundName) {
    final round = findMatch(roundName);
    if (round == null) return null;
    return round.maxScore;
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
