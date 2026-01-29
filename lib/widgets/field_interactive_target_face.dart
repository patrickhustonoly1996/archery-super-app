import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/arrow_coordinate.dart';
import '../models/field_scoring.dart';
import '../models/field_course.dart';
import '../theme/app_theme.dart';

/// Result of scoring an arrow on the field target face
class FieldPlotResult {
  final ArrowCoordinate coordinate;
  final FieldScoringZone zone;

  const FieldPlotResult({
    required this.coordinate,
    required this.zone,
  });
}

/// Interactive IFAA field target face for arrow plotting.
///
/// Uses IFAA ring proportions (X=0.1, 5=0.2, 4=0.4, 3=0.6, 2=0.8, 1=1.0)
/// rather than WA 10-zone (each ring = 0.1).
class FieldInteractiveTargetFace extends StatefulWidget {
  /// Already-plotted arrows on this target
  final List<ArrowCoordinate> existingArrows;

  /// Face size in cm (determines mm-to-pixel scaling)
  final int faceSizeCm;

  /// Round type (determines whether 2 and 1 rings score or are misses)
  final FieldRoundType roundType;

  /// Callback when an arrow is scored via plotting
  final ValueChanged<FieldPlotResult>? onArrowScored;

  /// Whether the widget accepts new arrow placements
  final bool enabled;

  /// Ghost arrows from previous session (shown at 30% opacity)
  final List<ArrowCoordinate>? ghostArrows;

  /// Historical average group centre from all sessions
  final ArrowCoordinate? historicalGroupCentre;

  const FieldInteractiveTargetFace({
    super.key,
    this.existingArrows = const [],
    required this.faceSizeCm,
    this.roundType = FieldRoundType.field,
    this.onArrowScored,
    this.enabled = true,
    this.ghostArrows,
    this.historicalGroupCentre,
  });

  @override
  State<FieldInteractiveTargetFace> createState() =>
      _FieldInteractiveTargetFaceState();
}

class _FieldInteractiveTargetFaceState
    extends State<FieldInteractiveTargetFace> {
  // Touch tracking
  Offset? _touchPosition;
  bool _isDragging = false;

  // Finger offset: shift the arrow placement up from the touch point
  // so the arrow isn't hidden under the finger
  static const double _fingerOffsetPx = 40.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the smallest dimension to ensure the target is square
        final size = math.min(constraints.maxWidth, constraints.maxHeight);

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Listener(
              onPointerDown: widget.enabled ? _onPointerDown : null,
              onPointerMove: widget.enabled ? _onPointerMove : null,
              onPointerUp: widget.enabled ? _onPointerUp : null,
              child: CustomPaint(
                painter: _FieldTargetFacePainter(
                  existingArrows: widget.existingArrows,
                  faceSizeCm: widget.faceSizeCm,
                  ghostArrows: widget.ghostArrows ?? [],
                  historicalGroupCentre: widget.historicalGroupCentre,
                  previewPosition: _isDragging ? _touchPosition : null,
                  roundType: widget.roundType,
                ),
                size: Size(size, size),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _isDragging = true;
      _touchPosition = _adjustForFingerOffset(event.localPosition);
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDragging) return;
    setState(() {
      _touchPosition = _adjustForFingerOffset(event.localPosition);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isDragging || _touchPosition == null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size.shortestSide;
    final pos = _touchPosition!;

    // Convert pixel position to ArrowCoordinate
    final coordinate = ArrowCoordinate.fromWidgetPixels(
      px: pos.dx,
      py: pos.dy,
      widgetSize: size,
      faceSizeCm: widget.faceSizeCm,
    );

    // Determine score zone
    final zone = _determineZone(coordinate);

    setState(() {
      _isDragging = false;
      _touchPosition = null;
    });

    widget.onArrowScored?.call(FieldPlotResult(
      coordinate: coordinate,
      zone: zone,
    ));
  }

  Offset _adjustForFingerOffset(Offset raw) {
    // Shift the arrow placement up from the touch point
    return Offset(raw.dx, raw.dy - _fingerOffsetPx);
  }

  /// Determine the scoring zone from an arrow coordinate
  FieldScoringZone _determineZone(ArrowCoordinate coord) {
    final faceRadius = coord.faceSizeCm * 5.0; // mm
    final dist = coord.distanceMm;

    if (dist <= faceRadius * 0.1) return FieldScoringZone.x;
    if (dist <= faceRadius * 0.2) return FieldScoringZone.five;
    if (dist <= faceRadius * 0.4) return FieldScoringZone.four;
    if (dist <= faceRadius * 0.6) return FieldScoringZone.three;

    // Expert round includes 2 and 1 rings
    if (widget.roundType == FieldRoundType.expert) {
      if (dist <= faceRadius * 0.8) return FieldScoringZone.two;
      if (dist <= faceRadius * 1.0) return FieldScoringZone.one;
    }

    return FieldScoringZone.miss;
  }
}

/// Custom painter for the IFAA field target face
class _FieldTargetFacePainter extends CustomPainter {
  final List<ArrowCoordinate> existingArrows;
  final int faceSizeCm;
  final List<ArrowCoordinate> ghostArrows;
  final ArrowCoordinate? historicalGroupCentre;
  final Offset? previewPosition;
  final FieldRoundType roundType;

  _FieldTargetFacePainter({
    required this.existingArrows,
    required this.faceSizeCm,
    required this.ghostArrows,
    this.historicalGroupCentre,
    this.previewPosition,
    required this.roundType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final faceDiameterMm = faceSizeCm * 10.0;
    final scale = radius / (faceDiameterMm / 2);

    // Draw target rings
    _drawTargetRings(canvas, center, radius);

    // Draw ghost arrows (historical)
    for (final arrow in ghostArrows) {
      _drawGhostArrow(canvas, center, arrow, scale);
    }

    // Draw historical group centre
    if (historicalGroupCentre != null) {
      _drawHistoricalGroupCentre(canvas, center, historicalGroupCentre!, scale);
    }

    // Draw existing arrows
    for (int i = 0; i < existingArrows.length; i++) {
      _drawArrow(canvas, center, existingArrows[i], scale, i);
    }

    // Draw preview position (during drag)
    if (previewPosition != null) {
      _drawPreview(canvas, previewPosition!);
    }
  }

  void _drawTargetRings(Canvas canvas, Offset center, double radius) {
    // IFAA ring zones (from center out)
    final zones = [
      (0.1, AppColors.gold), // X ring
      (0.2, AppColors.gold), // 5 ring
      (0.4, const Color(0xFFFF5555)), // 4 ring (red)
      (0.6, const Color(0xFF5599FF)), // 3 ring (blue)
      (0.8, AppColors.textPrimary), // 2 ring
      (1.0, Colors.white), // 1 ring
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
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppColors.surfaceLight;

    for (final (fraction, _) in zones) {
      canvas.drawCircle(center, radius * fraction, ringPaint);
    }
  }

  void _drawArrow(
    Canvas canvas,
    Offset center,
    ArrowCoordinate arrow,
    double scale,
    int index,
  ) {
    final pos = Offset(
      center.dx + arrow.xMm * scale,
      center.dy + arrow.yMm * scale,
    );

    // Arrow marker (gold circle)
    final arrowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.gold;
    canvas.drawCircle(pos, 5, arrowPaint);

    // Outline
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.background;
    canvas.drawCircle(pos, 5, outlinePaint);

    // Arrow number label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${index + 1}',
        style: const TextStyle(
          color: AppColors.background,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
    );
  }

  void _drawGhostArrow(
    Canvas canvas,
    Offset center,
    ArrowCoordinate arrow,
    double scale,
  ) {
    final pos = Offset(
      center.dx + arrow.xMm * scale,
      center.dy + arrow.yMm * scale,
    );

    // Ghost arrow (grey, 30% opacity)
    final ghostPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.grey.withValues(alpha: 0.3);
    canvas.drawCircle(pos, 4, ghostPaint);

    // Ghost outline
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.grey.withValues(alpha: 0.2);
    canvas.drawCircle(pos, 4, outlinePaint);
  }

  void _drawHistoricalGroupCentre(
    Canvas canvas,
    Offset center,
    ArrowCoordinate groupCentre,
    double scale,
  ) {
    final pos = Offset(
      center.dx + groupCentre.xMm * scale,
      center.dy + groupCentre.yMm * scale,
    );

    // Dashed cyan crosshair
    final crosshairPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.cyan.withValues(alpha: 0.6);

    // Draw dashed lines
    const dashLength = 4.0;
    const gapLength = 3.0;
    const armLength = 12.0;

    // Horizontal dashes
    _drawDashedLine(
      canvas,
      Offset(pos.dx - armLength, pos.dy),
      Offset(pos.dx + armLength, pos.dy),
      crosshairPaint,
      dashLength,
      gapLength,
    );

    // Vertical dashes
    _drawDashedLine(
      canvas,
      Offset(pos.dx, pos.dy - armLength),
      Offset(pos.dx, pos.dy + armLength),
      crosshairPaint,
      dashLength,
      gapLength,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashLength,
    double gapLength,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final unitDx = dx / distance;
    final unitDy = dy / distance;

    double drawn = 0;
    bool drawing = true;

    while (drawn < distance) {
      final segmentLength = drawing ? dashLength : gapLength;
      final remaining = distance - drawn;
      final actualLength = math.min(segmentLength, remaining);

      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + unitDx * drawn, start.dy + unitDy * drawn),
          Offset(
            start.dx + unitDx * (drawn + actualLength),
            start.dy + unitDy * (drawn + actualLength),
          ),
          paint,
        );
      }

      drawn += actualLength;
      drawing = !drawing;
    }
  }

  void _drawPreview(Canvas canvas, Offset position) {
    // Preview dot (semi-transparent gold, larger)
    final previewPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.gold.withValues(alpha: 0.5);
    canvas.drawCircle(position, 7, previewPaint);

    // Preview outline
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.gold;
    canvas.drawCircle(position, 7, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _FieldTargetFacePainter oldDelegate) {
    return existingArrows != oldDelegate.existingArrows ||
        ghostArrows != oldDelegate.ghostArrows ||
        historicalGroupCentre != oldDelegate.historicalGroupCentre ||
        previewPosition != oldDelegate.previewPosition ||
        faceSizeCm != oldDelegate.faceSizeCm ||
        roundType != oldDelegate.roundType;
  }
}
