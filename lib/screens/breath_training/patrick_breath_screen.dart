import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../db/database.dart';
import '../../utils/unique_id.dart';
import '../../services/beep_service.dart';
import '../../services/breath_training_service.dart';
import '../../services/vibration_service.dart';
import '../../widgets/breathing_visualizer.dart';
import '../../widgets/breathing_reminder.dart';
import '../../providers/breath_training_provider.dart';
import '../../providers/skills_provider.dart';

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
  warmup,      // 2 sets of paced breathing before first test
  preparation, // Brief pause with instruction before exhale
  exhaling,    // Timing the exhale
  recovery,    // Paced breathing after exhale
  complete,    // Session finished, showing results
}

class _PatrickBreathScreenState extends State<PatrickBreathScreen> {
  static const int _inhaleSeconds = 4;
  static const int _exhaleSeconds = 6;
  static const int _recoveryBreaths = 4;
  static const int _warmupBreaths = 2; // 2 sets of paced breathing before test
  static const int _preparationSeconds = 3; // Countdown before exhale starts

  final _service = BreathTrainingService();
  final _beepService = BeepService();
  final _vibration = VibrationService();
  bool _beepsEnabled = false;
  bool _vibrationsEnabled = true; // Default ON

  Timer? _timer;
  PatrickState _state = PatrickState.idle;
  BreathPhase _breathPhase = BreathPhase.idle;

  // Current exhale test
  int _currentExhaleTime = 0;
  int _recoveryBreathCount = 0;
  int _warmupBreathCount = 0;
  int _phaseSecondsRemaining = 0;
  int _preparationCountdown = 0;
  double _phaseProgress = 0.0;

  // Session stats
  final List<int> _exhaleTimes = [];
  int _bestEver = 0;
  bool _isNewRecord = false;

  // Tick counter for smooth animation
  int _tickCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final best = await _service.getPatrickBestExhale();
    final beepsEnabled = await _service.getBeepsEnabled();
    final vibrationsEnabled = await _vibration.isEnabled();
    if (mounted) {
      setState(() {
        _bestEver = best;
        _beepsEnabled = beepsEnabled;
        _vibrationsEnabled = vibrationsEnabled;
      });
    }
    if (beepsEnabled) {
      await _beepService.initialize();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startWarmup() {
    _vibration.medium();
    _timer?.cancel();

    setState(() {
      _state = PatrickState.warmup;
      _breathPhase = BreathPhase.inhale;
      _warmupBreathCount = 0;
      _phaseSecondsRemaining = _inhaleSeconds;
      _phaseProgress = 0.0;
      _tickCount = 0;
    });

    // Play inhale beep at start
    if (_beepsEnabled) {
      _beepService.playInhaleBeep();
    }

    _timer = Timer.periodic(const Duration(milliseconds: 100), _tickWarmup);
  }

  void _tickWarmup(Timer timer) {
    _tickCount++;

    if (_tickCount % 10 != 0) {
      // Update progress smoothly with sub-second interpolation
      final totalMs =
          (_breathPhase == BreathPhase.inhale ? _inhaleSeconds : _exhaleSeconds) *
              1000;
      final subSecondMs = (_tickCount % 10) * 100;
      final elapsedMs = totalMs - (_phaseSecondsRemaining * 1000) + subSecondMs;
      setState(() {
        _phaseProgress = (elapsedMs / totalMs).clamp(0.0, 1.0);
      });
      return;
    }

    setState(() {
      _phaseSecondsRemaining--;

      if (_phaseSecondsRemaining <= 0) {
        if (_breathPhase == BreathPhase.inhale) {
          _breathPhase = BreathPhase.exhale;
          _phaseSecondsRemaining = _exhaleSeconds;
          _vibration.exhale();
          // Two beeps for exhale
          if (_beepsEnabled) {
            _beepService.playExhaleBeep();
          }
        } else {
          _warmupBreathCount++;

          if (_warmupBreathCount >= _warmupBreaths) {
            // Warmup complete - transition to preparation
            _timer?.cancel();
            _startPreparation();
            return;
          } else {
            _breathPhase = BreathPhase.inhale;
            _phaseSecondsRemaining = _inhaleSeconds;
            _vibration.inhale();
            // One beep for inhale
            if (_beepsEnabled) {
              _beepService.playInhaleBeep();
            }
          }
        }
        _phaseProgress = 0.0;
      }
    });
  }

  void _startPreparation() {
    _vibration.double();
    setState(() {
      _state = PatrickState.preparation;
      _breathPhase = BreathPhase.idle;
      _preparationCountdown = _preparationSeconds;
      _phaseProgress = 0.0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), _tickPreparation);
  }

  void _tickPreparation(Timer timer) {
    setState(() {
      _preparationCountdown--;
      if (_preparationCountdown <= 0) {
        _timer?.cancel();
        _startExhale();
      }
    });
  }

  void _startExhale() {
    if (_vibrationsEnabled) _vibration.medium();
    _timer?.cancel();

    setState(() {
      _state = PatrickState.exhaling;
      _breathPhase = BreathPhase.exhale;
      _currentExhaleTime = 0;
      _phaseProgress = 0.0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentExhaleTime++;
      });
    });
  }

  void _stopExhale() async {
    _vibration.heavy();
    _timer?.cancel();

    // Save exhale time
    _exhaleTimes.add(_currentExhaleTime);

    // Check for new record
    final isRecord = await _service.updatePatrickBestExhale(_currentExhaleTime);
    if (isRecord) {
      setState(() {
        _isNewRecord = true;
        _bestEver = _currentExhaleTime;
      });
    }

    // Transition to recovery breathing
    setState(() {
      _state = PatrickState.recovery;
      _breathPhase = BreathPhase.inhale;
      _phaseSecondsRemaining = _inhaleSeconds;
      _recoveryBreathCount = 0;
      _phaseProgress = 0.0;
      _tickCount = 0;
    });

    // One beep for inhale (recovery starts)
    if (_beepsEnabled) {
      _beepService.playInhaleBeep();
    }

    _timer = Timer.periodic(const Duration(milliseconds: 100), _tickRecovery);
  }

  void _tickRecovery(Timer timer) {
    _tickCount++;

    if (_tickCount % 10 != 0) {
      // Update progress smoothly with sub-second interpolation
      final totalMs =
          (_breathPhase == BreathPhase.inhale ? _inhaleSeconds : _exhaleSeconds) *
              1000;
      final subSecondMs = (_tickCount % 10) * 100;
      final elapsedMs = totalMs - (_phaseSecondsRemaining * 1000) + subSecondMs;
      setState(() {
        _phaseProgress = (elapsedMs / totalMs).clamp(0.0, 1.0);
      });
      return;
    }

    setState(() {
      _phaseSecondsRemaining--;

      if (_phaseSecondsRemaining <= 0) {
        if (_breathPhase == BreathPhase.inhale) {
          _breathPhase = BreathPhase.exhale;
          _phaseSecondsRemaining = _exhaleSeconds;
          _vibration.exhale();
          // Two beeps for exhale
          if (_beepsEnabled) {
            _beepService.playExhaleBeep();
          }
        } else {
          _recoveryBreathCount++;

          if (_recoveryBreathCount >= _recoveryBreaths) {
            // Recovery complete - ready for another test or finish
            _timer?.cancel();
            _state = PatrickState.idle;
            _breathPhase = BreathPhase.idle;
            _isNewRecord = false; // Reset for potential next round
            _vibration.double();
          } else {
            _breathPhase = BreathPhase.inhale;
            _phaseSecondsRemaining = _inhaleSeconds;
            _vibration.inhale();
            // One beep for inhale
            if (_beepsEnabled) {
              _beepService.playInhaleBeep();
            }
          }
        }
        _phaseProgress = 0.0;
      }
    });
  }

  void _finishSession() {
    _timer?.cancel();
    // Clear provider state
    context.read<BreathTrainingProvider>().reset();
    // Save to database
    _saveSessionToDatabase();
    setState(() {
      _state = PatrickState.complete;
    });
  }

  Future<void> _saveSessionToDatabase() async {
    if (_exhaleTimes.isEmpty) return;

    try {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final logId = UniqueId.generate();
      await db.insertBreathTrainingLog(
        BreathTrainingLogsCompanion.insert(
          id: logId,
          sessionType: 'patrickBreath',
          bestExhaleSeconds: Value(_bestThisSession),
          rounds: Value(_exhaleTimes.length),
          completedAt: DateTime.now(),
        ),
      );
      debugPrint('Patrick breath session saved: ${_bestThisSession}s best exhale');

      // Award XP for breath work
      if (mounted) {
        final skillsProvider = context.read<SkillsProvider>();
        await skillsProvider.awardBreathTrainingXp(
          logId: logId,
          bestExhaleSeconds: _bestThisSession,
        );
      }
    } catch (e) {
      debugPrint('Error saving patrick breath session: $e');
    }
  }

  Future<bool> _onWillPop() async {
    final isActive = _state != PatrickState.idle && _state != PatrickState.complete;
    if (isActive) {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Leave Session?'),
          content: const Text('You can pause and return later, or abandon the session.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'stay'),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () {
                _pauseForNavigation();
                Navigator.pop(context, 'pause');
              },
              child: Text(
                'Pause & Leave',
                style: TextStyle(color: AppColors.gold),
              ),
            ),
            TextButton(
              onPressed: () {
                _timer?.cancel();
                context.read<BreathTrainingProvider>().reset();
                Navigator.pop(context, 'abandon');
              },
              child: Text(
                'Abandon',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
      return result == 'pause' || result == 'abandon';
    }
    return true;
  }

  void _pauseForNavigation() {
    _timer?.cancel();
    // Mark as active in provider
    final provider = context.read<BreathTrainingProvider>();
    provider.startPatrickBreathSession();
    provider.pauseForNavigation();
  }

  String get _statusText {
    switch (_state) {
      case PatrickState.idle:
        return _exhaleTimes.isEmpty ? 'Ready' : 'Ready for Another';
      case PatrickState.warmup:
        return _breathPhase == BreathPhase.inhale ? 'Breathe In' : 'Breathe Out';
      case PatrickState.preparation:
        return 'Get Ready';
      case PatrickState.exhaling:
        return 'Exhaling';
      case PatrickState.recovery:
        return _breathPhase == BreathPhase.inhale ? 'Breathe In Slowly' : 'Breathe Out Slowly';
      case PatrickState.complete:
        return 'Session Complete';
    }
  }

  String get _instructionText {
    switch (_state) {
      case PatrickState.idle:
        return _exhaleTimes.isEmpty
            ? 'Tap Start to warm up'
            : 'Tap button to test again, or tap Done';
      case PatrickState.warmup:
        return 'Warmup breath ${_warmupBreathCount + 1}/$_warmupBreaths';
      case PatrickState.preparation:
        return 'Exhale nasally and slowly\nControl the rate of air flow';
      case PatrickState.exhaling:
        return 'Slow and steady through the nose...';
      case PatrickState.recovery:
        return 'Breathe easily and slowly\nThis is where the benefit is made';
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
    final isWarmup = _state == PatrickState.warmup;
    final isPreparation = _state == PatrickState.preparation;
    final isIdle = _state == PatrickState.idle;
    final needsWarmup = _exhaleTimes.isEmpty && isIdle;
    final isActive = _state != PatrickState.idle && _state != PatrickState.complete;

    return PopScope(
      canPop: !isActive,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Long Exhale Test', style: TextStyle(fontSize: 18)),
              Text(
                'The Patrick Breath',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _state == PatrickState.complete
              ? _buildCompleteView()
              : SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom -
                          kToolbarHeight - 48,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                    const SizedBox(height: AppSpacing.xl),

                    // Main visualizer
                    if (isExhaling)
                      _ExhaleTimer(seconds: _currentExhaleTime)
                    else if (isPreparation)
                      _PreparationCountdown(
                        seconds: _preparationCountdown,
                        instruction: _instructionText,
                      )
                    else
                      BreathingVisualizer(
                        progress: _phaseProgress,
                        phase: _breathPhase,
                        centerText: (isRecovering || isWarmup) ? '$_phaseSecondsRemaining' : null,
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
                          color: AppColors.gold.withValues(alpha:0.2),
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

                    const SizedBox(height: AppSpacing.xl),

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
                    if (isWarmup) ...[
                      // Warmup in progress - no buttons
                      const SizedBox(
                        height: 80,
                        child: Center(
                          child: Text(
                            'Warming up...',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ] else if (needsWarmup) ...[
                      // First test - show Start button for warmup
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _startWarmup,
                          child: const Text(
                            'Start',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ] else if (isPreparation) ...[
                      // Preparation countdown - no buttons needed
                      const SizedBox(height: 80),
                    ] else if (isExhaling) ...[
                      // Exhale in progress - show Stop button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _stopExhale,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          child: const Text(
                            'Stop',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ] else if (isRecovering) ...[
                      // Recovery in progress - show toggles
                      _buildInSessionToggles(),
                    ] else ...[
                      // Idle after at least one test - tap to start another
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _startPreparation,
                          child: const Text(
                            'Test Again',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Done button (only show after at least one test)
                      if (_exhaleTimes.isNotEmpty)
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
                    ],

                    const SizedBox(height: AppSpacing.md),

                    BreathingReminder(
                      isActive: _state != PatrickState.idle && _state != PatrickState.complete,
                      isPostHold: _state == PatrickState.recovery,
                    ),
                  ],
                    ),
                  ),
                ),
        ),
      ),
      ),
    );
  }

  Widget _buildInSessionToggles() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _InSessionToggle(
            icon: Icons.vibration,
            label: 'Vibration',
            value: _vibrationsEnabled,
            onChanged: (value) async {
              setState(() => _vibrationsEnabled = value);
              await _vibration.setEnabled(value);
            },
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.surfaceLight,
          ),
          _InSessionToggle(
            icon: Icons.volume_up,
            label: 'Sound',
            value: _beepsEnabled,
            onChanged: (value) async {
              setState(() => _beepsEnabled = value);
              await _service.setBeepsEnabled(value);
              if (value) {
                await _beepService.initialize();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteView() {
    final avgTime =
        _exhaleTimes.reduce((a, b) => a + b) / _exhaleTimes.length;

    return SingleChildScrollView(
      child: Column(
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

        const SizedBox(height: AppSpacing.xl),

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
      ),
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
        color: AppColors.gold.withValues(alpha:0.15),
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

class _PreparationCountdown extends StatelessWidget {
  final int seconds;
  final String instruction;

  const _PreparationCountdown({
    required this.seconds,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceDark,
        border: Border.all(
          color: AppColors.gold,
          width: 3,
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
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              instruction,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _InSessionToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _InSessionToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: value ? AppColors.gold : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: value ? AppColors.gold : AppColors.textMuted,
                ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            width: 36,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: value
                  ? AppColors.gold.withValues(alpha:0.3)
                  : AppColors.surfaceLight,
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? AppColors.gold : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
