import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'pixel_bow_icon.dart';

/// App logo - clean typography with the pixel arrow icon
class AppLogo extends StatelessWidget {
  final double size;
  final bool showSubtitle;

  const AppLogo({
    super.key,
    this.size = 1.0,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pixel arrow icon
        PixelBowIcon(size: 64 * size),
        SizedBox(height: 12 * size),
        // Clean typography
        Text(
          'Archery',
          style: TextStyle(
            fontSize: 28 * size,
            fontWeight: FontWeight.w600,
            color: AppColors.gold,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Super App',
          style: TextStyle(
            fontSize: 18 * size,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            letterSpacing: 0,
          ),
        ),
        if (showSubtitle) ...[
          SizedBox(height: 8 * size),
          Text(
            'Track. Analyse. Improve.',
            style: TextStyle(
              fontFamily: AppFonts.mono, // VT323 for subtle retro touch
              fontSize: 16 * size,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact inline logo for app bars and small spaces
class AppLogoCompact extends StatelessWidget {
  const AppLogoCompact({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelBowIcon(size: 28),
        const SizedBox(width: 8),
        const Text(
          'Archery',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.gold,
          ),
        ),
      ],
    );
  }
}
