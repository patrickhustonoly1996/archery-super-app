import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Achievement type for shield badge design.
enum AchievementType {
  /// Standard XP award
  standard,

  /// 7-day streak
  streak7,

  /// 14-day streak
  streak14,

  /// 30-day streak
  streak30,

  /// Personal Best score
  personalBest,

  /// Competition participation
  competition,

  /// Level up milestone (10, 25, 50, 75, 99)
  milestone,

  /// Excellent form bonus
  excellentForm,

  /// Full session plotted
  fullPlot,
}

/// Data for an XP award celebration.
class XpAwardEvent {
  final String skillName;
  final int xpAmount;
  final String reason;
  final AchievementType achievementType;

  const XpAwardEvent({
    required this.skillName,
    required this.xpAmount,
    required this.reason,
    this.achievementType = AchievementType.standard,
  });
}

/// Full-screen overlay for XP award celebrations.
/// Shows a shield badge with fireworks, then zooms to user profile icon.
class XpBadgeCelebration extends StatefulWidget {
  final XpAwardEvent event;
  final VoidCallback onComplete;
  final Offset? targetPosition; // Position of user profile icon to zoom to

  const XpBadgeCelebration({
    super.key,
    required this.event,
    required this.onComplete,
    this.targetPosition,
  });

  /// Show the celebration overlay.
  static Future<void> show(
    BuildContext context,
    XpAwardEvent event, {
    Offset? targetPosition,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => XpBadgeCelebration(
        event: event,
        targetPosition: targetPosition ?? const Offset(28, 60), // Default top-left
        onComplete: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<XpBadgeCelebration> createState() => _XpBadgeCelebrationState();
}

class _XpBadgeCelebrationState extends State<XpBadgeCelebration>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _fireworksController;
  late AnimationController _exitController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _exitScaleAnimation;
  late Animation<Offset> _exitPositionAnimation;
  late Animation<double> _exitFadeAnimation;

  final List<_Particle> _particles = [];
  final Random _random = Random();

  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    // Entrance animation - badge pops in
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.elasticOut),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeIn),
    );

    // Fireworks animation
    _fireworksController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fireworksController.addListener(() => setState(() {}));

    // Exit animation - zoom to user icon
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _exitScaleAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInBack),
    );
    _exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    // Generate particles
    _generateParticles();

    // Start entrance animation
    _entranceController.forward();
    _fireworksController.forward();

    // Start exit after delay
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _startExitAnimation();
      }
    });
  }

  void _startExitAnimation() {
    setState(() => _isExiting = true);

    // Calculate exit position animation
    final screenSize = MediaQuery.of(context).size;
    final startPosition = Offset(screenSize.width / 2, screenSize.height / 2);
    final endPosition = widget.targetPosition ?? const Offset(28, 60);

    _exitPositionAnimation = Tween<Offset>(
      begin: startPosition,
      end: endPosition,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeInOut));

    _exitController.forward().then((_) {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  void _generateParticles() {
    // Generate burst particles around center
    for (int burst = 0; burst < 2; burst++) {
      final burstDelay = burst * 0.2;

      for (int i = 0; i < 15; i++) {
        final angle = _random.nextDouble() * 2 * pi;
        final speed = 0.15 + _random.nextDouble() * 0.25;
        final color = _getRandomGoldColor();

        _particles.add(_Particle(
          x: 0.5,
          y: 0.4,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 0.05,
          color: color,
          size: 3 + _random.nextDouble() * 4,
          delay: burstDelay,
          lifetime: 0.5 + _random.nextDouble() * 0.3,
        ));
      }
    }

    // Add sparkles
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: 0.3 + _random.nextDouble() * 0.4,
        y: 0.25 + _random.nextDouble() * 0.3,
        vx: (_random.nextDouble() - 0.5) * 0.08,
        vy: 0.03 + _random.nextDouble() * 0.06,
        color: AppColors.gold.withValues(alpha: 0.8),
        size: 2 + _random.nextDouble() * 2,
        delay: _random.nextDouble() * 0.4,
        lifetime: 0.4 + _random.nextDouble() * 0.4,
        isSparkle: true,
      ));
    }
  }

  Color _getRandomGoldColor() {
    final colors = [
      AppColors.gold,
      AppColors.gold.withValues(alpha: 0.8),
      const Color(0xFFFFE066),
      const Color(0xFFFFAA00),
      Colors.white.withValues(alpha: 0.9),
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _fireworksController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: _isExiting ? null : _startExitAnimation,
        child: Stack(
          children: [
            // Fireworks particles (only during entrance)
            if (!_isExiting)
              CustomPaint(
                size: size,
                painter: _FireworksPainter(
                  particles: _particles,
                  progress: _fireworksController.value,
                ),
              ),

            // Badge
            _isExiting
                ? AnimatedBuilder(
                    animation: _exitController,
                    builder: (context, child) {
                      return Positioned(
                        left: _exitPositionAnimation.value.dx - 40,
                        top: _exitPositionAnimation.value.dy - 40,
                        child: Transform.scale(
                          scale: _exitScaleAnimation.value,
                          child: Opacity(
                            opacity: _exitFadeAnimation.value,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _buildBadge(),
                  )
                : Center(
                    child: AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Opacity(
                            opacity: _fadeInAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: _buildBadge(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    final achievementType = widget.event.achievementType;
    final shieldInfo = _getShieldInfo(achievementType);

    return Container(
      width: 180,
      height: 220,
      child: CustomPaint(
        painter: _ShieldPainter(
          achievementType: achievementType,
          accentColor: shieldInfo.accentColor,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 45),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Achievement badge icon/emblem at top
              if (shieldInfo.emblem != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: shieldInfo.accentColor.withValues(alpha: 0.2),
                    border: Border.all(
                      color: shieldInfo.accentColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      shieldInfo.emblem!,
                      style: TextStyle(
                        fontFamily: AppFonts.pixel,
                        fontSize: 16,
                        color: shieldInfo.accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // XP amount
              Text(
                '+${widget.event.xpAmount}',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 28,
                  color: shieldInfo.accentColor,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
              Text(
                'XP',
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 14,
                  color: shieldInfo.accentColor.withValues(alpha: 0.8),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              // Achievement title
              Text(
                shieldInfo.title,
                style: TextStyle(
                  fontFamily: AppFonts.pixel,
                  fontSize: 11,
                  color: shieldInfo.accentColor,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Reason
              Text(
                widget.event.reason,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _ShieldInfo _getShieldInfo(AchievementType type) {
    switch (type) {
      case AchievementType.streak7:
        return _ShieldInfo(
          title: '7 DAY STREAK',
          emblem: '7',
          accentColor: const Color(0xFFFF6B35), // Orange flame
        );
      case AchievementType.streak14:
        return _ShieldInfo(
          title: '14 DAY STREAK',
          emblem: '14',
          accentColor: const Color(0xFFFF3366), // Hot pink
        );
      case AchievementType.streak30:
        return _ShieldInfo(
          title: '30 DAY STREAK',
          emblem: '30',
          accentColor: const Color(0xFF9933FF), // Purple
        );
      case AchievementType.personalBest:
        return _ShieldInfo(
          title: 'PERSONAL BEST!',
          emblem: 'PB',
          accentColor: const Color(0xFF00FF88), // Bright green
        );
      case AchievementType.competition:
        return _ShieldInfo(
          title: 'COMPETITION',
          emblem: '★',
          accentColor: const Color(0xFF00BFFF), // Bright cyan
        );
      case AchievementType.milestone:
        return _ShieldInfo(
          title: 'MILESTONE',
          emblem: '◆',
          accentColor: const Color(0xFFFFD700), // Gold
        );
      case AchievementType.excellentForm:
        return _ShieldInfo(
          title: 'EXCELLENT FORM',
          emblem: '✓',
          accentColor: const Color(0xFF00FF88), // Green
        );
      case AchievementType.fullPlot:
        return _ShieldInfo(
          title: 'FULL SESSION',
          emblem: '▣',
          accentColor: const Color(0xFF00BFFF), // Cyan
        );
      case AchievementType.standard:
      default:
        return _ShieldInfo(
          title: widget.event.skillName.toUpperCase(),
          emblem: null,
          accentColor: AppColors.gold,
        );
    }
  }
}

class _ShieldInfo {
  final String title;
  final String? emblem;
  final Color accentColor;

  const _ShieldInfo({
    required this.title,
    this.emblem,
    required this.accentColor,
  });
}

/// Pixel art shield painter.
class _ShieldPainter extends CustomPainter {
  final AchievementType achievementType;
  final Color accentColor;

  _ShieldPainter({
    required this.achievementType,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Shield background (dark)
    final bgPath = _createShieldPath(size);
    paint.color = AppColors.backgroundDark;
    canvas.drawPath(bgPath, paint);

    // Decorative elements based on achievement type
    _drawDecorations(canvas, size);

    // Shield border (accent color)
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = accentColor;
    canvas.drawPath(bgPath, borderPaint);

    // Inner border highlight
    final innerPath = _createShieldPath(
      Size(size.width - 12, size.height - 12),
      offset: const Offset(6, 6),
    );
    borderPaint
      ..strokeWidth = 1
      ..color = accentColor.withValues(alpha: 0.4);
    canvas.drawPath(innerPath, borderPaint);

    // Corner rivets (pixel style)
    _drawRivet(canvas, Offset(size.width * 0.15, size.height * 0.1), accentColor);
    _drawRivet(canvas, Offset(size.width * 0.85, size.height * 0.1), accentColor);
    _drawRivet(canvas, Offset(size.width * 0.1, size.height * 0.35), accentColor);
    _drawRivet(canvas, Offset(size.width * 0.9, size.height * 0.35), accentColor);
  }

  void _drawDecorations(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    switch (achievementType) {
      case AchievementType.streak7:
      case AchievementType.streak14:
      case AchievementType.streak30:
        // Flame pattern at bottom
        _drawFlamePattern(canvas, size, paint);
        break;
      case AchievementType.personalBest:
        // Star burst pattern
        _drawStarPattern(canvas, size, paint);
        break;
      case AchievementType.competition:
        // Trophy pattern
        _drawDiamondPattern(canvas, size, paint);
        break;
      case AchievementType.milestone:
        // Crown pattern at top
        _drawCrownPattern(canvas, size, paint);
        break;
      default:
        // Standard subtle pattern
        _drawSubtlePattern(canvas, size, paint);
        break;
    }
  }

  void _drawFlamePattern(Canvas canvas, Size size, Paint paint) {
    paint.color = accentColor.withValues(alpha: 0.15);
    final w = size.width;
    final h = size.height;

    // Flame shapes at bottom
    for (int i = 0; i < 5; i++) {
      final x = w * (0.2 + i * 0.15);
      final baseY = h * 0.85;
      final flameH = h * (0.1 + (i % 2) * 0.05);

      final path = Path()
        ..moveTo(x - 8, baseY)
        ..lineTo(x, baseY - flameH)
        ..lineTo(x + 8, baseY);
      canvas.drawPath(path, paint);
    }
  }

  void _drawStarPattern(Canvas canvas, Size size, Paint paint) {
    paint.color = accentColor.withValues(alpha: 0.1);
    final w = size.width;
    final h = size.height;

    // Radiating lines from center
    final centerX = w / 2;
    final centerY = h * 0.45;

    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final endX = centerX + cos(angle) * w * 0.35;
      final endY = centerY + sin(angle) * h * 0.25;

      canvas.drawLine(
        Offset(centerX, centerY),
        Offset(endX, endY),
        paint..strokeWidth = 2,
      );
    }
  }

  void _drawDiamondPattern(Canvas canvas, Size size, Paint paint) {
    paint.color = accentColor.withValues(alpha: 0.1);
    final w = size.width;
    final h = size.height;

    // Small diamonds in corners
    final positions = [
      Offset(w * 0.25, h * 0.25),
      Offset(w * 0.75, h * 0.25),
      Offset(w * 0.5, h * 0.7),
    ];

    for (final pos in positions) {
      final path = Path()
        ..moveTo(pos.dx, pos.dy - 8)
        ..lineTo(pos.dx + 6, pos.dy)
        ..lineTo(pos.dx, pos.dy + 8)
        ..lineTo(pos.dx - 6, pos.dy)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawCrownPattern(Canvas canvas, Size size, Paint paint) {
    paint.color = accentColor.withValues(alpha: 0.15);
    final w = size.width;
    final h = size.height;

    // Crown shape at top
    final path = Path()
      ..moveTo(w * 0.3, h * 0.15)
      ..lineTo(w * 0.35, h * 0.08)
      ..lineTo(w * 0.4, h * 0.12)
      ..lineTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.6, h * 0.12)
      ..lineTo(w * 0.65, h * 0.08)
      ..lineTo(w * 0.7, h * 0.15);

    canvas.drawPath(path, paint..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  void _drawSubtlePattern(Canvas canvas, Size size, Paint paint) {
    paint.color = accentColor.withValues(alpha: 0.08);

    // Subtle horizontal lines
    for (int i = 1; i < 4; i++) {
      final y = size.height * (0.2 + i * 0.15);
      canvas.drawLine(
        Offset(size.width * 0.15, y),
        Offset(size.width * 0.85, y),
        paint..strokeWidth = 1,
      );
    }
  }

  Path _createShieldPath(Size size, {Offset offset = Offset.zero}) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final ox = offset.dx;
    final oy = offset.dy;

    // Shield shape - pointed bottom
    path.moveTo(ox + w * 0.1, oy + h * 0.05);
    path.lineTo(ox + w * 0.9, oy + h * 0.05);
    path.lineTo(ox + w * 0.95, oy + h * 0.1);
    path.lineTo(ox + w * 0.95, oy + h * 0.5);
    path.lineTo(ox + w * 0.5, oy + h * 0.9);
    path.lineTo(ox + w * 0.05, oy + h * 0.5);
    path.lineTo(ox + w * 0.05, oy + h * 0.1);
    path.close();

    return path;
  }

  void _drawRivet(Canvas canvas, Offset position, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(center: position, width: 6, height: 6),
      paint,
    );
    paint.color = color.withValues(alpha: 0.5);
    canvas.drawRect(
      Rect.fromCenter(center: position + const Offset(1, 1), width: 3, height: 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter oldDelegate) =>
      achievementType != oldDelegate.achievementType ||
      accentColor != oldDelegate.accentColor;
}

/// Particle data for fireworks.
class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double delay;
  double lifetime;
  bool isSparkle;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.delay,
    required this.lifetime,
    this.isSparkle = false,
  });
}

/// Custom painter for fireworks particles.
class _FireworksPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _FireworksPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final adjustedProgress = progress - particle.delay;
      if (adjustedProgress < 0 || adjustedProgress > particle.lifetime) continue;

      final age = adjustedProgress / particle.lifetime;
      final fade = 1.0 - age;

      final x = (particle.x + particle.vx * adjustedProgress) * size.width;
      final y = (particle.y + particle.vy * adjustedProgress +
              0.08 * adjustedProgress * adjustedProgress) *
          size.height;

      if (x < 0 || x > size.width || y < 0 || y > size.height) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.color.a * fade)
        ..style = PaintingStyle.fill;

      if (particle.isSparkle) {
        final sparkleSize = particle.size * fade;
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(x, y), width: sparkleSize, height: sparkleSize / 3),
          paint,
        );
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset(x, y), width: sparkleSize / 3, height: sparkleSize),
          paint,
        );
      } else {
        final pixelSize = particle.size * fade;
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: pixelSize, height: pixelSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
