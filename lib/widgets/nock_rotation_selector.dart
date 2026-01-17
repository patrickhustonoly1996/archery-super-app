import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shows a rear-view arrow graphic for selecting nock rotation
/// Positions are clock-based: '12' (top), '4' (right-lower), '8' (left-lower)
class NockRotationSelector extends StatelessWidget {
  final String? selectedPosition;
  final ValueChanged<String?> onSelected;
  final double size;

  const NockRotationSelector({
    super.key,
    this.selectedPosition,
    required this.onSelected,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArrowRearViewPainter(selectedPosition),
        child: Stack(
          children: [
            // 12 o'clock position (top)
            _buildPositionButton('12', 0),
            // 4 o'clock position (right-lower)
            _buildPositionButton('4', 120),
            // 8 o'clock position (left-lower)
            _buildPositionButton('8', 240),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionButton(String position, double angleDegrees) {
    final isSelected = selectedPosition == position;
    final angleRadians = (angleDegrees - 90) * math.pi / 180;
    final radius = size * 0.35;
    final x = (size / 2) + radius * math.cos(angleRadians) - 16;
    final y = (size / 2) + radius * math.sin(angleRadians) - 16;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () => onSelected(isSelected ? null : position),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? AppColors.gold : AppColors.surfaceDark,
            border: Border.all(
              color: isSelected ? AppColors.gold : AppColors.surfaceLight,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              position,
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 11,
                color: isSelected ? AppColors.background : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the rear-view of an arrow shaft with fletching
class _ArrowRearViewPainter extends CustomPainter {
  final String? selectedPosition;

  _ArrowRearViewPainter(this.selectedPosition);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final shaftRadius = size.width * 0.08;
    final fletchingLength = size.width * 0.25;
    final fletchingWidth = size.width * 0.015;

    // Draw arrow shaft (circle)
    final shaftPaint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, shaftRadius, shaftPaint);

    final shaftOutline = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, shaftRadius, shaftOutline);

    // Draw three fletchings at 120 degree intervals
    final fletchingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = fletchingWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final angle = (i * 120 - 90) * math.pi / 180; // Start from 12 o'clock
      final clockPosition = ['12', '4', '8'][i];

      // Fletching color: cock feather (12) is different, or highlight selected
      if (selectedPosition == clockPosition) {
        fletchingPaint.color = AppColors.gold;
      } else if (clockPosition == '12') {
        fletchingPaint.color = const Color(0xFFE74C3C); // Red cock feather
      } else {
        fletchingPaint.color = const Color(0xFF3498DB); // Blue hen feathers
      }

      final innerPoint = Offset(
        center.dx + shaftRadius * math.cos(angle),
        center.dy + shaftRadius * math.sin(angle),
      );
      final outerPoint = Offset(
        center.dx + (shaftRadius + fletchingLength) * math.cos(angle),
        center.dy + (shaftRadius + fletchingLength) * math.sin(angle),
      );

      canvas.drawLine(innerPoint, outerPoint, fletchingPaint);
    }

    // Draw nock groove in center
    final nockPaint = Paint()
      ..color = AppColors.textMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final nockLength = shaftRadius * 0.6;
    canvas.drawLine(
      Offset(center.dx - nockLength, center.dy),
      Offset(center.dx + nockLength, center.dy),
      nockPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArrowRearViewPainter oldDelegate) {
    return selectedPosition != oldDelegate.selectedPosition;
  }
}

/// Compact nock rotation selector for use in bottom sheet
class CompactNockRotationSelector extends StatelessWidget {
  final String? selectedPosition;
  final ValueChanged<String?> onSelected;

  const CompactNockRotationSelector({
    super.key,
    this.selectedPosition,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Nock:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildChip('12'),
        const SizedBox(width: AppSpacing.xs),
        _buildChip('4'),
        const SizedBox(width: AppSpacing.xs),
        _buildChip('8'),
        const SizedBox(width: AppSpacing.xs),
        _buildChip(null, label: '—'),
      ],
    );
  }

  Widget _buildChip(String? position, {String? label}) {
    final isSelected = selectedPosition == position;
    return GestureDetector(
      onTap: () => onSelected(position),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.surfaceLight,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label ?? position!,
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 11,
            color: isSelected ? AppColors.gold : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
