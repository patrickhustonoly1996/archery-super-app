import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable stat box widget for displaying metrics.
///
/// Shows a value with a label, commonly used for displaying
/// statistics like score, Xs, percentage, ends, etc.
///
/// Usage:
/// ```dart
/// StatBox(
///   label: 'Score',
///   value: '285',
///   highlighted: true,
/// )
/// ```
class StatBox extends StatelessWidget {
  /// The label text shown below the value
  final String label;

  /// The main value to display
  final String value;

  /// Whether to highlight the value in gold
  final bool highlighted;

  /// Whether to show a background container
  final bool showBackground;

  const StatBox({
    super.key,
    required this.label,
    required this.value,
    this.highlighted = false,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: highlighted ? AppColors.gold : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );

    if (showBackground) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: content,
      );
    }

    return content;
  }
}
