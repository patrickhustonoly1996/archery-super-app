import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/breath_hold_award.dart';

/// A flowing, vapor-like badge for breath hold achievements
/// Design: organic, wispy edges with a ethereal quality
class BreathHoldAwardBadge extends StatelessWidget {
  final BreathHoldAwardLevel level;
  final bool isCompact;
  final bool showDetails;

  const BreathHoldAwardBadge({
    super.key,
    required this.level,
    this.isCompact = false,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactBadge();
    }
    return _buildFullBadge();
  }

  Widget _buildCompactBadge() {
    final color = _getAwardColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _VaporIcon(color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            '${level.seconds}s',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBadge() {
    final color = _getAwardColor();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Vapor shield icon
          _VaporShield(color: color, size: 64),
          const SizedBox(height: 12),
          // Seconds display
          Text(
            '${level.seconds}s',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 28,
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          // Title
          Text(
            level.title.toUpperCase(),
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 14,
              color: color,
              letterSpacing: 2,
            ),
          ),
          if (showDetails) ...[
            const SizedBox(height: 8),
            Text(
              level.description,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                color: color.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Color progression based on achievement tier
  Color _getAwardColor() {
    final seconds = level.seconds;
    if (seconds >= 60) {
      // 60+ seconds - transcendent cyan (elite)
      return const Color(0xFF00E5FF);
    } else if (seconds >= 45) {
      // 45-55 seconds - deep violet (mastery)
      return const Color(0xFFAA66FF);
    } else if (seconds >= 35) {
      // 35-40 seconds - gold (achievement)
      return AppColors.gold;
    } else if (seconds >= 25) {
      // 25-30 seconds - teal (progress)
      return const Color(0xFF26A69A);
    } else {
      // 20 seconds - soft blue-gray (beginning)
      return const Color(0xFF78909C);
    }
  }
}

/// Compact vapor/breath icon
class _VaporIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _VaporIcon({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _VaporIconPainter(color: color),
    );
  }
}

class _VaporIconPainter extends CustomPainter {
  final Color color;

  _VaporIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Three wavy vapor lines rising up
    final path1 = Path()
      ..moveTo(w * 0.3, h * 0.9)
      ..quadraticBezierTo(w * 0.15, h * 0.6, w * 0.35, h * 0.3)
      ..quadraticBezierTo(w * 0.4, h * 0.15, w * 0.3, h * 0.05);

    final path2 = Path()
      ..moveTo(w * 0.5, h * 0.85)
      ..quadraticBezierTo(w * 0.65, h * 0.55, w * 0.45, h * 0.25)
      ..quadraticBezierTo(w * 0.4, h * 0.1, w * 0.5, h * 0.0);

    final path3 = Path()
      ..moveTo(w * 0.7, h * 0.9)
      ..quadraticBezierTo(w * 0.85, h * 0.65, w * 0.65, h * 0.35)
      ..quadraticBezierTo(w * 0.6, h * 0.2, w * 0.7, h * 0.08);

    canvas.drawPath(path1, paint..color = color.withValues(alpha: 0.6));
    canvas.drawPath(path2, paint..color = color);
    canvas.drawPath(path3, paint..color = color.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Larger vapor shield icon - flowing trophy/medal shape
class _VaporShield extends StatelessWidget {
  final Color color;
  final double size;

  const _VaporShield({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _VaporShieldPainter(color: color),
    );
  }
}

class _VaporShieldPainter extends CustomPainter {
  final Color color;

  _VaporShieldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, w * 0.45, glowPaint);

    // Main shield shape - organic flowing form
    final shieldPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final shieldPath = Path();
    // Start at top
    shieldPath.moveTo(w * 0.5, h * 0.08);
    // Right side - flowing curve
    shieldPath.cubicTo(
      w * 0.75, h * 0.12,
      w * 0.88, h * 0.3,
      w * 0.85, h * 0.5,
    );
    // Right bottom - organic taper
    shieldPath.cubicTo(
      w * 0.82, h * 0.7,
      w * 0.65, h * 0.85,
      w * 0.5, h * 0.95,
    );
    // Left bottom - mirror
    shieldPath.cubicTo(
      w * 0.35, h * 0.85,
      w * 0.18, h * 0.7,
      w * 0.15, h * 0.5,
    );
    // Left side - flowing curve
    shieldPath.cubicTo(
      w * 0.12, h * 0.3,
      w * 0.25, h * 0.12,
      w * 0.5, h * 0.08,
    );
    shieldPath.close();

    canvas.drawPath(shieldPath, shieldPaint);

    // Border with varying thickness for flowing effect
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(shieldPath, borderPaint);

    // Inner vapor wisps
    final vaporPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Central rising vapor
    final vapor1 = Path()
      ..moveTo(w * 0.5, h * 0.75)
      ..quadraticBezierTo(w * 0.45, h * 0.55, w * 0.5, h * 0.4)
      ..quadraticBezierTo(w * 0.52, h * 0.3, w * 0.48, h * 0.22);
    canvas.drawPath(vapor1, vaporPaint);

    // Left wisp
    final vapor2 = Path()
      ..moveTo(w * 0.35, h * 0.7)
      ..quadraticBezierTo(w * 0.28, h * 0.5, w * 0.38, h * 0.35)
      ..quadraticBezierTo(w * 0.4, h * 0.28, w * 0.35, h * 0.25);
    canvas.drawPath(vapor2, vaporPaint..color = color.withValues(alpha: 0.3));

    // Right wisp
    final vapor3 = Path()
      ..moveTo(w * 0.65, h * 0.7)
      ..quadraticBezierTo(w * 0.72, h * 0.5, w * 0.62, h * 0.35)
      ..quadraticBezierTo(w * 0.6, h * 0.28, w * 0.65, h * 0.25);
    canvas.drawPath(vapor3, vaporPaint..color = color.withValues(alpha: 0.3));

    // Small floating particles/dots for ethereal effect
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.4, h * 0.45), 2, dotPaint);
    canvas.drawCircle(Offset(w * 0.6, h * 0.42), 1.5, dotPaint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.32), 1.5, dotPaint);
    canvas.drawCircle(Offset(w * 0.45, h * 0.28), 1, dotPaint..color = color.withValues(alpha: 0.3));
    canvas.drawCircle(Offset(w * 0.58, h * 0.52), 1, dotPaint..color = color.withValues(alpha: 0.3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Row of earned breath hold awards (compact display)
class BreathHoldAwardRow extends StatelessWidget {
  final List<BreathHoldAwardLevel> earnedLevels;
  final int maxVisible;

  const BreathHoldAwardRow({
    super.key,
    required this.earnedLevels,
    this.maxVisible = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (earnedLevels.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort by seconds descending, show top achievements
    final sorted = List<BreathHoldAwardLevel>.from(earnedLevels)
      ..sort((a, b) => b.seconds.compareTo(a.seconds));
    final visible = sorted.take(maxVisible).toList();
    final remaining = sorted.length - maxVisible;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visible.map((level) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: BreathHoldAwardBadge(level: level, isCompact: true),
            )),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$remaining',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

/// Grid display of all breath hold awards (earned and unearned)
class BreathHoldAwardGrid extends StatelessWidget {
  final Set<int> earnedThresholds;
  final void Function(BreathHoldAwardLevel)? onAwardTap;

  const BreathHoldAwardGrid({
    super.key,
    required this.earnedThresholds,
    this.onAwardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BreathHoldAwardLevel.values.map((level) {
        final isEarned = earnedThresholds.contains(level.seconds);
        return GestureDetector(
          onTap: onAwardTap != null ? () => onAwardTap!(level) : null,
          child: _AwardGridItem(
            level: level,
            isEarned: isEarned,
          ),
        );
      }).toList(),
    );
  }
}

class _AwardGridItem extends StatelessWidget {
  final BreathHoldAwardLevel level;
  final bool isEarned;

  const _AwardGridItem({
    required this.level,
    required this.isEarned,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      width: 56,
      height: 72,
      decoration: BoxDecoration(
        color: isEarned
            ? color.withValues(alpha: 0.15)
            : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEarned ? color.withValues(alpha: 0.5) : AppColors.surfaceLight,
          width: isEarned ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _VaporIcon(
            color: isEarned ? color : AppColors.textMuted.withValues(alpha: 0.3),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            '${level.seconds}s',
            style: TextStyle(
              fontFamily: AppFonts.pixel,
              fontSize: 12,
              color: isEarned ? color : AppColors.textMuted,
              fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    final seconds = level.seconds;
    if (seconds >= 60) return const Color(0xFF00E5FF);
    if (seconds >= 45) return const Color(0xFFAA66FF);
    if (seconds >= 35) return AppColors.gold;
    if (seconds >= 25) return const Color(0xFF26A69A);
    return const Color(0xFF78909C);
  }
}
