import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Immutable coordinate representing an arrow position in millimeters from target center.
/// This is the single source of truth for arrow positioning.
///
/// Stored values:
/// - xMm: horizontal distance from center (positive = right)
/// - yMm: vertical distance from center (positive = down)
/// - faceSizeCm: the target face size this coordinate was recorded on
///
/// All other representations (normalized, pixels) are computed from these values.
@immutable
class ArrowCoordinate {
  /// X position in millimeters from center (positive = right)
  final double xMm;

  /// Y position in millimeters from center (positive = down)
  final double yMm;

  /// The target face size in cm this coordinate was recorded on
  final int faceSizeCm;

  const ArrowCoordinate({
    required this.xMm,
    required this.yMm,
    required this.faceSizeCm,
  });

  // ============================================================================
  // DERIVED PROPERTIES (computed, not stored)
  // ============================================================================

  /// Target face radius in mm
  double get faceRadiusMm => faceSizeCm * 5.0;

  /// Distance from center in mm (Euclidean)
  double get distanceMm => math.sqrt(xMm * xMm + yMm * yMm);

  /// Angle from center in radians (0 = right, pi/2 = down)
  double get angleRadians => math.atan2(yMm, xMm);

  /// Angle from center in degrees (0 = right, 90 = down)
  double get angleDegrees => angleRadians * 180 / math.pi;

  /// Normalized X coordinate (-1 to +1) relative to face radius
  double get normalizedX => xMm / faceRadiusMm;

  /// Normalized Y coordinate (-1 to +1) relative to face radius
  double get normalizedY => yMm / faceRadiusMm;

  /// Normalized distance (0 to ~1) relative to face radius
  /// Values > 1.0 indicate shots outside the target face
  double get normalizedDistance => distanceMm / faceRadiusMm;

  /// Whether this coordinate is within the target face bounds
  bool get isOnTarget => normalizedDistance <= 1.0;

  // ============================================================================
  // FACTORY CONSTRUCTORS
  // ============================================================================

  /// Create from normalized coordinates (-1 to +1)
  factory ArrowCoordinate.fromNormalized({
    required double x,
    required double y,
    required int faceSizeCm,
  }) {
    final radiusMm = faceSizeCm * 5.0;
    return ArrowCoordinate(
      xMm: x * radiusMm,
      yMm: y * radiusMm,
      faceSizeCm: faceSizeCm,
    );
  }

  /// Create from widget pixel coordinates
  factory ArrowCoordinate.fromWidgetPixels({
    required double px,
    required double py,
    required double widgetSize,
    required int faceSizeCm,
  }) {
    final center = widgetSize / 2;
    final normalizedX = (px - center) / center;
    final normalizedY = (py - center) / center;
    return ArrowCoordinate.fromNormalized(
      x: normalizedX,
      y: normalizedY,
      faceSizeCm: faceSizeCm,
    );
  }

  /// Create from polar coordinates (distance in mm and angle in radians)
  factory ArrowCoordinate.fromPolar({
    required double distanceMm,
    required double angleRadians,
    required int faceSizeCm,
  }) {
    return ArrowCoordinate(
      xMm: distanceMm * math.cos(angleRadians),
      yMm: distanceMm * math.sin(angleRadians),
      faceSizeCm: faceSizeCm,
    );
  }

  // ============================================================================
  // CONVERSION METHODS
  // ============================================================================

  /// Convert to widget pixel position (rounded for crisp rendering)
  Offset toWidgetPixels(double widgetSize) {
    final center = widgetSize / 2;
    return Offset(
      (center + normalizedX * center).roundToDouble(),
      (center + normalizedY * center).roundToDouble(),
    );
  }

  /// Convert to widget pixel position without rounding (for transforms)
  Offset toWidgetPixelsExact(double widgetSize) {
    final center = widgetSize / 2;
    return Offset(
      center + normalizedX * center,
      center + normalizedY * center,
    );
  }

  /// Get coordinates for a different face size (same physical position)
  /// Useful when comparing shots across different target faces
  ArrowCoordinate forFaceSize(int newFaceSizeCm) {
    return ArrowCoordinate(
      xMm: xMm,
      yMm: yMm,
      faceSizeCm: newFaceSizeCm,
    );
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Calculate distance to another coordinate in mm
  double distanceTo(ArrowCoordinate other) {
    final dx = xMm - other.xMm;
    final dy = yMm - other.yMm;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Calculate the midpoint between this and another coordinate
  ArrowCoordinate midpointTo(ArrowCoordinate other) {
    return ArrowCoordinate(
      xMm: (xMm + other.xMm) / 2,
      yMm: (yMm + other.yMm) / 2,
      faceSizeCm: faceSizeCm,
    );
  }

  /// Apply an offset in mm
  ArrowCoordinate offset(double dxMm, double dyMm) {
    return ArrowCoordinate(
      xMm: xMm + dxMm,
      yMm: yMm + dyMm,
      faceSizeCm: faceSizeCm,
    );
  }

  // ============================================================================
  // EQUALITY & DISPLAY
  // ============================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ArrowCoordinate) return false;
    // Use sub-mm precision for equality (0.01mm tolerance)
    const epsilon = 0.01;
    return (xMm - other.xMm).abs() < epsilon &&
        (yMm - other.yMm).abs() < epsilon &&
        faceSizeCm == other.faceSizeCm;
  }

  @override
  int get hashCode => Object.hash(
        (xMm * 100).round(),
        (yMm * 100).round(),
        faceSizeCm,
      );

  @override
  String toString() =>
      'ArrowCoordinate(x: ${xMm.toStringAsFixed(1)}mm, y: ${yMm.toStringAsFixed(1)}mm, dist: ${distanceMm.toStringAsFixed(1)}mm, face: ${faceSizeCm}cm)';

  /// Human-readable position description
  String toDisplayString() {
    final dist = distanceMm.toStringAsFixed(1);
    final xDir = xMm >= 0 ? 'R' : 'L';
    final yDir = yMm >= 0 ? 'D' : 'U';
    final xVal = xMm.abs().toStringAsFixed(1);
    final yVal = yMm.abs().toStringAsFixed(1);
    return '${dist}mm (${xVal}mm $xDir, ${yVal}mm $yDir)';
  }
}
