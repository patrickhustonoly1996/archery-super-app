import 'package:flutter/material.dart';

/// Custom bow icon for archery equipment
class BowIcon extends StatelessWidget {
  final double size;
  final Color color;

  const BowIcon({
    super.key,
    this.size = 24,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BowIconPainter(color: color),
    );
  }
}

class _BowIconPainter extends CustomPainter {
  final Color color;

  _BowIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.08
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw the bow limb (curved arc)
    final bowPath = Path();

    // Recurve bow shape - curved limbs with recurve tips
    bowPath.moveTo(size.width * 0.15, size.height * 0.1);

    // Top recurve tip (curves back)
    bowPath.quadraticBezierTo(
      size.width * 0.05, size.height * 0.15,
      size.width * 0.12, size.height * 0.2,
    );

    // Top limb to grip
    bowPath.quadraticBezierTo(
      size.width * 0.35, size.height * 0.35,
      centerX * 0.85, centerY,
    );

    // Bottom limb from grip
    bowPath.quadraticBezierTo(
      size.width * 0.35, size.height * 0.65,
      size.width * 0.12, size.height * 0.8,
    );

    // Bottom recurve tip (curves back)
    bowPath.quadraticBezierTo(
      size.width * 0.05, size.height * 0.85,
      size.width * 0.15, size.height * 0.9,
    );

    canvas.drawPath(bowPath, paint);

    // Draw the bowstring
    final stringPaint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.04
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.1),
      Offset(size.width * 0.15, size.height * 0.9),
      stringPaint,
    );

    // Draw arrow rest indicator (small horizontal line)
    final restPaint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.06
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX * 0.7, centerY),
      Offset(size.width * 0.5, centerY),
      restPaint,
    );

    // Draw arrow (simplified)
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.04
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Arrow shaft
    canvas.drawLine(
      Offset(size.width * 0.15, centerY),
      Offset(size.width * 0.85, centerY),
      arrowPaint,
    );

    // Arrow point
    final pointPath = Path();
    pointPath.moveTo(size.width * 0.85, centerY);
    pointPath.lineTo(size.width * 0.95, centerY);
    canvas.drawPath(pointPath, arrowPaint..strokeWidth = size.width * 0.06);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
