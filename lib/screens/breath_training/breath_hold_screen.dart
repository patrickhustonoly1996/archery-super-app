import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/breath_training_service.dart';
import '../../widgets/breathing_visualizer.dart';

/// Breath hold session with progressive difficulty
/// Structure: paced breaths -> exhale hold -> paced recovery -> repeat
/// Hold duration increases each round
class BreathHoldScreen extends StatefulWidget {
  const BreathHoldScreen({super.key});

  @override
  State<BreathHoldScreen> createState() => _BreathHoldScreenState();
}

enum SessionState {
  idle,
  pacedBreathing,
  holdCountdown,
  holding,
  recovery,
  complete,
}

class _BreathHoldScreenState extends State<BreathHoldScreen> {
  static const int _inhaleSeconds = 4;
  static const int _exhaleSeconds = 6;
  static const int _pacedBreathsPerCycle = 3;
  static const int _recoveryBreaths = 4;

  final _service = BreathTrainingService();

  Timer? _timer;
  SessionState _state = SessionState.idle;
  BreathPhase _breathPhase = BreathPhase.idle;

  // Settings
  int _baseHoldDuration = 15;
  int _totalRounds = 5;

  // Session progress
  int _currentRound = 0;
  int _pacedBreathCount = 0;
  int _phaseSecondsRemaining = 0;
  double _phaseProgress = 0.0;
  int _totalHoldTime = 0;

  // Current hold target (increases each round)
  int get _currentHoldTarget {
    // Progressive: round 1 = base, each round adds ~20%
    final progressionFactor = 1.0 + (_currentRound * 0.2);
    return (_baseHoldDuration * progressionFactor).round();
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final holdDuration = await _service.getHoldDuration();
    final rounds = await _service.getHoldSessionRounds();
    if (mounted) {
      setState(() {
        _baseHoldDuration = holdDuration;
        _totalRounds = rounds;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSession() {
    HapticFeedback.mediumImpact();
    setState(() {
      _state = SessionState.pacedBreathing;
      _breathPhase = BreathPhase.inhale;
      _currentRound = 0;
      _pacedBreathCount = 0;
      _phaseSecondsRemaining = _inhaleSeconds;
      _phaseProgress = 0.0;
      _totalHoldTime = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 100), _tick);
  }

  void _stopSession() {
    _timer?.cancel();
    HapticFeedback.lightImpact();
    setState(() {
      _state = SessionState.idle;
      _breathPhase = BreathPhase.idle;
    });
  }

  void _tick(Timer timer) {
    if (timer.tick % 10 != 0) {
      // Update progress smoothly between seconds
      _updateProgress();
      return;
    }

    setState(() {
      _phaseSecondsRemaining--;

      switch (_state) {
        case SessionState.pacedBreathing:
          _handlePacedBreathing();
          break;
        case SessionState.holdCountdown:
          _handleHoldCountdown();
          break;
        case SessionState.holding:
          _handleHolding();
          break;
        case SessionState.recovery:
          _handleRecovery();
          break;
        default:
          break;
      }
    });
  }

  void _updateProgress() {
    int totalPhaseMs;
    switch (_state) {
      case SessionState.pacedBreathing:
      case SessionState.recovery:
        totalPhaseMs =
            (_breathPhase == BreathPhase.inhale ? _inhaleSeconds : _exhaleSeconds) *
                1000;
        break;
      case SessionState.holdCountdown:
        totalPhaseMs = 3000; // 3 second countdown
        break;
      case SessionState.holding:
        totalPhaseMs = _currentHoldTarget * 1000;
        break;
      default:
        return;
    }

    final elapsedMs = totalPhaseMs - (_phaseSecondsRemaining * 1000);
    setState(() {
      _phaseProgress = (elapsedMs / totalPhaseMs).clamp(0.0, 1.0);
    });
  }

  void _handlePacedBreathing() {
    if (_phaseSecondsRemaining <= 0) {
      HapticFeedback.lightImpact();

      if (_breathPhase == BreathPhase.inhale) {
        _breathPhase = BreathPhase.exhale;
        _phaseSecondsRemaining = _exhaleSeconds;
      } else {
        _pacedBreathCount++;

        if (_pacedBreathCount >= _pacedBreathsPerCycle) {
          // Move to hold countdown
          _state = SessionState.holdCountdown;
          _breathPhase = BreathPhase.exhale;
          _phaseSecondsRemaining = 3; // 3 second countdown
          _pacedBreathCount = 0;
        } else {
          _breathPhase = BreathPhase.inhale;
          _phaseSecondsRemaining = _inhaleSeconds;
        }
      }
      _phaseProgress = 0.0;
    }
  }

  void _handleHoldCountdown() {
    if (_phaseSecondsRemaining <= 0) {
      HapticFeedback.mediumImpact();
      _state = SessionState.holding;
      _breathPhase = BreathPhase.hold;
      _phaseSecondsRemaining = _currentHoldTarget;
      _phaseProgress = 0.0;
    }
  }

  void _handleHolding() {
    _totalHoldTime++;

    if (_phaseSecondsRemaining <= 0) {
      HapticFeedback.heavyImpact();
      _currentRound++;

      if (_currentRound >= _totalRounds) {
        // Session complete
        _state = SessionState.complete;
        _timer?.cancel();
      } else {
        // Move to recovery breaths
        _state = SessionState.recovery;
        _breathPhase = BreathPhase.inhale;
        _phaseSecondsRemaining = _inhaleSeconds;
        _pacedBreathCount = 0;
      }
      _phaseProgress = 0.0;
    }
  }

  void _handleRecovery() {
    if (_phaseSecondsRemaining <= 0) {
      HapticFeedback.lightImpact();

      if (_breathPhase == BreathPhase.inhale) {
        _breathPhase = BreathPhase.exhale;
        _phaseSecondsRemaining = _exhaleSeconds;
      } else {
        _pacedBreathCount++;

        if (_pacedBreathCount >= _recoveryBreaths) {
          // Move to next round's paced breathing
          _state = SessionState.pacedBreathing;
          _breathPhase = BreathPhase.inhale;
          _phaseSecondsRemaining = _inhaleSeconds;
          _pacedBreathCount = 0;
        } else {
          _breathPhase = BreathPhase.inhale;
          _phaseSecondsRemaining = _inhaleSeconds;
        }
      }
      _phaseProgress = 0.0;
    }
  }

  String get _statusText {
    switch (_state) {
      case SessionState.idle:
        return 'Ready';
      case SessionState.pacedBreathing:
        return _breathPhase == BreathPhase.inhale ? 'Breathe In' : 'Breathe Out';
      case SessionState.holdCountdown:
        return 'Exhale and Hold';
      case SessionState.holding:
        return 'Hold';
      case SessionState.recovery:
        return _breathPhase == BreathPhase.inhale ? 'Breathe In' : 'Breathe Out';
      case SessionState.complete:
        return 'Complete';
    }
  }

  String get _secondaryText {
    switch (_state) {
      case SessionState.idle:
        return 'Tap Start to begin';
      case SessionState.pacedBreathing:
        return 'Preparing for hold';
      case SessionState.holdCountdown:
        return 'Get ready';
      case SessionState.holding:
        return 'Target: ${_currentHoldTarget}s';
      case SessionState.recovery:
        return 'Recovery breath ${_pacedBreathCount + 1}/$_recoveryBreaths';
      case SessionState.complete:
        return 'Total hold time: ${_totalHoldTime}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _state != SessionState.idle && _state != SessionState.complete;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Breath Holds'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Progress indicator
              _RoundProgress(
                currentRound: _currentRound,
                totalRounds: _totalRounds,
                isComplete: _state == SessionState.complete,
              ),

              const Spacer(),

              // Breathing visualizer
              BreathingVisualizer(
                progress: _phaseProgress,
                phase: _breathPhase,
                centerText: isActive ? '$_phaseSecondsRemaining' : null,
                secondaryText: _statusText,
              ),

              const SizedBox(height: AppSpacing.md),

              // Secondary info
              Text(
                _secondaryText,
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const Spacer(),

              // Stats bar
              if (_currentRound > 0 || _state == SessionState.complete)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Rounds',
                        value: '$_currentRound / $_totalRounds',
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: AppColors.surfaceLight,
                      ),
                      _StatItem(
                        label: 'Hold Time',
                        value: '${_totalHoldTime}s',
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: AppColors.surfaceLight,
                      ),
                      _StatItem(
                        label: 'Next Hold',
                        value: _currentRound < _totalRounds
                            ? '${_currentHoldTarget}s'
                            : '-',
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.lg),

              // Control button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_state == SessionState.complete) {
                      Navigator.pop(context);
                    } else if (isActive) {
                      _stopSession();
                    } else {
                      _startSession();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? AppColors.error
                        : _state == SessionState.complete
                            ? AppColors.gold
                            : AppColors.gold,
                  ),
                  child: Text(
                    _state == SessionState.complete
                        ? 'Done'
                        : isActive
                            ? 'Stop'
                            : 'Start',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Nose breathing only',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundProgress extends StatelessWidget {
  final int currentRound;
  final int totalRounds;
  final bool isComplete;

  const _RoundProgress({
    required this.currentRound,
    required this.totalRounds,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalRounds, (index) {
          final isCompleted = index < currentRound;
          final isCurrent = index == currentRound && !isComplete;

          return Container(
            width: 24,
            height: 24,
            margin: EdgeInsets.only(
              left: index > 0 ? AppSpacing.sm : 0,
            ),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.gold
                  : isCurrent
                      ? AppColors.gold.withOpacity(0.3)
                      : AppColors.surfaceLight,
              border: isCurrent
                  ? Border.all(color: AppColors.gold, width: 2)
                  : null,
            ),
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: AppColors.backgroundDark,
                  )
                : null,
          );
        }),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 18,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}
