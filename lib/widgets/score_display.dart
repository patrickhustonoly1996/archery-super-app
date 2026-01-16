import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable score display widget.
///
/// Shows a score value with optional maximum score and X count.
/// Provides consistent styling across all screens.
///
/// Usage:
/// ```dart
/// ScoreDisplay(
///   score: 285,
///   maxScore: 300,
///   xCount: 12,
/// )
/// ```
class ScoreDisplay extends StatelessWidget {
  /// The score value to display
  final int score;

  /// Optional maximum possible score (e.g., 300 for a 300 round)
  final int? maxScore;

  /// Optional X count (center shots)
  final int? xCount;

  /// Size variant
  final ScoreDisplaySize size;

  /// Whether to show the score in gold (highlight)
  final bool highlighted;

  const ScoreDisplay({
    super.key,
    required this.score,
    this.maxScore,
    this.xCount,
    this.size = ScoreDisplaySize.medium,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final scoreStyle = switch (size) {
      ScoreDisplaySize.small => textTheme.titleMedium,
      ScoreDisplaySize.medium => textTheme.headlineSmall,
      ScoreDisplaySize.large => textTheme.headlineMedium,
    };

    final secondaryStyle = switch (size) {
      ScoreDisplaySize.small => textTheme.bodySmall,
      ScoreDisplaySize.medium => textTheme.bodyMedium,
      ScoreDisplaySize.large => textTheme.titleMedium,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main score
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$score',
              style: scoreStyle?.copyWith(
                color: highlighted ? AppColors.gold : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (maxScore != null) ...[
              Text(
                '/$maxScore',
                style: secondaryStyle?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),

        // X count
        if (xCount != null && xCount! > 0)
          Text(
            '$xCount X\'s',
            style: secondaryStyle?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

/// Score display size variants
enum ScoreDisplaySize {
  /// Small - for list items
  small,
  /// Medium - for cards (default)
  medium,
  /// Large - for featured/hero displays
  large,
}

/// Compact inline score display for lists and tables
class InlineScoreDisplay extends StatelessWidget {
  final int score;
  final int? maxScore;
  final int? xCount;

  const InlineScoreDisplay({
    super.key,
    required this.score,
    this.maxScore,
    this.xCount,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$score',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (maxScore != null)
            TextSpan(
              text: '/$maxScore',
              style: TextStyle(
                color: AppColors.textMuted,
              ),
            ),
          if (xCount != null && xCount! > 0)
            TextSpan(
              text: ' ($xCount X)',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
