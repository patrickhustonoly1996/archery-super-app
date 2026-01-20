import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 16x16 pixel art archer with bow
/// Scales with text scale factor when scaleWithText is true
class PixelArcherIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool scaleWithText;

  const PixelArcherIcon({
    super.key,
    required this.size,
    this.color,
    this.scaleWithText = true,
  });

  @override
  Widget build(BuildContext context) {
    final scaledSize = scaleWithText
        ? size * MediaQuery.textScalerOf(context).scale(1.0)
        : size;
    return CustomPaint(
      size: Size(scaledSize, scaledSize),
      painter: _PixelArcherPainter(color: color ?? AppColors.gold),
    );
  }
}

class _PixelArcherPainter extends CustomPainter {
  final Color color;

  _PixelArcherPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = size.width / 16;
    final paint = Paint()..color = color;
    final dimPaint = Paint()..color = color.withValues(alpha: 0.5);

    // Head (circle-ish)
    _px(canvas, 7, 1, p, paint);
    _px(canvas, 8, 1, p, paint);
    _px(canvas, 6, 2, p, paint);
    _px(canvas, 7, 2, p, paint);
    _px(canvas, 8, 2, p, paint);
    _px(canvas, 9, 2, p, paint);
    _px(canvas, 7, 3, p, paint);
    _px(canvas, 8, 3, p, paint);

    // Neck
    _px(canvas, 7, 4, p, dimPaint);
    _px(canvas, 8, 4, p, dimPaint);

    // Torso
    _px(canvas, 6, 5, p, paint);
    _px(canvas, 7, 5, p, paint);
    _px(canvas, 8, 5, p, paint);
    _px(canvas, 9, 5, p, paint);
    _px(canvas, 6, 6, p, paint);
    _px(canvas, 7, 6, p, paint);
    _px(canvas, 8, 6, p, paint);
    _px(canvas, 9, 6, p, paint);
    _px(canvas, 6, 7, p, paint);
    _px(canvas, 7, 7, p, paint);
    _px(canvas, 8, 7, p, paint);
    _px(canvas, 9, 7, p, paint);
    _px(canvas, 7, 8, p, paint);
    _px(canvas, 8, 8, p, paint);

    // Left arm (drawing arm, pulling string back)
    _px(canvas, 10, 5, p, paint);
    _px(canvas, 11, 5, p, paint);
    _px(canvas, 12, 5, p, dimPaint);
    _px(canvas, 13, 5, p, dimPaint); // Hand at anchor

    // Right arm (bow arm, extended forward)
    _px(canvas, 5, 5, p, paint);
    _px(canvas, 4, 5, p, paint);
    _px(canvas, 3, 5, p, paint);
    _px(canvas, 2, 5, p, paint);

    // Bow (vertical, on left side)
    _px(canvas, 1, 2, p, dimPaint); // Top limb tip
    _px(canvas, 1, 3, p, paint);
    _px(canvas, 1, 4, p, paint);
    _px(canvas, 1, 5, p, paint);   // Grip
    _px(canvas, 1, 6, p, paint);
    _px(canvas, 1, 7, p, paint);
    _px(canvas, 1, 8, p, dimPaint); // Bottom limb tip

    // String (slight curve to anchor point)
    _px(canvas, 2, 3, p, dimPaint);
    _px(canvas, 3, 4, p, dimPaint);
    _px(canvas, 2, 7, p, dimPaint);
    _px(canvas, 3, 6, p, dimPaint);

    // Arrow (from bow to hand)
    _px(canvas, 2, 5, p, paint);
    _px(canvas, 3, 5, p, paint);
    _px(canvas, 4, 5, p, paint);
    _px(canvas, 5, 5, p, paint);
    _px(canvas, 6, 5, p, paint);
    _px(canvas, 7, 5, p, paint);
    _px(canvas, 8, 5, p, paint);
    _px(canvas, 9, 5, p, paint);
    _px(canvas, 10, 5, p, paint);
    _px(canvas, 11, 5, p, paint);
    _px(canvas, 12, 5, p, paint);
    _px(canvas, 13, 5, p, paint);

    // Arrow point
    _px(canvas, 0, 5, p, paint);

    // Legs
    _px(canvas, 6, 9, p, paint);
    _px(canvas, 9, 9, p, paint);
    _px(canvas, 6, 10, p, paint);
    _px(canvas, 9, 10, p, paint);
    _px(canvas, 6, 11, p, paint);
    _px(canvas, 9, 11, p, paint);
    _px(canvas, 5, 12, p, paint);
    _px(canvas, 6, 12, p, paint);
    _px(canvas, 9, 12, p, paint);
    _px(canvas, 10, 12, p, paint);

    // Feet
    _px(canvas, 4, 13, p, dimPaint);
    _px(canvas, 5, 13, p, paint);
    _px(canvas, 6, 13, p, paint);
    _px(canvas, 9, 13, p, paint);
    _px(canvas, 10, 13, p, paint);
    _px(canvas, 11, 13, p, dimPaint);
  }

  void _px(Canvas canvas, int x, int y, double p, Paint paint) {
    canvas.drawRect(Rect.fromLTWH(x * p, y * p, p, p), paint);
  }

  @override
  bool shouldRepaint(covariant _PixelArcherPainter oldDelegate) =>
      color != oldDelegate.color;
}
