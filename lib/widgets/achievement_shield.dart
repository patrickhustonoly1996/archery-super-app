import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Display mode for achievement shields
enum ShieldStyle {
  /// Standard shield for regular achievements
  standard,

  /// Elaborate shield with extra decorations for competition PBs
  elaborate,
}

/// Small achievement shield badge for display in skills panel.
/// Two styles: standard (regular achievements) and elaborate (competition PBs).
class AchievementShield extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color accentColor;
  final ShieldStyle style;
  final double size;
  final VoidCallback? onTap;

  const AchievementShield({
    super.key,
    required this.title,
    this.subtitle,
    this.accentColor = AppColors.gold,
    this.style = ShieldStyle.standard,
    this.size = 60,
    this.onTap,
  });

  /// Create a shield for streak achievements
  factory AchievementShield.streak({
    required int days,
    double size = 60,
    VoidCallback? onTap,
  }) {
    final color = days >= 30
        ? const Color(0xFF9933FF) // Purple for 30 day
        : days >= 14
            ? const Color(0xFFFF3366) // Hot pink for 14 day
            : const Color(0xFFFF6B35); // Orange for 7 day
    return AchievementShield(
      title: '$days',
      subtitle: 'DAY',
      accentColor: color,
      style: ShieldStyle.standard,
      size: size,
      onTap: onTap,
    );
  }

  /// Create a shield for personal best (practice)
  factory AchievementShield.personalBest({
    required String roundName,
    required int score,
    double size = 60,
    VoidCallback? onTap,
  }) {
    return AchievementShield(
      title: 'PB',
      subtitle: _shortenRoundName(roundName),
      accentColor: const Color(0xFF00FF88), // Bright green
      style: ShieldStyle.standard,
      size: size,
      onTap: onTap,
    );
  }

  /// Create a shield for competition personal best (elaborate style)
  factory AchievementShield.competitionPb({
    required String roundName,
    required int score,
    double size = 60,
    VoidCallback? onTap,
  }) {
    return AchievementShield(
      title: 'PB',
      subtitle: _shortenRoundName(roundName),
      accentColor: const Color(0xFF00BFFF), // Bright cyan
      style: ShieldStyle.elaborate,
      size: size,
      onTap: onTap,
    );
  }

  /// Create a shield for milestone achievement
  factory AchievementShield.milestone({
    required int level,
    double size = 60,
    VoidCallback? onTap,
  }) {
    return AchievementShield(
      title: '$level',
      subtitle: 'LVL',
      accentColor: AppColors.gold,
      style: ShieldStyle.standard,
      size: size,
      onTap: onTap,
    );
  }

  /// Create a shield for excellent form
  factory AchievementShield.excellentForm({
    double size = 60,
    VoidCallback? onTap,
  }) {
    return AchievementShield(
      title: '\u2713', // Checkmark
      subtitle: 'FORM',
      accentColor: const Color(0xFF00FF88), // Green
      style: ShieldStyle.standard,
      size: size,
      onTap: onTap,
    );
  }

  static String _shortenRoundName(String name) {
    // Shorten common round names
    final lower = name.toLowerCase();
    if (lower.contains('portsmouth')) return 'POR';
    if (lower.contains('worcester')) return 'WOR';
    if (lower.contains('vegas')) return 'VEG';
    if (lower.contains('wa 720')) return '720';
    if (lower.contains('wa720')) return '720';
    if (lower.contains('wa 1440')) return '1440';
    if (lower.contains('wa1440')) return '1440';
    if (lower.contains('national')) return 'NAT';
    if (lower.contains('york')) return 'YRK';
    if (lower.contains('hereford')) return 'HER';
    if (lower.contains('bristol')) return 'BRI';
    if (lower.contains('st george')) return 'STG';
    if (lower.contains('albion')) return 'ALB';
    if (lower.contains('windsor')) return 'WIN';
    if (lower.contains('western')) return 'WST';
    if (lower.contains('short western')) return 'SWS';
    if (lower.contains('american')) return 'AMR';
    // Default: take first 3 chars
    if (name.length >= 3) {
      return name.substring(0, 3).toUpperCase();
    }
    return name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        size: Size(size, size * 1.2),
        painter: _AchievementShieldPainter(
          title: title,
          subtitle: subtitle,
          accentColor: accentColor,
          style: style,
        ),
      ),
    );
  }
}

/// Pixel art shield painter for achievements.
class _AchievementShieldPainter extends CustomPainter {
  final String title;
  final String? subtitle;
  final Color accentColor;
  final ShieldStyle style;

  _AchievementShieldPainter({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // Shield path
    final shieldPath = _createShieldPath(w, h);

    // Background
    paint.color = AppColors.backgroundDark;
    canvas.drawPath(shieldPath, paint);

    // Elaborate style gets extra decorations
    if (style == ShieldStyle.elaborate) {
      _drawElaborateDecorations(canvas, size, paint);
    }

    // Border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style == ShieldStyle.elaborate ? 2.5 : 2
      ..color = accentColor;
    canvas.drawPath(shieldPath, borderPaint);

    // Inner border for elaborate
    if (style == ShieldStyle.elaborate) {
      final innerPath = _createShieldPath(w - 6, h - 6, offset: const Offset(3, 3));
      borderPaint
        ..strokeWidth = 1
        ..color = accentColor.withValues(alpha: 0.5);
      canvas.drawPath(innerPath, borderPaint);
    }

    // Rivets
    _drawRivet(canvas, Offset(w * 0.15, h * 0.12), accentColor);
    _drawRivet(canvas, Offset(w * 0.85, h * 0.12), accentColor);

    // Text
    _drawText(canvas, size);
  }

  void _drawElaborateDecorations(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    // Crown/star pattern at top
    paint.color = accentColor.withValues(alpha: 0.2);

    // Top crown points
    final crownPath = Path()
      ..moveTo(w * 0.25, h * 0.15)
      ..lineTo(w * 0.3, h * 0.08)
      ..lineTo(w * 0.35, h * 0.12)
      ..lineTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.65, h * 0.12)
      ..lineTo(w * 0.7, h * 0.08)
      ..lineTo(w * 0.75, h * 0.15);
    canvas.drawPath(crownPath, paint..style = PaintingStyle.stroke..strokeWidth = 1.5);
    paint.style = PaintingStyle.fill;

    // Diamond accents
    final diamondPositions = [
      Offset(w * 0.2, h * 0.35),
      Offset(w * 0.8, h * 0.35),
      Offset(w * 0.5, h * 0.75),
    ];

    for (final pos in diamondPositions) {
      final size = 4.0;
      final diamond = Path()
        ..moveTo(pos.dx, pos.dy - size)
        ..lineTo(pos.dx + size, pos.dy)
        ..lineTo(pos.dx, pos.dy + size)
        ..lineTo(pos.dx - size, pos.dy)
        ..close();
      canvas.drawPath(diamond, paint);
    }

    // Extra corner rivets for elaborate
    _drawRivet(canvas, Offset(w * 0.1, h * 0.35), accentColor.withValues(alpha: 0.5), small: true);
    _drawRivet(canvas, Offset(w * 0.9, h * 0.35), accentColor.withValues(alpha: 0.5), small: true);
  }

  void _drawText(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Title
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          fontFamily: AppFonts.pixel,
          fontSize: w * 0.28,
          color: accentColor,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(
      canvas,
      Offset(
        (w - titlePainter.width) / 2,
        h * 0.28 - titlePainter.height / 2,
      ),
    );

    // Subtitle
    if (subtitle != null) {
      final subtitlePainter = TextPainter(
        text: TextSpan(
          text: subtitle,
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: w * 0.15,
            color: accentColor.withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      subtitlePainter.layout();
      subtitlePainter.paint(
        canvas,
        Offset(
          (w - subtitlePainter.width) / 2,
          h * 0.52 - subtitlePainter.height / 2,
        ),
      );
    }
  }

  Path _createShieldPath(double w, double h, {Offset offset = Offset.zero}) {
    final ox = offset.dx;
    final oy = offset.dy;

    return Path()
      ..moveTo(ox + w * 0.1, oy + h * 0.05)
      ..lineTo(ox + w * 0.9, oy + h * 0.05)
      ..lineTo(ox + w * 0.95, oy + h * 0.1)
      ..lineTo(ox + w * 0.95, oy + h * 0.5)
      ..lineTo(ox + w * 0.5, oy + h * 0.9)
      ..lineTo(ox + w * 0.05, oy + h * 0.5)
      ..lineTo(ox + w * 0.05, oy + h * 0.1)
      ..close();
  }

  void _drawRivet(Canvas canvas, Offset position, Color color, {bool small = false}) {
    final rivSize = small ? 3.0 : 4.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(center: position, width: rivSize, height: rivSize),
      paint,
    );
    paint.color = color.withValues(alpha: 0.5);
    canvas.drawRect(
      Rect.fromCenter(
        center: position + const Offset(0.5, 0.5),
        width: rivSize / 2,
        height: rivSize / 2,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AchievementShieldPainter oldDelegate) =>
      title != oldDelegate.title ||
      subtitle != oldDelegate.subtitle ||
      accentColor != oldDelegate.accentColor ||
      style != oldDelegate.style;
}

/// Row of achievement shields with optional "more" indicator.
class AchievementShieldRow extends StatelessWidget {
  final List<Widget> shields;
  final int maxVisible;
  final VoidCallback? onSeeAll;

  const AchievementShieldRow({
    super.key,
    required this.shields,
    this.maxVisible = 5,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCount = shields.length > maxVisible ? maxVisible : shields.length;
    final hasMore = shields.length > maxVisible;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ...shields.take(visibleCount),
        if (hasMore) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Text(
                '+${shields.length - maxVisible}',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 12,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
