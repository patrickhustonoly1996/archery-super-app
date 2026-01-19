import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Conditional imports
import 'delayed_camera_native.dart' if (dart.library.js_interop) 'delayed_camera_web.dart'
    as platform_camera;

/// A custom reference line drawn by the user
class ReferenceLine {
  final Offset startNormalized; // 0.0-1.0 relative to view size
  final Offset endNormalized;
  final Color color;

  ReferenceLine({
    required this.startNormalized,
    required this.endNormalized,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'sx': startNormalized.dx,
        'sy': startNormalized.dy,
        'ex': endNormalized.dx,
        'ey': endNormalized.dy,
        'color': color.value,
      };

  factory ReferenceLine.fromJson(Map<String, dynamic> json) => ReferenceLine(
        startNormalized: Offset(json['sx'] as double, json['sy'] as double),
        endNormalized: Offset(json['ex'] as double, json['ey'] as double),
        color: Color(json['color'] as int),
      );
}

/// Highly visible colors for reference lines
class LineColors {
  static const List<Color> available = [
    Color(0xFFFF0000), // Red
    Color(0xFF00FF00), // Lime green
    Color(0xFF00FFFF), // Cyan
    Color(0xFFFF00FF), // Magenta
    Color(0xFFFFFF00), // Yellow
    Color(0xFFFF6600), // Orange
    Color(0xFF00FF99), // Spring green
    Color(0xFFFFFFFF), // White
  ];
}

class DelayedCameraScreen extends StatefulWidget {
  const DelayedCameraScreen({super.key});

  @override
  State<DelayedCameraScreen> createState() => _DelayedCameraScreenState();
}

class _DelayedCameraScreenState extends State<DelayedCameraScreen> {
  @override
  Widget build(BuildContext context) {
    // Use platform-specific implementation
    return platform_camera.buildDelayedCameraScreen(context);
  }
}

/// Timestamped frame for the delay buffer (shared between implementations)
class TimestampedFrame {
  final Uint8List bytes;
  final int timestamp;

  TimestampedFrame({
    required this.bytes,
    required this.timestamp,
  });
}

/// Grid painter (shared)
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    final thirdWidth = size.width / 3;
    final thirdHeight = size.height / 3;

    canvas.drawLine(
      Offset(thirdWidth, 0),
      Offset(thirdWidth, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(thirdWidth * 2, 0),
      Offset(thirdWidth * 2, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(0, thirdHeight),
      Offset(size.width, thirdHeight),
      paint,
    );
    canvas.drawLine(
      Offset(0, thirdHeight * 2),
      Offset(size.width, thirdHeight * 2),
      paint,
    );

    // Center crosshairs
    final centerPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.6)
      ..strokeWidth = 1;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const crossSize = 20.0;

    canvas.drawLine(
      Offset(cx - crossSize, cy),
      Offset(cx + crossSize, cy),
      centerPaint,
    );
    canvas.drawLine(
      Offset(cx, cy - crossSize),
      Offset(cx, cy + crossSize),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Reference lines painter (shared)
class ReferenceLinesPainter extends CustomPainter {
  final List<ReferenceLine> lines;
  final Offset? currentStart;
  final Offset? currentEnd;
  final Color currentColor;
  final Size viewSize;

  ReferenceLinesPainter({
    required this.lines,
    required this.currentStart,
    required this.currentEnd,
    required this.currentColor,
    required this.viewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw saved lines
    for (final line in lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(
          line.startNormalized.dx * size.width,
          line.startNormalized.dy * size.height,
        ),
        Offset(
          line.endNormalized.dx * size.width,
          line.endNormalized.dy * size.height,
        ),
        paint,
      );
    }

    // Draw current line being drawn
    if (currentStart != null && currentEnd != null) {
      final paint = Paint()
        ..color = currentColor.withValues(alpha: 0.7)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(
          currentStart!.dx * size.width,
          currentStart!.dy * size.height,
        ),
        Offset(
          currentEnd!.dx * size.width,
          currentEnd!.dy * size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ReferenceLinesPainter oldDelegate) => true;
}

/// Preferences keys (shared)
class DelayedCameraPrefs {
  static const String keyDelay = 'delayed_camera_delay';
  static const String keyLines = 'delayed_camera_lines';
  static const String keyColor = 'delayed_camera_color';
}
