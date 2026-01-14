import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';
import '../models/arrow_coordinate.dart';
import '../models/group_analysis.dart';
import '../utils/target_coordinate_system.dart';

/// Shows rolling average impact point of last N arrows
/// Zoomed in to show only the scoring zone (inner 40% of target = rings 7-X)
class RollingAverageWidget extends StatelessWidget {
  final List<Arrow> arrows;
  final int maxArrows;
  final double size;
  final int faceSizeCm;
  static const double _zoomFactor = 2.5; // Show inner 40% of target

  const RollingAverageWidget({
    super.key,
    required this.arrows,
    this.maxArrows = 12,
    this.size = 80,
    this.faceSizeCm = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (arrows.isEmpty) {
      return _buildEmptyState();
    }

    // Convert arrows to ArrowCoordinates
    final coords = arrows.map((arrow) {
      // Prefer mm coordinates if available
      if (arrow.xMm != 0 || arrow.yMm != 0) {
        return ArrowCoordinate(
          xMm: arrow.xMm,
          yMm: arrow.yMm,
          faceSizeCm: faceSizeCm,
        );
      }
      // Fallback to normalized coordinates
      return ArrowCoordinate.fromNormalized(
        x: arrow.x,
        y: arrow.y,
        faceSizeCm: faceSizeCm,
      );
    }).toList();

    // Calculate group analysis
    final group = GroupAnalysis.calculate(coords);
    final coordSystem = TargetCoordinateSystem(
      faceSizeCm: faceSizeCm,
      widgetSize: size,
    );

    // Convert group center to widget pixels
    final centerPixels = coordSystem.coordinateToPixels(group.center);

    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfaceLight, width: 2),
          color: AppColors.backgroundDark,
        ),
        child: ClipOval(
          child: Stack(
            children: [
              // Zoomed mini target face (centered, scaled up)
              Center(
                child: Transform.scale(
                  scale: _zoomFactor,
                  child: CustomPaint(
                    size: Size(size, size),
                    painter: _MiniTargetPainter(),
                  ),
                ),
              ),

              // Group center marker (scaled for zoom)
              Positioned(
                left: _scalePosition(centerPixels.dx, size) - 5,
                top: _scalePosition(centerPixels.dy, size) - 5,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                ),
              ),

              // Crosshair overlay for reference
              CustomPaint(
                size: Size(size, size),
                painter: _CrosshairPainter(),
              ),

              // Count and spread label at bottom
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${arrows.length}/$maxArrows',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceDark.withValues(alpha: 0.9),
          border: Border.all(color: AppColors.surfaceLight, width: 2),
        ),
        child: Center(
          child: Text(
            '0/$maxArrows',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// Scale a pixel position for the zoom view
  double _scalePosition(double pixelPos, double widgetSize) {
    final center = widgetSize / 2;
    // Convert pixel position to offset from center, apply zoom, convert back
    final offsetFromCenter = pixelPos - center;
    final scaledOffset = offsetFromCenter * _zoomFactor;
    return (center + scaledOffset).roundToDouble();
  }
}

class _MiniTargetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw simplified rings (just the key zones)
    final rings = [
      (1.0, AppColors.ring1), // 1-2 white
      (TargetRings.ring3, AppColors.ring3), // 3-4 black
      (TargetRings.ring5, AppColors.ring5), // 5-6 blue
      (TargetRings.ring7, AppColors.ring7), // 7-8 red
      (TargetRings.ring9, AppColors.ring9), // 9-10 gold
      (TargetRings.x, AppColors.ringX), // X
    ];

    // Draw rings from outside in
    for (final ring in rings) {
      final ringRadius = ring.$1 * radius;
      final paint = Paint()
        ..color = ring.$2
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, ringRadius, paint);
    }

    // Draw subtle ring lines
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (final ring in rings) {
      canvas.drawCircle(center, ring.$1 * radius, linePaint);
    }

    // Draw center dot
    final centerPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 1, centerPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 1, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // High contrast crosshair - white with black outline
    final outlinePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final crosshairPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw outline first, then white line on top
    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - 12),
      Offset(center.dx, center.dy - 4),
      outlinePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + 4),
      Offset(center.dx, center.dy + 12),
      outlinePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 12),
      Offset(center.dx, center.dy - 4),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + 4),
      Offset(center.dx, center.dy + 12),
      crosshairPaint,
    );

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - 12, center.dy),
      Offset(center.dx - 4, center.dy),
      outlinePaint,
    );
    canvas.drawLine(
      Offset(center.dx + 4, center.dy),
      Offset(center.dx + 12, center.dy),
      outlinePaint,
    );
    canvas.drawLine(
      Offset(center.dx - 12, center.dy),
      Offset(center.dx - 4, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx + 4, center.dy),
      Offset(center.dx + 12, center.dy),
      crosshairPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
