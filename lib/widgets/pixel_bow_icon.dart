import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// App logo - pixel arrow with target
/// Scales with text scale factor when scaleWithText is true
class PixelBowIcon extends StatelessWidget {
  final double size;
  final bool scaleWithText;

  const PixelBowIcon({
    super.key,
    required this.size,
    this.scaleWithText = true,
  });

  @override
  Widget build(BuildContext context) {
    final scaledSize = scaleWithText
        ? size * MediaQuery.textScalerOf(context).scale(1.0)
        : size;
    return CustomPaint(
      size: Size(scaledSize, scaledSize),
      painter: _PixelArrowPainter(),
    );
  }
}

class _PixelArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pixelSize = size.width / 16;
    final paint = Paint()..color = AppColors.gold;

    // Pixel arrow pointing right - centered vertically
    // Arrow shaft (thick, 2 pixels high)
    for (int x = 1; x <= 11; x++) {
      _drawPixel(canvas, x, 7, pixelSize, paint);
      _drawPixel(canvas, x, 8, pixelSize, paint);
    }

    // Arrow head - top diagonal
    _drawPixel(canvas, 9, 4, pixelSize, paint);
    _drawPixel(canvas, 10, 5, pixelSize, paint);
    _drawPixel(canvas, 11, 6, pixelSize, paint);
    _drawPixel(canvas, 12, 7, pixelSize, paint);
    _drawPixel(canvas, 12, 8, pixelSize, paint);

    // Arrow head - bottom diagonal
    _drawPixel(canvas, 11, 9, pixelSize, paint);
    _drawPixel(canvas, 10, 10, pixelSize, paint);
    _drawPixel(canvas, 9, 11, pixelSize, paint);

    // Fletching at back (subtle)
    final fletchPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.5);
    _drawPixel(canvas, 1, 5, pixelSize, fletchPaint);
    _drawPixel(canvas, 2, 6, pixelSize, fletchPaint);
    _drawPixel(canvas, 1, 10, pixelSize, fletchPaint);
    _drawPixel(canvas, 2, 9, pixelSize, fletchPaint);

    // Nock detail
    final nockPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.3);
    _drawPixel(canvas, 0, 7, pixelSize, nockPaint);
    _drawPixel(canvas, 0, 8, pixelSize, nockPaint);
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
