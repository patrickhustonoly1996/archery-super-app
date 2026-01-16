import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'pixel_bow_icon.dart';

/// ASA Logo - matches the official logo design
/// Gold pixelated arrow with glow, "ARCHERY" text, and "SUPER APP" with decorative lines
class ASALogo extends StatelessWidget {
  final double scale;
  final bool showGlow;

  const ASALogo({
    super.key,
    this.scale = 1.0,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Arrow icon with glow
        Container(
          decoration: showGlow
              ? BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.6),
                      blurRadius: 40 * scale,
                      spreadRadius: 8 * scale,
                    ),
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 60 * scale,
                      spreadRadius: 16 * scale,
                    ),
                  ],
                )
              : null,
          child: PixelBowIcon(size: 80 * scale),
        ),
        SizedBox(height: 32 * scale),

        // "ARCHERY" text - chunky, wide letter spacing
        Text(
          'ARCHERY',
          style: TextStyle(
            fontFamily: AppFonts.pixel, // VT323
            fontSize: 36 * scale,
            color: AppColors.gold,
            letterSpacing: 8 * scale,
            height: 1.0,
          ),
        ),
        SizedBox(height: 16 * scale),

        // "SUPER APP" with decorative lines
        _SuperAppLine(scale: scale),
      ],
    );
  }
}

/// The "SUPER APP" text with decorative horizontal lines and squares
class _SuperAppLine extends StatelessWidget {
  final double scale;

  const _SuperAppLine({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left square
        Container(
          width: 8 * scale,
          height: 8 * scale,
          color: AppColors.gold,
        ),
        // Left line
        Container(
          width: 40 * scale,
          height: 2 * scale,
          color: AppColors.gold.withValues(alpha: 0.5),
        ),
        SizedBox(width: 12 * scale),
        // Text
        Text(
          'SUPER APP',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 14 * scale,
            color: AppColors.gold.withValues(alpha: 0.8),
            letterSpacing: 4 * scale,
          ),
        ),
        SizedBox(width: 12 * scale),
        // Right line
        Container(
          width: 40 * scale,
          height: 2 * scale,
          color: AppColors.gold.withValues(alpha: 0.5),
        ),
        // Right square
        Container(
          width: 8 * scale,
          height: 8 * scale,
          color: AppColors.gold,
        ),
      ],
    );
  }
}

/// Compact version of the logo for smaller spaces
class ASALogoCompact extends StatelessWidget {
  final double scale;

  const ASALogoCompact({super.key, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelBowIcon(size: 32 * scale),
        SizedBox(width: 12 * scale),
        Text(
          'ARCHERY',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 20 * scale,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
