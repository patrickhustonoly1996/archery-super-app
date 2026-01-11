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
class BreathingVisualizer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Calculate circle size based on phase and progress
    // Inhale: grows from 0.4 to 1.0
    // Exhale: shrinks from 1.0 to 0.4
    // Hold: stays at 0.4 (after exhale)
    // Idle: stays at 0.6
    double scaleFactor;
    switch (phase) {
      case BreathPhase.inhale:
        scaleFactor = 0.4 + (0.6 * progress);
        break;
      case BreathPhase.exhale:
        scaleFactor = 1.0 - (0.6 * progress);
        break;
      case BreathPhase.hold:
        scaleFactor = 0.4;
        break;
      case BreathPhase.idle:
        scaleFactor = 0.6;
        break;
    }

    final circleSize = size * scaleFactor;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer guide ring (max size indicator)
          Container(
            width: size,
            height: size,
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
            width: size * 0.4,
            height: size * 0.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.surfaceLight,
                width: 1,
              ),
            ),
          ),

          // Main breathing circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getPhaseColor().withOpacity(0.15),
              border: Border.all(
                color: _getPhaseColor(),
                width: 3,
              ),
            ),
          ),

          // Center text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (centerText != null)
                Text(
                  centerText!,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: _getPhaseColor(),
                  ),
                ),
              if (secondaryText != null) ...[
                const SizedBox(height: 4),
                Text(
                  secondaryText!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getPhaseColor() {
    switch (phase) {
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
