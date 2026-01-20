import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'pixel_bow_icon.dart';

/// App logo - clean typography with the pixel arrow icon
/// Scales with text scale factor when scaleWithText is true
class AppLogo extends StatelessWidget {
  final double size;
  final bool showSubtitle;
  final bool scaleWithText;

  const AppLogo({
    super.key,
    this.size = 1.0,
    this.showSubtitle = false,
    this.scaleWithText = true,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = scaleWithText
        ? MediaQuery.textScalerOf(context).scale(1.0)
        : 1.0;
    final effectiveSize = size * textScale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pixel arrow icon
        PixelBowIcon(size: 64 * effectiveSize, scaleWithText: false),
        SizedBox(height: 12 * effectiveSize),
        // Clean typography
        Text(
          'Archery',
          style: TextStyle(
            fontSize: 28 * effectiveSize,
            fontWeight: FontWeight.w600,
            color: AppColors.gold,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Super App',
          style: TextStyle(
            fontSize: 18 * effectiveSize,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            letterSpacing: 0,
          ),
        ),
        if (showSubtitle) ...[
          SizedBox(height: 8 * effectiveSize),
          Text(
            'Track. Analyse. Improve.',
            style: TextStyle(
              fontFamily: AppFonts.mono, // VT323 for subtle retro touch
              fontSize: 16 * effectiveSize,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact inline logo for app bars and small spaces
/// Scales with text scale factor when scaleWithText is true
class AppLogoCompact extends StatelessWidget {
  final bool scaleWithText;

  const AppLogoCompact({
    super.key,
    this.scaleWithText = true,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = scaleWithText
        ? MediaQuery.textScalerOf(context).scale(1.0)
        : 1.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelBowIcon(size: 28 * textScale, scaleWithText: false),
        SizedBox(width: 8 * textScale),
        Text(
          'Archery',
          style: TextStyle(
            fontSize: 16 * textScale,
            fontWeight: FontWeight.w600,
            color: AppColors.gold,
          ),
        ),
      ],
    );
  }
}
