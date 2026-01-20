import 'package:flutter/material.dart';
import '../providers/accessibility_provider.dart' show ColorblindMode;
export '../providers/accessibility_provider.dart' show ColorblindMode;

/// Archery Super App design system
/// Dark base + Gold primary, minimal animation, 8px grid
/// VT323 for logo & menus, Share Tech Mono for body text

class AppFonts {
  // VT323 - pixel font for logo, titles, menu items
  static const String pixel = 'VT323';
  // Share Tech Mono - angular technical mono for body text & data
  static const String body = 'ShareTechMono';
  // Aliases for compatibility (use body font as default)
  static const String main = 'ShareTechMono';
  static const String mono = 'ShareTechMono';
  static const String display = 'VT323';
}

class AppColors {
  // Primary
  static const gold = Color(0xFFFFD700);
  static const goldMuted = Color(0x80FFD700); // 50% opacity

  // Background
  static const background = Color(0xFF121212);
  static const backgroundDark = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1E1E1E);
  static const surfaceLight = Color(0xFF2A2A2A);
  static const surfaceBright = Color(0xFF3A3A3A);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0B0);
  static const textMuted = Color(0xFF8A8A8A); // Improved contrast (5.5:1 vs background)

  // Semantic
  static const error = Color(0xFFCF6679);
  static const success = Color(0xFF4CAF50);

  // Muted fluorescent accents (≤50% opacity highlights)
  static const cyan = Color(0x8000E5FF); // Indoor indicator
  static const magenta = Color(0x80FF00FF); // Outdoor indicator

  // Neon accents (full brightness for charts)
  static const neonCyan = Color(0xFF00E5FF); // Practice scores, data highlights
  static const neonMagenta = Color(0xFFFF00FF); // Accent highlights
  static const neonPink = Color(0xFFFF1493); // Alternative accent
  static const accentCyan = neonCyan; // Alias for sight marks UI

  // Target face ring colors (WA standard)
  static const ringX = Color(0xFFFFD700); // Gold center
  static const ring10 = Color(0xFFFFD700);
  static const ring9 = Color(0xFFFFD700);
  static const ring8 = Color(0xFFE53935); // Red
  static const ring7 = Color(0xFFE53935);
  static const ring6 = Color(0xFF42A5F5); // Blue
  static const ring5 = Color(0xFF42A5F5);
  static const ring4 = Color(0xFF212121); // Black
  static const ring3 = Color(0xFF212121);
  static const ring2 = Color(0xFFEEEEEE); // White
  static const ring1 = Color(0xFFEEEEEE);

  // =========================================================================
  // COLORBLIND-FRIENDLY PALETTES
  // =========================================================================

  // Deuteranopia/Protanopia-friendly ring colors
  // Replaces red with orange, keeps blue distinct
  static const cbRing8Deutan = Color(0xFFFF8C00); // Dark orange (replaces red)
  static const cbRing7Deutan = Color(0xFFFF8C00);
  static const cbRing6Deutan = Color(0xFF1E88E5); // Darker blue (more distinct)
  static const cbRing5Deutan = Color(0xFF1E88E5);

  // Tritanopia-friendly ring colors
  // Replaces blue with pink/purple
  static const cbRing8Tritan = Color(0xFFE53935); // Keep red
  static const cbRing7Tritan = Color(0xFFE53935);
  static const cbRing6Tritan = Color(0xFFAB47BC); // Purple (replaces blue)
  static const cbRing5Tritan = Color(0xFFAB47BC);

  // High contrast mode - uses very distinct colors
  static const cbRing8HighContrast = Color(0xFFFF6B00); // Bright orange
  static const cbRing7HighContrast = Color(0xFFFF6B00);
  static const cbRing6HighContrast = Color(0xFF00B8D4); // Cyan (distinct from orange)
  static const cbRing5HighContrast = Color(0xFF00B8D4);

  // Colorblind-friendly status colors
  static const cbErrorDeutan = Color(0xFFFF6B00); // Orange instead of red
  static const cbErrorTritan = Color(0xFFCF6679); // Keep pink/red
  static const cbErrorHighContrast = Color(0xFFFF6B00); // Bright orange

  // Colorblind-friendly chart colors (practice vs competition)
  static const cbPracticeDeutan = Color(0xFF00B8D4); // Teal (distinct from gold)
  static const cbPracticeTritan = Color(0xFF00E5FF); // Cyan
  static const cbPracticeHighContrast = Color(0xFF00BFA5); // Teal
}

/// Provides colorblind-friendly colors based on the current accessibility mode
class AccessibleColors {
  /// Get the ring color for a given score, adjusted for colorblind mode
  static Color getRingColor(int score, ColorblindMode mode) {
    // Gold, black, and white rings are fine for all colorblind types
    if (score >= 9) return AppColors.ring10; // Gold
    if (score <= 4 && score >= 3) return AppColors.ring4; // Black
    if (score <= 2 && score >= 1) return AppColors.ring2; // White

    // Red and blue rings need adjustment based on colorblind type
    switch (mode) {
      case ColorblindMode.none:
        if (score >= 7) return AppColors.ring8; // Red
        return AppColors.ring6; // Blue

      // Red-green colorblindness (most common) - use orange instead of red
      case ColorblindMode.deuteranopia:
      case ColorblindMode.protanopia:
      case ColorblindMode.deuteranomaly:
      case ColorblindMode.protanomaly:
        if (score >= 7) return AppColors.cbRing8Deutan; // Orange
        return AppColors.cbRing6Deutan; // Darker blue

      // Blue-yellow colorblindness - use purple instead of blue
      case ColorblindMode.tritanopia:
      case ColorblindMode.tritanomaly:
        if (score >= 7) return AppColors.cbRing8Tritan; // Red
        return AppColors.cbRing6Tritan; // Purple

      // Monochrome vision - use distinct grayscale values
      case ColorblindMode.achromatopsia:
        if (score >= 7) return const Color(0xFF808080); // Mid gray
        return const Color(0xFFB0B0B0); // Light gray

      case ColorblindMode.highContrast:
        if (score >= 7) return AppColors.cbRing8HighContrast; // Bright orange
        return AppColors.cbRing6HighContrast; // Cyan
    }
  }

  /// Get error/warning color adjusted for colorblind mode
  static Color getErrorColor(ColorblindMode mode) {
    switch (mode) {
      case ColorblindMode.none:
        return AppColors.error;
      case ColorblindMode.deuteranopia:
      case ColorblindMode.protanopia:
      case ColorblindMode.deuteranomaly:
      case ColorblindMode.protanomaly:
        return AppColors.cbErrorDeutan; // Orange
      case ColorblindMode.tritanopia:
      case ColorblindMode.tritanomaly:
        return AppColors.cbErrorTritan;
      case ColorblindMode.achromatopsia:
        return const Color(0xFF606060); // Dark gray
      case ColorblindMode.highContrast:
        return AppColors.cbErrorHighContrast;
    }
  }

  /// Get practice/secondary chart color adjusted for colorblind mode
  static Color getPracticeColor(ColorblindMode mode) {
    switch (mode) {
      case ColorblindMode.none:
        return AppColors.neonCyan;
      case ColorblindMode.deuteranopia:
      case ColorblindMode.protanopia:
      case ColorblindMode.deuteranomaly:
      case ColorblindMode.protanomaly:
        return AppColors.cbPracticeDeutan; // Teal
      case ColorblindMode.tritanopia:
      case ColorblindMode.tritanomaly:
        return AppColors.cbPracticeTritan;
      case ColorblindMode.achromatopsia:
        return const Color(0xFFB0B0B0); // Light gray
      case ColorblindMode.highContrast:
        return AppColors.cbPracticeHighContrast;
    }
  }

  /// Check if patterns should be used (for complete colorblindness or high contrast)
  static bool shouldUsePatterns(ColorblindMode mode) {
    return mode == ColorblindMode.achromatopsia || mode == ColorblindMode.highContrast;
  }

  /// Check if ring labels should be shown (helpful for complete colorblindness)
  static bool shouldShowRingLabels(ColorblindMode mode) {
    return mode == ColorblindMode.achromatopsia || mode == ColorblindMode.highContrast;
  }
}

// ColorblindMode is now defined in providers/accessibility_provider.dart
// Import from there: import '../providers/accessibility_provider.dart';

/// Traditional archery award colours
/// Progression: White → Black → Blue → Red → Gold → Purple
///
/// Used for:
/// - AGB Classifications (A3 → GMB)
/// - Streak awards (3 → 90 days)
/// - Skill milestones
class AwardColors {
  // The 6 traditional archery award colours (lowest to highest)
  static const white = Color(0xFFEEEEEE);
  static const black = Color(0xFF212121);
  static const blue = Color(0xFF42A5F5);
  static const red = Color(0xFFE53935);
  static const gold = Color(0xFFFFD700);
  static const purple = Color(0xFF9C27B0);

  /// All award colours in progression order (lowest to highest)
  static const List<Color> progression = [white, black, blue, red, gold, purple];

  /// Get text colour for contrast on award background
  static Color getTextColor(Color awardColor) {
    if (awardColor == white || awardColor == gold) {
      return AppColors.background; // Dark text on light backgrounds
    }
    return Colors.white; // White text on dark backgrounds
  }
}

/// Award tier enumeration for unified colour system
enum AwardTier {
  white(0, 'White', AwardColors.white),
  black(1, 'Black', AwardColors.black),
  blue(2, 'Blue', AwardColors.blue),
  red(3, 'Red', AwardColors.red),
  gold(4, 'Gold', AwardColors.gold),
  purple(5, 'Purple', AwardColors.purple);

  const AwardTier(this.tierLevel, this.displayName, this.color);

  final int tierLevel;
  final String displayName;
  final Color color;

  /// Get contrasting text colour for this tier
  Color get textColor => AwardColors.getTextColor(color);

  /// Get tier from index (clamped to valid range)
  static AwardTier fromIndex(int idx) {
    return AwardTier.values[idx.clamp(0, 5)];
  }
}

/// Streak tier thresholds (days)
/// Maps consecutive days to award tiers
class StreakTiers {
  static const int whiteDays = 3;
  static const int blackDays = 7;
  static const int blueDays = 14;
  static const int redDays = 30;
  static const int goldDays = 60;
  static const int purpleDays = 90;

  /// Get award tier for a streak length
  static AwardTier getTier(int streakDays) {
    if (streakDays >= purpleDays) return AwardTier.purple;
    if (streakDays >= goldDays) return AwardTier.gold;
    if (streakDays >= redDays) return AwardTier.red;
    if (streakDays >= blueDays) return AwardTier.blue;
    if (streakDays >= blackDays) return AwardTier.black;
    if (streakDays >= whiteDays) return AwardTier.white;
    return AwardTier.white; // Default for < 3 days (not yet earned)
  }

  /// Get days required for next tier (null if at max)
  static int? getDaysToNextTier(int currentStreak) {
    if (currentStreak < whiteDays) return whiteDays;
    if (currentStreak < blackDays) return blackDays;
    if (currentStreak < blueDays) return blueDays;
    if (currentStreak < redDays) return redDays;
    if (currentStreak < goldDays) return goldDays;
    if (currentStreak < purpleDays) return purpleDays;
    return null; // Already at max tier
  }

  /// Check if streak has earned any tier
  static bool hasEarnedTier(int streakDays) => streakDays >= whiteDays;
}

class AppSpacing {
  static const double grid = 8.0;

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      // Default font for ALL text - no sans-serif fallback
      fontFamily: AppFonts.body,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      primaryColor: AppColors.gold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.goldMuted,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.all(AppSpacing.sm),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.backgroundDark,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceLight,
        thickness: 1,
      ),
      textTheme: TextTheme(
        // Headlines - VT323 pixel font for impact
        headlineLarge: TextStyle(
          fontFamily: AppFonts.pixel,
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppFonts.pixel,
          fontSize: 26,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppFonts.pixel,
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        // Body text - Share Tech Mono for readability
        bodyLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 17,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Target ring boundaries as fractions of target radius
/// WA 10-ring target: X is innermost, 1 is outermost
/// @deprecated Use TargetRingsMm for new code - provides mm-based precision
class TargetRings {
  // Each value is the outer boundary of that ring as a fraction of total radius
  static const double x = 0.05; // X ring (inner 10)
  static const double ring10 = 0.10;
  static const double ring9 = 0.20;
  static const double ring8 = 0.30;
  static const double ring7 = 0.40;
  static const double ring6 = 0.50;
  static const double ring5 = 0.60;
  static const double ring4 = 0.70;
  static const double ring3 = 0.80;
  static const double ring2 = 0.90;
  static const double ring1 = 1.00;

  /// Get ring value from distance (as fraction of radius)
  static int getScore(double distanceFraction) {
    if (distanceFraction <= x) return 10; // X counts as 10
    if (distanceFraction <= ring10) return 10;
    if (distanceFraction <= ring9) return 9;
    if (distanceFraction <= ring8) return 8;
    if (distanceFraction <= ring7) return 7;
    if (distanceFraction <= ring6) return 6;
    if (distanceFraction <= ring5) return 5;
    if (distanceFraction <= ring4) return 4;
    if (distanceFraction <= ring3) return 3;
    if (distanceFraction <= ring2) return 2;
    if (distanceFraction <= ring1) return 1;
    return 0; // Miss
  }

  /// Check if arrow is in the X ring
  static bool isX(double distanceFraction) {
    return distanceFraction <= x;
  }

  /// Get color for a ring value
  static Color getColor(int score) {
    switch (score) {
      case 10:
        return AppColors.ring10;
      case 9:
        return AppColors.ring9;
      case 8:
        return AppColors.ring8;
      case 7:
        return AppColors.ring7;
      case 6:
        return AppColors.ring6;
      case 5:
        return AppColors.ring5;
      case 4:
        return AppColors.ring4;
      case 3:
        return AppColors.ring3;
      case 2:
        return AppColors.ring2;
      case 1:
        return AppColors.ring1;
      default:
        return AppColors.textMuted;
    }
  }
}

/// Target ring boundaries in millimeters from center.
/// Single source of truth for scoring with sub-millimeter precision.
///
/// WA (World Archery) standard target faces have 10 concentric rings plus
/// an inner X ring (counts as 10 but tracked separately for tiebreaks).
/// Ring boundaries scale proportionally with face size.
class TargetRingsMm {
  /// Epsilon for floating point comparisons (0.001mm = 1 micron tolerance)
  static const double epsilon = 0.001;

  /// Ring boundary as percentage of face radius (WA standard)
  /// Each ring is 10% of the total face radius
  static const List<double> ringPercentages = [
    0.05,  // X ring (inner 10) - 5% of radius
    0.10,  // Ring 10 - 10% of radius
    0.20,  // Ring 9
    0.30,  // Ring 8
    0.40,  // Ring 7
    0.50,  // Ring 6
    0.60,  // Ring 5
    0.70,  // Ring 4
    0.80,  // Ring 3
    0.90,  // Ring 2
    1.00,  // Ring 1 (outer edge)
  ];

  /// Get the X ring boundary in mm for a given face size
  static double getXRingMm(int faceSizeCm) {
    final radiusMm = faceSizeCm * 5.0;
    return radiusMm * 0.05; // X ring is 5% of radius
  }

  /// Get the outer boundary of a ring in mm
  /// Ring 10 is innermost scoring ring, Ring 1 is outermost
  static double getRingBoundaryMm(int ring, int faceSizeCm) {
    if (ring < 1 || ring > 10) {
      throw ArgumentError('Ring must be 1-10, got $ring');
    }
    final radiusMm = faceSizeCm * 5.0;
    // Ring 10 is at index 1, ring 1 is at index 10
    final percentIndex = 11 - ring;
    return radiusMm * ringPercentages[percentIndex];
  }

  /// Get all ring boundaries as a map {ring: boundaryMm}
  static Map<int, double> getAllBoundariesMm(int faceSizeCm) {
    return {
      for (int ring = 1; ring <= 10; ring++)
        ring: getRingBoundaryMm(ring, faceSizeCm),
    };
  }

  /// Get score from distance in mm with epsilon tolerance.
  /// This is the definitive scoring function - visual display must match this.
  /// For 10-zone scoring, returns the ring number (10-1).
  /// For 5-zone scoring, returns the color score (9-7-5-3-1).
  static int scoreFromDistanceMm(
    double distanceMm,
    int faceSizeCm, {
    String scoringType = '10-zone',
  }) {
    // First get the 10-zone ring number
    int ring;

    // Check each ring from inside out
    // X ring counts as 10
    if (distanceMm <= getXRingMm(faceSizeCm) + epsilon) {
      ring = 10;
    } else {
      ring = 0; // Default to miss
      // Ring 10 through Ring 1
      for (int r = 10; r >= 1; r--) {
        final boundaryMm = getRingBoundaryMm(r, faceSizeCm);
        if (distanceMm <= boundaryMm + epsilon) {
          ring = r;
          break;
        }
      }
    }

    // Convert to 5-zone scoring if needed
    if (scoringType == '5-zone') {
      return ringTo5ZoneScore(ring);
    }

    return ring;
  }

  /// Convert a 10-zone ring number to a 5-zone score.
  /// 5-zone scoring: Gold=9, Red=7, Blue=5, Black=3, White=1, Miss=0
  static int ringTo5ZoneScore(int ring) {
    // Gold (X/10/9) → 9
    if (ring >= 9) return 9;
    // Red (8/7) → 7
    if (ring >= 7) return 7;
    // Blue (6/5) → 5
    if (ring >= 5) return 5;
    // Black (4/3) → 3
    if (ring >= 3) return 3;
    // White (2/1) → 1
    if (ring >= 1) return 1;
    // Miss
    return 0;
  }

  /// Check if distance is in the X ring (for X count tracking)
  static bool isXRing(double distanceMm, int faceSizeCm) {
    return distanceMm <= getXRingMm(faceSizeCm) + epsilon;
  }

  /// Get score and X status in one call
  static ({int score, bool isX}) scoreAndX(
    double distanceMm,
    int faceSizeCm, {
    String scoringType = '10-zone',
  }) {
    return (
      score: scoreFromDistanceMm(distanceMm, faceSizeCm, scoringType: scoringType),
      isX: isXRing(distanceMm, faceSizeCm),
    );
  }

  /// Get the ring number for a given distance (not the score).
  /// Returns 11 for X ring, 10-1 for standard rings, 0 for miss.
  static int getRingNumber(double distanceMm, int faceSizeCm) {
    if (distanceMm <= getXRingMm(faceSizeCm) + epsilon) {
      return 11; // X ring
    }
    for (int ring = 10; ring >= 1; ring--) {
      final boundaryMm = getRingBoundaryMm(ring, faceSizeCm);
      if (distanceMm <= boundaryMm + epsilon) {
        return ring;
      }
    }
    return 0; // Miss
  }

  /// Get color for a ring/score value
  static Color getColor(int score) {
    return TargetRings.getColor(score);
  }

  /// Get contrasting text color for a ring (for arrow markers)
  static Color getContrastingTextColor(int score) {
    switch (score) {
      case 10:
      case 9:
        return Colors.black; // Black text on gold
      case 8:
      case 7:
        return Colors.white; // White text on red
      case 6:
      case 5:
        return Colors.white; // White text on blue
      case 4:
      case 3:
        return Colors.white; // White text on black
      case 2:
      case 1:
        return Colors.black; // Black text on white
      default:
        return Colors.white;
    }
  }

  /// Standard face sizes in WA rules (in cm)
  static const List<int> standardFaceSizes = [122, 80, 60, 40];

  /// Common face size descriptions
  static String faceSizeDescription(int faceSizeCm) {
    switch (faceSizeCm) {
      case 122:
        return '122cm (Outdoor 70m/90m)';
      case 80:
        return '80cm (Outdoor 50m/60m)';
      case 60:
        return '60cm (Outdoor 30m)';
      case 40:
        return '40cm (Indoor 18m/25m)';
      default:
        return '${faceSizeCm}cm';
    }
  }
}
