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

  /// Whether the score exceeds the maximum (indicates a scoring bug)
  bool get _scoreExceedsMax => maxScore != null && score > maxScore!;

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

    // Determine score color - warn (red) if exceeds max, otherwise normal
    final scoreColor = _scoreExceedsMax
        ? Colors.red
        : (highlighted ? AppColors.gold : AppColors.textPrimary);

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
                color: scoreColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (maxScore != null) ...[
              Text(
                '/$maxScore',
                style: secondaryStyle?.copyWith(
                  color: _scoreExceedsMax ? Colors.red.shade300 : AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),

        // Warning if score exceeds maximum
        if (_scoreExceedsMax)
          Text(
            'Score exceeds maximum',
            style: TextStyle(
              color: Colors.red,
              fontSize: (secondaryStyle?.fontSize ?? 12) * 0.9,
              fontFamily: secondaryStyle?.fontFamily,
            ),
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

  /// Whether the score exceeds the maximum (indicates a scoring bug)
  bool get _scoreExceedsMax => maxScore != null && score > maxScore!;

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
              color: _scoreExceedsMax ? Colors.red : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (maxScore != null)
            TextSpan(
              text: '/$maxScore',
              style: TextStyle(
                color: _scoreExceedsMax ? Colors.red.shade300 : AppColors.textMuted,
              ),
            ),
          if (_scoreExceedsMax)
            TextSpan(
              text: ' (!)',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
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
