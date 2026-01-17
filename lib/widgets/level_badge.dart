import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/xp_calculation_service.dart';

/// Compact level badge for menu items
/// Shows current level with optional XP progress bar
class LevelBadge extends StatelessWidget {
  final int level;
  final int currentXp;
  final bool showProgress;
  final double size;

  const LevelBadge({
    super.key,
    required this.level,
    required this.currentXp,
    this.showProgress = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final progress = XpCalculationService.progressToNextLevel(currentXp);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Level number in gold box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.15),
            border: Border.all(color: AppColors.gold, width: 1),
          ),
          child: Text(
            'LV$level',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 10,
              color: AppColors.gold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (showProgress) ...[
          const SizedBox(width: 6),
          // XP progress bar
          SizedBox(
            width: 40,
            height: 4,
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Progress fill
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Larger level display for skills panel
class LevelDisplay extends StatelessWidget {
  final String skillName;
  final int level;
  final int currentXp;
  final VoidCallback? onTap;

  const LevelDisplay({
    super.key,
    required this.skillName,
    required this.level,
    required this.currentXp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = XpCalculationService.progressToNextLevel(currentXp);
    final xpToNext = XpCalculationService.xpToNextLevel(currentXp);
    final currentLevelXp = XpCalculationService.xpForLevel(level);
    final nextLevelXp = XpCalculationService.xpForLevel(level + 1);
    final xpInLevel = currentXp - currentLevelXp;
    final xpNeeded = nextLevelXp - currentLevelXp;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border.all(color: AppColors.surfaceLight, width: 1),
        ),
        child: Row(
          children: [
            // Level number
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 20,
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Skill name and progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skillName.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Progress bar
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // XP text
                  Text(
                    level >= 99
                        ? 'MAX LEVEL'
                        : '$xpInLevel / $xpNeeded XP',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow indicator
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
