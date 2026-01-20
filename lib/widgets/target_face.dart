import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../db/database.dart';
import '../utils/target_coordinate_system.dart';

/// Renders an archery target face with plotted arrows
class TargetFace extends StatelessWidget {
  final List<Arrow> arrows;
  final double size;
  final bool showRingLabels;
  final bool triSpot; // WA 18 tri-spot shows only 6-10 rings
  final bool compoundScoring; // Compound inner 10 - smaller X ring
  final ColorblindMode colorblindMode; // Colorblind accessibility mode

  const TargetFace({
    super.key,
    required this.arrows,
    this.size = 300,
    this.showRingLabels = false,
    this.triSpot = false,
    this.compoundScoring = false,
    this.colorblindMode = ColorblindMode.none,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate marker size for positioning offset
    final markerSize = (size * _ArrowMarker._markerFraction).clamp(4.0, 10.0);
    final halfMarker = markerSize / 2;

    // For tri-spot, arrows need to be scaled to match the ring scaling
    // Ring 6 (at 0.5 normalized) fills the face, so scale = 1/0.5 = 2.0
    final arrowScale = triSpot ? (1.0 / TargetRings.ring6) : 1.0;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TargetFacePainter(
          showRingLabels: showRingLabels || AccessibleColors.shouldShowRingLabels(colorblindMode),
          triSpot: triSpot,
          compoundScoring: compoundScoring,
          colorblindMode: colorblindMode,
        ),
        child: Stack(
          children: arrows.map((arrow) {
            // Convert normalized coordinates (-1 to 1) to widget coordinates
            // For tri-spot, scale up arrow positions to match ring scaling
            final centerX = size / 2;
            final centerY = size / 2;
            final radius = size / 2;

            final x = centerX + (arrow.x * arrowScale * radius);
            final y = centerY + (arrow.y * arrowScale * radius);

            return Positioned(
              left: x - halfMarker,
              top: y - halfMarker,
              child: _ArrowMarker(
                score: arrow.score,
                isX: arrow.isX,
                shaftNumber: arrow.shaftNumber,
                targetSize: size,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TargetFacePainter extends CustomPainter {
  final bool showRingLabels;
  final bool triSpot;
  final bool compoundScoring;
  final ColorblindMode colorblindMode;

  _TargetFacePainter({
    this.showRingLabels = false,
    this.triSpot = false,
    this.compoundScoring = false,
    this.colorblindMode = ColorblindMode.none,
  });

  // WA compound indoor: X ring is 20mm diameter on 40cm face (2.5% of radius)
  // vs recurve X ring at 40mm diameter (5% of radius)
  static const double compoundXRing = 0.025; // Half the size of recurve X
  static const double compound10Ring = 0.05; // Compound 10 = recurve X size

  /// Get ring color based on score and colorblind mode
  Color _getRingColor(int score) {
    return AccessibleColors.getRingColor(score, colorblindMode);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Ring sizes - compound has smaller inner 10/X
    final xSize = compoundScoring ? compoundXRing : TargetRings.x;
    final ring10Size = compoundScoring ? compound10Ring : TargetRings.ring10;

    // Ring colors from outside to inside - use colorblind-friendly colors
    // Tri-spot only shows rings 6-10 (no 1-5 rings)
    final rings = triSpot
        ? [
            (TargetRings.ring6, _getRingColor(6)), // 6 - blue (outermost for tri-spot)
            (TargetRings.ring7, _getRingColor(7)), // 7 - red
            (TargetRings.ring8, _getRingColor(8)), // 8 - red
            (TargetRings.ring9, _getRingColor(9)), // 9 - gold
            (ring10Size, _getRingColor(10)), // 10 - gold (smaller for compound)
            (xSize, _getRingColor(10)), // X - gold center (smaller for compound)
          ]
        : [
            (TargetRings.ring1, _getRingColor(1)), // 1 - white
            (TargetRings.ring2, _getRingColor(2)), // 2 - white
            (TargetRings.ring3, _getRingColor(3)), // 3 - black
            (TargetRings.ring4, _getRingColor(4)), // 4 - black
            (TargetRings.ring5, _getRingColor(5)), // 5 - blue
            (TargetRings.ring6, _getRingColor(6)), // 6 - blue
            (TargetRings.ring7, _getRingColor(7)), // 7 - red
            (TargetRings.ring8, _getRingColor(8)), // 8 - red
            (TargetRings.ring9, _getRingColor(9)), // 9 - gold
            (ring10Size, _getRingColor(10)), // 10 - gold (smaller for compound)
            (xSize, _getRingColor(10)), // X - gold center (smaller for compound)
          ];

    // For tri-spot, scale rings to fill the face (6 ring becomes the outer edge)
    final ringScale = triSpot ? (1.0 / TargetRings.ring6) : 1.0;

    // Draw rings from outside in
    for (int i = 0; i < rings.length - 1; i++) {
      final ringRadius = rings[i].$1 * radius * ringScale;
      final paint = Paint()
        ..color = rings[i].$2
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, ringRadius, paint);
    }

    // Draw ring lines - thin black lines matching 5-zone tri-spot appearance
    const lineWidth = 0.8;
    final linePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    for (final ring in rings) {
      canvas.drawCircle(center, ring.$1 * radius * ringScale, linePaint);
    }

    // Draw X ring (innermost)
    if (compoundScoring) {
      // Compound: solid gold fill with clear black border
      final xPaint = Paint()
        ..color = _getRingColor(10)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, xSize * radius * ringScale, xPaint);

      final xBorderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, xSize * radius * ringScale, xBorderPaint);
    } else {
      // Recurve: subtle shadow line only (no fill, just a faint ring outline)
      final xShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawCircle(center, xSize * radius * ringScale, xShadowPaint);
    }

    // Draw center cross (within X ring)
    final crossSize = compoundScoring
        ? xSize * radius * ringScale * 0.6 // Larger cross for compound
        : xSize * radius * ringScale * 0.4; // Visible cross for recurve
    final crossPaint = Paint()
      ..color = Colors.black.withValues(alpha: compoundScoring ? 1.0 : 0.5)
      ..strokeWidth = compoundScoring ? 1.5 : lineWidth
      ..strokeCap = StrokeCap.round;
    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - crossSize),
      Offset(center.dx, center.dy + crossSize),
      crossPaint,
    );
    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - crossSize, center.dy),
      Offset(center.dx + crossSize, center.dy),
      crossPaint,
    );

    // Draw ring labels if enabled (for colorblind accessibility)
    if (showRingLabels) {
      _drawRingLabels(canvas, center, radius, ringScale);
    }
  }

  /// Draw score labels on rings for accessibility
  void _drawRingLabels(Canvas canvas, Offset center, double radius, double ringScale) {
    final ringScores = triSpot
        ? [6, 7, 8, 9, 10]
        : [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

    // Position labels at the midpoint of each ring
    for (int i = 0; i < ringScores.length; i++) {
      final score = ringScores[i];

      // Calculate position at the right edge of the ring (3 o'clock position)
      double ringRadius;
      if (triSpot) {
        // Tri-spot ring positions
        final boundaries = [
          TargetRings.ring6,
          TargetRings.ring7,
          TargetRings.ring8,
          TargetRings.ring9,
          TargetRings.ring10,
        ];
        final nextBoundary = i + 1 < boundaries.length
            ? boundaries[i + 1]
            : (compoundScoring ? compound10Ring : TargetRings.x);
        ringRadius = ((boundaries[i] + nextBoundary) / 2) * radius * ringScale;
      } else {
        // Full target ring positions
        final boundaries = [
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
        ];
        final nextBoundary = i + 1 < boundaries.length
            ? boundaries[i + 1]
            : (compoundScoring ? compound10Ring : TargetRings.x);
        ringRadius = ((boundaries[i] + nextBoundary) / 2) * radius * ringScale;
      }

      // Position label at 3 o'clock (right side of ring)
      final labelX = center.dx + ringRadius;
      final labelY = center.dy;

      // Choose text color based on ring color for contrast
      Color textColor;
      if (score >= 9) {
        textColor = Colors.black; // Black on gold
      } else if (score >= 7) {
        textColor = Colors.white; // White on red
      } else if (score >= 5) {
        textColor = Colors.white; // White on blue
      } else if (score >= 3) {
        textColor = Colors.white; // White on black
      } else {
        textColor = Colors.black; // Black on white
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$score',
          style: TextStyle(
            color: textColor,
            fontSize: radius * 0.06, // Scale font with target size
            fontWeight: FontWeight.bold,
            fontFamily: 'ShareTechMono',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TargetFacePainter oldDelegate) =>
      triSpot != oldDelegate.triSpot ||
      compoundScoring != oldDelegate.compoundScoring ||
      colorblindMode != oldDelegate.colorblindMode ||
      showRingLabels != oldDelegate.showRingLabels;
}

class _ArrowMarker extends StatelessWidget {
  final int score;
  final bool isX;
  final int? shaftNumber;
  final double targetSize;

  /// Arrow marker size as fraction of target diameter
  /// 7mm on 122cm target = 0.00574, but scaled up for visibility
  static const double _markerFraction = 0.02; // 2% of target for visibility

  const _ArrowMarker({
    required this.score,
    required this.isX,
    required this.targetSize,
    this.shaftNumber,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate marker size proportional to target (min 4px, max 10px)
    final markerSize = (targetSize * _markerFraction).clamp(4.0, 10.0);
    final borderWidth = (markerSize * 0.15).clamp(0.5, 1.5);

    // Use contrasting color based on ring
    Color markerColor;
    if (score >= 9) {
      markerColor = Colors.black; // Black on gold
    } else if (score >= 7) {
      markerColor = Colors.white; // White on red
    } else if (score >= 5) {
      markerColor = Colors.white; // White on blue
    } else if (score >= 3) {
      markerColor = Colors.white; // White on black
    } else {
      markerColor = Colors.black; // Black on white
    }

    // Simple dot - no text labels
    return Container(
      width: markerSize,
      height: markerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: markerColor,
        border: Border.all(
          color: markerColor == Colors.black ? Colors.white : Colors.black,
          width: borderWidth,
        ),
      ),
    );
  }
}

/// Interactive target face for plotting arrows with touch-hold-drag
///
/// Architecture: The target fills available space naturally (no Transform.scale).
/// Touch coordinates map directly to normalized coords (-1 to +1).
/// Pinch-to-zoom is handled via InteractiveViewer for proper viewport semantics.
class InteractiveTargetFace extends StatefulWidget {
  final List<Arrow> arrows;
  final double size;
  final Function(double x, double y) onArrowPlotted;
  final bool enabled;
  final bool isIndoor;
  final bool triSpot;
  final bool isLeftHanded;
  final bool compoundScoring; // Smaller inner 10/X for compound
  final ColorblindMode colorblindMode; // Colorblind accessibility mode
  final bool showRingLabels; // Show ring number labels

  /// Enable line cutter detection and in/out dialog
  final bool lineCutterDialogEnabled;

  /// Callback for pending arrow position (for external zoom window)
  final Function(double? x, double? y)? onPendingArrowChanged;

  /// Optional transform controller for coordinate adjustment when zoomed
  final TransformationController? transformController;

  const InteractiveTargetFace({
    super.key,
    required this.arrows,
    required this.onArrowPlotted,
    this.size = 300,
    this.enabled = true,
    this.isIndoor = false,
    this.triSpot = false,
    this.isLeftHanded = false,
    this.lineCutterDialogEnabled = false,
    this.compoundScoring = false,
    this.colorblindMode = ColorblindMode.none,
    this.showRingLabels = false,
    this.onPendingArrowChanged,
    this.transformController,
  });

  @override
  State<InteractiveTargetFace> createState() => _InteractiveTargetFaceState();
}

class _InteractiveTargetFaceState extends State<InteractiveTargetFace> {
  // Touch state - coordinates in WIDGET space (not transformed)
  Offset? _touchPosition;
  Offset? _arrowPosition; // Where arrow will be placed (offset from touch)
  bool _isHolding = false;

  // Finger offset constants (in widget pixels)
  // Offset from touch point so user can see where arrow lands
  static const double _holdOffsetX = 50.0; // Horizontal (sign flipped for lefties)
  static const double _holdOffsetY = 50.0; // Vertical (always upward)

  // Linecutter detection threshold - ~4% of radius gives a reasonable "near the line" zone
  // Each ring is 10% of radius, so 4% covers roughly the inner/outer 40% of each ring
  static const double _boundaryProximityThreshold = 0.04;

  /// Convert a gesture position to widget-local coordinates, accounting for any
  /// InteractiveViewer transformation (zoom/pan).
  Offset _gestureToWidgetLocal(Offset gesturePosition) {
    final controller = widget.transformController;
    if (controller == null) {
      return gesturePosition;
    }

    // The gesture position is in the transformed (zoomed) viewport space.
    // We need to convert it back to the widget's original coordinate space.
    // InteractiveViewer uses a Matrix4 transformation, so we invert it.
    final matrix = controller.value;
    final inverseMatrix = Matrix4.tryInvert(matrix);
    if (inverseMatrix == null) {
      return gesturePosition;
    }

    // Transform the point from viewport space to widget space
    final transformed = MatrixUtils.transformPoint(inverseMatrix, gesturePosition);
    return transformed;
  }

  /// Convert widget-space pixel position to normalized coordinates (-1 to +1)
  /// For tri-spot, coordinates are scaled so edge taps map to ring 6 boundary (0.5)
  (double, double) _widgetToNormalized(Offset widgetPosition) {
    final center = widget.size / 2;
    final radius = widget.size / 2;
    var normalizedX = (widgetPosition.dx - center) / radius;
    var normalizedY = (widgetPosition.dy - center) / radius;

    // For tri-spot, scale down so edge (1.0) maps to ring 6 boundary (0.5)
    if (widget.triSpot) {
      normalizedX *= TargetRings.ring6;
      normalizedY *= TargetRings.ring6;
    }

    return (normalizedX, normalizedY);
  }

  /// Calculate arrow position with finger offset applied
  Offset _calculateArrowPosition(Offset touchPosition) {
    final xOffset = widget.isLeftHanded ? _holdOffsetX : -_holdOffsetX;
    return Offset(
      touchPosition.dx + xOffset,
      touchPosition.dy - _holdOffsetY,
    );
  }

  /// Check if normalized position is near a ring boundary
  /// Returns the ring number where IN = that score, OUT = score - 1
  /// Special cases: ring 11 = X ring boundary (IN=X, OUT=10)
  ///                ring 1 = outer edge (IN=1, OUT=Miss)
  ({bool isNear, int? ring}) _checkBoundaryProximity(double normX, double normY) {
    final distanceFromCenter = math.sqrt(normX * normX + normY * normY);

    // Ring boundaries with their "IN" score
    // X ring boundary: IN = X (counts as 10), OUT = regular 10
    // Ring 10 boundary: IN = 10, OUT = 9
    // Ring 1 boundary: IN = 1, OUT = Miss (0)
    final ringBoundaries = [
      (TargetRings.x, 11),      // X ring - use 11 to distinguish from 10
      (TargetRings.ring10, 10),
      (TargetRings.ring9, 9),
      (TargetRings.ring8, 8),
      (TargetRings.ring7, 7),
      (TargetRings.ring6, 6),
      (TargetRings.ring5, 5),
      (TargetRings.ring4, 4),
      (TargetRings.ring3, 3),
      (TargetRings.ring2, 2),
      (TargetRings.ring1, 1),
    ];

    double minDistance = double.infinity;
    int? nearestRing;

    for (final (boundary, ringNumber) in ringBoundaries) {
      final dist = (distanceFromCenter - boundary).abs();
      if (dist < minDistance) {
        minDistance = dist;
        nearestRing = ringNumber;
      }
    }

    return (
      isNear: minDistance <= _boundaryProximityThreshold,
      ring: minDistance <= _boundaryProximityThreshold ? nearestRing : null,
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled) return;

    // Transform gesture position to widget-local coordinates (accounting for zoom)
    final localPos = _gestureToWidgetLocal(details.localPosition);
    final arrowPos = _calculateArrowPosition(localPos);

    setState(() {
      _touchPosition = localPos;
      _arrowPosition = arrowPos;
      _isHolding = true;
    });

    // Notify parent of pending arrow position (for fixed zoom window)
    final (normX, normY) = _widgetToNormalized(arrowPos);
    widget.onPendingArrowChanged?.call(normX, normY);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enabled || !_isHolding) return;

    // Transform gesture position to widget-local coordinates (accounting for zoom)
    final localPos = _gestureToWidgetLocal(details.localPosition);
    final arrowPos = _calculateArrowPosition(localPos);

    setState(() {
      _touchPosition = localPos;
      _arrowPosition = arrowPos;
    });

    // Notify parent of pending arrow position
    final (normX, normY) = _widgetToNormalized(arrowPos);
    widget.onPendingArrowChanged?.call(normX, normY);
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enabled || !_isHolding || _arrowPosition == null) return;

    final finalArrowPosition = _arrowPosition!;
    final (normalizedX, normalizedY) = _widgetToNormalized(finalArrowPosition);

    // Clear pending arrow
    widget.onPendingArrowChanged?.call(null, null);

    // Check if within target bounds
    final distance = math.sqrt(normalizedX * normalizedX + normalizedY * normalizedY);
    if (distance <= 1.0) {
      // Check for linecutter dialog
      if (widget.lineCutterDialogEnabled) {
        final proximity = _checkBoundaryProximity(normalizedX, normalizedY);
        if (proximity.isNear && proximity.ring != null) {
          _handleLineCutter(normalizedX, normalizedY, proximity.ring!);
        } else {
          widget.onArrowPlotted(normalizedX, normalizedY);
        }
      } else {
        widget.onArrowPlotted(normalizedX, normalizedY);
      }
    } else {
      // Arrow placed outside target - show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Arrow off target - drag onto face to plot',
            style: TextStyle(fontFamily: AppFonts.body),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.surfaceDark,
        ),
      );
    }

    // Reset state
    setState(() {
      _touchPosition = null;
      _arrowPosition = null;
      _isHolding = false;
    });
  }

  Future<void> _handleLineCutter(double x, double y, int nearRing) async {
    final higherScore = await _showLineCutterDialog(nearRing);

    if (higherScore != null) {
      final adjustmentFactor = higherScore ? -0.015 : 0.015;
      final currentDist = math.sqrt(x * x + y * y);
      if (currentDist > 0) {
        final scale = (currentDist + adjustmentFactor) / currentDist;
        x *= scale;
        y *= scale;
      }
    }

    widget.onArrowPlotted(x, y);
  }

  Future<bool?> _showLineCutterDialog(int nearRing) async {
    // Use extracted helper for testability
    final labels = LineCutterLabels.forRing(nearRing);

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'Line cutter',
          style: TextStyle(
            fontFamily: 'VT323',
            fontSize: 24,
            color: AppColors.gold,
          ),
        ),
        content: Text(
          'Arrow is on the ${labels.ringLabel} line.\nIn or out?',
          style: TextStyle(
            fontFamily: 'Share Tech Mono',
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              labels.outLabel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.backgroundDark,
            ),
            child: Text(labels.inLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate marker sizes proportionally
    final previewSize = (widget.size * _ArrowMarker._markerFraction * 1.3).clamp(5.0, 12.0);
    final halfPreview = previewSize / 2;

    // Target fills available space naturally - NO Transform.scale
    // Touch coordinates map directly to normalized coords
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main target - fills widget naturally
            TargetFace(
              arrows: widget.arrows,
              size: widget.size,
              triSpot: widget.triSpot,
              compoundScoring: widget.compoundScoring,
              colorblindMode: widget.colorblindMode,
              showRingLabels: widget.showRingLabels,
            ),

            // Offset line from touch to arrow position
            if (_isHolding && _touchPosition != null && _arrowPosition != null)
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _OffsetLinePainter(
                  from: _touchPosition!,
                  to: _arrowPosition!,
                ),
              ),

            // Preview arrow marker at intended position
            if (_isHolding && _arrowPosition != null)
              Positioned(
                left: _arrowPosition!.dx - halfPreview,
                top: _arrowPosition!.dy - halfPreview,
                child: Container(
                  width: previewSize,
                  height: previewSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.8),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OffsetLinePainter extends CustomPainter {
  final Offset from;
  final Offset to;

  _OffsetLinePainter({required this.from, required this.to});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(from, to, paint);
  }

  @override
  bool shouldRepaint(covariant _OffsetLinePainter oldDelegate) {
    return from != oldDelegate.from || to != oldDelegate.to;
  }
}

/// Fixed zoom window for displaying magnified view of arrow placement.
/// Positioned at a fixed location (e.g., top of screen) by the parent widget.
/// Uses normalized coordinates (-1 to +1) for the arrow position.
class FixedZoomWindow extends StatelessWidget {
  /// Normalized X coordinate (-1 to +1) of where the arrow will be placed
  final double targetX;

  /// Normalized Y coordinate (-1 to +1) of where the arrow will be placed
  final double targetY;

  /// Zoom magnification level (e.g., 3.0 = 3x zoom)
  final double zoomLevel;

  /// Size of the zoom window in pixels
  final double size;

  /// Whether to show crosshair overlay
  final bool showCrosshair;

  /// Whether this is a tri-spot (indoor) target
  final bool triSpot;

  /// Whether to use compound scoring (smaller X ring)
  final bool compoundScoring;

  /// Colorblind accessibility mode
  final ColorblindMode colorblindMode;

  const FixedZoomWindow({
    super.key,
    required this.targetX,
    required this.targetY,
    this.zoomLevel = 4.0,
    this.size = 140,
    this.showCrosshair = true,
    this.triSpot = false,
    this.compoundScoring = false,
    this.colorblindMode = ColorblindMode.none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CustomPaint(
          painter: _FixedZoomWindowPainter(
            targetX: targetX,
            targetY: targetY,
            zoomLevel: zoomLevel,
            showCrosshair: showCrosshair,
            triSpot: triSpot,
            compoundScoring: compoundScoring,
            colorblindMode: colorblindMode,
          ),
        ),
      ),
    );
  }
}

/// Painter for the fixed zoom window - uses canvas transforms for proper rendering
class _FixedZoomWindowPainter extends CustomPainter {
  final double targetX;
  final double targetY;
  final double zoomLevel;
  final bool showCrosshair;
  final bool triSpot;
  final bool compoundScoring;
  final ColorblindMode colorblindMode;

  _FixedZoomWindowPainter({
    required this.targetX,
    required this.targetY,
    required this.zoomLevel,
    required this.showCrosshair,
    this.triSpot = false,
    this.compoundScoring = false,
    this.colorblindMode = ColorblindMode.none,
  });

  /// Get ring color based on score and colorblind mode
  Color _getRingColor(int score) {
    return AccessibleColors.getRingColor(score, colorblindMode);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final viewRadius = size.width / 2;

    // The effective target radius when zoomed
    final effectiveTargetRadius = viewRadius * zoomLevel;

    // Save canvas state
    canvas.save();

    // Translate so the target position (targetX, targetY) is at center of view
    // targetX/targetY are normalized -1 to 1
    final offsetX = -targetX * effectiveTargetRadius;
    final offsetY = -targetY * effectiveTargetRadius;

    canvas.translate(center.dx + offsetX, center.dy + offsetY);

    // Draw target rings at the zoomed scale
    _drawRings(canvas, Offset.zero, effectiveTargetRadius);
    _drawRingLines(canvas, Offset.zero, effectiveTargetRadius);

    canvas.restore();

    // Draw crosshair at center (the arrow position)
    if (showCrosshair) {
      _drawCrosshair(canvas, center, size);
    }
  }

  void _drawRings(Canvas canvas, Offset center, double radius) {
    // Get ring sizes based on compound scoring mode
    final xSize = compoundScoring ? _TargetFacePainter.compoundXRing : TargetRings.x;
    final ring10Size = compoundScoring ? _TargetFacePainter.compound10Ring : TargetRings.ring10;

    // Use colorblind-friendly colors
    final rings = triSpot
        ? [
            (TargetRings.ring6, _getRingColor(6)),
            (TargetRings.ring7, _getRingColor(7)),
            (TargetRings.ring8, _getRingColor(8)),
            (TargetRings.ring9, _getRingColor(9)),
            (ring10Size, _getRingColor(10)),
            (xSize, _getRingColor(10)),
          ]
        : [
            (TargetRings.ring1, _getRingColor(1)),
            (TargetRings.ring2, _getRingColor(2)),
            (TargetRings.ring3, _getRingColor(3)),
            (TargetRings.ring4, _getRingColor(4)),
            (TargetRings.ring5, _getRingColor(5)),
            (TargetRings.ring6, _getRingColor(6)),
            (TargetRings.ring7, _getRingColor(7)),
            (TargetRings.ring8, _getRingColor(8)),
            (TargetRings.ring9, _getRingColor(9)),
            (ring10Size, _getRingColor(10)),
            (xSize, _getRingColor(10)),
          ];

    final ringScale = triSpot ? (1.0 / TargetRings.ring6) : 1.0;

    for (int i = 0; i < rings.length - 1; i++) {
      final ringRadius = rings[i].$1 * radius * ringScale;
      final paint = Paint()
        ..color = rings[i].$2
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, ringRadius, paint);
    }

    // Draw X ring
    if (compoundScoring) {
      // Compound: solid gold fill with clear black border
      final xPaint = Paint()
        ..color = _getRingColor(10)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, xSize * radius * ringScale, xPaint);

      final xBorderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, xSize * radius * ringScale, xBorderPaint);
    } else {
      // Recurve: subtle shadow line only
      final xShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, xSize * radius * ringScale, xShadowPaint);
    }
  }

  void _drawRingLines(Canvas canvas, Offset center, double radius) {
    final xSize = compoundScoring ? _TargetFacePainter.compoundXRing : TargetRings.x;
    final ring10Size = compoundScoring ? _TargetFacePainter.compound10Ring : TargetRings.ring10;

    final rings = triSpot
        ? [TargetRings.ring6, TargetRings.ring7, TargetRings.ring8, TargetRings.ring9, ring10Size, xSize]
        : [TargetRings.ring1, TargetRings.ring2, TargetRings.ring3, TargetRings.ring4,
           TargetRings.ring5, TargetRings.ring6, TargetRings.ring7, TargetRings.ring8,
           TargetRings.ring9, ring10Size, xSize];

    final ringScale = triSpot ? (1.0 / TargetRings.ring6) : 1.0;

    final linePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final ring in rings) {
      canvas.drawCircle(center, ring * radius * ringScale, linePaint);
    }
  }

  void _drawCrosshair(Canvas canvas, Offset center, Size size) {
    final crosshairPaint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 1.5;

    // Horizontal line
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      crosshairPaint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      crosshairPaint,
    );

    // Center dot
    final dotPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _FixedZoomWindowPainter oldDelegate) {
    return oldDelegate.targetX != targetX ||
        oldDelegate.targetY != targetY ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.triSpot != triSpot ||
        oldDelegate.compoundScoring != compoundScoring ||
        oldDelegate.colorblindMode != colorblindMode;
  }
}
