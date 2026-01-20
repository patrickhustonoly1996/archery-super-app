import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wind conditions using simplified Beaufort scale for archery
/// Shows visual indicators and practical descriptions
class WindSlider extends StatelessWidget {
  final int? beaufortScale; // 0-6+ (archery relevant range)
  final ValueChanged<int?>? onChanged;
  final bool enabled;

  const WindSlider({
    super.key,
    this.beaufortScale,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Wind',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            if (beaufortScale != null)
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

        // Wind display with description
        if (beaufortScale != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: _getWindColor(beaufortScale!).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(
                color: _getWindColor(beaufortScale!).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // Wind indicator (animated lines)
                SizedBox(
                  width: 40,
                  height: 30,
                  child: CustomPaint(
                    painter: _WindIndicatorPainter(
                      intensity: beaufortScale! / 6.0,
                      color: _getWindColor(beaufortScale!),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getWindName(beaufortScale!),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _getWindColor(beaufortScale!),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        _getWindDescription(beaufortScale!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'B${beaufortScale}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
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
                'Select wind conditions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.sm),

        // Slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: beaufortScale != null
                ? _getWindColor(beaufortScale!)
                : AppColors.textMuted,
            inactiveTrackColor: AppColors.surfaceBright,
            thumbColor: beaufortScale != null
                ? _getWindColor(beaufortScale!)
                : AppColors.textMuted,
            overlayColor: (beaufortScale != null
                    ? _getWindColor(beaufortScale!)
                    : AppColors.gold)
                .withValues(alpha: 0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: (beaufortScale ?? 0).toDouble(),
            min: 0,
            max: 6,
            divisions: 6,
            onChanged: enabled
                ? (value) => onChanged?.call(value.round())
                : null,
          ),
        ),

        // Labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel(context, 'CALM', 0),
              _buildLabel(context, 'LIGHT', 2),
              _buildLabel(context, 'MOD', 4),
              _buildLabel(context, 'STRONG', 6),
            ],
          ),
        ),

        // Archery impact note
        if (beaufortScale != null && beaufortScale! >= 4)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: _getWindColor(beaufortScale!),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _getArcheryImpact(beaufortScale!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getWindColor(beaufortScale!),
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLabel(BuildContext context, String text, int value) {
    final isSelected = beaufortScale == value;
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? _getWindColor(value) : AppColors.textMuted,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
    );
  }

  String _getWindName(int beaufort) {
    switch (beaufort) {
      case 0:
        return 'Calm';
      case 1:
        return 'Light Air';
      case 2:
        return 'Light Breeze';
      case 3:
        return 'Gentle Breeze';
      case 4:
        return 'Moderate Breeze';
      case 5:
        return 'Fresh Breeze';
      case 6:
      default:
        return 'Strong Breeze';
    }
  }

  String _getWindDescription(int beaufort) {
    switch (beaufort) {
      case 0:
        return 'Smoke rises vertically';
      case 1:
        return 'Smoke drifts, flags limp';
      case 2:
        return 'Leaves rustle, feel wind on face';
      case 3:
        return 'Leaves & twigs in motion';
      case 4:
        return 'Small branches move, flags extend';
      case 5:
        return 'Small trees sway';
      case 6:
      default:
        return 'Large branches move, wind whistles';
    }
  }

  String _getArcheryImpact(int beaufort) {
    switch (beaufort) {
      case 4:
        return 'Noticeable arrow drift - adjust aim';
      case 5:
        return 'Significant drift - timing between gusts advised';
      case 6:
      default:
        return 'Challenging conditions - consider pausing';
    }
  }

  Color _getWindColor(int beaufort) {
    if (beaufort <= 1) return AppColors.success; // Calm - green
    if (beaufort <= 2) return const Color(0xFF81C784); // Light - light green
    if (beaufort <= 3) return AppColors.gold; // Gentle - gold
    if (beaufort <= 4) return const Color(0xFFFFB74D); // Moderate - orange
    if (beaufort <= 5) return const Color(0xFFFF7043); // Fresh - deep orange
    return AppColors.error; // Strong - red
  }
}

/// Custom painter for wind indicator lines
class _WindIndicatorPainter extends CustomPainter {
  final double intensity; // 0.0 to 1.0
  final Color color;

  _WindIndicatorPainter({
    required this.intensity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final lineCount = 3;
    final spacing = size.height / (lineCount + 1);

    for (int i = 0; i < lineCount; i++) {
      final y = spacing * (i + 1);

      // Line length varies with intensity and position
      final baseLength = size.width * 0.4;
      final extraLength = size.width * 0.5 * intensity;
      final length = baseLength + extraLength * (1 - (i * 0.2));

      // Draw wavy line for higher intensity
      if (intensity > 0.3) {
        final path = Path();
        path.moveTo(0, y);

        final waves = (intensity * 3).ceil();
        final waveHeight = intensity * 4;

        for (int w = 0; w < waves; w++) {
          final segmentLength = length / waves;
          final x1 = segmentLength * w;
          final x2 = segmentLength * (w + 0.5);
          final x3 = segmentLength * (w + 1);

          path.quadraticBezierTo(
            x2,
            y + (w.isEven ? waveHeight : -waveHeight),
            x3.clamp(0, length),
            y,
          );
        }

        canvas.drawPath(path, paint..style = PaintingStyle.stroke);
      } else {
        // Simple straight line for calm conditions
        canvas.drawLine(
          Offset(0, y),
          Offset(length, y),
          paint,
        );
      }

      // Arrow head at end
      if (intensity > 0.1) {
        final arrowSize = 4.0 + intensity * 2;
        canvas.drawLine(
          Offset(length, y),
          Offset(length - arrowSize, y - arrowSize * 0.6),
          paint,
        );
        canvas.drawLine(
          Offset(length, y),
          Offset(length - arrowSize, y + arrowSize * 0.6),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WindIndicatorPainter oldDelegate) {
    return oldDelegate.intensity != intensity || oldDelegate.color != color;
  }
}

/// Convert wind speed (m/s) to Beaufort scale
int windSpeedToBeaufort(double speedMs) {
  if (speedMs < 0.3) return 0;
  if (speedMs < 1.6) return 1;
  if (speedMs < 3.4) return 2;
  if (speedMs < 5.5) return 3;
  if (speedMs < 8.0) return 4;
  if (speedMs < 10.8) return 5;
  return 6; // Cap at 6 for archery purposes
}

/// Convert Beaufort scale to approximate wind speed (m/s)
double beaufortToWindSpeed(int beaufort) {
  switch (beaufort) {
    case 0:
      return 0.0;
    case 1:
      return 0.9;
    case 2:
      return 2.5;
    case 3:
      return 4.4;
    case 4:
      return 6.7;
    case 5:
      return 9.4;
    case 6:
    default:
      return 12.0;
  }
}

/// Convert Beaufort to the old string format for backwards compatibility
String beaufortToWindString(int? beaufort) {
  if (beaufort == null) return 'none';
  if (beaufort <= 1) return 'none';
  if (beaufort <= 2) return 'light';
  if (beaufort <= 4) return 'moderate';
  return 'strong';
}

/// Convert old wind string to Beaufort
int? windStringToBeaufort(String? wind) {
  if (wind == null) return null;
  switch (wind) {
    case 'none':
      return 0;
    case 'light':
      return 2;
    case 'moderate':
      return 4;
    case 'strong':
      return 6;
    default:
      return null;
  }
}
