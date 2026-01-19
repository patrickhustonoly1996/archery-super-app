import 'dart:math' as math;

import '../models/sight_mark.dart';

/// Calculator for sight mark interpolation and prediction
/// Uses quadratic curve fitting when possible (3+ marks) for accuracy,
/// falls back to power-law interpolation with 2 marks (models arrow drop).
///
/// Future: This could be enhanced with crowdsourced data from thousands
/// of archers to provide accurate predictions even for new users based
/// on bow type, poundage, and arrow specs.
class SightMarkCalculator {
  /// Predict sight mark for a given distance using available data
  /// Returns null if insufficient data
  static PredictedSightMark? predict({
    required List<SightMark> marks,
    required double targetDistance,
    required DistanceUnit unit,
  }) {
    // Filter to same unit and sort by distance
    final filtered = marks
        .where((m) => m.unit == unit && m.isValid)
        .toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    if (filtered.isEmpty) return null;

    // Exact match - highest confidence
    final exact = filtered.where((m) => m.distance == targetDistance).toList();
    if (exact.isNotEmpty) {
      exact.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return PredictedSightMark(
        distance: targetDistance,
        unit: unit,
        predictedValue: exact.first.numericValue,
        confidence: SightMarkConfidence.high,
        source: 'exact',
        basedOn: exact.first,
      );
    }

    // With 3+ marks, use quadratic fitting (matches ballistic curve)
    if (filtered.length >= 3) {
      return _quadraticPredict(filtered, targetDistance, unit);
    }

    // With 2 marks, use power-law interpolation (models arrow ballistics)
    if (filtered.length == 2) {
      return _twoPointPredict(filtered, targetDistance, unit);
    }

    // With 1 mark, can only return that if it's close
    return null;
  }

  /// Quadratic curve fitting: sightMark = a*distance² + b*distance + c
  /// Uses least squares regression for best fit
  static PredictedSightMark? _quadraticPredict(
    List<SightMark> marks,
    double targetDistance,
    DistanceUnit unit,
  ) {
    final n = marks.length;

    // Build sums for normal equations
    double sumX = 0, sumX2 = 0, sumX3 = 0, sumX4 = 0;
    double sumY = 0, sumXY = 0, sumX2Y = 0;

    for (final mark in marks) {
      final x = mark.distance;
      final y = mark.numericValue;
      final x2 = x * x;

      sumX += x;
      sumX2 += x2;
      sumX3 += x2 * x;
      sumX4 += x2 * x2;
      sumY += y;
      sumXY += x * y;
      sumX2Y += x2 * y;
    }

    // Solve 3x3 system using Cramer's rule
    // [n    sumX   sumX2 ] [c]   [sumY  ]
    // [sumX sumX2  sumX3 ] [b] = [sumXY ]
    // [sumX2 sumX3 sumX4 ] [a]   [sumX2Y]

    final nDouble = n.toDouble();

    final det = _det3x3(
      nDouble, sumX, sumX2,
      sumX, sumX2, sumX3,
      sumX2, sumX3, sumX4,
    );

    if (det.abs() < 1e-10) {
      // Matrix is singular, fall back to linear
      return _linearPredict(marks, targetDistance, unit);
    }

    final detA = _det3x3(
      nDouble, sumX, sumY,
      sumX, sumX2, sumXY,
      sumX2, sumX3, sumX2Y,
    );

    final detB = _det3x3(
      nDouble, sumY, sumX2,
      sumX, sumXY, sumX3,
      sumX2, sumX2Y, sumX4,
    );

    final detC = _det3x3(
      sumY, sumX, sumX2,
      sumXY, sumX2, sumX3,
      sumX2Y, sumX3, sumX4,
    );

    final a = detA / det;
    final b = detB / det;
    final c = detC / det;

    // Calculate predicted value
    final predicted = a * targetDistance * targetDistance +
        b * targetDistance +
        c;

    // Calculate R² to assess fit quality
    final rSquared = _calculateRSquared(marks, a, b, c);

    // Determine confidence based on:
    // - R² value (how well the curve fits)
    // - Whether we're interpolating or extrapolating
    final minDist = marks.first.distance;
    final maxDist = marks.last.distance;
    final isExtrapolating = targetDistance < minDist || targetDistance > maxDist;

    SightMarkConfidence confidence;
    String source;

    if (isExtrapolating) {
      // Extrapolation is less reliable
      final extrapolationDistance = targetDistance < minDist
          ? minDist - targetDistance
          : targetDistance - maxDist;
      final range = maxDist - minDist;

      if (extrapolationDistance > range * 0.5) {
        confidence = SightMarkConfidence.low;
      } else if (rSquared > 0.95) {
        confidence = SightMarkConfidence.medium;
      } else {
        confidence = SightMarkConfidence.low;
      }
      source = 'extrapolated';
    } else {
      // Interpolation
      if (rSquared > 0.98) {
        confidence = SightMarkConfidence.high;
      } else if (rSquared > 0.90) {
        confidence = SightMarkConfidence.medium;
      } else {
        confidence = SightMarkConfidence.low;
      }
      source = 'interpolated';
    }

    return PredictedSightMark(
      distance: targetDistance,
      unit: unit,
      predictedValue: predicted,
      confidence: confidence,
      source: source,
      interpolatedFrom: marks,
    );
  }

  /// Power-law interpolation between two points
  /// Uses sightMark = c + k * distance^n where n ≈ 1.4
  /// This models arrow drop physics better than linear interpolation,
  /// producing increasing gaps at longer distances.
  static PredictedSightMark? _twoPointPredict(
    List<SightMark> marks,
    double targetDistance,
    DistanceUnit unit,
  ) {
    if (marks.length < 2) return null;

    // Power exponent - between linear (1.0) and quadratic (2.0)
    // 1.4 is typical for arrow ballistics
    const double n = 1.4;

    // Find bracketing points or nearest two
    SightMark? lower, upper;

    for (final mark in marks) {
      if (mark.distance <= targetDistance) {
        lower = mark;
      }
      if (mark.distance >= targetDistance && upper == null) {
        upper = mark;
      }
    }

    // If no bracket, use the two nearest points
    lower ??= marks[marks.length - 2];
    upper ??= marks[marks.length - 1];

    if (lower.distance == upper.distance) return null;

    final d1 = lower.distance;
    final d2 = upper.distance;
    final s1 = lower.numericValue;
    final s2 = upper.numericValue;

    // Solve for k and c in: sightMark = c + k * d^n
    // s1 = c + k * d1^n
    // s2 = c + k * d2^n
    // k = (s2 - s1) / (d2^n - d1^n)
    // c = s1 - k * d1^n

    final d1n = math.pow(d1, n).toDouble();
    final d2n = math.pow(d2, n).toDouble();

    if ((d2n - d1n).abs() < 1e-10) {
      // Distances too close, fall back to linear
      final ratio = (targetDistance - d1) / (d2 - d1);
      final predicted = s1 + (s2 - s1) * ratio;
      return PredictedSightMark(
        distance: targetDistance,
        unit: unit,
        predictedValue: predicted,
        confidence: SightMarkConfidence.low,
        source: 'linear fallback',
        interpolatedFrom: [lower, upper],
      );
    }

    final k = (s2 - s1) / (d2n - d1n);
    final c = s1 - k * d1n;

    // Predict using power model
    final predicted = c + k * math.pow(targetDistance, n).toDouble();

    final isExtrapolating = targetDistance < marks.first.distance ||
        targetDistance > marks.last.distance;

    return PredictedSightMark(
      distance: targetDistance,
      unit: unit,
      predictedValue: predicted,
      confidence: isExtrapolating
          ? SightMarkConfidence.low
          : SightMarkConfidence.medium,
      source: isExtrapolating ? 'power extrapolated' : 'power interpolated',
      interpolatedFrom: [lower, upper],
    );
  }


  /// Calculate R² (coefficient of determination) for quadratic fit
  static double _calculateRSquared(
    List<SightMark> marks,
    double a,
    double b,
    double c,
  ) {
    if (marks.isEmpty) return 0;

    // Calculate mean Y
    double sumY = 0;
    for (final mark in marks) {
      sumY += mark.numericValue;
    }
    final meanY = sumY / marks.length;

    // Calculate SS_tot and SS_res
    double ssTot = 0;
    double ssRes = 0;

    for (final mark in marks) {
      final y = mark.numericValue;
      final yPred = a * mark.distance * mark.distance +
          b * mark.distance +
          c;

      ssTot += (y - meanY) * (y - meanY);
      ssRes += (y - yPred) * (y - yPred);
    }

    if (ssTot == 0) return 1.0;
    return 1.0 - (ssRes / ssTot);
  }

  /// 3x3 determinant for Cramer's rule
  static double _det3x3(
    double a11, double a12, double a13,
    double a21, double a22, double a23,
    double a31, double a32, double a33,
  ) {
    return a11 * (a22 * a33 - a23 * a32) -
        a12 * (a21 * a33 - a23 * a31) +
        a13 * (a21 * a32 - a22 * a31);
  }

  /// Get curve coefficients for visualization
  /// Returns [a, b, c] where sightMark = a*distance² + b*distance + c
  static List<double>? getCurveCoefficients(List<SightMark> marks, DistanceUnit unit) {
    final filtered = marks
        .where((m) => m.unit == unit && m.isValid)
        .toList();

    if (filtered.length < 3) return null;

    final n = filtered.length;
    double sumX = 0, sumX2 = 0, sumX3 = 0, sumX4 = 0;
    double sumY = 0, sumXY = 0, sumX2Y = 0;

    for (final mark in filtered) {
      final x = mark.distance;
      final y = mark.numericValue;
      final x2 = x * x;

      sumX += x;
      sumX2 += x2;
      sumX3 += x2 * x;
      sumX4 += x2 * x2;
      sumY += y;
      sumXY += x * y;
      sumX2Y += x2 * y;
    }

    final det = _det3x3(
      n.toDouble(), sumX, sumX2,
      sumX, sumX2, sumX3,
      sumX2, sumX3, sumX4,
    );

    if (det.abs() < 1e-10) return null;

    final a = _det3x3(
          n.toDouble(), sumX, sumY,
          sumX, sumX2, sumXY,
          sumX2, sumX3, sumX2Y,
        ) / det;

    final b = _det3x3(
          n.toDouble(), sumY, sumX2,
          sumX, sumXY, sumX3,
          sumX2, sumX2Y, sumX4,
        ) / det;

    final c = _det3x3(
          sumY, sumX, sumX2,
          sumXY, sumX2, sumX3,
          sumX2Y, sumX3, sumX4,
        ) / det;

    return [a, b, c];
  }
}
