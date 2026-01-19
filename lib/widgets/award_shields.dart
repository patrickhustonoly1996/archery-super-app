import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Award shield badges for different skill categories
/// Each has a distinct visual style suited to its domain
/// All designed to look like collectible pin badges

// =============================================================================
// BREATH AWARD BADGE - Flowing, organic, lung-inspired curves
// =============================================================================

class BreathAwardBadge extends StatelessWidget {
  final AwardTier tier;
  final double size;
  final int? streakDays;

  const BreathAwardBadge({
    super.key,
    required this.tier,
    this.size = 64,
    this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.15,
      child: CustomPaint(
        painter: _BreathShieldPainter(tier: tier),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: size * 0.1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.air,
                  color: tier.textColor,
                  size: size * 0.35,
                ),
                if (streakDays != null)
                  Text(
                    '$streakDays',
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: size * 0.2,
                      color: tier.textColor,
                      height: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathShieldPainter extends CustomPainter {
  final AwardTier tier;

  _BreathShieldPainter({required this.tier});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Flowing, organic shield shape inspired by lungs/breath
    final path = Path();
    path.moveTo(w * 0.5, 0);
    // Right side - flowing curve
    path.cubicTo(w * 0.85, h * 0.05, w, h * 0.2, w, h * 0.35);
    path.cubicTo(w, h * 0.55, w * 0.85, h * 0.7, w * 0.5, h);
    // Left side - flowing curve
    path.cubicTo(w * 0.15, h * 0.7, 0, h * 0.55, 0, h * 0.35);
    path.cubicTo(0, h * 0.2, w * 0.15, h * 0.05, w * 0.5, 0);
    path.close();

    // Fill
    final fillPaint = Paint()
      ..color = tier.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Border - metallic edge effect
    final borderPaint = Paint()
      ..color = _getBorderColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, borderPaint);

    // Inner highlight for pin badge effect
    final highlightPath = Path();
    highlightPath.moveTo(w * 0.5, h * 0.08);
    highlightPath.cubicTo(w * 0.75, h * 0.12, w * 0.88, h * 0.25, w * 0.88, h * 0.35);
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(highlightPath, highlightPaint);
  }

  Color _getBorderColor() {
    // Metallic border colours
    if (tier == AwardTier.gold) return const Color(0xFFB8860B);
    if (tier == AwardTier.purple) return const Color(0xFF6A1B9A);
    if (tier == AwardTier.white) return const Color(0xFFBDBDBD);
    return Colors.white.withValues(alpha: 0.5);
  }

  @override
  bool shouldRepaint(covariant _BreathShieldPainter oldDelegate) {
    return oldDelegate.tier != tier;
  }
}

// =============================================================================
// BOW TRAINING AWARD BADGE - Chunky, masculine, strong angles
// =============================================================================

class BowTrainingAwardBadge extends StatelessWidget {
  final AwardTier tier;
  final double size;
  final int? streakDays;

  const BowTrainingAwardBadge({
    super.key,
    required this.tier,
    this.size = 64,
    this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.2,
      child: CustomPaint(
        painter: _BowTrainingShieldPainter(tier: tier),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: size * 0.08),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Muscular arm / strength icon
                Icon(
                  Icons.fitness_center,
                  color: tier.textColor,
                  size: size * 0.35,
                ),
                if (streakDays != null)
                  Text(
                    '$streakDays',
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: size * 0.22,
                      color: tier.textColor,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BowTrainingShieldPainter extends CustomPainter {
  final AwardTier tier;

  _BowTrainingShieldPainter({required this.tier});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Chunky, masculine shield - broad shoulders, heavy base
    final path = Path();
    // Flat top with strong shoulders
    path.moveTo(w * 0.15, 0);
    path.lineTo(w * 0.85, 0);
    // Right shoulder - chunky angle
    path.lineTo(w, h * 0.12);
    path.lineTo(w, h * 0.5);
    // Right side taper to point
    path.lineTo(w * 0.5, h);
    // Left side taper from point
    path.lineTo(0, h * 0.5);
    path.lineTo(0, h * 0.12);
    // Left shoulder
    path.lineTo(w * 0.15, 0);
    path.close();

    // Fill
    final fillPaint = Paint()
      ..color = tier.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Heavy border for masculine feel
    final borderPaint = Paint()
      ..color = _getBorderColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawPath(path, borderPaint);

    // Inner bevel effect - chunky
    final innerPath = Path();
    innerPath.moveTo(w * 0.2, h * 0.08);
    innerPath.lineTo(w * 0.8, h * 0.08);
    innerPath.lineTo(w * 0.92, h * 0.15);
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(innerPath, innerPaint);

    // Rivets for industrial look
    _drawRivet(canvas, Offset(w * 0.2, h * 0.15), w * 0.04);
    _drawRivet(canvas, Offset(w * 0.8, h * 0.15), w * 0.04);
  }

  void _drawRivet(Canvas canvas, Offset center, double radius) {
    final rivetPaint = Paint()
      ..color = _getBorderColor()
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, rivetPaint);
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
      radius * 0.4,
      highlightPaint,
    );
  }

  Color _getBorderColor() {
    if (tier == AwardTier.gold) return const Color(0xFFB8860B);
    if (tier == AwardTier.purple) return const Color(0xFF6A1B9A);
    if (tier == AwardTier.white) return const Color(0xFF9E9E9E);
    if (tier == AwardTier.black) return const Color(0xFF424242);
    return Colors.white.withValues(alpha: 0.6);
  }

  @override
  bool shouldRepaint(covariant _BowTrainingShieldPainter oldDelegate) {
    return oldDelegate.tier != tier;
  }
}

// =============================================================================
// EDUCATION AWARD BADGE - Erudite, refined, scholarly
// =============================================================================

class EducationAwardBadge extends StatelessWidget {
  final AwardTier tier;
  final double size;
  final int? streakDays;

  const EducationAwardBadge({
    super.key,
    required this.tier,
    this.size = 64,
    this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.25,
      child: CustomPaint(
        painter: _EducationShieldPainter(tier: tier),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: size * 0.15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Book / scholarly icon
                Icon(
                  Icons.menu_book,
                  color: tier.textColor,
                  size: size * 0.32,
                ),
                if (streakDays != null)
                  Text(
                    '$streakDays',
                    style: TextStyle(
                      fontFamily: AppFonts.body, // More refined font
                      fontSize: size * 0.18,
                      color: tier.textColor,
                      fontStyle: FontStyle.italic,
                      height: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EducationShieldPainter extends CustomPainter {
  final AwardTier tier;

  _EducationShieldPainter({required this.tier});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Refined, elegant shield - crest style with decorative top
    final path = Path();
    // Decorative curved top (like a university crest)
    path.moveTo(w * 0.5, h * 0.06);
    path.quadraticBezierTo(w * 0.25, 0, w * 0.1, h * 0.08);
    path.quadraticBezierTo(0, h * 0.12, 0, h * 0.2);
    // Left side - elegant taper
    path.lineTo(0, h * 0.6);
    path.quadraticBezierTo(0, h * 0.75, w * 0.2, h * 0.85);
    // Bottom point - refined
    path.quadraticBezierTo(w * 0.35, h * 0.92, w * 0.5, h);
    path.quadraticBezierTo(w * 0.65, h * 0.92, w * 0.8, h * 0.85);
    // Right side
    path.quadraticBezierTo(w, h * 0.75, w, h * 0.6);
    path.lineTo(w, h * 0.2);
    path.quadraticBezierTo(w, h * 0.12, w * 0.9, h * 0.08);
    path.quadraticBezierTo(w * 0.75, 0, w * 0.5, h * 0.06);
    path.close();

    // Fill
    final fillPaint = Paint()
      ..color = tier.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Refined thin border
    final borderPaint = Paint()
      ..color = _getBorderColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);

    // Inner decorative line (scholarly detail)
    final innerPath = Path();
    innerPath.moveTo(w * 0.5, h * 0.14);
    innerPath.quadraticBezierTo(w * 0.3, h * 0.1, w * 0.18, h * 0.15);
    innerPath.quadraticBezierTo(w * 0.1, h * 0.18, w * 0.1, h * 0.25);
    final innerPaint = Paint()
      ..color = _getBorderColor().withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(innerPath, innerPaint);

    // Mirror on right
    final innerPathR = Path();
    innerPathR.moveTo(w * 0.5, h * 0.14);
    innerPathR.quadraticBezierTo(w * 0.7, h * 0.1, w * 0.82, h * 0.15);
    innerPathR.quadraticBezierTo(w * 0.9, h * 0.18, w * 0.9, h * 0.25);
    canvas.drawPath(innerPathR, innerPaint);
  }

  Color _getBorderColor() {
    if (tier == AwardTier.gold) return const Color(0xFFD4AF37); // Scholarly gold
    if (tier == AwardTier.purple) return const Color(0xFF7B1FA2);
    if (tier == AwardTier.white) return const Color(0xFFBDBDBD);
    return Colors.white.withValues(alpha: 0.7);
  }

  @override
  bool shouldRepaint(covariant _EducationShieldPainter oldDelegate) {
    return oldDelegate.tier != tier;
  }
}

// =============================================================================
// ANALYSIS AWARD BADGE - Precise, angular, technical
// =============================================================================

class AnalysisAwardBadge extends StatelessWidget {
  final AwardTier tier;
  final double size;
  final int? streakDays;

  const AnalysisAwardBadge({
    super.key,
    required this.tier,
    this.size = 64,
    this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.15,
      child: CustomPaint(
        painter: _AnalysisShieldPainter(tier: tier),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: size * 0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Precision / analysis icon
                Icon(
                  Icons.analytics,
                  color: tier.textColor,
                  size: size * 0.35,
                ),
                if (streakDays != null)
                  Text(
                    '$streakDays',
                    style: TextStyle(
                      fontFamily: AppFonts.mono, // Technical font
                      fontSize: size * 0.18,
                      color: tier.textColor,
                      letterSpacing: 1,
                      height: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalysisShieldPainter extends CustomPainter {
  final AwardTier tier;

  _AnalysisShieldPainter({required this.tier});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Precise, angular shield - hexagonal influence, sharp edges
    final path = Path();
    // Top edge - angled
    path.moveTo(w * 0.2, 0);
    path.lineTo(w * 0.8, 0);
    // Top right angle
    path.lineTo(w, h * 0.15);
    // Right side - straight precision
    path.lineTo(w, h * 0.55);
    // Bottom right angle
    path.lineTo(w * 0.7, h * 0.8);
    // Bottom point - sharp
    path.lineTo(w * 0.5, h);
    // Bottom left angle
    path.lineTo(w * 0.3, h * 0.8);
    // Left side
    path.lineTo(0, h * 0.55);
    path.lineTo(0, h * 0.15);
    // Top left angle
    path.lineTo(w * 0.2, 0);
    path.close();

    // Fill
    final fillPaint = Paint()
      ..color = tier.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Sharp, precise border
    final borderPaint = Paint()
      ..color = _getBorderColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawPath(path, borderPaint);

    // Technical grid lines for precision feel
    final gridPaint = Paint()
      ..color = tier.textColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Horizontal lines
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(w * 0.15, h * 0.2 * i),
        Offset(w * 0.85, h * 0.2 * i),
        gridPaint,
      );
    }

    // Corner detail marks
    _drawCornerMark(canvas, Offset(w * 0.12, h * 0.1), w * 0.08);
    _drawCornerMark(canvas, Offset(w * 0.88, h * 0.1), w * 0.08);
  }

  void _drawCornerMark(Canvas canvas, Offset pos, double size) {
    final paint = Paint()
      ..color = _getBorderColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(pos, Offset(pos.dx + size, pos.dy), paint);
    canvas.drawLine(pos, Offset(pos.dx, pos.dy + size), paint);
  }

  Color _getBorderColor() {
    if (tier == AwardTier.gold) return const Color(0xFFB8860B);
    if (tier == AwardTier.purple) return const Color(0xFF6A1B9A);
    if (tier == AwardTier.white) return const Color(0xFFBDBDBD);
    if (tier == AwardTier.black) return const Color(0xFF616161);
    return Colors.white.withValues(alpha: 0.7);
  }

  @override
  bool shouldRepaint(covariant _AnalysisShieldPainter oldDelegate) {
    return oldDelegate.tier != tier;
  }
}

// =============================================================================
// CLASSIFICATION AWARD BADGE - Elaborate, fancy, heraldic
// =============================================================================

class ClassificationAwardBadge extends StatelessWidget {
  final AwardTier tier;
  final double size;
  final String? classificationCode;

  const ClassificationAwardBadge({
    super.key,
    required this.tier,
    this.size = 64,
    this.classificationCode,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.1,
      height: size * 1.3,
      child: CustomPaint(
        painter: _ClassificationShieldPainter(tier: tier),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: size * 0.2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (classificationCode != null)
                  Text(
                    classificationCode!,
                    style: TextStyle(
                      fontFamily: AppFonts.pixel,
                      fontSize: size * 0.3,
                      color: tier.textColor,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  )
                else
                  Icon(
                    Icons.workspace_premium,
                    color: tier.textColor,
                    size: size * 0.4,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassificationShieldPainter extends CustomPainter {
  final AwardTier tier;

  _ClassificationShieldPainter({required this.tier});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Elaborate heraldic shield with decorative flourishes
    final path = Path();
    // Decorative top with crown-like points
    path.moveTo(w * 0.5, 0);
    path.lineTo(w * 0.35, h * 0.08);
    path.lineTo(w * 0.25, h * 0.02);
    path.lineTo(w * 0.15, h * 0.1);
    path.quadraticBezierTo(0, h * 0.12, 0, h * 0.22);
    // Left side with decorative indent
    path.lineTo(0, h * 0.4);
    path.quadraticBezierTo(w * 0.05, h * 0.45, 0, h * 0.5);
    path.lineTo(0, h * 0.65);
    // Bottom left curve
    path.quadraticBezierTo(0, h * 0.8, w * 0.25, h * 0.9);
    // Elaborate bottom point
    path.quadraticBezierTo(w * 0.4, h * 0.95, w * 0.5, h);
    path.quadraticBezierTo(w * 0.6, h * 0.95, w * 0.75, h * 0.9);
    // Bottom right curve
    path.quadraticBezierTo(w, h * 0.8, w, h * 0.65);
    // Right side with decorative indent
    path.lineTo(w, h * 0.5);
    path.quadraticBezierTo(w * 0.95, h * 0.45, w, h * 0.4);
    path.lineTo(w, h * 0.22);
    path.quadraticBezierTo(w, h * 0.12, w * 0.85, h * 0.1);
    // Crown-like top right
    path.lineTo(w * 0.75, h * 0.02);
    path.lineTo(w * 0.65, h * 0.08);
    path.lineTo(w * 0.5, 0);
    path.close();

    // Fill with gradient for fancy effect
    final rect = Rect.fromLTWH(0, 0, w, h);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _lighten(tier.color, 0.15),
        tier.color,
        _darken(tier.color, 0.1),
      ],
      stops: const [0.0, 0.4, 1.0],
    );
    final fillPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Ornate border
    final borderPaint = Paint()
      ..color = _getBorderColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, borderPaint);

    // Inner decorative border
    _drawInnerBorder(canvas, w, h);

    // Decorative corner flourishes
    _drawFlourish(canvas, Offset(w * 0.15, h * 0.25), w * 0.1, false);
    _drawFlourish(canvas, Offset(w * 0.85, h * 0.25), w * 0.1, true);
  }

  void _drawInnerBorder(Canvas canvas, double w, double h) {
    final innerPath = Path();
    innerPath.moveTo(w * 0.5, h * 0.12);
    innerPath.quadraticBezierTo(w * 0.25, h * 0.14, w * 0.12, h * 0.25);
    innerPath.lineTo(w * 0.12, h * 0.6);
    innerPath.quadraticBezierTo(w * 0.12, h * 0.72, w * 0.3, h * 0.82);
    innerPath.quadraticBezierTo(w * 0.42, h * 0.88, w * 0.5, h * 0.9);
    innerPath.quadraticBezierTo(w * 0.58, h * 0.88, w * 0.7, h * 0.82);
    innerPath.quadraticBezierTo(w * 0.88, h * 0.72, w * 0.88, h * 0.6);
    innerPath.lineTo(w * 0.88, h * 0.25);
    innerPath.quadraticBezierTo(w * 0.75, h * 0.14, w * 0.5, h * 0.12);

    final innerPaint = Paint()
      ..color = _getBorderColor().withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(innerPath, innerPaint);
  }

  void _drawFlourish(Canvas canvas, Offset pos, double size, bool mirror) {
    final paint = Paint()
      ..color = _getBorderColor().withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final dir = mirror ? -1.0 : 1.0;
    final path = Path();
    path.moveTo(pos.dx, pos.dy);
    path.quadraticBezierTo(
      pos.dx + size * 0.5 * dir,
      pos.dy - size * 0.3,
      pos.dx + size * dir,
      pos.dy,
    );
    canvas.drawPath(path, paint);
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  Color _getBorderColor() {
    if (tier == AwardTier.gold) return const Color(0xFFB8860B);
    if (tier == AwardTier.purple) return const Color(0xFF6A1B9A);
    if (tier == AwardTier.white) return const Color(0xFFBDBDBD);
    if (tier == AwardTier.black) return const Color(0xFF424242);
    if (tier == AwardTier.red) return const Color(0xFFB71C1C);
    if (tier == AwardTier.blue) return const Color(0xFF1565C0);
    return Colors.white.withValues(alpha: 0.7);
  }

  @override
  bool shouldRepaint(covariant _ClassificationShieldPainter oldDelegate) {
    return oldDelegate.tier != tier;
  }
}

// =============================================================================
// AWARD BADGE SHOWCASE - For displaying all tiers
// =============================================================================

/// Displays a row of all tier badges for a category
class AwardBadgeShowcase extends StatelessWidget {
  final String category;
  final double badgeSize;

  const AwardBadgeShowcase({
    super.key,
    required this.category,
    this.badgeSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: AwardTier.values.map((tier) {
        return _buildBadge(tier);
      }).toList(),
    );
  }

  Widget _buildBadge(AwardTier tier) {
    switch (category) {
      case 'breath':
        return BreathAwardBadge(tier: tier, size: badgeSize);
      case 'bowTraining':
        return BowTrainingAwardBadge(tier: tier, size: badgeSize);
      case 'education':
        return EducationAwardBadge(tier: tier, size: badgeSize);
      case 'analysis':
        return AnalysisAwardBadge(tier: tier, size: badgeSize);
      case 'classification':
        return ClassificationAwardBadge(tier: tier, size: badgeSize);
      default:
        return BreathAwardBadge(tier: tier, size: badgeSize);
    }
  }
}
