import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/arrow_coordinate.dart';

/// Displays arrow impacts on a field target face with group center
class FieldTargetPlotWidget extends StatelessWidget {
  final List<ArrowCoordinate> arrows;
  final int faceSize; // cm
  final bool showGroupCenter;
  final double size;

  const FieldTargetPlotWidget({
    super.key,
    required this.arrows,
    required this.faceSize,
    this.showGroupCenter = true,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: CustomPaint(
        painter: _FieldTargetPainter(
          arrows: arrows,
          faceSize: faceSize,
          showGroupCenter: showGroupCenter && arrows.length >= 2,
        ),
        size: Size(size, size),
      ),
    );
  }
}

class _FieldTargetPainter extends CustomPainter {
  final List<ArrowCoordinate> arrows;
  final int faceSize;
  final bool showGroupCenter;

  _FieldTargetPainter({
    required this.arrows,
    required this.faceSize,
    required this.showGroupCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final faceDiameterMm = faceSize * 10.0; // cm to mm
    final scale = radius / (faceDiameterMm / 2);

    // Draw target rings (5-zone field face)
    _drawTargetRings(canvas, center, radius);

    // Draw arrows
    for (final arrow in arrows) {
      _drawArrow(canvas, center, arrow, scale);
    }

    // Draw group center if enabled
    if (showGroupCenter && arrows.length >= 2) {
      _drawGroupCenter(canvas, center, scale);
    }
  }

  void _drawTargetRings(Canvas canvas, Offset center, double radius) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 5-zone field target colors (from center out)
    final zones = [
      (0.1, AppColors.gold), // X ring
      (0.2, AppColors.gold), // 5 ring
      (0.4, const Color(0xFFFF5555)), // 4 ring (red)
      (0.6, const Color(0xFF5599FF)), // 3 ring (blue)
      (0.8, AppColors.textPrimary), // 2 ring (black)
      (1.0, Colors.white), // 1 ring (white)
    ];

    // Fill rings from outside in
    for (int i = zones.length - 1; i >= 0; i--) {
      final (fraction, color) = zones[i];
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.3);
      canvas.drawCircle(center, radius * fraction, fillPaint);
    }

    // Draw ring outlines
    for (final (fraction, _) in zones) {
      ringPaint.color = AppColors.surfaceLight;
      canvas.drawCircle(center, radius * fraction, ringPaint);
    }
  }

  void _drawArrow(Canvas canvas, Offset center, ArrowCoordinate arrow, double scale) {
    final arrowPos = Offset(
      center.dx + arrow.xMm * scale,
      center.dy + arrow.yMm * scale,
    );

    // Arrow marker
    final arrowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.gold;

    canvas.drawCircle(arrowPos, 4, arrowPaint);

    // Arrow outline
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.background;

    canvas.drawCircle(arrowPos, 4, outlinePaint);
  }

  void _drawGroupCenter(Canvas canvas, Offset center, double scale) {
    // Calculate group center
    final avgX = arrows.map((a) => a.xMm).reduce((a, b) => a + b) / arrows.length;
    final avgY = arrows.map((a) => a.yMm).reduce((a, b) => a + b) / arrows.length;

    final groupCenterPos = Offset(
      center.dx + avgX * scale,
      center.dy + avgY * scale,
    );

    // Draw crosshair for group center
    final centerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.cyan;

    // Horizontal line
    canvas.drawLine(
      Offset(groupCenterPos.dx - 8, groupCenterPos.dy),
      Offset(groupCenterPos.dx + 8, groupCenterPos.dy),
      centerPaint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(groupCenterPos.dx, groupCenterPos.dy - 8),
      Offset(groupCenterPos.dx, groupCenterPos.dy + 8),
      centerPaint,
    );

    // Circle around center
    centerPaint.strokeWidth = 1.5;
    canvas.drawCircle(groupCenterPos, 6, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _FieldTargetPainter oldDelegate) {
    return arrows != oldDelegate.arrows ||
        faceSize != oldDelegate.faceSize ||
        showGroupCenter != oldDelegate.showGroupCenter;
  }
}

/// Widget showing group statistics for a field target
class FieldGroupStatsWidget extends StatelessWidget {
  final List<ArrowCoordinate> arrows;
  final int faceSize;

  const FieldGroupStatsWidget({
    super.key,
    required this.arrows,
    required this.faceSize,
  });

  @override
  Widget build(BuildContext context) {
    if (arrows.length < 2) {
      return const SizedBox.shrink();
    }

    final centerX = arrows.map((a) => a.xMm).reduce((a, b) => a + b) / arrows.length;
    final centerY = arrows.map((a) => a.yMm).reduce((a, b) => a + b) / arrows.length;
    final centerOffset = math.sqrt(centerX * centerX + centerY * centerY);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.my_location,
            size: 14,
            color: Colors.cyan,
          ),
          const SizedBox(width: 4),
          Text(
            'Group center: ${centerOffset.toStringAsFixed(1)}mm from X',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}
