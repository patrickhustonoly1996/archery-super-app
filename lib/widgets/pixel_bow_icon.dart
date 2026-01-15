import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// App logo - pixel arrow with target
class PixelBowIcon extends StatelessWidget {
  final double size;

  const PixelBowIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PixelArrowPainter(),
    );
  }
}

class _PixelArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pixelSize = size.width / 16;
    final paint = Paint()..color = AppColors.gold;

    // Pixelated target in top-right corner (concentric rings)
    final targetCenter = Offset(size.width * 0.82, size.height * 0.18);

    // Outer ring - very faint
    final outerPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.15);
    _drawPixelCircle(canvas, targetCenter, pixelSize * 3.5, pixelSize, outerPaint);

    // Middle ring - faint
    final midPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.25);
    _drawPixelCircle(canvas, targetCenter, pixelSize * 2.5, pixelSize, midPaint);

    // Inner ring - pale yellow
    final innerPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.4);
    _drawPixelCircle(canvas, targetCenter, pixelSize * 1.5, pixelSize, innerPaint);

    // Center dot
    final centerPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.6);
    canvas.drawRect(
      Rect.fromCenter(center: targetCenter, width: pixelSize, height: pixelSize),
      centerPaint,
    );

    // Draw a stylized pixel arrow pointing right
    // Arrow shaft
    for (int x = 2; x <= 12; x++) {
      _drawPixel(canvas, x, 7, pixelSize, paint);
      _drawPixel(canvas, x, 8, pixelSize, paint);
    }

    // Arrow head - top part
    _drawPixel(canvas, 10, 4, pixelSize, paint);
    _drawPixel(canvas, 11, 5, pixelSize, paint);
    _drawPixel(canvas, 12, 6, pixelSize, paint);
    _drawPixel(canvas, 13, 7, pixelSize, paint);
    _drawPixel(canvas, 13, 8, pixelSize, paint);

    // Arrow head - bottom part
    _drawPixel(canvas, 12, 9, pixelSize, paint);
    _drawPixel(canvas, 11, 10, pixelSize, paint);
    _drawPixel(canvas, 10, 11, pixelSize, paint);

    // Fletching at back
    final fletchPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.6);
    _drawPixel(canvas, 2, 5, pixelSize, fletchPaint);
    _drawPixel(canvas, 3, 6, pixelSize, fletchPaint);
    _drawPixel(canvas, 2, 10, pixelSize, fletchPaint);
    _drawPixel(canvas, 3, 9, pixelSize, fletchPaint);
  }

  void _drawPixel(Canvas canvas, int x, int y, double pixelSize, Paint paint) {
    canvas.drawRect(
      Rect.fromLTWH(x * pixelSize, y * pixelSize, pixelSize, pixelSize),
      paint,
    );
  }

  // Draw a pixelated circle (ring) using discrete pixels
  void _drawPixelCircle(Canvas canvas, Offset center, double radius, double pixelSize, Paint paint) {
    // Draw pixels in a circle pattern
    final int steps = 16;
    for (int i = 0; i < steps; i++) {
      final angle = (i / steps) * 2 * 3.14159;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      // Snap to pixel grid
      final px = (x / pixelSize).round() * pixelSize;
      final py = (y / pixelSize).round() * pixelSize;
      canvas.drawRect(
        Rect.fromLTWH(px - pixelSize / 2, py - pixelSize / 2, pixelSize, pixelSize),
        paint,
      );
    }
  }

  double cos(double x) => _cos(x);
  double sin(double x) => _sin(x);

  // Simple trig without importing dart:math
  double _cos(double x) {
    x = x % (2 * 3.14159);
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _sin(double x) {
    x = x % (2 * 3.14159);
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
