import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/sight_marks_provider.dart';
import '../models/sight_mark.dart';

/// Widget displaying the expected sight mark for a given bow and distance
class ExpectedSightMark extends StatelessWidget {
  final String? bowId;
  final double? distance;
  final DistanceUnit unit;

  const ExpectedSightMark({
    super.key,
    required this.bowId,
    required this.distance,
    this.unit = DistanceUnit.meters,
  });

  @override
  Widget build(BuildContext context) {
    if (bowId == null || distance == null || distance == 0) {
      return const SizedBox.shrink();
    }

    return Consumer<SightMarksProvider>(
      builder: (context, provider, child) {
        // Ensure marks are loaded
        provider.loadMarksForBow(bowId!);

        final prediction = provider.getPredictedMark(
          bowId: bowId!,
          distance: distance!,
          unit: unit,
        );

        if (prediction == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              // Sight icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: const Icon(
                  Icons.visibility,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Expected sight mark
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expected Sight Mark',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    Text(
                      '${prediction.distanceDisplay}: ${prediction.displayValue}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              // Confidence indicator
              _buildConfidenceIndicator(context, prediction),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfidenceIndicator(BuildContext context, PredictedSightMark prediction) {
    Color color;
    String label;
    IconData icon;

    switch (prediction.confidence) {
      case SightMarkConfidence.high:
        color = AppColors.gold;
        label = 'High';
        icon = Icons.verified;
        break;
      case SightMarkConfidence.medium:
        color = AppColors.textPrimary;
        label = 'Est.';
        icon = Icons.analytics_outlined;
        break;
      case SightMarkConfidence.low:
      case SightMarkConfidence.unknown:
        color = AppColors.textMuted;
        label = 'Low';
        icon = Icons.help_outline;
        break;
    }

    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 2),
        Text(
          prediction.isExact ? 'Recorded' : (prediction.isInterpolated ? 'Interpolated' : 'Extrapolated'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 9,
              ),
        ),
      ],
    );
  }
}

/// Compact expected sight mark for inline display
class ExpectedSightMarkCompact extends StatelessWidget {
  final String? bowId;
  final double? distance;
  final DistanceUnit unit;

  const ExpectedSightMarkCompact({
    super.key,
    required this.bowId,
    required this.distance,
    this.unit = DistanceUnit.meters,
  });

  @override
  Widget build(BuildContext context) {
    if (bowId == null || distance == null || distance == 0) {
      return const SizedBox.shrink();
    }

    return Consumer<SightMarksProvider>(
      builder: (context, provider, child) {
        provider.loadMarksForBow(bowId!);

        final prediction = provider.getPredictedMark(
          bowId: bowId!,
          distance: distance!,
          unit: unit,
        );

        if (prediction == null) {
          return const SizedBox.shrink();
        }

        final confidenceColor = prediction.confidence == SightMarkConfidence.high
            ? AppColors.gold
            : (prediction.confidence == SightMarkConfidence.medium
                ? AppColors.textPrimary
                : AppColors.textMuted);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility, color: confidenceColor, size: 14),
            const SizedBox(width: 4),
            Text(
              prediction.displayValue,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: confidenceColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        );
      },
    );
  }
}
