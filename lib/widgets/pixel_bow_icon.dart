import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// App logo - the professional bow and arrow design
class PixelBowIcon extends StatelessWidget {
  final double size;

  const PixelBowIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/app_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _PixelBowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pixelSize = size.width / 16;
    final paint = Paint()..color = AppColors.gold;
    final dimPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.7);

    // === BOW (vertical, curved like original logo) ===
    // Upper limb tip (curves left)
    _drawPixel(canvas, 4, 1, pixelSize, dimPaint);
    _drawPixel(canvas, 3, 0, pixelSize, dimPaint);
    // Upper limb curving right
    _drawPixel(canvas, 5, 2, pixelSize, paint);
    _drawPixel(canvas, 6, 3, pixelSize, paint);
    _drawPixel(canvas, 6, 4, pixelSize, paint);
    _drawPixel(canvas, 7, 5, pixelSize, paint);
    _drawPixel(canvas, 7, 6, pixelSize, paint);
    // Grip
    _drawPixel(canvas, 8, 7, pixelSize, paint);
    _drawPixel(canvas, 8, 8, pixelSize, paint);
    // Lower limb curving right
    _drawPixel(canvas, 7, 9, pixelSize, paint);
    _drawPixel(canvas, 7, 10, pixelSize, paint);
    _drawPixel(canvas, 6, 11, pixelSize, paint);
    _drawPixel(canvas, 6, 12, pixelSize, paint);
    _drawPixel(canvas, 5, 13, pixelSize, paint);
    // Lower limb tip (curves left)
    _drawPixel(canvas, 4, 14, pixelSize, dimPaint);
    _drawPixel(canvas, 3, 15, pixelSize, dimPaint);

    // === STRING (vertical, connects limb tips) ===
    final stringPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.4);
    for (int y = 1; y <= 14; y++) {
      _drawPixel(canvas, 3, y, pixelSize, stringPaint);
    }

    // === ARROW (diagonal, bottom-left to top-right) ===
    // Fletching
    final fletchPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.5);
    _drawPixel(canvas, 0, 14, pixelSize, fletchPaint);
    _drawPixel(canvas, 0, 12, pixelSize, fletchPaint);
    _drawPixel(canvas, 1, 13, pixelSize, fletchPaint);

    // Shaft (diagonal)
    _drawPixel(canvas, 2, 12, pixelSize, paint);
    _drawPixel(canvas, 3, 11, pixelSize, paint);
    _drawPixel(canvas, 4, 10, pixelSize, paint);
    _drawPixel(canvas, 5, 9, pixelSize, paint);
    _drawPixel(canvas, 6, 8, pixelSize, paint);
    _drawPixel(canvas, 7, 7, pixelSize, paint);
    _drawPixel(canvas, 8, 6, pixelSize, paint);
    _drawPixel(canvas, 9, 5, pixelSize, paint);
    _drawPixel(canvas, 10, 4, pixelSize, paint);
    _drawPixel(canvas, 11, 3, pixelSize, paint);
    _drawPixel(canvas, 12, 2, pixelSize, paint);

    // Point
    _drawPixel(canvas, 13, 1, pixelSize, paint);
    _drawPixel(canvas, 14, 0, pixelSize, paint);
    _drawPixel(canvas, 14, 2, pixelSize, dimPaint);
    _drawPixel(canvas, 15, 1, pixelSize, dimPaint);
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
