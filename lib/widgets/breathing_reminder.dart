import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Rotating breathing reminder that displays different tips
/// More prominent during active sessions, with special post-hold messages
class BreathingReminder extends StatefulWidget {
  /// Whether the session is currently active
  final bool isActive;

  /// Whether we're in a post-hold recovery phase (shows specific recovery tips)
  final bool isPostHold;

  /// How often to rotate tips (in seconds)
  final int rotationIntervalSeconds;

  const BreathingReminder({
    super.key,
    this.isActive = false,
    this.isPostHold = false,
    this.rotationIntervalSeconds = 8,
  });

  @override
  State<BreathingReminder> createState() => _BreathingReminderState();
}

class _BreathingReminderState extends State<BreathingReminder>
    with SingleTickerProviderStateMixin {
  Timer? _rotationTimer;
  int _currentTipIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final _random = Random();

  // Core breathing principles
  static const List<String> _generalTips = [
    'Nasal breathing only',
    'Light, Slow, Deep',
    'Breathe into your stomach',
    'Inflate your diaphragm',
    'Expand the side ribs',
    'Never lift the chest up and down',
    'Breathe sideways into your ribs',
    'Fill your belly first',
    'Soft, quiet breaths',
    'Relax your shoulders',
    'Ribs expand outward, not upward',
  ];

  // Post-hold recovery specific tips
  static const List<String> _recoveryTips = [
    'Breathe steadily, slow the breath',
    'Gentle recovery, no gasping',
    'Let the breath settle naturally',
    'Soft nasal breaths only',
    'Expand sideways, not upwards',
    'Keep the breath light and quiet',
  ];

  List<String> get _currentTips => widget.isPostHold ? _recoveryTips : _generalTips;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _startRotation();
  }

  @override
  void didUpdateWidget(BreathingReminder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPostHold != oldWidget.isPostHold) {
      // Reset to first tip when switching between general and recovery tips
      _rotateTip();
    }
    if (widget.isActive != oldWidget.isActive) {
      _startRotation();
    }
  }

  void _startRotation() {
    _rotationTimer?.cancel();
    if (widget.isActive) {
      _rotationTimer = Timer.periodic(
        Duration(seconds: widget.rotationIntervalSeconds),
        (_) => _rotateTip(),
      );
    }
  }

  void _rotateTip() {
    _fadeController.reverse().then((_) {
      if (mounted) {
        setState(() {
          // Pick a random different tip
          int newIndex;
          do {
            newIndex = _random.nextInt(_currentTips.length);
          } while (newIndex == _currentTipIndex && _currentTips.length > 1);
          _currentTipIndex = newIndex;
        });
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure index is valid for current tip list
    final safeIndex = _currentTipIndex % _currentTips.length;
    final currentTip = _currentTips[safeIndex];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: widget.isActive ? AppSpacing.md : AppSpacing.sm,
        vertical: widget.isActive ? AppSpacing.sm : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: widget.isActive
            ? AppColors.gold.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: widget.isActive
            ? Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isActive) ...[
              Icon(
                widget.isPostHold ? Icons.self_improvement : Icons.air,
                color: AppColors.gold,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Text(
                currentTip,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.isActive ? AppColors.gold : AppColors.textMuted,
                      fontWeight: widget.isActive ? FontWeight.w500 : FontWeight.normal,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
