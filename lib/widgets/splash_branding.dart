import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Branded splash screen showing app icon and "built by HUSTON ARCHERY"
class SplashBranding extends StatelessWidget {
  const SplashBranding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon (golden arrow)
            Image.asset(
              'assets/favicon.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if icon not found
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.gps_fixed,
                    size: 60,
                    color: AppColors.backgroundDark,
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Branding text
            Text(
              'built by',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                color: AppColors.textMuted,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'HUSTON ARCHERY',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 24,
                color: AppColors.gold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 48),
            // Subtle loading indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.gold,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
