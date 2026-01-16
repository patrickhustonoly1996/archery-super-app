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

    // Clean target in top-right corner - outer ring + center square
    final targetCenterX = 12;
    final targetCenterY = 3;

    // Outer ring - simple 8 pixels forming a ring
    final ringPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.4);
    _drawPixel(canvas, targetCenterX - 1, targetCenterY - 2, pixelSize, ringPaint); // top
    _drawPixel(canvas, targetCenterX, targetCenterY - 2, pixelSize, ringPaint);
    _drawPixel(canvas, targetCenterX + 1, targetCenterY - 1, pixelSize, ringPaint); // right top
    _drawPixel(canvas, targetCenterX + 2, targetCenterY, pixelSize, ringPaint); // right
    _drawPixel(canvas, targetCenterX + 1, targetCenterY + 1, pixelSize, ringPaint); // right bottom
    _drawPixel(canvas, targetCenterX, targetCenterY + 2, pixelSize, ringPaint); // bottom
    _drawPixel(canvas, targetCenterX - 1, targetCenterY + 2, pixelSize, ringPaint);
    _drawPixel(canvas, targetCenterX - 2, targetCenterY + 1, pixelSize, ringPaint); // left bottom
    _drawPixel(canvas, targetCenterX - 2, targetCenterY, pixelSize, ringPaint); // left
    _drawPixel(canvas, targetCenterX - 2, targetCenterY - 1, pixelSize, ringPaint); // left top

    // Center square (2x2)
    final centerPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.7);
    _drawPixel(canvas, targetCenterX - 1, targetCenterY, pixelSize, centerPaint);
    _drawPixel(canvas, targetCenterX, targetCenterY, pixelSize, centerPaint);
    _drawPixel(canvas, targetCenterX - 1, targetCenterY + 1, pixelSize, centerPaint);
    _drawPixel(canvas, targetCenterX, targetCenterY + 1, pixelSize, centerPaint);

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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
