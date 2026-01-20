import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

/// Visual slope slider showing an archer shooting at a target
/// Angle changes as slider moves to show uphill/downhill shooting
class SlopeSlider extends StatelessWidget {
  final double value; // -45 to +45 degrees
  final ValueChanged<double>? onChanged;
  final bool enabled;

  const SlopeSlider({
    super.key,
    required this.value,
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
              'Slope',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            Text(
              _getSlopeDescription(value),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: value == 0 ? AppColors.textMuted : AppColors.gold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Visual archer/target display
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surfaceBright.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            child: CustomPaint(
              painter: _SlopePainter(
                slopeAngle: value,
                enabled: enabled,
              ),
              size: const Size(double.infinity, 80),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.gold,
            inactiveTrackColor: AppColors.surfaceBright,
            thumbColor: AppColors.gold,
            overlayColor: AppColors.gold.withValues(alpha: 0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: -45,
            max: 45,
            divisions: 90, // 1 degree increments
            onChanged: enabled ? onChanged : null,
          ),
        ),

        // Labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UPHILL',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
              ),
              Text(
                'LEVEL',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
              ),
              Text(
                'DOWNHILL',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getSlopeDescription(double angle) {
    if (angle == 0) return 'Level';
    final absAngle = angle.abs().round();
    if (angle < 0) {
      if (absAngle <= 5) return '$absAngle° slight uphill';
      if (absAngle <= 15) return '$absAngle° uphill';
      if (absAngle <= 30) return '$absAngle° steep uphill';
      return '$absAngle° very steep uphill';
    } else {
      if (absAngle <= 5) return '$absAngle° slight downhill';
      if (absAngle <= 15) return '$absAngle° downhill';
      if (absAngle <= 30) return '$absAngle° steep downhill';
      return '$absAngle° very steep downhill';
    }
  }
}

/// Custom painter that draws an archer shooting at a target with slope angle
class _SlopePainter extends CustomPainter {
  final double slopeAngle;
  final bool enabled;

  _SlopePainter({
    required this.slopeAngle,
    required this.enabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final archerColor = enabled ? AppColors.gold : AppColors.textMuted;
    final targetColor = enabled ? AppColors.gold : AppColors.textMuted;
    final groundColor = AppColors.surfaceBright;

    // Calculate positions based on slope
    // Negative slope = uphill (target higher than archer)
    // Positive slope = downhill (target lower than archer)
    final centerY = size.height / 2;
    final angleRad = slopeAngle * math.pi / 180;

    // Ground line position
    final groundY = centerY + 15;

    // Archer position (left side)
    final archerX = size.width * 0.15;
    final archerBaseY = groundY;

    // Target position (right side)
    final targetX = size.width * 0.85;
    // Target moves up/down based on slope relative to archer
    final horizontalDist = targetX - archerX;
    final targetBaseY = archerBaseY + (horizontalDist * math.tan(angleRad));

    // Draw ground/hill line
    final groundPaint = Paint()
      ..color = groundColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final groundPath = Path();
    groundPath.moveTo(0, archerBaseY);
    groundPath.lineTo(archerX, archerBaseY);
    groundPath.lineTo(targetX, targetBaseY);
    groundPath.lineTo(size.width, targetBaseY);
    canvas.drawPath(groundPath, groundPaint);

    // Draw archer (simplified bow shape)
    _drawArcher(canvas, archerX, archerBaseY - 25, archerColor, angleRad);

    // Draw target
    _drawTarget(canvas, targetX, targetBaseY - 15, targetColor);

    // Draw arrow trajectory (dotted line)
    _drawTrajectory(
      canvas,
      Offset(archerX + 15, archerBaseY - 25),
      Offset(targetX - 10, targetBaseY - 15),
      archerColor.withValues(alpha: 0.5),
    );
  }

  void _drawArcher(
      Canvas canvas, double x, double y, Color color, double aimAngle) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Head (circle)
    canvas.drawCircle(Offset(x, y - 15), 5, paint);

    // Body (line)
    canvas.drawLine(Offset(x, y - 10), Offset(x, y + 5), paint);

    // Legs (stance)
    canvas.drawLine(Offset(x, y + 5), Offset(x - 5, y + 15), paint);
    canvas.drawLine(Offset(x, y + 5), Offset(x + 5, y + 15), paint);

    // Bow arm (extended toward target)
    final bowArmEnd = Offset(
      x + 12 * math.cos(aimAngle),
      y - 5 + 12 * math.sin(aimAngle),
    );
    canvas.drawLine(Offset(x, y - 5), bowArmEnd, paint);

    // Draw arm (pulled back)
    canvas.drawLine(Offset(x, y - 5), Offset(x - 8, y - 8), paint);

    // Bow (arc)
    final bowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final bowRect = Rect.fromCenter(
      center: Offset(bowArmEnd.dx, bowArmEnd.dy),
      width: 20,
      height: 30,
    );

    canvas.save();
    canvas.translate(bowArmEnd.dx, bowArmEnd.dy);
    canvas.rotate(aimAngle);
    canvas.drawArc(
      Rect.fromCenter(center: Offset.zero, width: 6, height: 25),
      -math.pi / 2 - 0.5,
      math.pi + 1,
      false,
      bowPaint,
    );
    canvas.restore();

    // Arrow nocked
    final arrowStart = Offset(x - 5, y - 6);
    final arrowEnd = Offset(
      bowArmEnd.dx + 3 * math.cos(aimAngle),
      bowArmEnd.dy + 3 * math.sin(aimAngle),
    );
    canvas.drawLine(arrowStart, arrowEnd, paint);
  }

  void _drawTarget(Canvas canvas, double x, double y, Color color) {
    // Draw target stand
    final standPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Stand legs
    canvas.drawLine(Offset(x - 5, y + 15), Offset(x, y - 5), standPaint);
    canvas.drawLine(Offset(x + 5, y + 15), Offset(x, y - 5), standPaint);

    // Target face (concentric circles)
    final targetPaint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Outer ring (white)
    targetPaint.color = AppColors.textPrimary.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(x, y), 12, targetPaint);

    // Blue ring
    targetPaint.color = AwardColors.blue.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(x, y), 9, targetPaint);

    // Red ring
    targetPaint.color = AwardColors.red.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(x, y), 6, targetPaint);

    // Gold center (filled)
    final goldPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 3, goldPaint);
  }

  void _drawTrajectory(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw dotted line
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final steps = (length / 8).round();

    for (int i = 0; i < steps; i++) {
      final t = i / steps;
      final x = start.dx + dx * t;
      final y = start.dy + dy * t;

      if (i % 2 == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw arrow head at end
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final angle = math.atan2(dy, dx);
    final arrowSize = 6.0;

    canvas.drawLine(
      end,
      Offset(
        end.dx - arrowSize * math.cos(angle - 0.4),
        end.dy - arrowSize * math.sin(angle - 0.4),
      ),
      arrowPaint,
    );
    canvas.drawLine(
      end,
      Offset(
        end.dx - arrowSize * math.cos(angle + 0.4),
        end.dy - arrowSize * math.sin(angle + 0.4),
      ),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SlopePainter oldDelegate) {
    return oldDelegate.slopeAngle != slopeAngle ||
        oldDelegate.enabled != enabled;
  }
}
