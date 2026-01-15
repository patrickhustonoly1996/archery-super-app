import 'dart:math' as math;
import '../db/database.dart';

/// Smart zoom utility - calculates optimal zoom based on ACTUAL arrow spread
///
/// How it works:
/// 1. Calculate the group center (mean of arrow positions)
/// 2. Find the maximum distance from center to any arrow (group spread)
/// 3. Zoom to show the spread + 2 rings padding
///
/// Tight group → high zoom (5-6x), Wide group → low zoom (2-3x)
class SmartZoom {
  /// Minimum arrows needed before we start adapting zoom
  /// With fewer arrows, we use a sensible default
  static const int minArrowsForAdaptiveZoom = 3;

  /// Minimum zoom factor - never go below 2x
  static const double minZoom = 2.0;

  /// Maximum zoom factor - cap at 6x for usability
  static const double maxZoom = 6.0;

  /// Padding in normalized units (~2 rings = 0.2)
  static const double paddingRings = 0.2;

  /// Calculate the optimal zoom factor based on actual arrow spread
  ///
  /// [arrows] - List of plotted arrows with normalized x,y coordinates
  /// [isIndoor] - Indoor rounds typically have tighter groups (unused for now)
  ///
  /// Returns a zoom factor between minZoom and maxZoom
  static double calculateZoomFactor(List<Arrow> arrows, {required bool isIndoor}) {
    // Not enough arrows to determine spread - use sensible default
    if (arrows.length < minArrowsForAdaptiveZoom) {
      return minZoom;
    }

    // Step 1: Calculate group center (mean position)
    double sumX = 0;
    double sumY = 0;
    for (final arrow in arrows) {
      sumX += arrow.x;
      sumY += arrow.y;
    }
    final centerX = sumX / arrows.length;
    final centerY = sumY / arrows.length;

    // Step 2: Find maximum distance from center (group spread)
    // Using 90th percentile instead of max to ignore outliers
    final distances = arrows.map((arrow) {
      final dx = arrow.x - centerX;
      final dy = arrow.y - centerY;
      return math.sqrt(dx * dx + dy * dy);
    }).toList()..sort();

    // Use 90th percentile if we have enough arrows, otherwise max
    final percentileIndex = ((arrows.length - 1) * 0.9).round();
    final spreadRadius = distances[percentileIndex];

    // Step 3: Calculate zoom to show spread + padding
    // If spread is 0.3 (covers 3 rings from center), with 0.2 padding = 0.5
    // We want to zoom so 0.5 normalized units fills half the view
    // Zoom factor = 1 / (spreadRadius + padding)
    final viewRadius = spreadRadius + paddingRings;

    // Clamp viewRadius to reasonable range before computing zoom
    // Minimum 0.15 (very tight group) → 6.67x zoom (capped at 6x)
    // Maximum 0.5 (wide group) → 2x zoom
    final clampedRadius = viewRadius.clamp(1.0 / maxZoom, 1.0 / minZoom);
    final calculatedZoom = 1.0 / clampedRadius;

    return calculatedZoom.clamp(minZoom, maxZoom);
  }

  /// Calculate group statistics for display/debugging
  /// Returns (centerX, centerY, spreadRadius) in normalized coords
  static ({double centerX, double centerY, double spreadRadius})
      calculateGroupStats(List<Arrow> arrows) {
    if (arrows.isEmpty) {
      return (centerX: 0, centerY: 0, spreadRadius: 0);
    }

    double sumX = 0;
    double sumY = 0;
    for (final arrow in arrows) {
      sumX += arrow.x;
      sumY += arrow.y;
    }
    final centerX = sumX / arrows.length;
    final centerY = sumY / arrows.length;

    double maxDistance = 0;
    for (final arrow in arrows) {
      final dx = arrow.x - centerX;
      final dy = arrow.y - centerY;
      final distance = math.sqrt(dx * dx + dy * dy);
      if (distance > maxDistance) {
        maxDistance = distance;
      }
    }

    return (centerX: centerX, centerY: centerY, spreadRadius: maxDistance);
  }
}
