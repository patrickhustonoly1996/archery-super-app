/// AGB (Archery GB) Classification System
///
/// Classifications are based on achieving specific handicap thresholds
/// on two separate occasions with "prestige" rounds required for MB+.
///
/// Calculation based on archeryutils:
/// threshold = datum + (ageStep × 3) + genderAdj + (classIndex × 7)
///
/// Where:
/// - datum: bowstyle-specific base (Compound=15, Recurve=30, Barebow=47, Longbow=65)
/// - ageStep: age category modifier (Adult=0, 50+=1, U18=2, etc.)
/// - genderAdj: +7 for female
/// - classIndex: classification level index (0 for highest)

/// Outdoor classification levels (highest to lowest)
enum OutdoorClassification {
  grandMasterBowman('GMB', 'Grand Master Bowman', 0),
  masterBowman('MB', 'Master Bowman', 1),
  bowmanFirst('B1', 'Bowman 1st Class', 2),
  bowmanSecond('B2', 'Bowman 2nd Class', 3),
  bowmanThird('B3', 'Bowman 3rd Class', 4),
  archerFirst('A1', 'Archer 1st Class', 5),
  archerSecond('A2', 'Archer 2nd Class', 6),
  archerThird('A3', 'Archer 3rd Class', 7);

  const OutdoorClassification(this.code, this.displayName, this.classIndex);
  final String code;
  final String displayName;

  /// Index used in handicap threshold calculation (0 = highest classification)
  final int classIndex;

  /// Whether this classification requires a "prestige" round
  /// (York, Hereford, Bristol I, WA 1440, WA 720 at 70m/60m)
  bool get requiresPrestigeRound => classIndex <= 1; // GMB and MB

  static OutdoorClassification fromString(String code) {
    return OutdoorClassification.values.firstWhere(
      (e) => e.code == code || e.name == code,
      orElse: () => OutdoorClassification.archerThird,
    );
  }

  /// Get the next higher classification (null if already at top)
  OutdoorClassification? get nextHigher {
    if (classIndex == 0) return null;
    return OutdoorClassification.values.firstWhere(
      (e) => e.classIndex == classIndex - 1,
    );
  }

  /// Get the next lower classification (null if already at bottom)
  OutdoorClassification? get nextLower {
    if (classIndex == 7) return null;
    return OutdoorClassification.values.firstWhere(
      (e) => e.classIndex == classIndex + 1,
    );
  }
}

/// Indoor classification levels (highest to lowest)
enum IndoorClassification {
  grandMasterBowman('GMB', 'Grand Master Bowman', 0),
  masterBowman('MB', 'Master Bowman', 1),
  bowmanFirst('B1', 'Bowman 1st Class', 2),
  bowmanSecond('B2', 'Bowman 2nd Class', 3),
  bowmanThird('B3', 'Bowman 3rd Class', 4),
  archerFirst('A1', 'Archer 1st Class', 5),
  archerSecond('A2', 'Archer 2nd Class', 6),
  archerThird('A3', 'Archer 3rd Class', 7);

  const IndoorClassification(this.code, this.displayName, this.classIndex);
  final String code;
  final String displayName;

  /// Index used in handicap threshold calculation (0 = highest classification)
  final int classIndex;

  static IndoorClassification fromString(String code) {
    return IndoorClassification.values.firstWhere(
      (e) => e.code == code || e.name == code,
      orElse: () => IndoorClassification.archerThird,
    );
  }

  /// Get the next higher classification (null if already at top)
  IndoorClassification? get nextHigher {
    if (classIndex == 0) return null;
    return IndoorClassification.values.firstWhere(
      (e) => e.classIndex == classIndex - 1,
    );
  }

  /// Get the next lower classification (null if already at bottom)
  IndoorClassification? get nextLower {
    if (classIndex == 7) return null;
    return IndoorClassification.values.firstWhere(
      (e) => e.classIndex == classIndex + 1,
    );
  }
}

/// Classification scope (outdoor vs indoor)
enum ClassificationScope {
  outdoor('outdoor', 'Outdoor'),
  indoor('indoor', 'Indoor');

  const ClassificationScope(this.value, this.displayName);
  final String value;
  final String displayName;

  static ClassificationScope fromString(String value) {
    return ClassificationScope.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ClassificationScope.outdoor,
    );
  }
}

/// Bowstyle datums for handicap threshold calculation
/// These are the base handicap values for each bowstyle
class BowstyleDatum {
  static const int compound = 15;
  static const int recurve = 30;
  static const int barebow = 47;
  static const int traditional = 47; // Same as barebow
  static const int longbow = 65;

  /// Get datum for a bowstyle string
  static int forBowstyle(String bowstyle) {
    switch (bowstyle.toLowerCase()) {
      case 'compound':
        return compound;
      case 'recurve':
        return recurve;
      case 'barebow':
        return barebow;
      case 'traditional':
        return traditional;
      case 'longbow':
        return longbow;
      default:
        return recurve; // Default to recurve
    }
  }
}

/// Indoor bowstyle datums (slightly different from outdoor)
class IndoorBowstyleDatum {
  static const int compound = 5;
  static const int recurve = 14;
  static const int barebow = 30;
  static const int traditional = 30;
  static const int longbow = 45;

  /// Get datum for a bowstyle string
  static int forBowstyle(String bowstyle) {
    switch (bowstyle.toLowerCase()) {
      case 'compound':
        return compound;
      case 'recurve':
        return recurve;
      case 'barebow':
        return barebow;
      case 'traditional':
        return traditional;
      case 'longbow':
        return longbow;
      default:
        return recurve;
    }
  }
}

/// Prestige rounds required for MB+ outdoor classifications
class PrestigeRounds {
  /// Round IDs that qualify as prestige rounds for MB+ classification
  static const Set<String> outdoor = {
    'york',
    'hereford',
    'bristol_1',
    'wa_1440_90m',
    'wa_1440_70m',
    'wa_1440_60m',
    'wa_720_70m',
    'wa_720_60m',
  };

  /// Check if a round ID is a prestige round
  static bool isPrestigeRound(String roundId) {
    return outdoor.contains(roundId);
  }
}
