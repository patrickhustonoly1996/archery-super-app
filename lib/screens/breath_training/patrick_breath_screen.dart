import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/breath_training_service.dart';
import '../../widgets/breathing_visualizer.dart';

/// Patrick's long exhale test
/// Test: Hold start to time your exhale, release to stop
/// Then transition to paced breathing for recovery
/// Can do multiple rounds as training
class PatrickBreathScreen extends StatefulWidget {
  const PatrickBreathScreen({super.key});

  @override
  State<PatrickBreathScreen> createState() => _PatrickBreathScreenState();
}

enum PatrickState {
  idle,
  exhaling, // Timing the exhale
  recovery, // Paced breathing after exhale
  complete, // Session finished, showing results
}

class _PatrickBreathScreenState extends State<PatrickBreathScreen> {
  static const int _inhaleSeconds = 4;
  static const int _exhaleSeconds = 6;
  static const int _recoveryBreaths = 4;

  final _service = BreathTrainingService();

  Timer? _timer;
  PatrickState _state = PatrickState.idle;
  BreathPhase _breathPhase = BreathPhase.idle;

  // Current exhale test
  int _exhaleSeconds = 0;
  int _recoveryBreathCount = 0;
  int _phaseSecondsRemaining = 0;
  double _phaseProgress = 0.0;

  // Session stats
  List<int> _exhaleTimes = [];
  int _bestEver = 0;
  bool _isNewRecord = false;

  @override
  void initState() {
    super.initState();
    _loadBestTime();
  }

  Future<void> _loadBestTime() async {
    final best = await _service.getPatrickBestExhale();
    if (mounted) {
      setState(() => _bestEver = best);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startExhale() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();

    setState(() {
      _state = PatrickState.exhaling;
      _breathPhase = BreathPhase.exhale;
      _exhaleSeconds = 0;
      _phaseProgress = 0.0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _exhaleSeconds++;
      });
    });
  }

  void _stopExhale() async {
    HapticFeedback.heavyImpact();
    _timer?.cancel();

    // Save exhale time
    _exhaleTimes.add(_exhaleSeconds);

    // Check for new record
    final isRecord = await _service.updatePatrickBestExhale(_exhaleSeconds);
    if (isRecord) {
      setState(() {
        _isNewRecord = true;
        _bestEver = _exhaleSeconds;
      });
    }

    // Transition to recovery breathing
    setState(() {
      _state = PatrickState.recovery;
      _breathPhase = BreathPhase.inhale;
      _phaseSecondsRemaining = _inhaleSeconds;
      _recoveryBreathCount = 0;
      _phaseProgress = 0.0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), _tickRecovery);
  }

  void _tickRecovery(Timer timer) {
    if (timer.tick % 10 != 0) {
      // Update progress smoothly
      final totalMs =
          (_breathPhase == BreathPhase.inhale ? _inhaleSeconds : _exhaleSeconds) *
              1000;
      final elapsedMs = totalMs - (_phaseSecondsRemaining * 1000);
      setState(() {
        _phaseProgress = (elapsedMs / totalMs).clamp(0.0, 1.0);
      });
      return;
    }

    setState(() {
      _phaseSecondsRemaining--;

      if (_phaseSecondsRemaining <= 0) {
        HapticFeedback.lightImpact();

        if (_breathPhase == BreathPhase.inhale) {
          _breathPhase = BreathPhase.exhale;
          _phaseSecondsRemaining = _exhaleSeconds;
        } else {
          _recoveryBreathCount++;

          if (_recoveryBreathCount >= _recoveryBreaths) {
            // Recovery complete - ready for another test or finish
            _timer?.cancel();
            _state = PatrickState.idle;
            _breathPhase = BreathPhase.idle;
            _isNewRecord = false; // Reset for potential next round
          } else {
            _breathPhase = BreathPhase.inhale;
            _phaseSecondsRemaining = _inhaleSeconds;
          }
        }
        _phaseProgress = 0.0;
      }
    });
  }

  void _finishSession() {
    _timer?.cancel();
    setState(() {
      _state = PatrickState.complete;
    });
  }

  String get _statusText {
    switch (_state) {
      case PatrickState.idle:
        return _exhaleTimes.isEmpty ? 'Ready' : 'Ready for Another';
      case PatrickState.exhaling:
        return 'Exhaling';
      case PatrickState.recovery:
        return _breathPhase == BreathPhase.inhale ? 'Breathe In' : 'Breathe Out';
      case PatrickState.complete:
        return 'Session Complete';
    }
  }

  String get _instructionText {
    switch (_state) {
      case PatrickState.idle:
        return _exhaleTimes.isEmpty
            ? 'Hold the button and exhale slowly'
            : 'Hold button to test again, or tap Done';
      case PatrickState.exhaling:
        return 'Keep going... release when empty';
      case PatrickState.recovery:
        return 'Recovery breath ${_recoveryBreathCount + 1}/$_recoveryBreaths';
      case PatrickState.complete:
        return '';
    }
  }

  int get _bestThisSession {
    if (_exhaleTimes.isEmpty) return 0;
    return _exhaleTimes.reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final isExhaling = _state == PatrickState.exhaling;
    final isRecovering = _state == PatrickState.recovery;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Long Exhale Test'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _state == PatrickState.complete
              ? _buildCompleteView()
              : Column(
                  children: [
                    // Best time display
                    if (_bestEver > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: AppColors.gold,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Personal Best: ${_bestEver}s',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.gold,
                                  ),
                            ),
                          ],
                        ),
                      ),

                    const Spacer(),

                    // Main visualizer
                    if (isExhaling)
                      _ExhaleTimer(seconds: _exhaleSeconds)
                    else
                      BreathingVisualizer(
                        progress: _phaseProgress,
                        phase: _breathPhase,
                        centerText: isRecovering ? '$_phaseSecondsRemaining' : null,
                        secondaryText: _statusText,
                      ),

                    const SizedBox(height: AppSpacing.lg),

                    // New record badge
                    if (_isNewRecord && !isExhaling)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          border: Border.all(color: AppColors.gold),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppColors.gold,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'New Personal Best!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: AppSpacing.sm),

                    // Instruction
                    Text(
                      _instructionText,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(),

                    // Session stats
                    if (_exhaleTimes.isNotEmpty && !isExhaling && !isRecovering)
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
                              label: 'Tests',
                              value: '${_exhaleTimes.length}',
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: AppColors.surfaceLight,
                            ),
                            _StatItem(
                              label: 'Last',
                              value: '${_exhaleTimes.last}s',
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: AppColors.surfaceLight,
                            ),
                            _StatItem(
                              label: 'Best',
                              value: '${_bestThisSession}s',
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: AppSpacing.lg),

                    // Control buttons
                    if (!isRecovering) ...[
                      // Main exhale button
                      GestureDetector(
                        onLongPressStart: (_) {
                          if (!isRecovering) _startExhale();
                        },
                        onLongPressEnd: (_) {
                          if (isExhaling) _stopExhale();
                        },
                        child: Container(
                          width: double.infinity,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isExhaling
                                ? AppColors.gold
                                : AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                            border: Border.all(
                              color: AppColors.gold,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              isExhaling ? 'Release to Stop' : 'Hold to Exhale',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isExhaling
                                    ? AppColors.backgroundDark
                                    : AppColors.gold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Done button (only show after at least one test)
                      if (_exhaleTimes.isNotEmpty && !isExhaling)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: TextButton(
                            onPressed: _finishSession,
                            child: const Text(
                              'Done',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                    ] else ...[
                      // Recovery in progress - no buttons
                      const SizedBox(
                        height: 80,
                        child: Center(
                          child: Text(
                            'Recovering...',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ],

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

  Widget _buildCompleteView() {
    final avgTime =
        _exhaleTimes.reduce((a, b) => a + b) / _exhaleTimes.length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: AppColors.gold,
          size: 80,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Session Complete',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Results
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ResultItem(
                    label: 'Tests',
                    value: '${_exhaleTimes.length}',
                  ),
                  _ResultItem(
                    label: 'Best',
                    value: '${_bestThisSession}s',
                    isHighlighted: true,
                  ),
                  _ResultItem(
                    label: 'Average',
                    value: '${avgTime.toStringAsFixed(1)}s',
                  ),
                ],
              ),
              if (_bestThisSession >= _bestEver && _bestEver > 0) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.surfaceLight),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: AppColors.gold,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Personal Best: ${_bestEver}s',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExhaleTimer extends StatelessWidget {
  final int seconds;

  const _ExhaleTimer({required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold.withOpacity(0.15),
        border: Border.all(
          color: AppColors.gold,
          width: 4,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$seconds',
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 72,
              color: AppColors.gold,
            ),
          ),
          const Text(
            'seconds',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
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
            fontSize: 20,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ResultItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _ResultItem({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: isHighlighted ? 32 : 24,
            color: isHighlighted ? AppColors.gold : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
