import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../db/database.dart';
import '../utils/smart_zoom.dart';

/// Renders an archery target face with plotted arrows
class TargetFace extends StatelessWidget {
  final List<Arrow> arrows;
  final double size;
  final bool showRingLabels;
  final bool triSpot; // WA 18 tri-spot shows only 6-10 rings

  const TargetFace({
    super.key,
    required this.arrows,
    this.size = 300,
    this.showRingLabels = false,
    this.triSpot = false,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate marker size for positioning offset
    final markerSize = (size * _ArrowMarker._markerFraction).clamp(4.0, 10.0);
    final halfMarker = markerSize / 2;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TargetFacePainter(
          showRingLabels: showRingLabels,
          triSpot: triSpot,
        ),
        child: Stack(
          children: arrows.map((arrow) {
            // Convert normalized coordinates (-1 to 1) to widget coordinates
            final centerX = size / 2;
            final centerY = size / 2;
            final radius = size / 2;

            final x = centerX + (arrow.x * radius);
            final y = centerY + (arrow.y * radius);

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

  _TargetFacePainter({this.showRingLabels = false, this.triSpot = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Ring colors from outside to inside
    // Tri-spot only shows rings 6-10 (no 1-5 rings)
    final rings = triSpot
        ? [
            (TargetRings.ring6, AppColors.ring6), // 6 - blue (outermost for tri-spot)
            (TargetRings.ring7, AppColors.ring7), // 7 - red
            (TargetRings.ring8, AppColors.ring8), // 8 - red
            (TargetRings.ring9, AppColors.ring9), // 9 - gold
            (TargetRings.ring10, AppColors.ring10), // 10 - gold
            (TargetRings.x, AppColors.ringX), // X - gold center
          ]
        : [
            (TargetRings.ring1, AppColors.ring1), // 1 - white
            (TargetRings.ring2, AppColors.ring2), // 2 - white
            (TargetRings.ring3, AppColors.ring3), // 3 - black
            (TargetRings.ring4, AppColors.ring4), // 4 - black
            (TargetRings.ring5, AppColors.ring5), // 5 - blue
            (TargetRings.ring6, AppColors.ring6), // 6 - blue
            (TargetRings.ring7, AppColors.ring7), // 7 - red
            (TargetRings.ring8, AppColors.ring8), // 8 - red
            (TargetRings.ring9, AppColors.ring9), // 9 - gold
            (TargetRings.ring10, AppColors.ring10), // 10 - gold
            (TargetRings.x, AppColors.ringX), // X - gold center
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

    // Draw ring lines
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final ring in rings) {
      canvas.drawCircle(center, ring.$1 * radius * ringScale, linePaint);
    }

    // Draw X ring (innermost)
    final xPaint = Paint()
      ..color = AppColors.ringX
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, TargetRings.x * radius * ringScale, xPaint);

    // Draw center dot
    final centerPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2, centerPaint);

    // Draw crosshairs (very subtle)
    final crosshairPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      crosshairPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
class InteractiveTargetFace extends StatefulWidget {
  final List<Arrow> arrows;
  final double size;
  final Function(double x, double y) onArrowPlotted;
  final bool enabled;
  final bool isIndoor;
  final bool triSpot;

  const InteractiveTargetFace({
    super.key,
    required this.arrows,
    required this.onArrowPlotted,
    this.size = 300,
    this.enabled = true,
    this.isIndoor = false,
    this.triSpot = false,
  });

  @override
  State<InteractiveTargetFace> createState() => _InteractiveTargetFaceState();
}

class _InteractiveTargetFaceState extends State<InteractiveTargetFace> {
  // Touch state
  Offset? _touchPosition;
  Offset? _arrowPosition;
  bool _isHolding = false;

  // Linecutter state
  bool _isLinecutterMode = false;
  bool _isNearBoundary = false;
  Timer? _linecutterActivationTimer;
  double? _nearestBoundaryDistance;
  int? _nearestBoundaryRing;

  // Overlay for zoom window
  OverlayEntry? _zoomOverlay;

  // Zoom window constants
  static const double _linecutterZoomFactor = 6.0;
  static const double _zoomWindowSize = 120.0;
  static const double _holdOffset = 60.0; // Offset so finger doesn't cover target point
  static const double _boundaryProximityThreshold = 0.04; // 4% of radius - wider detection zone
  static const Duration _linecutterActivationDelay = Duration(milliseconds: 300); // Quick activation

  /// Cached zoom factor to prevent jumps during drag
  double? _cachedZoomFactor;

  /// Get the current zoom factor based on mode and smart zoom calculation
  double get _zoomFactor {
    if (_isLinecutterMode) {
      return _linecutterZoomFactor;
    }
    // Use cached zoom if we're in the middle of a drag to prevent jumping
    if (_isHolding && _cachedZoomFactor != null) {
      return _cachedZoomFactor!;
    }
    // Smart zoom calculates optimal zoom (minimum 2x) based on arrow grouping
    final baseZoom = SmartZoom.calculateZoomFactor(
      widget.arrows,
      isIndoor: widget.isIndoor,
    );
    return baseZoom;
  }

  /// Calculate distance from arrow position to nearest ring boundary
  /// Returns a record with (isNear, distance, ringNumber)
  ({bool isNear, double? distance, int? ring}) _checkBoundaryProximity(Offset arrowPosition) {
    // Convert widget coordinates to normalized (-1 to 1)
    final center = Offset(widget.size / 2, widget.size / 2);
    final radius = widget.size / 2;

    final normalizedX = (arrowPosition.dx - center.dx) / radius;
    final normalizedY = (arrowPosition.dy - center.dy) / radius;

    // Calculate distance from center
    final distanceFromCenter = math.sqrt(normalizedX * normalizedX + normalizedY * normalizedY);

    // Define all ring boundaries to check
    final ringBoundaries = [
      (TargetRings.x, 10),      // X ring
      (TargetRings.ring10, 10), // 10 ring
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

    // Find nearest boundary
    double minDistance = double.infinity;
    int? nearestRing;

    for (final (boundary, ringNumber) in ringBoundaries) {
      final distanceToBoundary = (distanceFromCenter - boundary).abs();
      if (distanceToBoundary < minDistance) {
        minDistance = distanceToBoundary;
        nearestRing = ringNumber;
      }
    }

    // Check if within threshold
    final isNear = minDistance <= _boundaryProximityThreshold;

    return (
      isNear: isNear,
      distance: isNear ? minDistance : null,
      ring: isNear ? nearestRing : null,
    );
  }

  void _cancelLinecutterTimer() {
    _linecutterActivationTimer?.cancel();
    _linecutterActivationTimer = null;
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled) return;

    // Cache the zoom factor at start of drag to prevent jumping
    _cachedZoomFactor = SmartZoom.calculateZoomFactor(
      widget.arrows,
      isIndoor: widget.isIndoor,
    );

    setState(() {
      _touchPosition = details.localPosition;
      // Apply the same offset from the start so arrow doesn't jump
      _arrowPosition = Offset(
        details.localPosition.dx,
        details.localPosition.dy - _holdOffset,
      );
      _isHolding = true;
    });

    // Show zoom overlay immediately (not in post-frame callback to avoid delay)
    _showZoomOverlay();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enabled || !_isHolding) return;

    setState(() {
      _touchPosition = details.localPosition;
      // Arrow position is where the actual impact will be (above the thumb)
      _arrowPosition = Offset(
        details.localPosition.dx,
        details.localPosition.dy - _holdOffset,
      );

      // Check boundary proximity for linecutter mode
      final proximity = _checkBoundaryProximity(_arrowPosition!);

      if (proximity.isNear && !_isLinecutterMode) {
        // Near a boundary and not in linecutter mode yet
        _isNearBoundary = true;
        _nearestBoundaryDistance = proximity.distance;
        _nearestBoundaryRing = proximity.ring;

        // Start timer if not already running
        _linecutterActivationTimer ??= Timer(_linecutterActivationDelay, () {
            // Timer completed - activate linecutter mode if still near boundary
            if (_isNearBoundary && !_isLinecutterMode) {
              setState(() {
                _isLinecutterMode = true;
              });
              // Haptic feedback for mode activation
              HapticFeedback.mediumImpact();
            }
          });
      } else if (!proximity.isNear) {
        // Moved away from boundary - cancel timer and exit mode
        _isNearBoundary = false;
        _nearestBoundaryDistance = null;
        _nearestBoundaryRing = null;

        // Cancel timer if running
        _cancelLinecutterTimer();

        // Exit linecutter mode if active
        if (_isLinecutterMode) {
          _isLinecutterMode = false;
        }
      }
      // else: already in linecutter mode and still near boundary, just update tracking
      else if (_isLinecutterMode && proximity.isNear) {
        // Update nearest boundary info even while in linecutter mode
        _nearestBoundaryDistance = proximity.distance;
        _nearestBoundaryRing = proximity.ring;
      }
    });

    // Update zoom overlay position
    _updateZoomOverlay();
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enabled || !_isHolding || _arrowPosition == null) return;

    // Capture arrow position before clearing state
    final finalArrowPosition = _arrowPosition!;

    // Remove zoom overlay first
    _removeZoomOverlay();

    // Convert widget coordinates to normalized (-1 to 1)
    final center = Offset(widget.size / 2, widget.size / 2);
    final radius = widget.size / 2;

    final normalizedX = (finalArrowPosition.dx - center.dx) / radius;
    final normalizedY = (finalArrowPosition.dy - center.dy) / radius;

    // Clamp to target bounds
    final distance = math.sqrt(normalizedX * normalizedX + normalizedY * normalizedY);
    if (distance <= 1.0) {
      widget.onArrowPlotted(normalizedX, normalizedY);
    }

    // Reset all state
    _cancelLinecutterTimer();
    setState(() {
      _touchPosition = null;
      _arrowPosition = null;
      _isHolding = false;
      _cachedZoomFactor = null;

      // Reset linecutter state
      _isLinecutterMode = false;
      _isNearBoundary = false;
      _nearestBoundaryDistance = null;
      _nearestBoundaryRing = null;
    });
  }

  @override
  void dispose() {
    _cancelLinecutterTimer();
    _removeZoomOverlay();
    super.dispose();
  }

  void _showZoomOverlay() {
    _removeZoomOverlay();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final targetPosition = renderBox.localToGlobal(Offset.zero);

    _zoomOverlay = OverlayEntry(
      builder: (context) {
        if (_arrowPosition == null || _touchPosition == null) {
          return const SizedBox.shrink();
        }

        // Calculate screen position for zoom window
        final screenTouchX = targetPosition.dx + _touchPosition!.dx;
        final screenTouchY = targetPosition.dy + _touchPosition!.dy;

        // Position zoom window above and to the left of touch
        // But keep it on screen
        final screenSize = MediaQuery.of(context).size;
        double zoomX = screenTouchX - _zoomWindowSize - 20;
        double zoomY = screenTouchY - _zoomWindowSize - 20;

        // Keep on screen
        if (zoomX < 10) zoomX = screenTouchX + 40;
        if (zoomY < 10) zoomY = 10;
        if (zoomX + _zoomWindowSize > screenSize.width - 10) {
          zoomX = screenSize.width - _zoomWindowSize - 10;
        }

        return Positioned(
          left: zoomX,
          top: zoomY,
          child: _ZoomWindow(
            targetSize: widget.size,
            arrowPosition: _arrowPosition!,
            arrows: widget.arrows,
            zoomFactor: _zoomFactor,
            windowSize: _zoomWindowSize,
            isLinecutterMode: _isLinecutterMode,
            isNearBoundary: _isNearBoundary,
            nearestRing: _nearestBoundaryRing,
            triSpot: widget.triSpot,
          ),
        );
      },
    );

    overlay.insert(_zoomOverlay!);
  }

  void _updateZoomOverlay() {
    _zoomOverlay?.markNeedsBuild();
  }

  void _removeZoomOverlay() {
    _zoomOverlay?.remove();
    _zoomOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main target
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: TargetFace(
              arrows: widget.arrows,
              size: widget.size,
              triSpot: widget.triSpot,
            ),
          ),

          // Offset line from touch to arrow
          if (_isHolding && _touchPosition != null && _arrowPosition != null)
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _OffsetLinePainter(
                from: _touchPosition!,
                to: _arrowPosition!,
              ),
            ),

          // Preview arrow position (proportional to target size)
          if (_isHolding && _arrowPosition != null)
            Builder(
              builder: (context) {
                // Preview marker slightly larger than arrow markers for visibility
                final previewSize = (widget.size * _ArrowMarker._markerFraction * 1.3).clamp(5.0, 12.0);
                final halfPreview = previewSize / 2;
                return Positioned(
                  left: _arrowPosition!.dx - halfPreview,
                  top: _arrowPosition!.dy - halfPreview,
                  child: Container(
                    width: previewSize,
                    height: previewSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withOpacity(0.8),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                  ),
                );
              },
            ),
        ],
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
      ..color = AppColors.gold.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(from, to, paint);
  }

  @override
  bool shouldRepaint(covariant _OffsetLinePainter oldDelegate) {
    return from != oldDelegate.from || to != oldDelegate.to;
  }
}

class _ZoomWindow extends StatelessWidget {
  final double targetSize;
  final Offset arrowPosition;
  final List<Arrow> arrows;
  final double zoomFactor;
  final double windowSize;
  final bool isLinecutterMode;
  final bool isNearBoundary;
  final int? nearestRing;
  final bool triSpot;

  const _ZoomWindow({
    required this.targetSize,
    required this.arrowPosition,
    required this.arrows,
    required this.zoomFactor,
    required this.windowSize,
    this.isLinecutterMode = false,
    this.isNearBoundary = false,
    this.nearestRing,
    this.triSpot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main zoom window
        Container(
          width: windowSize,
          height: windowSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isLinecutterMode ? AppColors.success : AppColors.gold,
              width: isLinecutterMode ? 3 : 2,
            ),
            color: AppColors.backgroundDark,
          ),
          child: ClipOval(
            child: Stack(
              children: [
                // Target and arrows
                OverflowBox(
                  maxWidth: targetSize * zoomFactor,
                  maxHeight: targetSize * zoomFactor,
                  child: Transform.translate(
                    offset: Offset(
                      -(arrowPosition.dx * zoomFactor) + (windowSize / 2),
                      -(arrowPosition.dy * zoomFactor) + (windowSize / 2),
                    ),
                    child: Transform.scale(
                      scale: zoomFactor,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: targetSize,
                        height: targetSize,
                        child: CustomPaint(
                          painter: _TargetFacePainter(triSpot: triSpot),
                          child: Builder(
                          builder: (context) {
                            // Calculate marker size for this target
                            final markerSize = (targetSize * _ArrowMarker._markerFraction).clamp(4.0, 10.0);
                            final halfMarker = markerSize / 2;
                            return Stack(
                              children: [
                                // Show existing arrows
                                ...arrows.map((arrow) {
                                  final centerX = targetSize / 2;
                                  final centerY = targetSize / 2;
                                  final radius = targetSize / 2;
                                  final x = centerX + (arrow.x * radius);
                                  final y = centerY + (arrow.y * radius);
                                  return Positioned(
                                    left: x - halfMarker,
                                    top: y - halfMarker,
                                    child: _ArrowMarker(
                                      score: arrow.score,
                                      isX: arrow.isX,
                                      shaftNumber: arrow.shaftNumber,
                                      targetSize: targetSize,
                                    ),
                                  );
                                }),
                                // Show current arrow position (slightly larger for visibility)
                                Positioned(
                                  left: arrowPosition.dx - halfMarker - 1,
                                  top: arrowPosition.dy - halfMarker - 1,
                                  child: Container(
                                    width: markerSize + 2,
                                    height: markerSize + 2,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.gold,
                                      border: Border.all(color: Colors.black, width: 1.5),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Crosshair overlay (centered on zoom window)
                CustomPaint(
                  size: Size(windowSize, windowSize),
                  painter: _CrosshairPainter(),
                ),
              ],
            ),
          ),
        ),

        // Linecutter mode label
        if (isLinecutterMode)
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'LINECUTTER',
                style: TextStyle(
                  color: AppColors.backgroundDark,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Maximum contrast crosshair - thick black outline, bright magenta/cyan inner
    final outlinePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final crosshairPaint = Paint()
      ..color = const Color(0xFFFF00FF) // Magenta - high visibility
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Gap in center so crosshair doesn't obscure exact point
    const gapSize = 8.0;
    const armLength = 24.0;

    // Draw outline first, then white line on top for contrast
    // Vertical lines (with gap in center)
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
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + gapSize),
      Offset(center.dx, center.dy + armLength),
      crosshairPaint,
    );

    // Horizontal lines (with gap in center)
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
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx + gapSize, center.dy),
      Offset(center.dx + armLength, center.dy),
      crosshairPaint,
    );

    // Bold center dot to mark exact arrow position
    final dotOutlinePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    final dotPaint = Paint()
      ..color = const Color(0xFFFF00FF) // Magenta to match crosshair
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, dotOutlinePaint);
    canvas.drawCircle(center, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
