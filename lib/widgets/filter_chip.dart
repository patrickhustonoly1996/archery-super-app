import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable filter chip widget.
///
/// Shows a label with count and colored dot indicator.
/// Used for filtering and categorizing content.
///
/// Usage:
/// ```dart
/// AppFilterChip(
///   label: 'Training',
///   count: 12,
///   color: AppColors.neonGreen,
///   isSelected: true,
///   onTap: () => setState(() => selectedFilter = 'training'),
/// )
/// ```
class AppFilterChip extends StatelessWidget {
  /// The label text to display
  final String label;

  /// The count to show in parentheses
  final int count;

  /// Whether this chip is currently selected
  final bool isSelected;

  /// The color for the dot and selected state
  final Color color;

  /// Callback when the chip is tapped
  final VoidCallback onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$label ($count)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? color : AppColors.textMuted,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
