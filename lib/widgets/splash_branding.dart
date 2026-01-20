import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Branded splash screen showing app icon and "built by HUSTON ARCHERY"
/// Scales with text scale factor for accessibility
class SplashBranding extends StatelessWidget {
  const SplashBranding({super.key});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon (golden arrow)
            Image.asset(
              'assets/favicon.png',
              width: 120 * textScale,
              height: 120 * textScale,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if icon not found
                return Container(
                  width: 120 * textScale,
                  height: 120 * textScale,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(24 * textScale),
                  ),
                  child: Icon(
                    Icons.gps_fixed,
                    size: 60 * textScale,
                    color: AppColors.backgroundDark,
                  ),
                );
              },
            ),
            SizedBox(height: 32 * textScale),
            // Branding text
            Text(
              'built by',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14 * textScale,
                color: AppColors.textMuted,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 4 * textScale),
            Text(
              'HUSTON ARCHERY',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 24 * textScale,
                color: AppColors.gold,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 48 * textScale),
            // Subtle loading indicator
            SizedBox(
              width: 24 * textScale,
              height: 24 * textScale,
              child: CircularProgressIndicator(
                color: AppColors.gold,
                strokeWidth: 2 * textScale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
