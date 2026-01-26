import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Light quality options for outdoor archery
enum LightQuality {
  directSun('direct_sun', 'Direct Sun', 'Full sun, harsh shadows'),
  partialSun('partial_sun', 'Partial Sun', 'Sun through light clouds'),
  brightCloudy('bright_cloudy', 'Bright Cloudy', 'Overcast but bright'),
  overcast('overcast', 'Overcast', 'Dull, even light');

  final String value;
  final String displayName;
  final String description;

  const LightQuality(this.value, this.displayName, this.description);

  static LightQuality? fromString(String? value) {
    if (value == null) return null;
    // Handle old sky values
    switch (value) {
      case 'sunny':
        return LightQuality.directSun;
      case 'cloudy':
        return LightQuality.brightCloudy;
      case 'overcast':
        return LightQuality.overcast;
      case 'rainy':
        return LightQuality.overcast;
      default:
        return LightQuality.values.where((e) => e.value == value).firstOrNull;
    }
  }

  /// Convert to old sky string for backwards compatibility
  String toSkyString() {
    switch (this) {
      case LightQuality.directSun:
        return 'sunny';
      case LightQuality.partialSun:
        return 'cloudy';
      case LightQuality.brightCloudy:
        return 'cloudy';
      case LightQuality.overcast:
        return 'overcast';
    }
  }
}

/// Light quality options for indoor archery
enum IndoorLightQuality {
  bright('bright', 'Bright', 'Well-lit venue'),
  regular('regular', 'Regular', 'Standard indoor lighting'),
  dim('dim', 'Dim', 'Low lighting'),
  dark('dark', 'Dark', 'Poorly lit');

  final String value;
  final String displayName;
  final String description;

  const IndoorLightQuality(this.value, this.displayName, this.description);

  static IndoorLightQuality? fromString(String? value) {
    if (value == null) return null;
    return IndoorLightQuality.values.where((e) => e.value == value).firstOrNull;
  }
}

/// Sun position relative to the archer (8 compass directions + overhead)
enum SunPosition {
  none('none', 'N/A', 'No direct sun'),
  // Cardinal directions (relative to archer facing target)
  inFace('in_face', 'N', 'Sun behind target (in face)'),
  right('right', 'E', 'Sun on archer\'s right'),
  behind('behind', 'S', 'Sun behind archer'),
  left('left', 'W', 'Sun on archer\'s left'),
  // Diagonal directions
  frontRight('front_right', 'NE', 'Sun front-right'),
  backRight('back_right', 'SE', 'Sun back-right'),
  backLeft('back_left', 'SW', 'Sun back-left'),
  frontLeft('front_left', 'NW', 'Sun front-left'),
  // Overhead
  overhead('overhead', 'OVER', 'Sun directly above');

  final String value;
  final String displayName;
  final String description;

  const SunPosition(this.value, this.displayName, this.description);

  static SunPosition? fromString(String? value) {
    if (value == null) return null;
    // Handle legacy values
    if (value == 'in_face') return SunPosition.inFace;
    if (value == 'behind') return SunPosition.behind;
    if (value == 'left') return SunPosition.left;
    if (value == 'right') return SunPosition.right;
    if (value == 'overhead') return SunPosition.overhead;
    if (value == 'none') return SunPosition.none;
    return SunPosition.values.where((e) => e.value == value).firstOrNull;
  }
}

/// Combined sun position and light quality selector
class SunLightSelector extends StatelessWidget {
  final SunPosition? sunPosition;
  final LightQuality? lightQuality;
  final ValueChanged<SunPosition?>? onSunPositionChanged;
  final ValueChanged<LightQuality?>? onLightQualityChanged;
  final bool enabled;

  const SunLightSelector({
    super.key,
    this.sunPosition,
    this.lightQuality,
    this.onSunPositionChanged,
    this.onLightQualityChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Light quality section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Light',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            if (lightQuality != null || sunPosition != null)
              GestureDetector(
                onTap: enabled
                    ? () {
                        onLightQualityChanged?.call(null);
                        onSunPositionChanged?.call(null);
                      }
                    : null,
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

        // Light quality chips
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: LightQuality.values.map((quality) {
            final isSelected = lightQuality == quality;
            return GestureDetector(
              onTap: enabled
                  ? () => onLightQualityChanged
                      ?.call(isSelected ? null : quality)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _getLightColor(quality).withValues(alpha: 0.2)
                      : AppColors.surfaceBright,
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                  border: isSelected
                      ? Border.all(color: _getLightColor(quality))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getLightIcon(quality),
                      size: 14,
                      color: isSelected
                          ? _getLightColor(quality)
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      quality.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? _getLightColor(quality)
                                : AppColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // Sun position section (only show if sun is visible)
        if (lightQuality == LightQuality.directSun ||
            lightQuality == LightQuality.partialSun) ...[
          const SizedBox(height: AppSpacing.md),

          Text(
            'Sun Direction (relative to target)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Visual sun position selector - 8 compass directions
          Center(
            child: SizedBox(
              width: 200,
              height: 160,
              child: CustomPaint(
                painter: _SunPositionPainter(
                  selectedPosition: sunPosition,
                  enabled: enabled,
                ),
                child: _buildSunPositionButtons(context),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSunPositionButtons(BuildContext context) {
    // 8 compass points arranged in a circle + overhead in center
    return Stack(
      children: [
        // N - In Face (top center)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: _buildSunButton(context, SunPosition.inFace, 'N'),
          ),
        ),

        // NE - Front Right (top right)
        Positioned(
          top: 12,
          right: 12,
          child: _buildSunButton(context, SunPosition.frontRight, 'NE'),
        ),

        // E - Right (middle right)
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Center(
            child: _buildSunButton(context, SunPosition.right, 'E'),
          ),
        ),

        // SE - Back Right (bottom right)
        Positioned(
          bottom: 12,
          right: 12,
          child: _buildSunButton(context, SunPosition.backRight, 'SE'),
        ),

        // S - Behind (bottom center)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: _buildSunButton(context, SunPosition.behind, 'S'),
          ),
        ),

        // SW - Back Left (bottom left)
        Positioned(
          bottom: 12,
          left: 12,
          child: _buildSunButton(context, SunPosition.backLeft, 'SW'),
        ),

        // W - Left (middle left)
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Center(
            child: _buildSunButton(context, SunPosition.left, 'W'),
          ),
        ),

        // NW - Front Left (top left)
        Positioned(
          top: 12,
          left: 12,
          child: _buildSunButton(context, SunPosition.frontLeft, 'NW'),
        ),

        // Overhead (center)
        Positioned.fill(
          child: Center(
            child: _buildSunButton(
              context,
              SunPosition.overhead,
              'OVER',
              isCenter: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSunButton(
    BuildContext context,
    SunPosition position,
    String label, {
    bool isCenter = false,
  }) {
    final isSelected = sunPosition == position;

    return GestureDetector(
      onTap: enabled
          ? () =>
              onSunPositionChanged?.call(isSelected ? null : position)
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCenter ? AppSpacing.sm : AppSpacing.xs,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          border: isSelected ? Border.all(color: AppColors.gold, width: 1) : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? AppColors.gold : AppColors.textMuted,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ),
    );
  }

  IconData _getLightIcon(LightQuality quality) {
    switch (quality) {
      case LightQuality.directSun:
        return Icons.wb_sunny;
      case LightQuality.partialSun:
        return Icons.wb_cloudy;
      case LightQuality.brightCloudy:
        return Icons.cloud;
      case LightQuality.overcast:
        return Icons.cloud_queue;
    }
  }

  Color _getLightColor(LightQuality quality) {
    switch (quality) {
      case LightQuality.directSun:
        return AppColors.gold;
      case LightQuality.partialSun:
        return const Color(0xFFFFB74D); // Light orange
      case LightQuality.brightCloudy:
        return AppColors.textSecondary;
      case LightQuality.overcast:
        return AppColors.textMuted;
    }
  }
}

/// Custom painter for sun position visual - shows compass with archer/target
class _SunPositionPainter extends CustomPainter {
  final SunPosition? selectedPosition;
  final bool enabled;

  _SunPositionPainter({
    required this.selectedPosition,
    required this.enabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw compass circle
    final compassPaint = Paint()
      ..color = AppColors.surfaceBright.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(centerX, centerY), 50, compassPaint);

    // Draw archer position (center-bottom of compass)
    _drawArcher(canvas, centerX, centerY + 20, enabled);

    // Draw target (center-top of compass - where archer is aiming)
    _drawTarget(canvas, centerX, centerY - 25, enabled);

    // Draw shooting line (archer to target)
    final linePaint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(centerX, centerY + 15),
      Offset(centerX, centerY - 20),
      linePaint,
    );
  }

  void _drawArcher(Canvas canvas, double x, double y, bool enabled) {
    final paint = Paint()
      ..color = enabled ? AppColors.gold : AppColors.textMuted
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Simple stick figure from above (circle for head, shoulders line)
    canvas.drawCircle(Offset(x, y), 4, paint);
    canvas.drawLine(Offset(x - 6, y + 6), Offset(x + 6, y + 6), paint);
  }

  void _drawTarget(Canvas canvas, double x, double y, bool enabled) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Target from above (concentric circles)
    paint.color = AppColors.textPrimary.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(x, y), 10, paint);

    paint.color = AwardColors.blue.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(x, y), 7, paint);

    paint.color = AwardColors.red.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(x, y), 4, paint);

    final fillPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 2, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SunPositionPainter oldDelegate) {
    return oldDelegate.selectedPosition != selectedPosition ||
        oldDelegate.enabled != enabled;
  }
}

/// Summary text for light conditions
String getLightConditionsSummary(LightQuality? light, SunPosition? sun) {
  if (light == null) return 'Not recorded';

  String summary = light.displayName;

  if (sun != null && sun != SunPosition.none) {
    if (light == LightQuality.directSun || light == LightQuality.partialSun) {
      summary += ' (${sun.displayName.toLowerCase()})';
    }
  }

  return summary;
}

/// Indoor light quality selector
class IndoorLightSelector extends StatelessWidget {
  final IndoorLightQuality? lightQuality;
  final ValueChanged<IndoorLightQuality?>? onLightQualityChanged;
  final bool enabled;

  const IndoorLightSelector({
    super.key,
    this.lightQuality,
    this.onLightQualityChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Light',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            if (lightQuality != null)
              GestureDetector(
                onTap: enabled ? () => onLightQualityChanged?.call(null) : null,
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

        // Indoor light quality chips
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: IndoorLightQuality.values.map((quality) {
            final isSelected = lightQuality == quality;
            return GestureDetector(
              onTap: enabled
                  ? () => onLightQualityChanged?.call(isSelected ? null : quality)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _getIndoorLightColor(quality).withValues(alpha: 0.2)
                      : AppColors.surfaceBright,
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                  border: isSelected
                      ? Border.all(color: _getIndoorLightColor(quality))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getIndoorLightIcon(quality),
                      size: 14,
                      color: isSelected
                          ? _getIndoorLightColor(quality)
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      quality.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? _getIndoorLightColor(quality)
                                : AppColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getIndoorLightIcon(IndoorLightQuality quality) {
    switch (quality) {
      case IndoorLightQuality.bright:
        return Icons.lightbulb;
      case IndoorLightQuality.regular:
        return Icons.lightbulb_outline;
      case IndoorLightQuality.dim:
        return Icons.brightness_low;
      case IndoorLightQuality.dark:
        return Icons.brightness_3;
    }
  }

  Color _getIndoorLightColor(IndoorLightQuality quality) {
    switch (quality) {
      case IndoorLightQuality.bright:
        return AppColors.gold;
      case IndoorLightQuality.regular:
        return AppColors.textPrimary;
      case IndoorLightQuality.dim:
        return AppColors.textSecondary;
      case IndoorLightQuality.dark:
        return AppColors.textMuted;
    }
  }
}
