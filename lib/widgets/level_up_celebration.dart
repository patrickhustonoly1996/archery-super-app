import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/skills_provider.dart';
import '../theme/app_theme.dart';

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
  AudioPlayer? _audioPlayer;

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

    // Play celebration sound
    _playCelebrationSound();

    // Auto-dismiss after animation
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  void _playCelebrationSound() async {
    try {
      _audioPlayer = AudioPlayer();
      // Use a simple beep sound - in production, use a proper C64-style jingle
      await _audioPlayer?.play(
        AssetSource('sounds/level_up.mp3'),
        volume: 0.5,
      );
    } catch (e) {
      // Sound is optional, don't crash if it fails
      debugPrint('Could not play level up sound: $e');
    }
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
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: widget.onComplete,
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

            // Level up text
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark.withValues(alpha: 0.95),
                    border: Border.all(color: AppColors.gold, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "LEVEL UP!" header
                      Text(
                        'LEVEL UP!',
                        style: TextStyle(
                          fontFamily: AppFonts.pixel,
                          fontSize: 28,
                          color: AppColors.gold,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(
                              color: AppColors.gold.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Skill name
                      Text(
                        widget.event.skillName.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppFonts.pixel,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Level transition
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LevelBox(level: widget.event.oldLevel, isOld: true),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.arrow_forward,
                              color: AppColors.gold,
                              size: 24,
                            ),
                          ),
                          _LevelBox(level: widget.event.newLevel, isOld: false),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tap to dismiss hint
                      Text(
                        'TAP TO CONTINUE',
                        style: TextStyle(
                          fontFamily: AppFonts.pixel,
                          fontSize: 10,
                          color: AppColors.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
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
      width: 56,
      height: 56,
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
            fontSize: 24,
            color: isOld ? AppColors.textMuted : AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
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

/// Widget that listens for level-up events and shows celebrations.
class LevelUpListener extends StatefulWidget {
  final Widget child;

  const LevelUpListener({super.key, required this.child});

  @override
  State<LevelUpListener> createState() => _LevelUpListenerState();
}

class _LevelUpListenerState extends State<LevelUpListener> {
  @override
  Widget build(BuildContext context) {
    // This widget wraps the app and checks for pending level-ups
    // The actual checking is done in the parent widget that has access to SkillsProvider
    return widget.child;
  }
}
