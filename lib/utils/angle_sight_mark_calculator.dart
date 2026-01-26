import '../models/user_profile.dart';
import 'angle_correction_constants.dart';

/// Result of angle correction factor calculation
class AngleCorrectionFactors {
  /// Factor applied per degree of uphill slope
  final double uphill;

  /// Factor applied per degree of downhill slope
  final double downhill;

  /// Ratio of downhill to uphill factor
  double get ratio => uphill > 0 ? downhill / uphill : 1.0;

  const AngleCorrectionFactors({
    required this.uphill,
    required this.downhill,
  });
}

/// Entry in an angle table showing sight mark and percentage
class AngleTableEntry {
  /// The slope angle in degrees (negative = uphill, positive = downhill)
  final double angle;

  /// The calculated sight mark value
  final double sightMark;

  /// The sight mark as a percentage of the flat mark
  final double percentage;

  const AngleTableEntry({
    required this.angle,
    required this.sightMark,
    required this.percentage,
  });

  /// Whether this is an uphill shot (target above archer)
  bool get isUphill => angle < 0;

  /// Whether this is a downhill shot (target below archer)
  bool get isDownhill => angle > 0;

  /// Whether this is a flat shot
  bool get isFlat => angle == 0;
}

/// Angle-based sight mark calculator using arrow speed as the driver.
///
/// The physics of angle correction depends on arrow speed:
/// - Fast arrows (290+ fps): Minimal correction, uphill ≈ downhill
/// - Slow arrows (180 fps): Maximum correction, downhill > uphill
///
/// As arrow speed decreases:
/// 1. Total correction increases (more arc = more gravity effect)
/// 2. Up/down difference increases (slower arrow = more time for gravity asymmetry)
class AngleSightMarkCalculator {
  const AngleSightMarkCalculator._();

  /// Standard angles used in angle tables
  static List<double> get standardAngles =>
      AngleCorrectionConstants.standardAngles;

  /// Estimate arrow speed from equipment data.
  ///
  /// Uses bow type, poundage, and optionally draw length and arrow weight
  /// to calculate an estimated arrow speed in fps.
  ///
  /// Example outputs:
  /// - 60# compound, 28" draw: ~280 fps
  /// - 40# recurve, 28" draw: ~195 fps
  /// - 35# barebow, 27" draw: ~185 fps
  /// - 35# longbow, 28" draw: ~138 fps
  static double estimateArrowSpeed({
    required BowType bowType,
    required double poundage,
    double? drawLength,
    double? arrowWeightGrains,
  }) {
    final draw = drawLength ?? AngleCorrectionConstants.standardDrawLength;

    // Get base values for bow type
    final baseSpeed = AngleCorrectionConstants.getBaseSpeed(bowType);
    final basePoundage = AngleCorrectionConstants.getBasePoundage(bowType);
    final fpsPerPound = AngleCorrectionConstants.getFpsPerPound(bowType);

    // Calculate speed from poundage difference
    double speed = baseSpeed + ((poundage - basePoundage) * fpsPerPound);

    // Adjust for draw length difference from 28"
    speed += (draw - AngleCorrectionConstants.standardDrawLength) *
        AngleCorrectionConstants.fpsPerInchOfDraw;

    // Adjust for arrow weight if known
    if (arrowWeightGrains != null) {
      final weightDiff =
          arrowWeightGrains - AngleCorrectionConstants.standardArrowWeight;
      speed -= (weightDiff / 5) * AngleCorrectionConstants.fpsLossPerFiveGrains;
    }

    return speed.clamp(
      AngleCorrectionConstants.minSpeed,
      AngleCorrectionConstants.maxSpeed,
    );
  }

  /// Get a friendly description of estimated arrow speed
  static String getSpeedDescription(double fps) {
    if (fps >= 280) return 'Fast';
    if (fps >= 240) return 'Medium-Fast';
    if (fps >= 200) return 'Medium';
    if (fps >= 170) return 'Medium-Slow';
    return 'Slow';
  }

  /// Get a typical bow setup description for a speed range
  static String getTypicalSetupForSpeed(double fps) {
    if (fps >= 290) return '70# compound, light arrows';
    if (fps >= 270) return '60# compound, medium arrows';
    if (fps >= 240) return '45# recurve, heavy setup';
    if (fps >= 210) return '40# recurve, medium arrows';
    if (fps >= 180) return '35# barebow or light recurve';
    if (fps >= 160) return '35# longbow, heavy arrows';
    return 'Light traditional, short draw';
  }

  /// Get correction factors based on arrow speed.
  ///
  /// Returns separate factors for uphill and downhill corrections.
  /// At fast speeds (290fps+), these are nearly equal.
  /// At slow speeds (180fps), downhill is ~2x uphill.
  static AngleCorrectionFactors getFactorsForSpeed(double fps) {
    // Normalize speed to 0-1 range (0 = fast, 1 = slow)
    final speedRange = AngleCorrectionConstants.fastSpeedThreshold -
        AngleCorrectionConstants.slowSpeedThreshold;
    final t = ((AngleCorrectionConstants.fastSpeedThreshold - fps) / speedRange)
        .clamp(0.0, 1.0);

    // Uphill factor: linear interpolation from fast to slow
    final uphill = AngleCorrectionConstants.uphillFactorFast +
        (t *
            (AngleCorrectionConstants.uphillFactorSlow -
                AngleCorrectionConstants.uphillFactorFast));

    // Up/down ratio: linear interpolation from 1.0 (fast) to 2.0 (slow)
    final ratio = AngleCorrectionConstants.upDownRatioFast +
        (t *
            (AngleCorrectionConstants.upDownRatioSlow -
                AngleCorrectionConstants.upDownRatioFast));

    // Downhill factor is uphill * ratio
    final downhill = uphill * ratio;

    return AngleCorrectionFactors(uphill: uphill, downhill: downhill);
  }

  /// Calculate sight mark for a specific angle.
  ///
  /// [flatSightMark] - The sight mark for flat ground at this distance
  /// [angleDegrees] - Slope angle in degrees (negative = uphill, positive = downhill)
  /// [arrowSpeedFps] - Arrow speed in feet per second
  ///
  /// Returns the adjusted sight mark for the angled shot.
  static double getSightMarkForAngle({
    required double flatSightMark,
    required double angleDegrees,
    required double arrowSpeedFps,
  }) {
    if (angleDegrees == 0) return flatSightMark;

    final factors = getFactorsForSpeed(arrowSpeedFps);

    if (angleDegrees < 0) {
      // UPHILL - target above archer
      // Sight mark decreases (aim lower on the sight)
      return flatSightMark - (angleDegrees.abs() * factors.uphill);
    } else {
      // DOWNHILL - target below archer
      // Sight mark decreases more (aim even lower)
      return flatSightMark - (angleDegrees * factors.downhill);
    }
  }

  /// Calculate sight mark as a percentage of the flat mark.
  ///
  /// This is useful for quick mental math in the field:
  /// "Shoot at 97% of your flat mark"
  static double getSightMarkAsPercentage({
    required double flatSightMark,
    required double angleDegrees,
    required double arrowSpeedFps,
  }) {
    if (flatSightMark == 0) return 100.0;

    final adjusted = getSightMarkForAngle(
      flatSightMark: flatSightMark,
      angleDegrees: angleDegrees,
      arrowSpeedFps: arrowSpeedFps,
    );
    return (adjusted / flatSightMark) * 100;
  }

  /// Generate a full angle table for a given flat sight mark.
  ///
  /// Returns entries for all standard angles (uphill and downhill)
  /// plus the flat (0 degree) entry.
  static List<AngleTableEntry> generateAngleTable({
    required double flatSightMark,
    required double arrowSpeedFps,
    List<double>? angles,
  }) {
    final angleList = angles ?? standardAngles;
    final entries = <AngleTableEntry>[];

    // Add uphill entries (negative angles)
    for (final angle in angleList.reversed) {
      final mark = getSightMarkForAngle(
        flatSightMark: flatSightMark,
        angleDegrees: -angle,
        arrowSpeedFps: arrowSpeedFps,
      );
      entries.add(AngleTableEntry(
        angle: -angle,
        sightMark: mark,
        percentage: (mark / flatSightMark) * 100,
      ));
    }

    // Add flat entry
    entries.add(AngleTableEntry(
      angle: 0,
      sightMark: flatSightMark,
      percentage: 100.0,
    ));

    // Add downhill entries (positive angles)
    for (final angle in angleList) {
      final mark = getSightMarkForAngle(
        flatSightMark: flatSightMark,
        angleDegrees: angle,
        arrowSpeedFps: arrowSpeedFps,
      );
      entries.add(AngleTableEntry(
        angle: angle,
        sightMark: mark,
        percentage: (mark / flatSightMark) * 100,
      ));
    }

    return entries;
  }

  /// Generate a compact angle table for display in a grid layout.
  ///
  /// Returns a map with uphill, flat, and downhill entries.
  static ({
    List<AngleTableEntry> uphill,
    AngleTableEntry flat,
    List<AngleTableEntry> downhill,
  }) generateCompactTable({
    required double flatSightMark,
    required double arrowSpeedFps,
    List<double>? angles,
  }) {
    final angleList = angles ?? standardAngles;

    final uphillEntries = <AngleTableEntry>[];
    final downhillEntries = <AngleTableEntry>[];

    for (final angle in angleList) {
      // Uphill
      final uphillMark = getSightMarkForAngle(
        flatSightMark: flatSightMark,
        angleDegrees: -angle,
        arrowSpeedFps: arrowSpeedFps,
      );
      uphillEntries.add(AngleTableEntry(
        angle: -angle,
        sightMark: uphillMark,
        percentage: (uphillMark / flatSightMark) * 100,
      ));

      // Downhill
      final downhillMark = getSightMarkForAngle(
        flatSightMark: flatSightMark,
        angleDegrees: angle,
        arrowSpeedFps: arrowSpeedFps,
      );
      downhillEntries.add(AngleTableEntry(
        angle: angle,
        sightMark: downhillMark,
        percentage: (downhillMark / flatSightMark) * 100,
      ));
    }

    return (
      uphill: uphillEntries,
      flat: AngleTableEntry(
        angle: 0,
        sightMark: flatSightMark,
        percentage: 100.0,
      ),
      downhill: downhillEntries,
    );
  }
}
