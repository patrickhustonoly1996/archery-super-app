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
  final bool compoundScoring; // Compound inner 10 - smaller X ring

  const TargetFace({
    super.key,
    required this.arrows,
    this.size = 300,
    this.showRingLabels = false,
    this.triSpot = false,
    this.compoundScoring = false,
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
          compoundScoring: compoundScoring,
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
  final bool compoundScoring;

  _TargetFacePainter({
    this.showRingLabels = false,
    this.triSpot = false,
    this.compoundScoring = false,
  });

  // WA compound indoor: X ring is 20mm diameter on 40cm face (2.5% of radius)
  // vs recurve X ring at 40mm diameter (5% of radius)
  static const double compoundXRing = 0.025; // Half the size of recurve X
  static const double compound10Ring = 0.05; // Compound 10 = recurve X size

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Ring sizes - compound has smaller inner 10/X
    final xSize = compoundScoring ? compoundXRing : TargetRings.x;
    final ring10Size = compoundScoring ? compound10Ring : TargetRings.ring10;

    // Ring colors from outside to inside
    // Tri-spot only shows rings 6-10 (no 1-5 rings)
    final rings = triSpot
        ? [
            (TargetRings.ring6, AppColors.ring6), // 6 - blue (outermost for tri-spot)
            (TargetRings.ring7, AppColors.ring7), // 7 - red
            (TargetRings.ring8, AppColors.ring8), // 8 - red
            (TargetRings.ring9, AppColors.ring9), // 9 - gold
            (ring10Size, AppColors.ring10), // 10 - gold (smaller for compound)
            (xSize, AppColors.ringX), // X - gold center (smaller for compound)
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
            (ring10Size, AppColors.ring10), // 10 - gold (smaller for compound)
            (xSize, AppColors.ringX), // X - gold center (smaller for compound)
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

    // Draw ring lines - solid black for clarity
    final linePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final ring in rings) {
      canvas.drawCircle(center, ring.$1 * radius * ringScale, linePaint);
    }

    // Draw X ring (innermost)
    final xPaint = Paint()
      ..color = AppColors.ringX
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, xSize * radius * ringScale, xPaint);

    // Draw center cross (within X ring)
    final crossSize = xSize * radius * ringScale * 0.25; // 25% of X ring
    final crossPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
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
  }

  @override
  bool shouldRepaint(covariant _TargetFacePainter oldDelegate) =>
      triSpot != oldDelegate.triSpot ||
      compoundScoring != oldDelegate.compoundScoring;
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
  final bool isLeftHanded;
  final bool compoundScoring; // Smaller inner 10/X for compound

  /// Enable line cutter detection and in/out dialog
  final bool lineCutterDialogEnabled;

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

  // Pinch-to-zoom state
  // Baseline 1.0 = target fills screen (internally multiplied by 2x)
  // Users can pinch OUT to zoom out (<1.0) for miss plotting (longbow)
  // Users can pinch IN to zoom in (>1.0) for precision
  double _userZoomScale = 1.0;
  bool _isPinchZooming = false;

  // Internal multiplier: 1.0 user scale = 2.0 actual scale (fills screen)
  static const double _baselineMultiplier = 2.0;

  // Zoom window constants
  static const double _linecutterZoomFactor = 10.0; // High zoom for line-cutter precision
  static const double _zoomWindowSize = 150.0;      // Larger window for precision
  static const double _linecutterWindowSize = 180.0; // Even larger for linecutter
  // Diagonal offset: 60px total distance at ~45° angle
  // sqrt(42² + 42²) ≈ 59.4px ≈ 60px
  static const double _holdOffsetX = 42.0; // Horizontal component (sign flipped for lefties)
  static const double _holdOffsetY = 42.0; // Vertical component (always upward)
  static const double _boundaryProximityThreshold = 0.01; // 1% of radius - ~6mm on 122cm target, tight for precision
  static const Duration _linecutterActivationDelay = Duration(milliseconds: 600); // Longer hold for intentional activation

  /// Cached zoom factor to prevent jumps during drag
  double? _cachedZoomFactor;

  /// Get the current zoom factor based on mode and smart zoom calculation
  /// This is RELATIVE to the user's current pinch zoom level
  double get _zoomFactor {
    double baseZoom;
    if (_isLinecutterMode) {
      baseZoom = _linecutterZoomFactor;
    } else if (_isHolding && _cachedZoomFactor != null) {
      // Use cached zoom if we're in the middle of a drag to prevent jumping
      baseZoom = _cachedZoomFactor!;
    } else {
      // Smart zoom calculates optimal zoom (minimum 2x) based on arrow grouping
      baseZoom = SmartZoom.calculateZoomFactor(
        widget.arrows,
        isIndoor: widget.isIndoor,
      );
    }
    // Multiply by user's current pinch zoom (with baseline) so the window is useful when zoomed in
    return baseZoom * _userZoomScale * _baselineMultiplier;
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
      // Apply diagonal offset: up-left for right-handers, up-right for left-handers
      // This keeps the arrow visible without your palm/arm blocking it
      final xOffset = widget.isLeftHanded ? _holdOffsetX : -_holdOffsetX;
      _arrowPosition = Offset(
        details.localPosition.dx + xOffset,
        details.localPosition.dy - _holdOffsetY,
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
      // Arrow position is where the actual impact will be (diagonal from thumb)
      final xOffset = widget.isLeftHanded ? _holdOffsetX : -_holdOffsetX;
      _arrowPosition = Offset(
        details.localPosition.dx + xOffset,
        details.localPosition.dy - _holdOffsetY,
      );

      // Check boundary proximity for linecutter mode
      final proximity = _checkBoundaryProximity(_arrowPosition!);

      if (proximity.isNear && !_isLinecutterMode) {
        // Near a boundary - start timer to activate linecutter mode
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

        // Use larger window in linecutter mode
        final currentWindowSize = _isLinecutterMode ? _linecutterWindowSize : _zoomWindowSize;

        return Positioned(
          left: zoomX,
          top: zoomY,
          child: _ZoomWindow(
            targetSize: widget.size,
            arrowPosition: _arrowPosition!,
            arrows: widget.arrows,
            zoomFactor: _zoomFactor,
            windowSize: currentWindowSize,
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

  // Handle scale gesture (used for both 1-finger plotting and 2-finger zoom)
  void _onScaleStart(ScaleStartDetails details) {
    if (!widget.enabled) return;

    if (details.pointerCount >= 2) {
      // 2+ fingers: start pinch-to-zoom
      setState(() {
        _isPinchZooming = true;
      });
    } else {
      // 1 finger: start arrow plotting
      _cachedZoomFactor = SmartZoom.calculateZoomFactor(
        widget.arrows,
        isIndoor: widget.isIndoor,
      );

      setState(() {
        _touchPosition = details.localFocalPoint;
        final xOffset = widget.isLeftHanded ? _holdOffsetX : -_holdOffsetX;
        _arrowPosition = Offset(
          details.localFocalPoint.dx + xOffset,
          details.localFocalPoint.dy - _holdOffsetY,
        );
        _isHolding = true;
      });

      _showZoomOverlay();
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.enabled) return;

    if (_isPinchZooming && details.pointerCount >= 2) {
      // Pinch-to-zoom: update scale (dampen sensitivity - use 30% of gesture scale)
      // User scale: 0.5 (zoomed out for miss area) to 5.0 (zoomed in)
      // 1.0 = baseline = target fills screen
      final dampedScale = 1.0 + (details.scale - 1.0) * 0.3;
      setState(() {
        _userZoomScale = (_userZoomScale * dampedScale).clamp(0.5, 5.0);
      });
    } else if (_isHolding && details.pointerCount == 1) {
      // Arrow plotting: update position
      setState(() {
        _touchPosition = details.localFocalPoint;
        final xOffset = widget.isLeftHanded ? _holdOffsetX : -_holdOffsetX;
        _arrowPosition = Offset(
          details.localFocalPoint.dx + xOffset,
          details.localFocalPoint.dy - _holdOffsetY,
        );

        // Check boundary proximity for linecutter mode
        final proximity = _checkBoundaryProximity(_arrowPosition!);

        if (proximity.isNear && !_isLinecutterMode) {
          // Near a boundary - start timer to activate linecutter mode
          _isNearBoundary = true;
          _nearestBoundaryDistance = proximity.distance;
          _nearestBoundaryRing = proximity.ring;

          // Start timer if not already running
          _linecutterActivationTimer ??= Timer(_linecutterActivationDelay, () {
            if (_isNearBoundary && !_isLinecutterMode) {
              setState(() {
                _isLinecutterMode = true;
              });
              HapticFeedback.mediumImpact();
            }
          });
        } else if (!proximity.isNear) {
          _isNearBoundary = false;
          _nearestBoundaryDistance = null;
          _nearestBoundaryRing = null;
          _cancelLinecutterTimer();
          if (_isLinecutterMode) {
            _isLinecutterMode = false;
          }
        } else if (_isLinecutterMode && proximity.isNear) {
          _nearestBoundaryDistance = proximity.distance;
          _nearestBoundaryRing = proximity.ring;
        }
      });

      _updateZoomOverlay();
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_isPinchZooming) {
      // End pinch-to-zoom
      setState(() {
        _isPinchZooming = false;
      });
    } else if (_isHolding && _arrowPosition != null) {
      // End arrow plotting - place arrow
      final finalArrowPosition = _arrowPosition!;
      _removeZoomOverlay();

      final center = Offset(widget.size / 2, widget.size / 2);
      final radius = widget.size / 2;

      final normalizedX = (finalArrowPosition.dx - center.dx) / radius;
      final normalizedY = (finalArrowPosition.dy - center.dy) / radius;

      final distance = math.sqrt(normalizedX * normalizedX + normalizedY * normalizedY);
      if (distance <= 1.0) {
        // Check if linecutter dialog is enabled and arrow is near boundary
        if (widget.lineCutterDialogEnabled) {
          final proximity = _checkBoundaryProximity(finalArrowPosition);
          if (proximity.isNear && proximity.ring != null) {
            // Show in/out dialog
            _handleLineCutter(normalizedX, normalizedY, proximity.ring!);
          } else {
            widget.onArrowPlotted(normalizedX, normalizedY);
          }
        } else {
          // No linecutter dialog - plot directly
          widget.onArrowPlotted(normalizedX, normalizedY);
        }
      }

      // Clean up state after callback
      _cancelLinecutterTimer();
      setState(() {
        _touchPosition = null;
        _arrowPosition = null;
        _isHolding = false;
        _cachedZoomFactor = null;
        _isLinecutterMode = false;
        _isNearBoundary = false;
        _nearestBoundaryDistance = null;
        _nearestBoundaryRing = null;
      });
    }
  }

  /// Handle line cutter scenario with async dialog
  Future<void> _handleLineCutter(double x, double y, int nearRing) async {
    final higherScore = await _showLineCutterDialog(nearRing);

    if (higherScore != null) {
      // Adjust position slightly based on choice
      // Move radially inward (higher score) or outward (lower score)
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

  /// Show dialog to ask if line cutter is in or out
  Future<bool?> _showLineCutterDialog(int nearRing) async {
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
          'Arrow is on the $nearRing line.\nIn or out?',
          style: TextStyle(
            fontFamily: 'Share Tech Mono',
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'OUT (${nearRing - 1})',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.backgroundDark,
            ),
            child: Text('IN ($nearRing)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        // Use scale gestures which handle both 1-finger drag and 2-finger pinch
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        child: Transform.scale(
          // Apply baseline multiplier: user's 1.0 = actual 2.0 (fills screen)
          scale: _userZoomScale * _baselineMultiplier,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main target
              TargetFace(
                arrows: widget.arrows,
                size: widget.size,
                triSpot: widget.triSpot,
                compoundScoring: widget.compoundScoring,
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
        // Linecutter mode label - at TOP so finger doesn't cover it
        if (isLinecutterMode)
          Positioned(
            top: -32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Text(
                'Line cutter?',
                style: TextStyle(
                  color: AppColors.backgroundDark,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

        // Main zoom window - target rings with crosshair overlay
        Container(
          width: windowSize,
          height: windowSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isLinecutterMode ? AppColors.success : AppColors.gold,
              width: isLinecutterMode ? 6 : 2,
            ),
            boxShadow: isLinecutterMode
                ? [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
            color: AppColors.backgroundDark,
          ),
          child: ClipOval(
            child: Stack(
              children: [
                // Zoomed target rings (no arrows)
                OverflowBox(
                  alignment: Alignment.topLeft,
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
                          size: Size(targetSize, targetSize),
                          painter: _TargetFacePainter(triSpot: triSpot),
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
      ],
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Simple thin black crosshair
    final crosshairPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Full lines through center (no gap)
    // Vertical line
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      crosshairPaint,
    );

    // Horizontal line
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      crosshairPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter that highlights the nearest ring boundary with a glowing effect
class _BoundaryHighlightPainter extends CustomPainter {
  final int ringNumber;
  final double targetSize;

  _BoundaryHighlightPainter({
    required this.ringNumber,
    required this.targetSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Get the boundary position for this ring
    double ringBoundary;
    if (ringNumber == 10) {
      // Could be X or 10 boundary - use 10 ring
      ringBoundary = TargetRings.ring10;
    } else if (ringNumber >= 1 && ringNumber <= 9) {
      // Standard rings
      final ringBoundaries = [
        0.0, // placeholder for index 0
        TargetRings.ring1,
        TargetRings.ring2,
        TargetRings.ring3,
        TargetRings.ring4,
        TargetRings.ring5,
        TargetRings.ring6,
        TargetRings.ring7,
        TargetRings.ring8,
        TargetRings.ring9,
      ];
      ringBoundary = ringBoundaries[ringNumber];
    } else {
      return; // Invalid ring number
    }

    final ringRadiusPixels = ringBoundary * radius;

    // Draw glowing highlight on the ring boundary
    // Outer glow
    final glowPaint = Paint()
      ..color = AppColors.success.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, ringRadiusPixels, glowPaint);

    // Inner bright line
    final highlightPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, ringRadiusPixels, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _BoundaryHighlightPainter oldDelegate) {
    return ringNumber != oldDelegate.ringNumber ||
        targetSize != oldDelegate.targetSize;
  }
}

/// Simple small arrow marker for zoom window - just a colored dot
class _ZoomWindowArrowMarker extends StatelessWidget {
  final int score;
  final double size;

  const _ZoomWindowArrowMarker({
    required this.score,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
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

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: markerColor,
        border: Border.all(
          color: markerColor == Colors.black ? Colors.white : Colors.black,
          width: 0.3,
        ),
      ),
    );
  }
}
