import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Streak arrow tiers - flaming arrows for consecutive practice days
enum StreakTier {
  spark(7, 'Spark', Color(0xFFFF6B35), Color(0xFFFFAA00)),     // 7 days - orange flame
  blaze(14, 'Blaze', Color(0xFFFF3366), Color(0xFFFF6B35)),   // 14 days - pink/orange
  inferno(30, 'Inferno', Color(0xFFFF0044), Color(0xFFFF3366)), // 30 days - red/pink
  phoenix(60, 'Phoenix', Color(0xFF9933FF), Color(0xFFFF0044)), // 60 days - purple/red
  legendary(90, 'Legendary', Color(0xFFFFD700), Color(0xFF9933FF)); // 90 days - gold/purple

  const StreakTier(this.days, this.displayName, this.primaryColor, this.secondaryColor);

  final int days;
  final String displayName;
  final Color primaryColor;
  final Color secondaryColor;

  /// Get tier from streak days
  static StreakTier? fromDays(int streakDays) {
    if (streakDays >= 90) return StreakTier.legendary;
    if (streakDays >= 60) return StreakTier.phoenix;
    if (streakDays >= 30) return StreakTier.inferno;
    if (streakDays >= 14) return StreakTier.blaze;
    if (streakDays >= 7) return StreakTier.spark;
    return null;
  }
}

/// Trophy tiers for competition achievements
enum TrophyTier {
  bronze('Bronze', Color(0xFFCD7F32), Color(0xFF8B4513)),
  silver('Silver', Color(0xFFC0C0C0), Color(0xFF808080)),
  gold('Gold', Color(0xFFFFD700), Color(0xFFDAA520)),
  champion('Champion', Color(0xFF00BFFF), Color(0xFF0080FF)); // Diamond/crystal

  const TrophyTier(this.displayName, this.primaryColor, this.secondaryColor);

  final String displayName;
  final Color primaryColor;
  final Color secondaryColor;
}

/// Crown tiers for level milestones
enum CrownTier {
  copper(10, 'Copper', Color(0xFFB87333), Color(0xFF8B4513)),
  silver(25, 'Silver', Color(0xFFC0C0C0), Color(0xFF808080)),
  gold(50, 'Gold', Color(0xFFFFD700), Color(0xFFDAA520)),
  platinum(75, 'Platinum', Color(0xFF00BFFF), Color(0xFF87CEEB)),
  legendary(99, 'Legendary', Color(0xFF9933FF), Color(0xFFFF00FF));

  const CrownTier(this.level, this.displayName, this.primaryColor, this.secondaryColor);

  final int level;
  final String displayName;
  final Color primaryColor;
  final Color secondaryColor;

  /// Get crown tier from level
  static CrownTier? fromLevel(int level) {
    if (level >= 99) return CrownTier.legendary;
    if (level >= 75) return CrownTier.platinum;
    if (level >= 50) return CrownTier.gold;
    if (level >= 25) return CrownTier.silver;
    if (level >= 10) return CrownTier.copper;
    return null;
  }
}

/// Star types for personal bests
enum StarType {
  practicePb('Practice PB', Color(0xFF00FF88), Color(0xFF00CC66)),
  competitionPb('Competition PB', Color(0xFF00BFFF), Color(0xFF0080FF)),
  roundRecord('Round Record', Color(0xFFFFD700), Color(0xFFFF8C00));

  const StarType(this.displayName, this.primaryColor, this.secondaryColor);

  final String displayName;
  final Color primaryColor;
  final Color secondaryColor;
}

/// Gem types for special achievements
enum GemType {
  sapphire('Sapphire', Color(0xFF0066FF), Color(0xFF0044CC)),
  ruby('Ruby', Color(0xFFE53935), Color(0xFFB71C1C)),
  emerald('Emerald', Color(0xFF00C853), Color(0xFF00962D)),
  diamond('Diamond', Color(0xFF00E5FF), Color(0xFFFFFFFF)),
  amethyst('Amethyst', Color(0xFF9C27B0), Color(0xFF6A1B9A));

  const GemType(this.displayName, this.primaryColor, this.highlightColor);

  final String displayName;
  final Color primaryColor;
  final Color highlightColor;
}

/// Chest types for XP rewards
enum ChestType {
  wooden('Wooden', Color(0xFF8B4513), Color(0xFFCD853F)),
  iron('Iron', Color(0xFF808080), Color(0xFFA9A9A9)),
  golden('Golden', Color(0xFFFFD700), Color(0xFFFFF8DC)),
  legendary('Legendary', Color(0xFF9933FF), Color(0xFFFF00FF));

  const ChestType(this.displayName, this.primaryColor, this.accentColor);

  final String displayName;
  final Color primaryColor;
  final Color accentColor;
}

/// Medal classifications (AGB system)
enum MedalClassification {
  a3('A3', AwardColors.white),
  a2('A2', AwardColors.white),
  a1('A1', AwardColors.white),
  b3('B3', AwardColors.black),
  b2('B2', AwardColors.black),
  b1('B1', AwardColors.black),
  mb('MB', AwardColors.blue),
  bmb('BMB', AwardColors.red),
  smb('SMB', AwardColors.gold),
  gmb('GMB', AwardColors.purple);

  const MedalClassification(this.displayName, this.color);

  final String displayName;
  final Color color;

  /// Get text color for contrast
  Color get textColor => AwardColors.getTextColor(color);
}

/// Archery-specific icon types
enum ArcheryIconType {
  bullseye('Bullseye', Color(0xFFFFD700)),
  bow('Bow', Color(0xFF8B4513)),
  quiver('Quiver', Color(0xFF8B4513)),
  wind('Wind', Color(0xFF00BFFF)),
  book('Book', Color(0xFF9C27B0)),
  chart('Chart', Color(0xFF00FF88));

  const ArcheryIconType(this.displayName, this.color);

  final String displayName;
  final Color color;
}
