import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 16x16 pixel art head and shoulders profile icon
class PixelProfileIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const PixelProfileIcon({
    super.key,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PixelProfilePainter(color: color ?? AppColors.gold),
    );
  }
}

class _PixelProfilePainter extends CustomPainter {
  final Color color;

  _PixelProfilePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = size.width / 16;
    final paint = Paint()..color = color;
    final dimPaint = Paint()..color = color.withValues(alpha: 0.5);

    // Head (rounded shape, centered)
    _px(canvas, 6, 1, p, paint);
    _px(canvas, 7, 1, p, paint);
    _px(canvas, 8, 1, p, paint);
    _px(canvas, 9, 1, p, paint);

    _px(canvas, 5, 2, p, paint);
    _px(canvas, 6, 2, p, paint);
    _px(canvas, 7, 2, p, paint);
    _px(canvas, 8, 2, p, paint);
    _px(canvas, 9, 2, p, paint);
    _px(canvas, 10, 2, p, paint);

    _px(canvas, 5, 3, p, paint);
    _px(canvas, 6, 3, p, paint);
    _px(canvas, 7, 3, p, paint);
    _px(canvas, 8, 3, p, paint);
    _px(canvas, 9, 3, p, paint);
    _px(canvas, 10, 3, p, paint);

    _px(canvas, 5, 4, p, paint);
    _px(canvas, 6, 4, p, paint);
    _px(canvas, 7, 4, p, paint);
    _px(canvas, 8, 4, p, paint);
    _px(canvas, 9, 4, p, paint);
    _px(canvas, 10, 4, p, paint);

    _px(canvas, 6, 5, p, paint);
    _px(canvas, 7, 5, p, paint);
    _px(canvas, 8, 5, p, paint);
    _px(canvas, 9, 5, p, paint);

    // Neck
    _px(canvas, 7, 6, p, dimPaint);
    _px(canvas, 8, 6, p, dimPaint);

    // Shoulders (curved outward)
    _px(canvas, 6, 7, p, paint);
    _px(canvas, 7, 7, p, paint);
    _px(canvas, 8, 7, p, paint);
    _px(canvas, 9, 7, p, paint);

    _px(canvas, 4, 8, p, paint);
    _px(canvas, 5, 8, p, paint);
    _px(canvas, 6, 8, p, paint);
    _px(canvas, 7, 8, p, paint);
    _px(canvas, 8, 8, p, paint);
    _px(canvas, 9, 8, p, paint);
    _px(canvas, 10, 8, p, paint);
    _px(canvas, 11, 8, p, paint);

    _px(canvas, 3, 9, p, paint);
    _px(canvas, 4, 9, p, paint);
    _px(canvas, 5, 9, p, paint);
    _px(canvas, 6, 9, p, paint);
    _px(canvas, 7, 9, p, paint);
    _px(canvas, 8, 9, p, paint);
    _px(canvas, 9, 9, p, paint);
    _px(canvas, 10, 9, p, paint);
    _px(canvas, 11, 9, p, paint);
    _px(canvas, 12, 9, p, paint);

    // Upper chest/torso
    _px(canvas, 2, 10, p, dimPaint);
    _px(canvas, 3, 10, p, paint);
    _px(canvas, 4, 10, p, paint);
    _px(canvas, 5, 10, p, paint);
    _px(canvas, 6, 10, p, paint);
    _px(canvas, 7, 10, p, paint);
    _px(canvas, 8, 10, p, paint);
    _px(canvas, 9, 10, p, paint);
    _px(canvas, 10, 10, p, paint);
    _px(canvas, 11, 10, p, paint);
    _px(canvas, 12, 10, p, paint);
    _px(canvas, 13, 10, p, dimPaint);

    _px(canvas, 1, 11, p, dimPaint);
    _px(canvas, 2, 11, p, paint);
    _px(canvas, 3, 11, p, paint);
    _px(canvas, 4, 11, p, paint);
    _px(canvas, 5, 11, p, paint);
    _px(canvas, 6, 11, p, paint);
    _px(canvas, 7, 11, p, paint);
    _px(canvas, 8, 11, p, paint);
    _px(canvas, 9, 11, p, paint);
    _px(canvas, 10, 11, p, paint);
    _px(canvas, 11, 11, p, paint);
    _px(canvas, 12, 11, p, paint);
    _px(canvas, 13, 11, p, paint);
    _px(canvas, 14, 11, p, dimPaint);

    // Bottom fade out
    _px(canvas, 1, 12, p, dimPaint);
    _px(canvas, 2, 12, p, dimPaint);
    _px(canvas, 3, 12, p, dimPaint);
    _px(canvas, 4, 12, p, dimPaint);
    _px(canvas, 5, 12, p, dimPaint);
    _px(canvas, 6, 12, p, dimPaint);
    _px(canvas, 7, 12, p, dimPaint);
    _px(canvas, 8, 12, p, dimPaint);
    _px(canvas, 9, 12, p, dimPaint);
    _px(canvas, 10, 12, p, dimPaint);
    _px(canvas, 11, 12, p, dimPaint);
    _px(canvas, 12, 12, p, dimPaint);
    _px(canvas, 13, 12, p, dimPaint);
    _px(canvas, 14, 12, p, dimPaint);
  }

  void _px(Canvas canvas, int x, int y, double p, Paint paint) {
    canvas.drawRect(Rect.fromLTWH(x * p, y * p, p, p), paint);
  }

  @override
  bool shouldRepaint(covariant _PixelProfilePainter oldDelegate) =>
      color != oldDelegate.color;
}
