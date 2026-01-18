import 'dart:convert';

/// Enum for primary bow types
enum BowType {
  recurve('recurve', 'Recurve'),
  compound('compound', 'Compound'),
  barebow('barebow', 'Barebow'),
  longbow('longbow', 'Longbow'),
  traditional('traditional', 'Traditional');

  const BowType(this.value, this.displayName);
  final String value;
  final String displayName;

  static BowType fromString(String value) {
    return BowType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BowType.recurve,
    );
  }
}

/// Enum for handedness
enum Handedness {
  right('right', 'Right-handed'),
  left('left', 'Left-handed');

  const Handedness(this.value, this.displayName);
  final String value;
  final String displayName;

  static Handedness fromString(String value) {
    return Handedness.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Handedness.right,
    );
  }
}

/// Competition levels
enum CompetitionLevel {
  local('local', 'Local'),
  regional('regional', 'Regional'),
  national('national', 'National'),
  international('international', 'International'),
  nationalTeam('national_team', 'National Team');

  const CompetitionLevel(this.value, this.displayName);
  final String value;
  final String displayName;

  static CompetitionLevel fromString(String value) {
    return CompetitionLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CompetitionLevel.local,
    );
  }

  static List<CompetitionLevel> fromJsonList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => fromString(e as String)).toList();
    } catch (_) {
      return [];
    }
  }

  static String toJsonList(List<CompetitionLevel> levels) {
    return jsonEncode(levels.map((e) => e.value).toList());
  }
}

/// Default target face suggestions based on bow type
class BowTypeDefaults {
  /// Get default indoor target face suggestion
  static String getIndoorSuggestion(BowType bowType) {
    switch (bowType) {
      case BowType.recurve:
        return 'Triple spot (40cm)';
      case BowType.compound:
        return 'Small inner 10 (40cm)';
      case BowType.barebow:
      case BowType.longbow:
      case BowType.traditional:
        return 'Full face (40cm)';
    }
  }

  /// Get default outdoor distance and face size
  static ({int distance, int faceSize}) getOutdoorDefaults(BowType bowType) {
    switch (bowType) {
      case BowType.recurve:
        return (distance: 70, faceSize: 122);
      case BowType.compound:
        return (distance: 50, faceSize: 80);
      case BowType.barebow:
        return (distance: 50, faceSize: 122);
      case BowType.longbow:
        return (distance: 50, faceSize: 122);
      case BowType.traditional:
        return (distance: 40, faceSize: 122);
    }
  }

  /// Get display string for outdoor defaults
  static String getOutdoorSuggestion(BowType bowType) {
    final defaults = getOutdoorDefaults(bowType);
    return '${defaults.distance}m, ${defaults.faceSize}cm face';
  }

  /// Get whether triple spot is typical for this bow type
  static bool prefersTripleSpot(BowType bowType) {
    return bowType == BowType.recurve || bowType == BowType.compound;
  }
}
