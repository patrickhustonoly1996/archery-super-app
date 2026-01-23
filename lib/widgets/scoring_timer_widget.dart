import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/scoring_timer_service.dart';
import '../services/beep_service.dart';

/// Compact scoring timer widget with traffic light visual and digital countdown.
/// Tap to start timer. Shows lead-in countdown, then main timer.
/// Visual indicator: Green → Amber (30s) → Red (expired)
class ScoringTimerWidget extends StatefulWidget {
  /// Whether the timer is enabled
  final bool enabled;

  /// Lead-in duration in seconds (10 or 15)
  final int leadInSeconds;

  /// Main timer duration in seconds (90, 120, 180, or 240)
  final int durationSeconds;

  /// Called when timer state changes (for parent to react if needed)
  final ValueChanged<ScoringTimerState>? onStateChanged;

  const ScoringTimerWidget({
    super.key,
    required this.enabled,
    required this.leadInSeconds,
    required this.durationSeconds,
    this.onStateChanged,
  });

  @override
  State<ScoringTimerWidget> createState() => _ScoringTimerWidgetState();
}

class _ScoringTimerWidgetState extends State<ScoringTimerWidget>
    with WidgetsBindingObserver {
  final _timerService = ScoringTimerService();
  final _beepService = BeepService();

  ScoringTimerState _state = ScoringTimerState.idle;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTimer();
  }

  @override
  void didUpdateWidget(ScoringTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leadInSeconds != widget.leadInSeconds ||
        oldWidget.durationSeconds != widget.durationSeconds) {
      _timerService.configure(
        leadInSeconds: widget.leadInSeconds,
        mainDurationSeconds: widget.durationSeconds,
      );
    }
  }

  void _initializeTimer() async {
    await _beepService.initialize();

    _timerService.configure(
      leadInSeconds: widget.leadInSeconds,
      mainDurationSeconds: widget.durationSeconds,
    );

    _timerService.setCallbacks(
      onTick: _onTick,
      onAudio: _onAudio,
      onStateChange: _onStateChange,
    );
  }

  void _onTick(ScoringTimerState state, int secondsRemaining) {
    if (mounted) {
      setState(() {
        _state = state;
        _secondsRemaining = secondsRemaining;
      });
    }
  }

  void _onAudio(TimerAudioEvent event) {
    switch (event) {
      case TimerAudioEvent.leadInStart:
        _beepService.playTripleBeep();
        break;
      case TimerAudioEvent.mainTimerStart:
        _beepService.playSingleBeep();
        break;
      case TimerAudioEvent.tenSecWarning:
        _beepService.playDoubleBeep();
        break;
      case TimerAudioEvent.timerExpired:
        _beepService.playTripleBeep();
        break;
    }
  }

  void _onStateChange() {
    widget.onStateChanged?.call(_timerService.state);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timerService.pause();
    } else if (state == AppLifecycleState.resumed) {
      _timerService.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerService.stop();
    super.dispose();
  }

  void _handleTap() {
    if (_state == ScoringTimerState.idle) {
      _timerService.start();
    } else if (_state == ScoringTimerState.expired) {
      _timerService.reset();
    }
  }

  Color _getIndicatorColor() {
    switch (_state) {
      case ScoringTimerState.idle:
        return AppColors.surfaceLight;
      case ScoringTimerState.leadIn:
        return AppColors.gold; // Gold during lead-in
      case ScoringTimerState.running:
        return const Color(0xFF4CAF50); // Green
      case ScoringTimerState.warning:
        return const Color(0xFFFFA726); // Amber
      case ScoringTimerState.expired:
        return const Color(0xFFEF5350); // Red
    }
  }

  String _getDisplayText() {
    if (_state == ScoringTimerState.idle) {
      return 'TAP';
    }
    if (_state == ScoringTimerState.leadIn) {
      return '$_secondsRemaining';
    }
    // Format as MM:SS
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }

    final indicatorColor = _getIndicatorColor();
    final displayText = _getDisplayText();
    final isLeadIn = _state == ScoringTimerState.leadIn;

    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: indicatorColor.withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Traffic light indicator
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: indicatorColor,
                boxShadow: _state != ScoringTimerState.idle
                    ? [
                        BoxShadow(
                          color: indicatorColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            // Timer display
            Text(
              displayText,
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: isLeadIn ? 24 : 18,
                color: _state == ScoringTimerState.idle
                    ? AppColors.textMuted
                    : indicatorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
