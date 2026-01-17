import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The current phase of breathing
enum BreathPhase {
  inhale,
  exhale,
  hold,
  idle,
}

/// Visual indicator for breathing - expands on inhale, contracts on exhale
/// Shows a gold ring that grows/shrinks smoothly
class BreathingVisualizer extends StatefulWidget {
  /// Progress from 0.0 to 1.0 within current phase
  final double progress;

  /// Current breathing phase
  final BreathPhase phase;

  /// Text to display in center (e.g., "Breathe In", "Hold", seconds remaining)
  final String? centerText;

  /// Secondary text below the main text
  final String? secondaryText;

  /// Size of the visualizer
  final double size;

  const BreathingVisualizer({
    super.key,
    required this.progress,
    required this.phase,
    this.centerText,
    this.secondaryText,
    this.size = 280,
  });

  @override
  State<BreathingVisualizer> createState() => _BreathingVisualizerState();
}

class _BreathingVisualizerState extends State<BreathingVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  BreathPhase? _lastPhase;

  // Durations for each phase (matching the breathing screens)
  static const int _inhaleDuration = 4;
  static const int _exhaleDuration = 6;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _lastPhase = widget.phase;
    _startPhaseAnimation();
  }

  @override
  void didUpdateWidget(BreathingVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only restart animation when phase actually changes
    if (widget.phase != _lastPhase) {
      _lastPhase = widget.phase;
      _startPhaseAnimation();
    }
  }

  void _startPhaseAnimation() {
    switch (widget.phase) {
      case BreathPhase.inhale:
        _controller.duration = Duration(seconds: _inhaleDuration);
        _controller.forward(from: 0);
        break;
      case BreathPhase.exhale:
        _controller.duration = Duration(seconds: _exhaleDuration);
        _controller.forward(from: 0);
        break;
      case BreathPhase.hold:
      case BreathPhase.idle:
        _controller.stop();
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getScaleFactor() {
    switch (widget.phase) {
      case BreathPhase.inhale:
        // Grow from 0.4 to 1.0
        return 0.4 + (0.6 * _controller.value);
      case BreathPhase.exhale:
        // Shrink from 1.0 to 0.4
        return 1.0 - (0.6 * _controller.value);
      case BreathPhase.hold:
        return 0.4;
      case BreathPhase.idle:
        return 0.6;
    }
  }

  @override
  Widget build(BuildContext context) {
    // On web, use larger size for better visibility
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = kIsWeb || screenWidth > 600;
    final effectiveSize = isLargeScreen ? widget.size * 1.3 : widget.size;
    final textScale = isLargeScreen ? 1.3 : 1.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final circleSize = effectiveSize * _getScaleFactor();
        return SizedBox(
          width: effectiveSize,
          height: effectiveSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer guide ring (max size indicator)
              Container(
                width: effectiveSize,
                height: effectiveSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surfaceLight,
                    width: 2,
                  ),
                ),
              ),

              // Inner guide ring (min size indicator)
              Container(
                width: effectiveSize * 0.4,
                height: effectiveSize * 0.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surfaceLight,
                    width: 1,
                  ),
                ),
              ),

              // Main breathing circle - smooth animation
              Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getPhaseColor().withValues(alpha: 0.15),
                  border: Border.all(
                    color: _getPhaseColor(),
                    width: isLargeScreen ? 4 : 3,
                  ),
                ),
              ),

              // Center text - larger on web
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.centerText != null)
                    Text(
                      widget.centerText!,
                      style: TextStyle(
                        fontSize: 24 * textScale,
                        fontWeight: FontWeight.w500,
                        color: _getPhaseColor(),
                      ),
                    ),
                  if (widget.secondaryText != null) ...[
                    SizedBox(height: 4 * textScale),
                    Text(
                      widget.secondaryText!,
                      style: TextStyle(
                        fontSize: 14 * textScale,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getPhaseColor() {
    switch (widget.phase) {
      case BreathPhase.inhale:
        return AppColors.gold;
      case BreathPhase.exhale:
        return AppColors.gold;
      case BreathPhase.hold:
        return const Color(0xFF66B2FF); // Muted blue for hold
      case BreathPhase.idle:
        return AppColors.textSecondary;
    }
  }
}

/// Timer display for breath training sessions
class BreathTimer extends StatelessWidget {
  final int seconds;
  final String? label;
  final bool isHighlighted;

  const BreathTimer({
    super.key,
    required this.seconds,
    this.label,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final timeStr = minutes > 0
        ? '$minutes:${secs.toString().padLeft(2, '0')}'
        : '$secs';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Text(
            label!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        Text(
          timeStr,
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 48,
            color: isHighlighted ? AppColors.gold : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
