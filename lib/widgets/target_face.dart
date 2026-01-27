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
  final String scoringType; // '10-zone', '5-zone', 'worcester'
  /// Arrow IDs to highlight with a green halo (current/selected end arrows)
  final Set<String>? highlightedArrowIds;
  /// Multiplier for arrow marker size (0.5 = half, 1.0 = default, 2.0 = double)
  final double arrowSizeMultiplier;

  const TargetFace({
    super.key,
    required this.arrows,
    this.size = 300,
    this.showRingLabels = false,
    this.triSpot = false,
    this.compoundScoring = false,
    this.colorblindMode = ColorblindMode.none,
    this.scoringType = '10-zone',
    this.highlightedArrowIds,
    this.arrowSizeMultiplier = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate marker size for positioning offset (with multiplier applied)
    final markerSize = (size * _ArrowMarker._markerFraction * arrowSizeMultiplier).clamp(2.0, 20.0);
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
          scoringType: scoringType,
        ),
        child: Stack(
          clipBehavior: Clip.none,
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
                isHighlighted: highlightedArrowIds?.contains(arrow.id) ?? false,
                sizeMultiplier: arrowSizeMultiplier,
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
  final String scoringType;

  _TargetFacePainter({
    this.showRingLabels = false,
    this.triSpot = false,
    this.compoundScoring = false,
    this.colorblindMode = ColorblindMode.none,
    this.scoringType = '10-zone',
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

    // Handle Worcester target separately - it has 5 equal rings
    if (scoringType == 'worcester') {
      _paintWorcesterTarget(canvas, center, radius);
      return;
    }

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

    // Draw 10 ring boundary more prominently for recurve
    if (!compoundScoring) {
      final ring10PromPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(center, ring10Size * radius * ringScale, ring10PromPaint);
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
      // Recurve: very subtle shadow line (less prominent than before)
      final xShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.3;
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

  /// Paint Worcester target face - white center, black outer rings
  void _paintWorcesterTarget(Canvas canvas, Offset center, double radius) {
    // Worcester has 5 equal-width rings scoring 5 (center) to 1 (outer)
    // Each ring is 20% of the radius
    // Ring 5 (center): white
    // Rings 4, 3, 2, 1: black

    // Draw outer black area first
    final blackPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, blackPaint);

    // Draw white center circle (ring 5)
    // Ring 5 extends from 0 to 0.2 of radius
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.2, whitePaint);

    // Draw ring boundary lines (white lines on black, black line on white center)
    final whiteLine = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final blackLine = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Ring boundaries at 20%, 40%, 60%, 80%, 100% of radius
    for (int i = 1; i <= 5; i++) {
      final ringRadius = radius * (i * 0.2);
      // Use black line for the innermost boundary (between 5 and 4), white for others
      final linePaint = i == 1 ? blackLine : whiteLine;
      canvas.drawCircle(center, ringRadius, linePaint);
    }

    // Draw center cross
    final crossSize = radius * 0.08;
    final crossPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy - crossSize),
      Offset(center.dx, center.dy + crossSize),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx - crossSize, center.dy),
      Offset(center.dx + crossSize, center.dy),
      crossPaint,
    );

    // Draw ring labels if enabled
    if (showRingLabels) {
      _drawWorcesterRingLabels(canvas, center, radius);
    }
  }

  /// Draw Worcester ring labels
  void _drawWorcesterRingLabels(Canvas canvas, Offset center, double radius) {
    for (int score = 1; score <= 5; score++) {
      // Position in the middle of each ring
      final ringMidpoint = radius * ((score - 0.5) * 0.2);
      final labelX = center.dx + ringMidpoint;
      final labelY = center.dy;

      // White text on black rings (1-4), black text on white center (5)
      final textColor = score == 5 ? Colors.black : Colors.white;

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$score',
          style: TextStyle(
            color: textColor,
            fontSize: radius * 0.08,
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
      showRingLabels != oldDelegate.showRingLabels ||
      scoringType != oldDelegate.scoringType;
}

class _ArrowMarker extends StatelessWidget {
  final int score;
  final bool isX;
  final int? shaftNumber;
  final double targetSize;
  /// Whether this arrow should be highlighted (current/selected end)
  final bool isHighlighted;
  /// Size multiplier for the marker (0.5 = half, 1.0 = default, 2.0 = double)
  final double sizeMultiplier;

  /// Arrow marker size as fraction of target diameter
  /// 7mm on 122cm target = 0.00574, but scaled up for visibility
  static const double _markerFraction = 0.02; // 2% of target for visibility

  const _ArrowMarker({
    required this.score,
    required this.isX,
    required this.targetSize,
    this.shaftNumber,
    this.isHighlighted = false,
    this.sizeMultiplier = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate marker size proportional to target with multiplier (min 2px, max 20px)
    final markerSize = (targetSize * _markerFraction * sizeMultiplier).clamp(2.0, 20.0);
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
        // Multi-layered halo for highlighted arrows - visible on ALL ring colors
        // White outer glow + cyan inner glow = universal contrast
        boxShadow: isHighlighted
            ? [
                // White outer glow - visible on dark backgrounds (black, blue, red)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  blurRadius: 10,
                  spreadRadius: 4,
                ),
                // Cyan inner glow - visible on light backgrounds (white, gold)
                BoxShadow(
                  color: const Color(0xFF00E5FF),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
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
  /// Callback when arrow is plotted. Optional scoreOverride for line cutter.
  final Function(double x, double y, {({int score, bool isX})? scoreOverride}) onArrowPlotted;
  final bool enabled;
  final bool isIndoor;
  final bool triSpot;
  final bool isLeftHanded;
  final bool compoundScoring; // Smaller inner 10/X for compound
  final ColorblindMode colorblindMode; // Colorblind accessibility mode
  final bool showRingLabels; // Show ring number labels

  /// Enable line cutter detection and in/out dialog
  final bool lineCutterDialogEnabled;

  /// Face size in cm (40 for indoor, 122/80/60 for outdoor)
  /// Used to calculate fixed mm threshold for line cutter
  final int faceSizeCm;

  /// Scoring type: '10-zone' (default), '5-zone' (imperial), 'worcester'
  /// This affects which ring boundaries trigger the linecutter dialog.
  final String scoringType;

  /// Callback for pending arrow position (for external zoom window)
  final Function(double? x, double? y)? onPendingArrowChanged;

  /// Optional transform controller for coordinate adjustment when zoomed
  final TransformationController? transformController;

  /// Arrow IDs to highlight with a green halo (current/selected end arrows)
  final Set<String>? highlightedArrowIds;

  /// Multiplier for arrow marker size (0.5 = half, 1.0 = default, 2.0 = double)
  final double arrowSizeMultiplier;

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
    this.faceSizeCm = 40,
    this.scoringType = '10-zone',
    this.compoundScoring = false,
    this.colorblindMode = ColorblindMode.none,
    this.showRingLabels = false,
    this.onPendingArrowChanged,
    this.transformController,
    this.highlightedArrowIds,
    this.arrowSizeMultiplier = 1.0,
  });

  @override
  State<InteractiveTargetFace> createState() => _InteractiveTargetFaceState();
}

class _InteractiveTargetFaceState extends State<InteractiveTargetFace> {
  // Touch state - coordinates in WIDGET space (not transformed)
  Offset? _touchPosition;
  Offset? _arrowPosition; // Where arrow will be placed (offset from touch)
  bool _isHolding = false;

  // Track active pointers to detect pinch vs single-finger drag
  final Set<int> _activePointers = {};
  int? _primaryPointer; // The first finger that touched - used for plotting

  // Finger offset constants (in screen pixels at 1x zoom)
  // Offset from touch point so user can see where arrow lands
  // These are scaled inversely with zoom so visual offset stays consistent
  static const double _holdOffsetX = 50.0; // Horizontal (sign flipped for lefties)
  static const double _holdOffsetY = 50.0; // Vertical (always upward)

  // Line cutter threshold in mm - fixed at 1.5mm regardless of face size
  // Line cutter only activates on the OUTER edge (lower score side) of the line
  static const double _lineCutterThresholdMm = 1.5;

  /// Calculate the normalized threshold based on face size
  /// 1.5mm on a 40cm face (200mm radius) = 0.0075 normalized
  double get _boundaryProximityThreshold {
    final radiusMm = widget.faceSizeCm * 5.0; // cm to mm, then /2 for radius
    return _lineCutterThresholdMm / radiusMm;
  }

  /// Convert a gesture position to widget-local coordinates.
  ///
  /// Note: When inside an InteractiveViewer, Flutter's hit testing system
  /// already transforms coordinates through the Transform widget. The
  /// event.localPosition we receive from Listener is already in widget-local
  /// coordinate space, so no additional transformation is needed.
  Offset _gestureToWidgetLocal(Offset gesturePosition) {
    // Flutter's Transform (used by InteractiveViewer) handles coordinate
    // transformation during hit testing. The localPosition from pointer
    // events is already in widget space - no inverse transform needed.
    return gesturePosition;
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

  /// Calculate arrow position with finger offset applied.
  /// The offset is scaled inversely with zoom so the visual distance between
  /// thumb and arrow preview stays consistent regardless of zoom level.
  Offset _calculateArrowPosition(Offset touchPosition) {
    final zoomScale = _currentZoomScale;
    // Divide offset by zoom scale so visual offset stays constant on screen
    final scaledOffsetX = _holdOffsetX / zoomScale;
    final scaledOffsetY = _holdOffsetY / zoomScale;
    final xOffset = widget.isLeftHanded ? scaledOffsetX : -scaledOffsetX;
    return Offset(
      touchPosition.dx + xOffset,
      touchPosition.dy - scaledOffsetY,
    );
  }

  /// Check if normalized position is on the OUTER edge of a ring boundary.
  /// Only triggers when arrow is just outside the line (lower score side).
  /// Returns the ring number of the higher score (the ring the arrow just missed).
  ///
  /// For 5-zone scoring (imperial rounds), only checks color boundaries:
  /// - Gold/Red at ring 9 (0.20) - score 9→7
  /// - Red/Blue at ring 7 (0.40) - score 7→5
  /// - Blue/Black at ring 5 (0.60) - score 5→3
  /// - Black/White at ring 3 (0.80) - score 3→1
  /// - White/Miss at ring 1 (1.0) - score 1→0
  ({bool isNear, int? ring}) _checkBoundaryProximity(double normX, double normY) {
    final distanceFromCenter = math.sqrt(normX * normX + normY * normY);

    // Get boundaries based on scoring type
    final ringBoundaries = _getBoundariesForScoringType();

    // Check each boundary - only trigger if on OUTER edge (just past the line)
    for (final (boundary, ringNumber) in ringBoundaries) {
      // Arrow must be just outside the line (distance > boundary)
      // and within the threshold of the line
      final distFromLine = distanceFromCenter - boundary;
      if (distFromLine > 0 && distFromLine <= _boundaryProximityThreshold) {
        return (isNear: true, ring: ringNumber);
      }
    }

    return (isNear: false, ring: null);
  }

  /// Get ring boundaries to check based on scoring type.
  /// For 5-zone, only check color boundaries where score changes.
  /// For 10-zone, check all ring boundaries.
  List<(double, int)> _getBoundariesForScoringType() {
    if (widget.scoringType == '5-zone') {
      // 5-zone scoring only has score changes at color boundaries
      // Each color spans 2 rings, so only check odd-numbered rings
      return [
        (TargetRings.ring9, 9),   // Gold/Red boundary (9→7)
        (TargetRings.ring7, 7),   // Red/Blue boundary (7→5)
        (TargetRings.ring5, 5),   // Blue/Black boundary (5→3)
        (TargetRings.ring3, 3),   // Black/White boundary (3→1)
        (TargetRings.ring1, 1),   // White/Miss boundary (1→0)
      ];
    }

    // 10-zone scoring (default) - check all boundaries
    return [
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
  }

  // Pointer event handlers for pinch-to-zoom support
  // We use Listener instead of GestureDetector to allow multi-finger gestures
  // to pass through to the parent InteractiveViewer for zoom handling

  void _onPointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);

    // If this is a second+ finger, cancel any in-progress plotting and let
    // InteractiveViewer handle the pinch gesture
    if (_activePointers.length > 1) {
      if (_isHolding) {
        setState(() {
          _isHolding = false;
          _touchPosition = null;
          _arrowPosition = null;
        });
        widget.onPendingArrowChanged?.call(null, null);
      }
      _primaryPointer = null;
      return;
    }

    // First finger - start plotting if enabled
    if (!widget.enabled) return;
    _primaryPointer = event.pointer;

    // Transform gesture position to widget-local coordinates (accounting for zoom)
    final localPos = _gestureToWidgetLocal(event.localPosition);
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

  void _onPointerMove(PointerMoveEvent event) {
    // Only track the primary pointer for plotting
    if (event.pointer != _primaryPointer) return;

    // If multiple pointers are active, don't plot (pinch gesture)
    if (_activePointers.length > 1) return;

    if (!widget.enabled || !_isHolding) return;

    // Transform gesture position to widget-local coordinates (accounting for zoom)
    final localPos = _gestureToWidgetLocal(event.localPosition);
    final arrowPos = _calculateArrowPosition(localPos);

    setState(() {
      _touchPosition = localPos;
      _arrowPosition = arrowPos;
    });

    // Notify parent of pending arrow position
    final (normX, normY) = _widgetToNormalized(arrowPos);
    widget.onPendingArrowChanged?.call(normX, normY);
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);

    // Only finalize if this was the primary pointer and we were plotting
    if (event.pointer != _primaryPointer) return;

    // If other pointers are still down, this was part of a pinch - don't plot
    if (_activePointers.isNotEmpty) {
      _primaryPointer = null;
      return;
    }

    _primaryPointer = null;

    if (!widget.enabled || !_isHolding || _arrowPosition == null) {
      setState(() {
        _isHolding = false;
        _touchPosition = null;
        _arrowPosition = null;
      });
      return;
    }

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

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);

    if (event.pointer == _primaryPointer) {
      _primaryPointer = null;
      if (_isHolding) {
        setState(() {
          _isHolding = false;
          _touchPosition = null;
          _arrowPosition = null;
        });
        widget.onPendingArrowChanged?.call(null, null);
      }
    }
  }

  Future<void> _handleLineCutter(double x, double y, int nearRing) async {
    final higherScore = await _showLineCutterDialog(nearRing);

    if (higherScore == null) {
      // Dialog dismissed - still plot with no override
      widget.onArrowPlotted(x, y);
      return;
    }

    // Determine the score based on user choice
    // nearRing is the ring the arrow just missed (higher score)
    // If higherScore=true (IN), give them that ring's score
    // If higherScore=false (OUT), calculate from position (already done automatically)
    if (higherScore) {
      // User says IN - override with the higher score
      final score = nearRing == 11 ? 10 : nearRing;
      final isX = nearRing == 11;
      widget.onArrowPlotted(x, y, scoreOverride: (score: score, isX: isX));
    } else {
      // User says OUT - no override, use calculated score from position
      widget.onArrowPlotted(x, y);
    }
  }

  Future<bool?> _showLineCutterDialog(int nearRing) async {
    // Use extracted helper for testability - choose label factory based on scoring type
    final labels = widget.scoringType == '5-zone'
        ? LineCutterLabels.forRing5Zone(nearRing)
        : LineCutterLabels.forRing(nearRing);

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
    // Calculate marker sizes proportionally with multiplier - match actual arrow marker size exactly
    final previewSize = (widget.size * _ArrowMarker._markerFraction * widget.arrowSizeMultiplier).clamp(2.0, 20.0);
    final halfPreview = previewSize / 2;

    // Target fills available space naturally - NO Transform.scale
    // Touch coordinates map directly to normalized coords
    return SizedBox(
      width: widget.size,
      height: widget.size,
      // Use Listener instead of GestureDetector to allow multi-finger gestures
      // to pass through to parent InteractiveViewer for pinch-to-zoom.
      // Single-finger drag is handled here for arrow plotting.
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
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
              scoringType: widget.scoringType,
              highlightedArrowIds: widget.highlightedArrowIds,
              arrowSizeMultiplier: widget.arrowSizeMultiplier,
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

            // Preview arrow marker at intended position - matches actual arrow marker exactly
            if (_isHolding && _arrowPosition != null)
              Positioned(
                left: _arrowPosition!.dx - halfPreview,
                top: _arrowPosition!.dy - halfPreview,
                child: Container(
                  width: previewSize,
                  height: previewSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(
                      color: Colors.white,
                      width: (previewSize * 0.15).clamp(0.5, 1.5),
                    ),
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
      ..color = Colors.black.withValues(alpha: 0.7)
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

  /// The current zoom level applied to the main target (from InteractiveViewer)
  /// The zoom window will display at [relativeZoom] times this level.
  final double currentZoomLevel;

  /// Zoom multiplier relative to the current target zoom level (default 2x)
  /// Final zoom = currentZoomLevel * relativeZoom
  final double relativeZoom;

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
    this.currentZoomLevel = 1.0,
    this.relativeZoom = 2.0,
    this.size = 140,
    this.showCrosshair = true,
    this.triSpot = false,
    this.compoundScoring = false,
    this.colorblindMode = ColorblindMode.none,
  });

  /// The effective zoom level for the window (current * relative)
  double get effectiveZoom => currentZoomLevel * relativeZoom;

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
            zoomLevel: effectiveZoom,
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

  /// Get the score at the crosshair position for color determination
  int _getScoreAtPosition() {
    // Coordinates are already in full-target normalized space
    // (triSpot scaling was applied at input - 0.5 = ring 6 boundary)
    // No further scaling needed for score calculation
    final distance = math.sqrt(targetX * targetX + targetY * targetY);
    return TargetRings.getScore(distance);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final viewRadius = size.width / 2;

    // The effective target radius when zoomed
    final effectiveTargetRadius = viewRadius * zoomLevel;

    // For triSpot, coordinates are already scaled by ring6 (0.5)
    // We need to apply the same ringScale to the offset calculation
    // so the crosshair aligns with the correct ring position
    final ringScale = triSpot ? (1.0 / TargetRings.ring6) : 1.0;

    // Save canvas state
    canvas.save();

    // Translate so the target position (targetX, targetY) is at center of view
    // Apply ringScale to account for triSpot coordinate pre-scaling
    final offsetX = -targetX * ringScale * effectiveTargetRadius;
    final offsetY = -targetY * ringScale * effectiveTargetRadius;

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

    // Draw 10 ring more prominently for recurve
    if (!compoundScoring) {
      final ring10PromPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, ring10Size * radius * ringScale, ring10PromPaint);
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
      // Recurve: very subtle shadow line (less prominent)
      final xShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
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
    // Determine crosshair color based on ring under the crosshair
    // Black by default, but yellow (gold) when hovering over black rings (3-4)
    final score = _getScoreAtPosition();
    final isOnBlackRing = score == 3 || score == 4;
    final crosshairColor = isOnBlackRing ? AppColors.gold : Colors.black;

    final crosshairPaint = Paint()
      ..color = crosshairColor
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
      ..color = crosshairColor
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
