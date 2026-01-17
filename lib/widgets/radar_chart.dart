import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

/// Data point for a single axis on the radar chart
class RadarDataPoint {
  final String label;
  final double value; // 0.0 to 1.0 (normalized)
  final String? displayValue; // Optional formatted value to show

  const RadarDataPoint({
    required this.label,
    required this.value,
    this.displayValue,
  });
}

/// A complete radar chart data set
class RadarChartData {
  final String? label;
  final List<RadarDataPoint> points;
  final Color color;
  final bool showFill;

  const RadarChartData({
    this.label,
    required this.points,
    this.color = AppColors.gold,
    this.showFill = true,
  });
}

/// Customizable radar/spider chart widget using CustomPaint
class RadarChart extends StatelessWidget {
  final List<RadarChartData> datasets;
  final double size;
  final int gridLevels;
  final bool showLabels;
  final bool showValues;
  final Color gridColor;
  final Color labelColor;

  const RadarChart({
    super.key,
    required this.datasets,
    this.size = 200,
    this.gridLevels = 5,
    this.showLabels = true,
    this.showValues = false,
    this.gridColor = AppColors.surfaceLight,
    this.labelColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    if (datasets.isEmpty || datasets.first.points.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            'No data',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarChartPainter(
          datasets: datasets,
          gridLevels: gridLevels,
          showLabels: showLabels,
          showValues: showValues,
          gridColor: gridColor,
          labelColor: labelColor,
        ),
        size: Size(size, size),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<RadarChartData> datasets;
  final int gridLevels;
  final bool showLabels;
  final bool showValues;
  final Color gridColor;
  final Color labelColor;

  _RadarChartPainter({
    required this.datasets,
    required this.gridLevels,
    required this.showLabels,
    required this.showValues,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * 0.7; // Leave room for labels
    final numAxes = datasets.first.points.length;

    if (numAxes < 3) return; // Need at least 3 axes

    final angleStep = (2 * math.pi) / numAxes;
    // Start from top (-90 degrees)
    const startAngle = -math.pi / 2;

    // Draw grid
    _drawGrid(canvas, center, radius, numAxes, angleStep, startAngle);

    // Draw axis lines
    _drawAxes(canvas, center, radius, numAxes, angleStep, startAngle);

    // Draw data polygons for each dataset
    for (final dataset in datasets) {
      _drawDataPolygon(
          canvas, center, radius, dataset, numAxes, angleStep, startAngle);
    }

    // Draw labels
    if (showLabels) {
      _drawLabels(canvas, center, radius, numAxes, angleStep, startAngle);
    }

    // Draw values at data points
    if (showValues) {
      _drawValues(canvas, center, radius, numAxes, angleStep, startAngle);
    }
  }

  void _drawGrid(Canvas canvas, Offset center, double radius, int numAxes,
      double angleStep, double startAngle) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric polygons
    for (int level = 1; level <= gridLevels; level++) {
      final levelRadius = (radius / gridLevels) * level;
      final path = Path();

      for (int i = 0; i <= numAxes; i++) {
        final angle = startAngle + (i % numAxes) * angleStep;
        final x = center.dx + levelRadius * math.cos(angle);
        final y = center.dy + levelRadius * math.sin(angle);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      path.close();
      canvas.drawPath(path, gridPaint);
    }
  }

  void _drawAxes(Canvas canvas, Offset center, double radius, int numAxes,
      double angleStep, double startAngle) {
    final axisPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < numAxes; i++) {
      final angle = startAngle + i * angleStep;
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);

      canvas.drawLine(center, Offset(endX, endY), axisPaint);
    }
  }

  void _drawDataPolygon(Canvas canvas, Offset center, double radius,
      RadarChartData dataset, int numAxes, double angleStep, double startAngle) {
    final points = dataset.points;
    final fillPath = Path();
    final strokePath = Path();

    final dataPoints = <Offset>[];

    for (int i = 0; i < numAxes; i++) {
      final value = points[i].value.clamp(0.0, 1.0);
      final angle = startAngle + i * angleStep;
      final pointRadius = radius * value;
      final x = center.dx + pointRadius * math.cos(angle);
      final y = center.dy + pointRadius * math.sin(angle);

      dataPoints.add(Offset(x, y));

      if (i == 0) {
        fillPath.moveTo(x, y);
        strokePath.moveTo(x, y);
      } else {
        fillPath.lineTo(x, y);
        strokePath.lineTo(x, y);
      }
    }

    fillPath.close();
    strokePath.close();

    // Draw fill with gradient-like effect
    if (dataset.showFill) {
      final fillPaint = Paint()
        ..color = dataset.color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw outer glow stroke
    final glowPaint = Paint()
      ..color = dataset.color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(strokePath, glowPaint);

    // Draw main stroke
    final strokePaint = Paint()
      ..color = dataset.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(strokePath, strokePaint);

    // Draw glowing data points
    final pointGlowPaint = Paint()
      ..color = dataset.color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final pointPaint = Paint()
      ..color = dataset.color
      ..style = PaintingStyle.fill;

    for (final point in dataPoints) {
      canvas.drawCircle(point, 8, pointGlowPaint); // Outer glow
      canvas.drawCircle(point, 4, pointPaint); // Core
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double radius, int numAxes,
      double angleStep, double startAngle) {
    final labels = datasets.first.points;
    final labelRadius = radius + 20;

    for (int i = 0; i < numAxes; i++) {
      final angle = startAngle + i * angleStep;
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      final textSpan = TextSpan(
        text: labels[i].label,
        style: TextStyle(
          color: labelColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();

      // Position text based on angle
      double offsetX = x - textPainter.width / 2;
      double offsetY = y - textPainter.height / 2;

      // Adjust for labels at edges
      final normalizedAngle = (angle + math.pi / 2) % (2 * math.pi);
      if (normalizedAngle < math.pi * 0.25 || normalizedAngle > math.pi * 1.75) {
        // Top
        offsetY -= 5;
      } else if (normalizedAngle > math.pi * 0.75 && normalizedAngle < math.pi * 1.25) {
        // Bottom
        offsetY += 5;
      }

      textPainter.paint(canvas, Offset(offsetX, offsetY));
    }
  }

  void _drawValues(Canvas canvas, Offset center, double radius, int numAxes,
      double angleStep, double startAngle) {
    final points = datasets.first.points;

    for (int i = 0; i < numAxes; i++) {
      if (points[i].displayValue == null) continue;

      final value = points[i].value.clamp(0.0, 1.0);
      final angle = startAngle + i * angleStep;
      final pointRadius = radius * value;
      final x = center.dx + pointRadius * math.cos(angle);
      final y = center.dy + pointRadius * math.sin(angle);

      final textSpan = TextSpan(
        text: points[i].displayValue,
        style: TextStyle(
          color: AppColors.gold,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height - 8),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarChartPainter oldDelegate) {
    return oldDelegate.datasets != datasets ||
        oldDelegate.gridLevels != gridLevels ||
        oldDelegate.showLabels != showLabels;
  }
}
