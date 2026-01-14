import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/arrow_coordinate.dart';
import '../theme/app_theme.dart';

/// Single source of truth for ALL coordinate conversions in the arrow plotting system.
///
/// Use this class everywhere - never do coordinate math inline elsewhere.
/// This ensures consistent, deterministic positioning across all views.
class TargetCoordinateSystem {
  /// Target face size in centimeters (e.g., 40 for indoor, 80/122 for outdoor)
  final int faceSizeCm;

  /// Widget size in pixels for rendering
  final double widgetSize;

  const TargetCoordinateSystem({
    required this.faceSizeCm,
    required this.widgetSize,
  });

  // ============================================================================
  // CORE MEASUREMENTS
  // ============================================================================

  /// Target radius in mm (half of face diameter)
  double get radiusMm => faceSizeCm * 5.0;

  /// Target diameter in mm
  double get diameterMm => faceSizeCm * 10.0;

  /// Widget center point in pixels
  Offset get widgetCenter => Offset(widgetSize / 2, widgetSize / 2);

  /// Widget radius in pixels (half of widget size)
  double get widgetRadius => widgetSize / 2;

  /// Pixels per millimeter for this widget/face combination
  double get pixelsPerMm => widgetSize / diameterMm;

  /// Millimeters per pixel
  double get mmPerPixel => diameterMm / widgetSize;

  // ============================================================================
  // COORDINATE CONVERSIONS
  // ============================================================================

  /// Convert widget pixels to ArrowCoordinate
  ArrowCoordinate pixelsToCoordinate(Offset pixels) {
    return ArrowCoordinate.fromWidgetPixels(
      px: pixels.dx,
      py: pixels.dy,
      widgetSize: widgetSize,
      faceSizeCm: faceSizeCm,
    );
  }

  /// Convert ArrowCoordinate to widget pixels (rounded for crisp rendering)
  Offset coordinateToPixels(ArrowCoordinate coord) {
    return coord.toWidgetPixels(widgetSize);
  }

  /// Convert ArrowCoordinate to widget pixels (exact, for transforms)
  Offset coordinateToPixelsExact(ArrowCoordinate coord) {
    return coord.toWidgetPixelsExact(widgetSize);
  }

  /// Convert normalized coordinates (-1 to +1) to widget pixels
  Offset normalizedToPixels(double normX, double normY) {
    return Offset(
      (widgetRadius + normX * widgetRadius).roundToDouble(),
      (widgetRadius + normY * widgetRadius).roundToDouble(),
    );
  }

  /// Convert widget pixels to normalized coordinates
  Offset pixelsToNormalized(Offset pixels) {
    return Offset(
      (pixels.dx - widgetRadius) / widgetRadius,
      (pixels.dy - widgetRadius) / widgetRadius,
    );
  }

  /// Convert mm offset to pixel offset
  double mmToPixels(double mm) => mm * pixelsPerMm;

  /// Convert pixel offset to mm
  double pixelsToMm(double pixels) => pixels * mmPerPixel;

  // ============================================================================
  // RING BOUNDARY HELPERS
  // ============================================================================

  /// Get the pixel radius for a specific ring number
  double ringBoundaryPixels(int ring) {
    final boundaryMm = TargetRingsMm.getRingBoundaryMm(ring, faceSizeCm);
    return mmToPixels(boundaryMm);
  }

  /// Get the normalized radius for a specific ring number
  double ringBoundaryNormalized(int ring) {
    return TargetRingsMm.getRingBoundaryMm(ring, faceSizeCm) / radiusMm;
  }

  /// Get all ring boundaries as pixel radii (for drawing)
  Map<int, double> get ringBoundariesPixels {
    return {
      for (int ring = 1; ring <= 10; ring++) ring: ringBoundaryPixels(ring),
    };
  }

  /// Get the X ring boundary in pixels
  double get xRingBoundaryPixels => mmToPixels(TargetRingsMm.getXRingMm(faceSizeCm));

  // ============================================================================
  // ZOOM WINDOW SUPPORT
  // ============================================================================

  /// Calculate the transform offset for centering a point in a zoom window.
  /// Used to properly position the target face in a magnified view.
  Offset zoomWindowOffset({
    required ArrowCoordinate centerOn,
    required double zoomFactor,
    required double windowSize,
  }) {
    final pointPixels = coordinateToPixelsExact(centerOn);
    return Offset(
      (windowSize / 2) - (pointPixels.dx * zoomFactor),
      (windowSize / 2) - (pointPixels.dy * zoomFactor),
    );
  }

  /// Transform a coordinate for display in a zoom window centered on another point.
  /// The arrow marker will be positioned relative to the zoom center.
  Offset coordinateToZoomWindowPixels({
    required ArrowCoordinate coord,
    required ArrowCoordinate centerOn,
    required double zoomFactor,
    required double windowSize,
  }) {
    final pointPixels = coordinateToPixelsExact(coord);
    final centerPixels = coordinateToPixelsExact(centerOn);
    return Offset(
      ((pointPixels.dx - centerPixels.dx) * zoomFactor + windowSize / 2).roundToDouble(),
      ((pointPixels.dy - centerPixels.dy) * zoomFactor + windowSize / 2).roundToDouble(),
    );
  }

  /// Calculate the visible bounds in a zoom window (for culling arrows outside view)
  Rect zoomWindowVisibleBounds({
    required ArrowCoordinate centerOn,
    required double zoomFactor,
    required double windowSize,
  }) {
    final visibleRadiusMm = (windowSize / 2 / zoomFactor) * mmPerPixel;
    return Rect.fromCenter(
      center: Offset(centerOn.xMm, centerOn.yMm),
      width: visibleRadiusMm * 2,
      height: visibleRadiusMm * 2,
    );
  }

  // ============================================================================
  // SCORING
  // ============================================================================

  /// Get score for an ArrowCoordinate using epsilon-based boundary detection
  int scoreFromCoordinate(ArrowCoordinate coord) {
    return TargetRingsMm.scoreFromDistanceMm(coord.distanceMm, faceSizeCm);
  }

  /// Check if coordinate is in the X ring
  bool isXRing(ArrowCoordinate coord) {
    return TargetRingsMm.isXRing(coord.distanceMm, faceSizeCm);
  }

  /// Get score and isX for an ArrowCoordinate
  ({int score, bool isX}) scoreAndX(ArrowCoordinate coord) {
    return (
      score: scoreFromCoordinate(coord),
      isX: isXRing(coord),
    );
  }

  // ============================================================================
  // BOUNDARY PROXIMITY DETECTION (for linecutter mode)
  // ============================================================================

  /// Check if a coordinate is near any ring boundary.
  /// Returns the ring number if near a boundary, null otherwise.
  /// Used to trigger linecutter precision mode.
  ({int? ring, double distanceMm})? nearestBoundary(
    ArrowCoordinate coord, {
    double thresholdPercent = 1.5,
  }) {
    final thresholdMm = radiusMm * (thresholdPercent / 100);
    double minDistance = double.infinity;
    int? nearestRing;

    // Check X ring boundary
    final xBoundaryMm = TargetRingsMm.getXRingMm(faceSizeCm);
    final xDistance = (coord.distanceMm - xBoundaryMm).abs();
    if (xDistance < minDistance) {
      minDistance = xDistance;
      nearestRing = 11; // Use 11 to represent X boundary
    }

    // Check all ring boundaries (10 down to 1)
    for (int ring = 10; ring >= 1; ring--) {
      final boundaryMm = TargetRingsMm.getRingBoundaryMm(ring, faceSizeCm);
      final distance = (coord.distanceMm - boundaryMm).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearestRing = ring;
      }
    }

    if (minDistance <= thresholdMm) {
      return (ring: nearestRing, distanceMm: minDistance);
    }
    return null;
  }

  // ============================================================================
  // AUTO-ZOOM CALCULATION
  // ============================================================================

  /// Calculate optimal zoom factor based on arrow grouping.
  /// Returns a zoom level that shows the group with appropriate padding.
  double calculateAutoZoom({
    required List<ArrowCoordinate> arrows,
    int minArrows = 6,
    double minZoom = 1.5,
    double maxZoom = 6.0,
    int paddingRings = 3,
  }) {
    if (arrows.length < minArrows) return minZoom;

    // Find the maximum distance from center among all arrows
    double maxDistance = 0;
    for (final arrow in arrows) {
      if (arrow.distanceMm > maxDistance) {
        maxDistance = arrow.distanceMm;
      }
    }

    // Add padding (rings worth of distance)
    final ringWidthMm = radiusMm / 10;
    final paddedDistanceMm = maxDistance + (ringWidthMm * paddingRings);

    // Calculate zoom to fit padded distance
    if (paddedDistanceMm <= 0) return minZoom;
    final zoom = radiusMm / paddedDistanceMm;

    return zoom.clamp(minZoom, maxZoom);
  }

  // ============================================================================
  // EQUALITY
  // ============================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TargetCoordinateSystem &&
        other.faceSizeCm == faceSizeCm &&
        other.widgetSize == widgetSize;
  }

  @override
  int get hashCode => Object.hash(faceSizeCm, widgetSize);

  @override
  String toString() =>
      'TargetCoordinateSystem(face: ${faceSizeCm}cm, widget: ${widgetSize}px, px/mm: ${pixelsPerMm.toStringAsFixed(2)})';
}
