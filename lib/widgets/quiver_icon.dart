import 'package:flutter/material.dart';

/// Custom quiver icon with arrows for archery equipment
class QuiverIcon extends StatelessWidget {
  final double size;
  final Color color;

  const QuiverIcon({
    super.key,
    this.size = 24,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _QuiverIconPainter(color: color),
    );
  }
}

class _QuiverIconPainter extends CustomPainter {
  final Color color;

  _QuiverIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.08
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Quiver body (slightly diagonal rectangle)
    final quiverPath = Path();

    // Draw quiver at slight angle
    quiverPath.moveTo(size.width * 0.25, size.height * 0.35);
    quiverPath.lineTo(size.width * 0.35, size.height * 0.95);
    quiverPath.lineTo(size.width * 0.65, size.height * 0.90);
    quiverPath.lineTo(size.width * 0.55, size.height * 0.30);
    quiverPath.close();

    canvas.drawPath(quiverPath, paint);

    // Fill quiver lightly
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(quiverPath, fillPaint);

    // Arrow shafts coming out of quiver (3 arrows at different angles)
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.06
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Arrow 1 (leftmost, angled left)
    canvas.drawLine(
      Offset(size.width * 0.30, size.height * 0.35),
      Offset(size.width * 0.15, size.height * 0.08),
      arrowPaint,
    );

    // Arrow 2 (middle, straight up)
    canvas.drawLine(
      Offset(size.width * 0.42, size.height * 0.32),
      Offset(size.width * 0.40, size.height * 0.05),
      arrowPaint,
    );

    // Arrow 3 (rightmost, angled right)
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.30),
      Offset(size.width * 0.65, size.height * 0.05),
      arrowPaint,
    );

    // Arrow fletching (small V shapes at top of each arrow)
    final fletchPaint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.04
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Fletch 1
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.08),
      Offset(size.width * 0.10, size.height * 0.15),
      fletchPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.08),
      Offset(size.width * 0.20, size.height * 0.13),
      fletchPaint,
    );

    // Fletch 2
    canvas.drawLine(
      Offset(size.width * 0.40, size.height * 0.05),
      Offset(size.width * 0.35, size.height * 0.12),
      fletchPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.40, size.height * 0.05),
      Offset(size.width * 0.45, size.height * 0.12),
      fletchPaint,
    );

    // Fletch 3
    canvas.drawLine(
      Offset(size.width * 0.65, size.height * 0.05),
      Offset(size.width * 0.60, size.height * 0.13),
      fletchPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.65, size.height * 0.05),
      Offset(size.width * 0.72, size.height * 0.10),
      fletchPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
