import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../theme/app_theme.dart';

/// Archery mode affects slope range and styling
enum ArcheryMode {
  /// Target archery - flat fields, mild slopes (±12°)
  target,

  /// Field archery - varied terrain, steep slopes (±45°)
  field,
}

/// Visual slope slider showing an archer shooting at a target
///
/// - Target archery mode: mild slopes up to ±12° (gold theme)
/// - Field archery mode: steep slopes up to ±45° (green theme)
///
/// Hold at the extreme end to switch to field archery mode
class SlopeSlider extends StatefulWidget {
  final double value; // degrees
  final ValueChanged<double>? onChanged;
  final bool enabled;
  final ArcheryMode? initialMode;

  const SlopeSlider({
    super.key,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.initialMode,
  });

  @override
  State<SlopeSlider> createState() => _SlopeSliderState();
}

class _SlopeSliderState extends State<SlopeSlider> {
  late ArcheryMode _mode;
  Timer? _holdTimer;
  bool _isHolding = false;

  // Target archery: ±12° max
  static const double _targetMax = 12.0;
  // Field archery: ±45° max
  static const double _fieldMax = 45.0;

  double get _currentMax => _mode == ArcheryMode.target ? _targetMax : _fieldMax;

  Color get _themeColor =>
      _mode == ArcheryMode.target ? AppColors.gold : const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    // Auto-detect mode based on initial value
    if (widget.initialMode != null) {
      _mode = widget.initialMode!;
    } else if (widget.value.abs() > _targetMax) {
      _mode = ArcheryMode.field;
    } else {
      _mode = ArcheryMode.target;
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _onSliderChanged(double value) {
    widget.onChanged?.call(value);

    // Check if at extreme in target mode
    if (_mode == ArcheryMode.target && value.abs() >= _targetMax - 0.5) {
      if (!_isHolding) {
        _isHolding = true;
        _holdTimer?.cancel();
        _holdTimer = Timer(const Duration(milliseconds: 800), () {
          if (_isHolding && mounted) {
            setState(() => _mode = ArcheryMode.field);
            // Haptic feedback would go here
          }
        });
      }
    } else {
      _isHolding = false;
      _holdTimer?.cancel();
    }
  }

  void _onSliderEnd(double value) {
    _isHolding = false;
    _holdTimer?.cancel();
  }

  void _toggleMode() {
    setState(() {
      if (_mode == ArcheryMode.target) {
        _mode = ArcheryMode.field;
      } else {
        _mode = ArcheryMode.target;
        // Clamp value to target range
        if (widget.value.abs() > _targetMax) {
          widget.onChanged?.call(widget.value.sign * _targetMax);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Clamp display value to current mode's range
    final displayValue = widget.value.clamp(-_currentMax, _currentMax);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row with mode toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Slope',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Mode indicator/toggle
                GestureDetector(
                  onTap: _toggleMode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _themeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _themeColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      _mode == ArcheryMode.target ? 'TARGET' : 'FIELD',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _themeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              _getSlopeDescription(displayValue),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: displayValue == 0 ? AppColors.textMuted : _themeColor,
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
                slopeAngle: displayValue,
                enabled: widget.enabled,
                mode: _mode,
                themeColor: _themeColor,
              ),
              size: const Size(double.infinity, 80),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _themeColor,
            inactiveTrackColor: AppColors.surfaceBright,
            thumbColor: _themeColor,
            overlayColor: _themeColor.withValues(alpha: 0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: displayValue,
            min: -_currentMax,
            max: _currentMax,
            divisions: (_currentMax * 2).round(),
            onChanged: widget.enabled
                ? (v) {
                    _onSliderChanged(v);
                    widget.onChanged?.call(v);
                  }
                : null,
            onChangeEnd: widget.enabled ? _onSliderEnd : null,
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

        // Field mode hint (only in target mode at extreme)
        if (_mode == ArcheryMode.target && widget.value.abs() >= _targetMax - 1)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Center(
              child: Text(
                'Hold for field archery mode',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.7),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ),
      ],
    );
  }

  String _getSlopeDescription(double angle) {
    if (angle == 0) return 'Level';

    final absAngle = angle.abs().round();
    final direction = angle < 0 ? 'uphill' : 'downhill';

    if (_mode == ArcheryMode.target) {
      // Target archery - gentle descriptions
      if (absAngle <= 2) return 'Barely $direction ($absAngle°)';
      if (absAngle <= 5) return 'Slight $direction ($absAngle°)';
      if (absAngle <= 8) return 'Gentle $direction ($absAngle°)';
      return 'Moderate $direction ($absAngle°)';
    } else {
      // Field archery - includes steeper terrain
      if (absAngle <= 3) return 'Slight $direction ($absAngle°)';
      if (absAngle <= 8) return 'Gentle $direction ($absAngle°)';
      if (absAngle <= 15) return 'Moderate $direction ($absAngle°)';
      if (absAngle <= 30) return 'Steep $direction ($absAngle°)';
      return 'Very steep $direction ($absAngle°)';
    }
  }
}

/// Custom painter that draws an archer shooting at a target with slope angle
class _SlopePainter extends CustomPainter {
  final double slopeAngle;
  final bool enabled;
  final ArcheryMode mode;
  final Color themeColor;

  _SlopePainter({
    required this.slopeAngle,
    required this.enabled,
    required this.mode,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final archerColor = enabled ? themeColor : AppColors.textMuted;
    final targetColor = enabled ? themeColor : AppColors.textMuted;
    final groundColor = mode == ArcheryMode.field
        ? const Color(0xFF4CAF50).withValues(alpha: 0.5) // Green for field
        : AppColors.surfaceBright;

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

    // Draw terrain (different for field vs target)
    if (mode == ArcheryMode.field) {
      _drawFieldTerrain(canvas, size, archerBaseY, targetBaseY, groundColor);
    } else {
      _drawFlatGround(canvas, size, archerX, archerBaseY, targetX, targetBaseY,
          groundColor);
    }

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

  void _drawFlatGround(Canvas canvas, Size size, double archerX,
      double archerBaseY, double targetX, double targetBaseY, Color color) {
    final groundPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final groundPath = Path();
    groundPath.moveTo(0, archerBaseY);
    groundPath.lineTo(archerX, archerBaseY);
    groundPath.lineTo(targetX, targetBaseY);
    groundPath.lineTo(size.width, targetBaseY);
    canvas.drawPath(groundPath, groundPaint);
  }

  void _drawFieldTerrain(Canvas canvas, Size size, double archerY,
      double targetY, Color color) {
    // Draw wavy terrain for field archery
    final terrainPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, archerY);

    // Create undulating terrain
    final segments = 8;
    final dx = size.width / segments;

    for (int i = 0; i <= segments; i++) {
      final x = i * dx;
      final progress = i / segments;
      final baseY = archerY + (targetY - archerY) * progress;

      // Add some waviness for field terrain feel
      final wave = (i > 0 && i < segments)
          ? math.sin(i * 0.8) * (slopeAngle.abs() > 10 ? 3 : 1)
          : 0.0;

      if (i == 0) {
        path.moveTo(x, baseY + wave);
      } else {
        path.lineTo(x, baseY + wave);
      }
    }

    // Complete the fill
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, terrainPaint);

    // Draw some grass marks for field feel
    final grassPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i < segments; i += 2) {
      final x = i * dx;
      final progress = i / segments;
      final baseY = archerY + (targetY - archerY) * progress;

      canvas.drawLine(
        Offset(x, baseY),
        Offset(x - 2, baseY - 4),
        grassPaint,
      );
      canvas.drawLine(
        Offset(x, baseY),
        Offset(x + 2, baseY - 3),
        grassPaint,
      );
    }
  }

  void _drawArcher(
      Canvas canvas, double x, double y, Color color, double aimAngle) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

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
      ..color = mode == ArcheryMode.field
          ? const Color(0xFF4CAF50) // Green center for field
          : AppColors.gold
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
        oldDelegate.enabled != enabled ||
        oldDelegate.mode != mode ||
        oldDelegate.themeColor != themeColor;
  }
}
