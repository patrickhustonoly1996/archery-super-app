import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated circular sweep guide for Auto-Plot scanning.
/// Displays a golden arc that shows scan progress and guides the user
/// through the ritualistic circular motion.
class CircularSweepGuide extends StatefulWidget {
  /// Progress from 0.0 to 1.0 representing scan completion
  final double progress;

  /// Whether scanning is currently active
  final bool isScanning;

  /// Whether the scan is complete
  final bool isComplete;

  /// Size of the guide (defaults to fill available space)
  final double? size;

  const CircularSweepGuide({
    super.key,
    required this.progress,
    required this.isScanning,
    this.isComplete = false,
    this.size,
  });

  @override
  State<CircularSweepGuide> createState() => _CircularSweepGuideState();
}

class _CircularSweepGuideState extends State<CircularSweepGuide>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the guide ring when idle
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Glow animation for the progress arc
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = widget.size ?? math.min(constraints.maxWidth, constraints.maxHeight) * 0.85;

        return AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
          builder: (context, child) {
            return CustomPaint(
              size: Size(size, size),
              painter: _CircularSweepPainter(
                progress: widget.progress,
                isScanning: widget.isScanning,
                isComplete: widget.isComplete,
                pulseValue: _pulseAnimation.value,
                glowValue: _glowAnimation.value,
              ),
            );
          },
        );
      },
    );
  }
}

class _CircularSweepPainter extends CustomPainter {
  final double progress;
  final bool isScanning;
  final bool isComplete;
  final double pulseValue;
  final double glowValue;

  _CircularSweepPainter({
    required this.progress,
    required this.isScanning,
    required this.isComplete,
    required this.pulseValue,
    required this.glowValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Draw outer guide ring (subtle when idle, brighter when scanning)
    _drawGuideRing(canvas, center, radius);

    // Draw progress arc
    if (isScanning || isComplete) {
      _drawProgressArc(canvas, center, radius);
    }

    // Draw tick marks around the circle
    _drawTickMarks(canvas, center, radius);

    // Draw center crosshair
    _drawCrosshair(canvas, center, radius);

    // Draw completion burst if done
    if (isComplete) {
      _drawCompletionBurst(canvas, center, radius);
    }

    // Draw motion indicator arrows when not scanning
    if (!isScanning && !isComplete) {
      _drawMotionIndicators(canvas, center, radius);
    }
  }

  void _drawGuideRing(Canvas canvas, Offset center, double radius) {
    final opacity = isScanning ? 0.8 : pulseValue;

    // Outer glow
    final glowPaint = Paint()
      ..color = AppColors.gold.withOpacity(opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius, glowPaint);

    // Main ring
    final ringPaint = Paint()
      ..color = AppColors.gold.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, ringPaint);

    // Inner subtle ring
    final innerRingPaint = Paint()
      ..color = AppColors.gold.withOpacity(opacity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius * 0.85, innerRingPaint);
  }

  void _drawProgressArc(Canvas canvas, Offset center, double radius) {
    final sweepAngle = progress * 2 * math.pi;
    final startAngle = -math.pi / 2; // Start from top

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Glowing progress arc
    final glowPaint = Paint()
      ..color = AppColors.gold.withOpacity(0.6 * glowValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    // Solid progress arc
    final arcPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);

    // Leading dot
    if (progress > 0 && progress < 1) {
      final dotAngle = startAngle + sweepAngle;
      final dotX = center.dx + radius * math.cos(dotAngle);
      final dotY = center.dy + radius * math.sin(dotAngle);

      // Dot glow
      final dotGlowPaint = Paint()
        ..color = AppColors.gold.withOpacity(0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(dotX, dotY), 10, dotGlowPaint);

      // Solid dot
      final dotPaint = Paint()..color = AppColors.gold;
      canvas.drawCircle(Offset(dotX, dotY), 6, dotPaint);
    }
  }

  void _drawTickMarks(Canvas canvas, Offset center, double radius) {
    final tickPaint = Paint()
      ..color = AppColors.gold.withOpacity(isScanning ? 0.6 : 0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Draw 12 tick marks (like a clock)
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final isMainTick = i % 3 == 0;
      final innerRadius = radius - (isMainTick ? 15 : 10);
      final outerRadius = radius - 5;

      final x1 = center.dx + innerRadius * math.cos(angle);
      final y1 = center.dy + innerRadius * math.sin(angle);
      final x2 = center.dx + outerRadius * math.cos(angle);
      final y2 = center.dy + outerRadius * math.sin(angle);

      tickPaint.strokeWidth = isMainTick ? 3 : 2;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }
  }

  void _drawCrosshair(Canvas canvas, Offset center, double radius) {
    final crosshairPaint = Paint()
      ..color = AppColors.gold.withOpacity(isScanning ? 0.8 : 0.4)
      ..strokeWidth = 1;

    final crosshairSize = radius * 0.15;

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - crosshairSize, center.dy),
      Offset(center.dx + crosshairSize, center.dy),
      crosshairPaint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - crosshairSize),
      Offset(center.dx, center.dy + crosshairSize),
      crosshairPaint,
    );

    // Center dot
    final dotPaint = Paint()
      ..color = AppColors.gold.withOpacity(isScanning ? 1.0 : 0.5);
    canvas.drawCircle(center, 3, dotPaint);
  }

  void _drawMotionIndicators(Canvas canvas, Offset center, double radius) {
    // Draw curved arrows indicating clockwise motion
    final arrowPaint = Paint()
      ..color = AppColors.gold.withOpacity(pulseValue * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Draw 4 motion arrows around the circle
    for (int i = 0; i < 4; i++) {
      final baseAngle = (i * 90 + 45) * math.pi / 180;
      final arrowRadius = radius + 25;

      // Arrow arc
      final arcLength = 25 * math.pi / 180;
      final startAngle = baseAngle - arcLength / 2;

      final rect = Rect.fromCircle(center: center, radius: arrowRadius);
      canvas.drawArc(rect, startAngle, arcLength, false, arrowPaint);

      // Arrow head
      final endAngle = startAngle + arcLength;
      final endX = center.dx + arrowRadius * math.cos(endAngle);
      final endY = center.dy + arrowRadius * math.sin(endAngle);

      // Calculate arrow head points (pointing clockwise)
      final headLength = 8.0;
      final headAngle1 = endAngle - math.pi * 0.7;
      final headAngle2 = endAngle - math.pi * 0.3;

      final headX1 = endX + headLength * math.cos(headAngle1);
      final headY1 = endY + headLength * math.sin(headAngle1);
      final headX2 = endX + headLength * math.cos(headAngle2);
      final headY2 = endY + headLength * math.sin(headAngle2);

      canvas.drawLine(Offset(endX, endY), Offset(headX1, headY1), arrowPaint);
      canvas.drawLine(Offset(endX, endY), Offset(headX2, headY2), arrowPaint);
    }
  }

  void _drawCompletionBurst(Canvas canvas, Offset center, double radius) {
    // Draw radiating lines for completion effect
    final burstPaint = Paint()
      ..color = AppColors.gold.withOpacity(glowValue * 0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 16; i++) {
      final angle = (i * 22.5) * math.pi / 180;
      final innerR = radius * 0.9;
      final outerR = radius * 1.1;

      final x1 = center.dx + innerR * math.cos(angle);
      final y1 = center.dy + innerR * math.sin(angle);
      final x2 = center.dx + outerR * math.cos(angle);
      final y2 = center.dy + outerR * math.sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), burstPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularSweepPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        isScanning != oldDelegate.isScanning ||
        isComplete != oldDelegate.isComplete ||
        pulseValue != oldDelegate.pulseValue ||
        glowValue != oldDelegate.glowValue;
  }
}

/// Widget showing scan instructions with the circular guide
class ScanInstructionOverlay extends StatelessWidget {
  final bool isScanning;
  final bool isComplete;
  final double progress;
  final int framesCollected;

  const ScanInstructionOverlay({
    super.key,
    required this.isScanning,
    required this.isComplete,
    required this.progress,
    required this.framesCollected,
  });

  @override
  Widget build(BuildContext context) {
    String instruction;
    if (isComplete) {
      instruction = 'SCAN COMPLETE';
    } else if (isScanning) {
      instruction = 'Keep moving slowly...';
    } else {
      instruction = 'TAP TO START SCAN';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            instruction,
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 16,
              color: isComplete ? AppColors.gold : AppColors.textPrimary,
            ),
          ),
        ),
        if (isScanning) ...[
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% · $framesCollected frames',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
