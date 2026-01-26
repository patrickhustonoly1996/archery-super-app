import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/skills_provider.dart';
import '../services/chiptune_service.dart';
import '../theme/app_theme.dart';
import 'xp_badge_celebration.dart';

/// Full-screen overlay for level-up celebrations.
/// Shows fireworks animation and plays C64-style chiptune sound.
class LevelUpCelebration extends StatefulWidget {
  final LevelUpEvent event;
  final VoidCallback onComplete;

  const LevelUpCelebration({
    super.key,
    required this.event,
    required this.onComplete,
  });

  /// Show the celebration overlay.
  static Future<void> show(BuildContext context, LevelUpEvent event) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => LevelUpCelebration(
        event: event,
        onComplete: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fireworksController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Scale animation for the level text
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeIn),
    );

    // Fireworks animation
    _fireworksController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _fireworksController.addListener(_updateParticles);

    // Generate initial particles
    _generateParticles();

    // Start animations
    _scaleController.forward();
    _fireworksController.forward();

    // Play celebration sound and wait for it to complete before allowing dismiss
    _playCelebrationSoundAndWait();
  }

  bool _soundComplete = false;
  bool _dismissed = false;
  final ChiptuneService _chiptune = ChiptuneService();

  void _playCelebrationSoundAndWait() async {
    try {
      final newLevel = widget.event.newLevel;

      // Play milestone jingle for milestone levels (10, 25, 50, 75, 92, 99)
      final milestones = [10, 25, 50, 75, 92, 99];
      if (milestones.contains(newLevel)) {
        await _chiptune.playMilestone();
      } else {
        await _chiptune.playLevelUp();
      }
    } catch (e) {
      // Sound is optional, don't crash if it fails
      debugPrint('Could not play level up sound: $e');
    }

    // Sound complete - auto-dismiss after a brief pause
    if (mounted && !_dismissed) {
      setState(() => _soundComplete = true);
      // Give a moment to see the full celebration, then dismiss
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_dismissed) {
          _dismiss();
        }
      });
    }
  }

  /// Dismiss the celebration - stops music if playing
  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _chiptune.stop(); // Stop music immediately
    widget.onComplete();
  }

  void _generateParticles() {
    // Generate multiple bursts of particles
    for (int burst = 0; burst < 3; burst++) {
      final burstDelay = burst * 0.3;
      final centerX = 0.2 + _random.nextDouble() * 0.6;
      final centerY = 0.3 + _random.nextDouble() * 0.3;

      for (int i = 0; i < 20; i++) {
        final angle = _random.nextDouble() * 2 * pi;
        final speed = 0.2 + _random.nextDouble() * 0.4;
        final color = _getRandomGoldColor();

        _particles.add(_Particle(
          x: centerX,
          y: centerY,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 0.1, // Slight upward bias
          color: color,
          size: 3 + _random.nextDouble() * 4,
          delay: burstDelay,
          lifetime: 0.6 + _random.nextDouble() * 0.4,
        ));
      }
    }

    // Add some sparkle particles
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble() * 0.6,
        vx: (_random.nextDouble() - 0.5) * 0.1,
        vy: 0.05 + _random.nextDouble() * 0.1,
        color: AppColors.gold.withValues(alpha: 0.8),
        size: 2 + _random.nextDouble() * 2,
        delay: _random.nextDouble() * 0.5,
        lifetime: 0.5 + _random.nextDouble() * 0.5,
        isSparkle: true,
      ));
    }
  }

  Color _getRandomGoldColor() {
    final colors = [
      AppColors.gold,
      AppColors.gold.withValues(alpha: 0.8),
      const Color(0xFFFFE066), // Lighter gold
      const Color(0xFFFFAA00), // Orange gold
      Colors.white.withValues(alpha: 0.9),
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _updateParticles() {
    setState(() {});
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fireworksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: _dismiss, // Tap anytime to stop music and dismiss
        child: Stack(
          children: [
            // Fireworks particles
            CustomPaint(
              size: size,
              painter: _FireworksPainter(
                particles: _particles,
                progress: _fireworksController.value,
              ),
            ),

            // Level up scroll banner
            Center(
              child: AnimatedBuilder(
                animation: _scaleController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  width: 280,
                  height: 220,
                  child: CustomPaint(
                    painter: _ScrollBannerPainter(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(40, 35, 40, 45),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // "LEVEL UP!" header
                          Text(
                            'LEVEL UP!',
                            style: TextStyle(
                              fontFamily: AppFonts.pixel,
                              fontSize: 24,
                              color: AppColors.gold,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Skill name
                          Text(
                            widget.event.skillName.toUpperCase(),
                            style: TextStyle(
                              fontFamily: AppFonts.pixel,
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Level transition
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LevelBox(level: widget.event.oldLevel, isOld: true),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '→',
                                  style: TextStyle(
                                    fontFamily: AppFonts.pixel,
                                    fontSize: 20,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ),
                              _LevelBox(level: widget.event.newLevel, isOld: false),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Tap to dismiss hint (only show when sound complete)
                          AnimatedOpacity(
                            opacity: _soundComplete ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              'TAP TO CONTINUE',
                              style: TextStyle(
                                fontFamily: AppFonts.pixel,
                                fontSize: 8,
                                color: AppColors.textMuted,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual level number box.
class _LevelBox extends StatelessWidget {
  final int level;
  final bool isOld;

  const _LevelBox({required this.level, required this.isOld});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isOld
            ? AppColors.surfaceDark
            : AppColors.gold.withValues(alpha: 0.2),
        border: Border.all(
          color: isOld ? AppColors.textMuted : AppColors.gold,
          width: isOld ? 1 : 2,
        ),
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 18,
            color: isOld ? AppColors.textMuted : AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Scroll banner painter with curly rolled ends.
class _ScrollBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Scroll colors
    final parchmentColor = const Color(0xFF1A1510); // Dark parchment
    final parchmentLight = const Color(0xFF2A2520); // Slightly lighter
    final rollColor = const Color(0xFF0F0A08); // Darker roll shadow
    final goldBorder = AppColors.gold;

    final paint = Paint()..style = PaintingStyle.fill;

    // Roll thickness
    const rollH = 22.0;
    const rollCurve = 12.0;

    // =========== TOP ROLL ===========
    // Roll shadow/depth (darker part behind)
    paint.color = rollColor;
    final topRollShadow = Path()
      ..moveTo(rollCurve, rollH + 4)
      ..quadraticBezierTo(0, rollH + 4, 0, rollH / 2 + 4)
      ..quadraticBezierTo(0, 4, rollCurve, 4)
      ..lineTo(w - rollCurve, 4)
      ..quadraticBezierTo(w, 4, w, rollH / 2 + 4)
      ..quadraticBezierTo(w, rollH + 4, w - rollCurve, rollH + 4)
      ..close();
    canvas.drawPath(topRollShadow, paint);

    // Top roll main body
    paint.color = parchmentLight;
    final topRoll = Path()
      ..moveTo(rollCurve, rollH)
      ..quadraticBezierTo(0, rollH, 0, rollH / 2)
      ..quadraticBezierTo(0, 0, rollCurve, 0)
      ..lineTo(w - rollCurve, 0)
      ..quadraticBezierTo(w, 0, w, rollH / 2)
      ..quadraticBezierTo(w, rollH, w - rollCurve, rollH)
      ..close();
    canvas.drawPath(topRoll, paint);

    // Top roll curl detail (left)
    paint.color = rollColor;
    canvas.drawOval(
      Rect.fromLTWH(-4, rollH / 2 - 6, 16, 12),
      paint,
    );
    paint.color = parchmentLight;
    canvas.drawOval(
      Rect.fromLTWH(-2, rollH / 2 - 4, 12, 8),
      paint,
    );

    // Top roll curl detail (right)
    paint.color = rollColor;
    canvas.drawOval(
      Rect.fromLTWH(w - 12, rollH / 2 - 6, 16, 12),
      paint,
    );
    paint.color = parchmentLight;
    canvas.drawOval(
      Rect.fromLTWH(w - 10, rollH / 2 - 4, 12, 8),
      paint,
    );

    // =========== MAIN PARCHMENT BODY ===========
    paint.color = parchmentColor;
    final body = Path()
      ..moveTo(8, rollH)
      ..lineTo(w - 8, rollH)
      ..lineTo(w - 8, h - rollH)
      ..lineTo(8, h - rollH)
      ..close();
    canvas.drawPath(body, paint);

    // =========== BOTTOM ROLL ===========
    // Roll shadow/depth
    paint.color = rollColor;
    final bottomRollShadow = Path()
      ..moveTo(rollCurve, h - rollH - 4)
      ..quadraticBezierTo(0, h - rollH - 4, 0, h - rollH / 2 - 4)
      ..quadraticBezierTo(0, h - 4, rollCurve, h - 4)
      ..lineTo(w - rollCurve, h - 4)
      ..quadraticBezierTo(w, h - 4, w, h - rollH / 2 - 4)
      ..quadraticBezierTo(w, h - rollH - 4, w - rollCurve, h - rollH - 4)
      ..close();
    canvas.drawPath(bottomRollShadow, paint);

    // Bottom roll main body
    paint.color = parchmentLight;
    final bottomRoll = Path()
      ..moveTo(rollCurve, h - rollH)
      ..quadraticBezierTo(0, h - rollH, 0, h - rollH / 2)
      ..quadraticBezierTo(0, h, rollCurve, h)
      ..lineTo(w - rollCurve, h)
      ..quadraticBezierTo(w, h, w, h - rollH / 2)
      ..quadraticBezierTo(w, h - rollH, w - rollCurve, h - rollH)
      ..close();
    canvas.drawPath(bottomRoll, paint);

    // Bottom roll curl detail (left)
    paint.color = rollColor;
    canvas.drawOval(
      Rect.fromLTWH(-4, h - rollH / 2 - 6, 16, 12),
      paint,
    );
    paint.color = parchmentLight;
    canvas.drawOval(
      Rect.fromLTWH(-2, h - rollH / 2 - 4, 12, 8),
      paint,
    );

    // Bottom roll curl detail (right)
    paint.color = rollColor;
    canvas.drawOval(
      Rect.fromLTWH(w - 12, h - rollH / 2 - 6, 16, 12),
      paint,
    );
    paint.color = parchmentLight;
    canvas.drawOval(
      Rect.fromLTWH(w - 10, h - rollH / 2 - 4, 12, 8),
      paint,
    );

    // =========== GOLD BORDERS ===========
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = goldBorder;

    // Top roll border
    final topBorder = Path()
      ..moveTo(rollCurve, rollH)
      ..quadraticBezierTo(0, rollH, 0, rollH / 2)
      ..quadraticBezierTo(0, 0, rollCurve, 0)
      ..lineTo(w - rollCurve, 0)
      ..quadraticBezierTo(w, 0, w, rollH / 2)
      ..quadraticBezierTo(w, rollH, w - rollCurve, rollH);
    canvas.drawPath(topBorder, borderPaint);

    // Bottom roll border
    final bottomBorder = Path()
      ..moveTo(rollCurve, h - rollH)
      ..quadraticBezierTo(0, h - rollH, 0, h - rollH / 2)
      ..quadraticBezierTo(0, h, rollCurve, h)
      ..lineTo(w - rollCurve, h)
      ..quadraticBezierTo(w, h, w, h - rollH / 2)
      ..quadraticBezierTo(w, h - rollH, w - rollCurve, h - rollH);
    canvas.drawPath(bottomBorder, borderPaint);

    // Side borders
    canvas.drawLine(Offset(8, rollH), Offset(8, h - rollH), borderPaint);
    canvas.drawLine(Offset(w - 8, rollH), Offset(w - 8, h - rollH), borderPaint);

    // Decorative pixel dots on rolls
    _drawRollDots(canvas, w, rollH, h);
  }

  void _drawRollDots(Canvas canvas, double w, double rollH, double h) {
    final dotPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Top roll dots
    for (double x = 30; x < w - 30; x += 40) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, rollH / 2), width: 4, height: 4),
        dotPaint,
      );
    }

    // Bottom roll dots
    for (double x = 30; x < w - 30; x += 40) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, h - rollH / 2), width: 4, height: 4),
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      // Calculate particle age
      final adjustedProgress = progress - particle.delay;
      if (adjustedProgress < 0 || adjustedProgress > particle.lifetime) continue;

      final age = adjustedProgress / particle.lifetime;
      final fade = 1.0 - age;

      // Update position
      final x = (particle.x + particle.vx * adjustedProgress) * size.width;
      final y = (particle.y + particle.vy * adjustedProgress + 0.1 * adjustedProgress * adjustedProgress) * size.height;

      // Skip if off screen
      if (x < 0 || x > size.width || y < 0 || y > size.height) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.color.a * fade)
        ..style = PaintingStyle.fill;

      if (particle.isSparkle) {
        // Draw sparkle as a cross
        final sparkleSize = particle.size * fade;
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: sparkleSize, height: sparkleSize / 3),
          paint,
        );
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: sparkleSize / 3, height: sparkleSize),
          paint,
        );
      } else {
        // Draw regular particle as a square (pixel style)
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

/// Widget that listens for level-up and XP award events and shows celebrations.
/// Wrap your app or main content with this widget to enable celebration displays.
class CelebrationListener extends StatefulWidget {
  final Widget child;

  const CelebrationListener({super.key, required this.child});

  @override
  State<CelebrationListener> createState() => _CelebrationListenerState();
}

class _CelebrationListenerState extends State<CelebrationListener> {
  bool _isShowingCelebration = false;

  @override
  void initState() {
    super.initState();
    // Check for pending celebrations after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForPendingCelebrations();
    });
  }

  void _checkForPendingCelebrations() {
    if (!mounted || _isShowingCelebration) return;

    final skillsProvider = context.read<SkillsProvider>();

    // Check for level-ups first (higher priority)
    if (skillsProvider.hasPendingLevelUp) {
      _showNextLevelUp(skillsProvider);
      return;
    }

    // Then check for XP awards
    if (skillsProvider.hasPendingXpAward) {
      _showNextXpAward(skillsProvider);
      return;
    }
  }

  Future<void> _showNextLevelUp(SkillsProvider skillsProvider) async {
    final event = skillsProvider.consumeNextLevelUp();
    if (event == null || !mounted) return;

    _isShowingCelebration = true;

    try {
      await LevelUpCelebration.show(context, event);
    } finally {
      _isShowingCelebration = false;
      // Check for more pending celebrations
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkForPendingCelebrations();
        });
      }
    }
  }

  Future<void> _showNextXpAward(SkillsProvider skillsProvider) async {
    final event = skillsProvider.consumeNextXpAward();
    if (event == null || !mounted) return;

    _isShowingCelebration = true;

    try {
      await XpBadgeCelebration.show(context, event);
    } finally {
      _isShowingCelebration = false;
      // Check for more pending celebrations
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkForPendingCelebrations();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to SkillsProvider changes and check for pending celebrations
    return Consumer<SkillsProvider>(
      builder: (context, skillsProvider, child) {
        // Trigger check when provider notifies (e.g., after awarding XP)
        if (!_isShowingCelebration &&
            (skillsProvider.hasPendingLevelUp || skillsProvider.hasPendingXpAward)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkForPendingCelebrations();
          });
        }
        return child!;
      },
      child: widget.child,
    );
  }
}
