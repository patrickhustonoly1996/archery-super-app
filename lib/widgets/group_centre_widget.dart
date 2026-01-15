import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';
import '../utils/smart_zoom.dart';

/// Shows the group centre of a set of arrows with a high-contrast cross
/// The cross indicates where the group centre is, NOT the target centre
/// No individual arrow impacts are shown - just the group centre
class GroupCentreWidget extends StatelessWidget {
  final List<Arrow> arrows;
  final String label;
  final double size;
  final double minZoom;

  const GroupCentreWidget({
    super.key,
    required this.arrows,
    required this.label,
    this.size = 80,
    this.minZoom = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    // Use SmartZoom which calculates based on actual arrow spread, not scores
    final zoomFactor = arrows.isEmpty
        ? minZoom
        : SmartZoom.calculateZoomFactor(arrows, isIndoor: false).clamp(minZoom, 6.0);

    // Calculate group centre
    double avgX = 0;
    double avgY = 0;
    if (arrows.isNotEmpty) {
      for (final arrow in arrows) {
        avgX += arrow.x;
        avgY += arrow.y;
      }
      avgX /= arrows.length;
      avgY /= arrows.length;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Square container with target and group centre cross
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.surfaceLight, width: 2),
            color: AppColors.backgroundDark,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                // Zoomed target face (centred on group centre, not target centre)
                if (arrows.isNotEmpty)
                  _ZoomedTargetView(
                    size: size,
                    zoomFactor: zoomFactor,
                    groupCentreX: avgX,
                    groupCentreY: avgY,
                  )
                else
                  // Empty state - show target centred normally
                  _ZoomedTargetView(
                    size: size,
                    zoomFactor: zoomFactor,
                    groupCentreX: 0,
                    groupCentreY: 0,
                  ),

                // High contrast cross at centre of view (which IS the group centre)
                CustomPaint(
                  size: Size(size, size),
                  painter: _GroupCentreCrossPainter(),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Label
        Text(
          arrows.isEmpty ? label : '$label (${arrows.length})',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Paints the target face zoomed and centred on a specific point
class _ZoomedTargetView extends StatelessWidget {
  final double size;
  final double zoomFactor;
  final double groupCentreX;
  final double groupCentreY;

  const _ZoomedTargetView({
    required this.size,
    required this.zoomFactor,
    required this.groupCentreX,
    required this.groupCentreY,
  });

  @override
  Widget build(BuildContext context) {
    // The target needs to be offset so that the group centre appears at the view centre
    // In normalized coords, group centre is at (groupCentreX, groupCentreY)
    // We need to translate the target so this point is at (0, 0) of the view

    final targetSize = size * zoomFactor;
    final halfViewSize = size / 2;
    final halfTargetSize = targetSize / 2;

    // Calculate offset to centre the group centre in the view
    // groupCentreX/Y are in normalized coords (-1 to 1)
    // Convert to pixel offset: multiply by half the zoomed target size
    final offsetX = -groupCentreX * halfTargetSize;
    final offsetY = -groupCentreY * halfTargetSize;

    // Use topLeft alignment so the transform math works correctly
    // Without this, the default center alignment shifts everything
    return OverflowBox(
      alignment: Alignment.topLeft,
      maxWidth: targetSize,
      maxHeight: targetSize,
      child: Transform.translate(
        offset: Offset(
          offsetX + halfViewSize - halfTargetSize,
          offsetY + halfViewSize - halfTargetSize,
        ),
        child: CustomPaint(
          size: Size(targetSize, targetSize),
          painter: _MiniTargetPainter(),
        ),
      ),
    );
  }
}

/// Paints a simplified target face
class _MiniTargetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw rings from outside in
    final rings = [
      (1.0, AppColors.ring1), // 1-2 white
      (TargetRings.ring3, AppColors.ring3), // 3-4 black
      (TargetRings.ring5, AppColors.ring5), // 5-6 blue
      (TargetRings.ring7, AppColors.ring7), // 7-8 red
      (TargetRings.ring9, AppColors.ring9), // 9-10 gold
      (TargetRings.x, AppColors.ringX), // X
    ];

    for (final ring in rings) {
      final ringRadius = ring.$1 * radius;
      final paint = Paint()
        ..color = ring.$2
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, ringRadius, paint);
    }

    // Draw ring lines
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (final ring in rings) {
      canvas.drawCircle(center, ring.$1 * radius, linePaint);
    }

    // Draw individual ring boundaries for accuracy
    final allBoundaries = [
      TargetRings.ring1,
      TargetRings.ring2,
      TargetRings.ring3,
      TargetRings.ring4,
      TargetRings.ring5,
      TargetRings.ring6,
      TargetRings.ring7,
      TargetRings.ring8,
      TargetRings.ring9,
      TargetRings.ring10,
      TargetRings.x,
    ];

    final thinLinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;

    for (final boundary in allBoundaries) {
      canvas.drawCircle(center, boundary * radius, thinLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// High contrast cross to mark the group centre
/// Uses thick black outline with bright inner color for visibility on any background
class _GroupCentreCrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Thick black outline for contrast
    final outlinePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Bright magenta inner line - high visibility
    final crossPaint = Paint()
      ..color = const Color(0xFFFF00FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Cross dimensions - spans most of the widget
    final armLength = size.width * 0.35;
    const gapSize = 6.0;

    // Vertical line (with gap)
    canvas.drawLine(
      Offset(center.dx, center.dy - armLength),
      Offset(center.dx, center.dy - gapSize),
      outlinePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + gapSize),
      Offset(center.dx, center.dy + armLength),
      outlinePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - armLength),
      Offset(center.dx, center.dy - gapSize),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + gapSize),
      Offset(center.dx, center.dy + armLength),
      crossPaint,
    );

    // Horizontal line (with gap)
    canvas.drawLine(
      Offset(center.dx - armLength, center.dy),
      Offset(center.dx - gapSize, center.dy),
      outlinePaint,
    );
    canvas.drawLine(
      Offset(center.dx + gapSize, center.dy),
      Offset(center.dx + armLength, center.dy),
      outlinePaint,
    );
    canvas.drawLine(
      Offset(center.dx - armLength, center.dy),
      Offset(center.dx - gapSize, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx + gapSize, center.dy),
      Offset(center.dx + armLength, center.dy),
      crossPaint,
    );

    // Centre dot
    final dotOutlinePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    final dotPaint = Paint()
      ..color = const Color(0xFFFF00FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, dotOutlinePaint);
    canvas.drawCircle(center, 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
