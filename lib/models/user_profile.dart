import 'dart:convert';

/// Enum for gender (for classification calculations)
enum Gender {
  male('male', 'Male'),
  female('female', 'Female');

  const Gender(this.value, this.displayName);
  final String value;
  final String displayName;

  static Gender fromString(String value) {
    return Gender.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Gender.male,
    );
  }

  static Gender? fromStringNullable(String? value) {
    if (value == null) return null;
    try {
      return Gender.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}

/// Enum for AGB age categories (for classification calculations)
/// Age categories determine handicap adjustments
enum AgeCategory {
  // Adult categories
  adult('adult', 'Adult', 0),
  under21('under_21', 'Under 21', 0), // Same as adult
  fiftyPlus('50+', '50+', 1),
  sixtyPlus('60+', '60+', 2),
  seventyPlus('70+', '70+', 3),

  // Junior categories
  under18('under_18', 'Under 18', 2),
  under16('under_16', 'Under 16', 4),
  under15('under_15', 'Under 15', 5),
  under14('under_14', 'Under 14', 6),
  under12('under_12', 'Under 12', 8);

  const AgeCategory(this.value, this.displayName, this.ageStep);
  final String value;
  final String displayName;

  /// Age step used in classification threshold calculation
  /// threshold = datum + (ageStep × 3) + genderAdj + (classIndex × 7)
  final int ageStep;

  static AgeCategory fromString(String value) {
    return AgeCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AgeCategory.adult,
    );
  }

  /// Calculate age category from date of birth
  static AgeCategory fromDateOfBirth(DateTime dob) {
    final now = DateTime.now();
    final age = now.year - dob.year -
        (now.month < dob.month || (now.month == dob.month && now.day < dob.day) ? 1 : 0);

    // Junior categories
    if (age < 12) return AgeCategory.under12;
    if (age < 14) return AgeCategory.under14;
    if (age < 15) return AgeCategory.under15;
    if (age < 16) return AgeCategory.under16;
    if (age < 18) return AgeCategory.under18;
    if (age < 21) return AgeCategory.under21;

    // Senior/veteran categories
    if (age >= 70) return AgeCategory.seventyPlus;
    if (age >= 60) return AgeCategory.sixtyPlus;
    if (age >= 50) return AgeCategory.fiftyPlus;

    return AgeCategory.adult;
  }
}

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
