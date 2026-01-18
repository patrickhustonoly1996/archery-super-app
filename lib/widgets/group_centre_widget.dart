import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';
import '../utils/smart_zoom.dart';

/// Data class for confidence ellipse parameters
class _EllipseParams {
  final double semiAxisX; // Semi-axis in X direction (after rotation)
  final double semiAxisY; // Semi-axis in Y direction (after rotation)
  final double rotation;  // Rotation angle in radians

  const _EllipseParams({
    required this.semiAxisX,
    required this.semiAxisY,
    required this.rotation,
  });

  static const zero = _EllipseParams(semiAxisX: 0, semiAxisY: 0, rotation: 0);
}

/// Shows the group centre of a set of arrows with a high-contrast cross
/// and confidence ellipse showing the group spread shape
class GroupCentreWidget extends StatelessWidget {
  final List<Arrow> arrows;
  final String label;
  final double size;
  final double minZoom;
  /// Confidence multiplier: 1.0 = ~68% (1 SD), 2.0 = ~95% (2 SD)
  final double confidenceMultiplier;
  /// Show ring notation (e.g., "9.2 ring group")
  final bool showRingNotation;

  const GroupCentreWidget({
    super.key,
    required this.arrows,
    required this.label,
    this.size = 80,
    this.minZoom = 2.0,
    this.confidenceMultiplier = 1.0,
    this.showRingNotation = true,
  });

  /// Calculate the group size in ring units
  /// Uses the mean of the two semi-axes of the confidence ellipse
  /// Normalized coords: 1.0 = edge of target, 0.1 = ring 10 boundary
  String _calculateRingNotation(_EllipseParams ellipse) {
    if (ellipse.semiAxisX == 0 && ellipse.semiAxisY == 0) return '';

    // Mean of semi-axes gives average "radius" of the ellipse
    final meanAxis = (ellipse.semiAxisX + ellipse.semiAxisY) / 2;

    // Convert to ring units: ring 10 is at ~0.1 normalized
    // So multiply by 10 to get approximate ring spread
    // A 0.1 spread means the group fits within 1 ring width
    final ringSpread = meanAxis * 10;

    // Format as "X.Y ring"
    return '${ringSpread.toStringAsFixed(1)} ring';
  }

  /// Calculate the confidence ellipse parameters from arrow positions
  /// Uses eigenvalue decomposition of the covariance matrix
  _EllipseParams _calculateEllipse(double avgX, double avgY) {
    if (arrows.length < 2) return _EllipseParams.zero;

    // Calculate variances and covariance
    double varX = 0;
    double varY = 0;
    double covXY = 0;

    for (final arrow in arrows) {
      final dx = arrow.x - avgX;
      final dy = arrow.y - avgY;
      varX += dx * dx;
      varY += dy * dy;
      covXY += dx * dy;
    }

    // Divide by n-1 for sample variance (Bessel's correction)
    final n = arrows.length - 1;
    varX /= n;
    varY /= n;
    covXY /= n;

    // Eigenvalue decomposition of 2x2 covariance matrix [[varX, covXY], [covXY, varY]]
    // Eigenvalues: λ = ((varX + varY) ± sqrt((varX - varY)² + 4*covXY²)) / 2
    final trace = varX + varY;
    final det = varX * varY - covXY * covXY;
    final discriminant = math.sqrt(math.max(0, trace * trace / 4 - det));

    final lambda1 = trace / 2 + discriminant; // Larger eigenvalue
    final lambda2 = trace / 2 - discriminant; // Smaller eigenvalue

    // Semi-axes are sqrt of eigenvalues, scaled by confidence multiplier
    // 1.0 = ~68% (1 SD), 2.0 = ~95% (2 SD)
    final semiAxis1 = math.sqrt(math.max(0, lambda1)) * confidenceMultiplier;
    final semiAxis2 = math.sqrt(math.max(0, lambda2)) * confidenceMultiplier;

    // Rotation angle from eigenvector of larger eigenvalue
    // θ = 0.5 * atan2(2*covXY, varX - varY)
    final rotation = 0.5 * math.atan2(2 * covXY, varX - varY);

    return _EllipseParams(
      semiAxisX: semiAxis1,
      semiAxisY: semiAxis2,
      rotation: rotation,
    );
  }

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

    // Calculate confidence ellipse
    final ellipse = _calculateEllipse(avgX, avgY);
    final ringNotation = showRingNotation ? _calculateRingNotation(ellipse) : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label (above the box)
        Text(
          arrows.isEmpty ? label : '$label (${arrows.length})',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Ring notation (if enabled and we have data)
        if (showRingNotation && ringNotation.isNotEmpty)
          Text(
            ringNotation,
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),

        const SizedBox(height: 4),

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

                // Confidence ellipse showing group spread (behind the cross)
                if (arrows.length >= 2)
                  CustomPaint(
                    size: Size(size, size),
                    painter: _ConfidenceEllipsePainter(
                      semiAxisX: ellipse.semiAxisX,
                      semiAxisY: ellipse.semiAxisY,
                      rotation: ellipse.rotation,
                      zoomFactor: zoomFactor,
                    ),
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

/// Paints a translucent confidence ellipse showing group spread
class _ConfidenceEllipsePainter extends CustomPainter {
  final double semiAxisX;
  final double semiAxisY;
  final double rotation;
  final double zoomFactor;

  _ConfidenceEllipsePainter({
    required this.semiAxisX,
    required this.semiAxisY,
    required this.rotation,
    required this.zoomFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Convert normalized coords to pixels
    // In normalized coords, 1.0 = edge of target = half the widget size * zoomFactor
    final pixelScale = (size.width / 2) * zoomFactor;
    final pixelAxisX = semiAxisX * pixelScale;
    final pixelAxisY = semiAxisY * pixelScale;

    // Don't draw if ellipse is too small
    if (pixelAxisX < 2 || pixelAxisY < 2) return;

    // Translucent magenta fill
    final fillPaint = Paint()
      ..color = const Color(0xFFFF00FF).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Magenta outline
    final strokePaint = Paint()
      ..color = const Color(0xFFFF00FF).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Save canvas state, rotate around center, draw ellipse, restore
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: pixelAxisX * 2,
      height: pixelAxisY * 2,
    );

    canvas.drawOval(rect, fillPaint);
    canvas.drawOval(rect, strokePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ConfidenceEllipsePainter oldDelegate) {
    return semiAxisX != oldDelegate.semiAxisX ||
        semiAxisY != oldDelegate.semiAxisY ||
        rotation != oldDelegate.rotation ||
        zoomFactor != oldDelegate.zoomFactor;
  }
}

/// Simple black cross to mark the group centre
class _GroupCentreCrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Simple black cross - small and defined
    final crossPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    // Cross dimensions - small, just marks the center
    const armLength = 8.0;

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - armLength),
      Offset(center.dx, center.dy + armLength),
      crossPaint,
    );

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - armLength, center.dy),
      Offset(center.dx + armLength, center.dy),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
