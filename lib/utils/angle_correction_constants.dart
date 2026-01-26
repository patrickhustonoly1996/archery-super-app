import '../models/user_profile.dart';

/// Constants for angle-based sight mark calculations.
///
/// These values can be tuned as we gather more real-world data.
/// Last updated: 2026-01-26
///
/// Reference sources:
/// - Chartres recurve sight angle diagram (docs/SIGHTMARKS_ANGLES_RECURVE.md)
/// - Compound data: [TO BE GATHERED FROM FIELD TESTING]
///
class AngleCorrectionConstants {
  // ═══════════════════════════════════════════════════════════════
  // SPEED ESTIMATION CONSTANTS
  // Used when estimating arrow speed from equipment
  // ═══════════════════════════════════════════════════════════════

  /// Base speeds at 28" draw, 400gr arrow (fps)
  static const double compoundBaseSpeed = 220; // At 40#
  static const double recurveBaseSpeed = 150; // At 30#
  static const double barebowBaseSpeed = 145; // At 30#
  static const double longbowBaseSpeed = 120; // At 30#
  static const double traditionalBaseSpeed = 120; // Same as longbow

  /// Base poundage for each bow type (where base speed applies)
  static const double compoundBasePoundage = 40;
  static const double recurveBasePoundage = 30;
  static const double barebowBasePoundage = 30;
  static const double longbowBasePoundage = 30;
  static const double traditionalBasePoundage = 30;

  /// Speed gain per pound of draw weight
  static const double compoundFpsPerPound = 3.0;
  static const double recurveFpsPerPound = 4.5;
  static const double barebowFpsPerPound = 4.0;
  static const double longbowFpsPerPound = 3.5;
  static const double traditionalFpsPerPound = 3.5;

  /// Speed change per inch of draw length from 28"
  static const double fpsPerInchOfDraw = 2.0;

  /// Standard reference draw length (inches)
  static const double standardDrawLength = 28.0;

  /// Speed loss per 5 grains of arrow weight over 400gr
  static const double fpsLossPerFiveGrains = 1.0;

  /// Standard reference arrow weight (grains)
  static const double standardArrowWeight = 400.0;

  /// Speed clamp values
  static const double minSpeed = 140.0;
  static const double maxSpeed = 350.0;

  // ═══════════════════════════════════════════════════════════════
  // ANGLE CORRECTION FACTORS
  // Determines uphill/downhill sight mark adjustments
  // ═══════════════════════════════════════════════════════════════

  /// Speed thresholds for factor interpolation
  static const double fastSpeedThreshold = 290; // fps - minimal correction
  static const double slowSpeedThreshold = 180; // fps - maximum correction

  /// Uphill factor range (per degree of slope)
  /// At 290fps: 0.002, At 180fps: 0.006
  static const double uphillFactorFast = 0.002;
  static const double uphillFactorSlow = 0.006;

  /// Up/down ratio range
  /// At 290fps: 1.0 (equal), At 180fps: 2.0 (downhill is 2x uphill)
  static const double upDownRatioFast = 1.0;
  static const double upDownRatioSlow = 2.0;

  /// Standard angles for angle tables (degrees)
  static const List<double> standardAngles = [5.0, 10.0, 15.0, 20.0, 25.0];

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Get base speed for a bow type
  static double getBaseSpeed(BowType bowType) {
    switch (bowType) {
      case BowType.compound:
        return compoundBaseSpeed;
      case BowType.recurve:
        return recurveBaseSpeed;
      case BowType.barebow:
        return barebowBaseSpeed;
      case BowType.longbow:
        return longbowBaseSpeed;
      case BowType.traditional:
        return traditionalBaseSpeed;
    }
  }

  /// Get base poundage for a bow type
  static double getBasePoundage(BowType bowType) {
    switch (bowType) {
      case BowType.compound:
        return compoundBasePoundage;
      case BowType.recurve:
        return recurveBasePoundage;
      case BowType.barebow:
        return barebowBasePoundage;
      case BowType.longbow:
        return longbowBasePoundage;
      case BowType.traditional:
        return traditionalBasePoundage;
    }
  }

  /// Get fps per pound for a bow type
  static double getFpsPerPound(BowType bowType) {
    switch (bowType) {
      case BowType.compound:
        return compoundFpsPerPound;
      case BowType.recurve:
        return recurveFpsPerPound;
      case BowType.barebow:
        return barebowFpsPerPound;
      case BowType.longbow:
        return longbowFpsPerPound;
      case BowType.traditional:
        return traditionalFpsPerPound;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // RECURVE REFERENCE DATA
  // From Chartres "Gain/Inclinaison" diagram
  // See: docs/SIGHTMARKS_ANGLES_RECURVE.md
  // ═══════════════════════════════════════════════════════════════

  /// Chartres inclination values (approximate, in sight units)
  /// Distance → (uphillAdjust, downhillAdjust) at ~15deg slope
  static const Map<int, (double, double)> chartresReference = {
    15: (-0.02, -0.03), // Short distance
    30: (-0.04, -0.07),
    45: (-0.08, -0.14),
    60: (-0.12, -0.20), // Long distance - more correction needed
  };

  // ═══════════════════════════════════════════════════════════════
  // COMPOUND REFERENCE DATA
  // TODO: Gather from field testing
  // ═══════════════════════════════════════════════════════════════

  /// Compound angle corrections (to be populated)
  /// Expected to be much smaller and more symmetric than recurve
  static const Map<int, (double, double)> compoundReference = {
    // TODO: Add real-world data from compound archers
    // Format: distance -> (uphillAdjust, downhillAdjust) at ~15deg slope
    // 50: (-0.01, -0.01),  // Expected: nearly equal
  };
}
