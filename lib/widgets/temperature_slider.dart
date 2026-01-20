import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Temperature region affects how temperature feels are described
enum TemperatureRegion {
  /// UK/Northern Europe - 18°C is pleasant
  temperate('Temperate (UK, N. Europe)'),
  /// Mediterranean - warmer baseline
  mediterranean('Mediterranean'),
  /// Continental US/Australia - wider range comfort
  continental('Continental (US, AU)'),
  /// Tropical - hot baseline
  tropical('Tropical');

  final String displayName;
  const TemperatureRegion(this.displayName);
}

/// Temperature slider with 5 levels and location-aware descriptions
class TemperatureSlider extends StatelessWidget {
  final double? value; // Temperature in Celsius, null = not set
  final ValueChanged<double?>? onChanged;
  final TemperatureRegion region;
  final bool enabled;

  const TemperatureSlider({
    super.key,
    this.value,
    this.onChanged,
    this.region = TemperatureRegion.temperate,
    this.enabled = true,
  });

  // Temperature stops for the slider (5 positions)
  static const List<double> _tempStops = [-5, 5, 15, 25, 35];

  @override
  Widget build(BuildContext context) {
    // Find nearest stop for display, or use middle if not set
    final displayIndex = value != null ? _getNearestStopIndex(value!) : null;
    final displayTemp = displayIndex != null ? _tempStops[displayIndex] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Temperature',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            if (value != null)
              GestureDetector(
                onTap: enabled ? () => onChanged?.call(null) : null,
                child: Text(
                  'Clear',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gold.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Temperature display with description
        if (displayTemp != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _getTempColor(displayTemp).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(
                color: _getTempColor(displayTemp).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${displayTemp.round()}°C',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _getTempColor(displayTemp),
                      ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  _getTempDescription(displayTemp, region),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceBright.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Center(
              child: Text(
                'Tap a temperature below',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.sm),

        // Temperature buttons (5 stops)
        Row(
          children: List.generate(5, (index) {
            final temp = _tempStops[index];
            final isSelected = displayIndex == index;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 2,
                  right: index == 4 ? 0 : 2,
                ),
                child: GestureDetector(
                  onTap: enabled
                      ? () => onChanged?.call(isSelected ? null : temp)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getTempColor(temp)
                          : AppColors.surfaceBright,
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${temp.round()}°',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? AppColors.background
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                        ),
                        Text(
                          _getShortDescription(index),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? AppColors.background.withValues(alpha: 0.8)
                                    : AppColors.textMuted,
                                fontSize: 9,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  int _getNearestStopIndex(double temp) {
    int nearest = 0;
    double minDiff = (temp - _tempStops[0]).abs();

    for (int i = 1; i < _tempStops.length; i++) {
      final diff = (temp - _tempStops[i]).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearest = i;
      }
    }
    return nearest;
  }

  String _getShortDescription(int index) {
    switch (index) {
      case 0:
        return 'COLD';
      case 1:
        return 'COOL';
      case 2:
        return 'MILD';
      case 3:
        return 'WARM';
      case 4:
        return 'HOT';
      default:
        return '';
    }
  }

  /// Get temperature description based on region
  String _getTempDescription(double temp, TemperatureRegion region) {
    switch (region) {
      case TemperatureRegion.temperate:
        // UK baseline: 18°C is pleasant
        if (temp <= -5) return 'Freezing';
        if (temp <= 5) return 'Cold, layer up';
        if (temp <= 15) return 'Cool, bring a jacket';
        if (temp <= 25) return 'Pleasant';
        return 'Hot, stay hydrated';

      case TemperatureRegion.mediterranean:
        // Mediterranean: warmer baseline
        if (temp <= 5) return 'Cold for here';
        if (temp <= 15) return 'Cool';
        if (temp <= 25) return 'Pleasant';
        if (temp <= 35) return 'Warm, typical';
        return 'Very hot';

      case TemperatureRegion.continental:
        // US/Australia: wider comfort range
        if (temp <= -5) return 'Freezing cold';
        if (temp <= 5) return 'Cold';
        if (temp <= 15) return 'Cool';
        if (temp <= 25) return 'Comfortable';
        return 'Hot';

      case TemperatureRegion.tropical:
        // Tropical: hot baseline
        if (temp <= 15) return 'Unusually cool';
        if (temp <= 25) return 'Comfortable';
        if (temp <= 35) return 'Normal';
        return 'Very hot';
    }
  }

  /// Get color for temperature value
  Color _getTempColor(double temp) {
    if (temp <= -5) return const Color(0xFF64B5F6); // Light blue - freezing
    if (temp <= 5) return const Color(0xFF4FC3F7); // Cyan - cold
    if (temp <= 15) return const Color(0xFF81C784); // Green - cool/mild
    if (temp <= 25) return AppColors.gold; // Gold - pleasant/warm
    return const Color(0xFFFF7043); // Orange - hot
  }
}

/// Simple temperature input that just stores the actual value
/// Used when auto-fetching from weather API
class TemperatureDisplay extends StatelessWidget {
  final double temperature;
  final TemperatureRegion region;

  const TemperatureDisplay({
    super.key,
    required this.temperature,
    this.region = TemperatureRegion.temperate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${temperature.round()}°C',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.gold,
              ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          _getDescription(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  String _getDescription() {
    switch (region) {
      case TemperatureRegion.temperate:
        if (temperature <= 0) return 'Freezing';
        if (temperature <= 10) return 'Cold';
        if (temperature <= 18) return 'Cool';
        if (temperature <= 24) return 'Pleasant';
        return 'Hot';
      default:
        if (temperature <= 10) return 'Cold';
        if (temperature <= 20) return 'Cool';
        if (temperature <= 28) return 'Pleasant';
        return 'Hot';
    }
  }
}
