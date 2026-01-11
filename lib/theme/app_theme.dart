import 'package:flutter/material.dart';

/// Archery Super App design system
/// Dark base + Gold primary, minimal animation, 8px grid
/// Clean system fonts with subtle retro accent (VT323) for data/technical elements

class AppFonts {
  // System sans-serif for headlines and UI - professional, readable
  static const String display = '.SF Pro Display'; // Falls back to system default
  // VT323 for data readouts, scores, technical info - subtle retro nod
  static const String mono = 'VT323';
  // Body uses system default for maximum readability
  static const String body = '.SF Pro Text';
}

class AppColors {
  // Primary
  static const gold = Color(0xFFFFD700);
  static const goldMuted = Color(0x80FFD700); // 50% opacity

  // Background
  static const backgroundDark = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1E1E1E);
  static const surfaceLight = Color(0xFF2A2A2A);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0B0);
  static const textMuted = Color(0xFF8A8A8A); // Improved contrast (5.5:1 vs background)

  // Semantic
  static const error = Color(0xFFCF6679);
  static const success = Color(0xFF4CAF50);

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
      textTheme: const TextTheme(
        // Headlines - clean system font, professional
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        // Body text - system default for readability
        bodyLarge: TextStyle(
          fontSize: 17,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        // Use VT323 mono for scores/data via explicit styling, not in base theme
      ),
    );
  }
}

/// Target ring boundaries as fractions of target radius
/// WA 10-ring target: X is innermost, 1 is outermost
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
