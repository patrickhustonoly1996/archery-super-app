import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../db/database.dart';
import '../../utils/unique_id.dart';
import '../../services/beep_service.dart';
import '../../services/breath_training_service.dart';
import '../../widgets/breathing_visualizer.dart';
import '../../widgets/breathing_reminder.dart';

/// Paced breathing session - inhale for 4, exhale for 6
/// Session with configurable duration
class PacedBreathingScreen extends StatefulWidget {
  const PacedBreathingScreen({super.key});

  @override
  State<PacedBreathingScreen> createState() => _PacedBreathingScreenState();
}

enum PacedState {
  setup,    // Initial setup screen
  idle,     // Ready to start
  active,   // Session in progress
}

class _PacedBreathingScreenState extends State<PacedBreathingScreen> {
  static const int _inhaleSeconds = 4;
  static const int _exhaleSeconds = 6;

  // Duration options in minutes (0 = unlimited)
  static const List<int> _durationOptions = [0, 3, 5, 10, 15, 20];

  final _service = BreathTrainingService();
  final _beepService = BeepService();

  Timer? _timer;
  PacedState _state = PacedState.setup;
  bool _beepsEnabled = false;
  BreathPhase _phase = BreathPhase.idle;
  int _phaseSecondsRemaining = 0;
  double _phaseProgress = 0.0;
  int _totalBreaths = 0;
  int _totalSeconds = 0;

  // Settings
  int _targetDurationMinutes = 5; // Default 5 minutes
  int _targetDurationSeconds = 0; // Calculated from minutes

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final beepsEnabled = await _service.getBeepsEnabled();
    final savedDuration = await _service.getPacedBreathingDuration();
    if (mounted) {
      setState(() {
        _beepsEnabled = beepsEnabled;
        _targetDurationMinutes = savedDuration;
        _targetDurationSeconds = savedDuration * 60;
      });
    }
    if (beepsEnabled) {
      await _beepService.initialize();
    }
  }

  bool get _isRunning => _state == PacedState.active;
  bool get _isUnlimited => _targetDurationMinutes == 0;
  int get _remainingSeconds => _isUnlimited ? 0 : _targetDurationSeconds - _totalSeconds;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSession() {
    setState(() {
      _state = PacedState.active;
      _phase = BreathPhase.inhale;
      _phaseSecondsRemaining = _inhaleSeconds;
      _phaseProgress = 0.0;
      _totalBreaths = 0;
      _totalSeconds = 0;
    });

    // Haptic feedback on start
    HapticFeedback.mediumImpact();

    // Play inhale beep at start
    if (_beepsEnabled) {
      _beepService.playInhaleBeep();
    }

    _timer = Timer.periodic(const Duration(milliseconds: 100), _tick);
  }

  void _stopSession() {
    _timer?.cancel();
    HapticFeedback.lightImpact();
    // Save to database if meaningful session (at least 1 minute)
    if (_totalSeconds >= 60) {
      _saveSessionToDatabase();
    }
    setState(() {
      _state = PacedState.idle;
      _phase = BreathPhase.idle;
    });
  }

  void _completeSession() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    _saveSessionToDatabase();
    setState(() {
      _state = PacedState.idle;
      _phase = BreathPhase.idle;
    });
    // Show completion message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session complete! $_totalBreaths breaths in ${_formatTime(_totalSeconds)}'),
        backgroundColor: AppColors.surfaceDark,
      ),
    );
  }

  void _extendSession(int additionalMinutes) {
    setState(() {
      _targetDurationMinutes += additionalMinutes;
      _targetDurationSeconds = _targetDurationMinutes * 60;
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _saveSessionToDatabase() async {
    try {
      final db = Provider.of<AppDatabase>(context, listen: false);
      await db.insertBreathTrainingLog(
        BreathTrainingLogsCompanion.insert(
          id: UniqueId.generate(),
          sessionType: 'pacedBreathing',
          durationMinutes: Value(_totalSeconds ~/ 60),
          rounds: Value(_totalBreaths),
          completedAt: DateTime.now(),
        ),
      );
      debugPrint('Paced breathing session saved: ${_totalSeconds ~/ 60} min, $_totalBreaths breaths');
    } catch (e) {
      debugPrint('Error saving paced breathing session: $e');
    }
  }

  void _tick(Timer timer) {
    setState(() {
      // Update progress within phase (100ms increments)
      final totalPhaseMs = (_phase == BreathPhase.inhale
              ? _inhaleSeconds
              : _exhaleSeconds) *
          1000;
      final elapsedMs = totalPhaseMs -
          (_phaseSecondsRemaining * 1000) +
          (1000 - (timer.tick % 10) * 100);
      _phaseProgress = (elapsedMs / totalPhaseMs).clamp(0.0, 1.0);

      // Check for second transitions
      if (timer.tick % 10 == 0) {
        _totalSeconds++;
        _phaseSecondsRemaining--;

        // Check if session duration reached (only for timed sessions)
        if (!_isUnlimited && _totalSeconds >= _targetDurationSeconds) {
          _completeSession();
          return;
        }

        if (_phaseSecondsRemaining <= 0) {
          // Phase complete - switch
          HapticFeedback.lightImpact();

          if (_phase == BreathPhase.inhale) {
            _phase = BreathPhase.exhale;
            _phaseSecondsRemaining = _exhaleSeconds;
            // Two beeps for exhale
            if (_beepsEnabled) {
              _beepService.playExhaleBeep();
            }
          } else {
            _phase = BreathPhase.inhale;
            _phaseSecondsRemaining = _inhaleSeconds;
            _totalBreaths++;
            // One beep for inhale
            if (_beepsEnabled) {
              _beepService.playInhaleBeep();
            }
          }
          _phaseProgress = 0.0;
        }
      }
    });
  }

  String get _phaseText {
    switch (_phase) {
      case BreathPhase.inhale:
        return 'Breathe In';
      case BreathPhase.exhale:
        return 'Breathe Out';
      default:
        return 'Ready';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paced Breathing'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _state == PacedState.setup
              ? _buildSetupView()
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
              // Info bar with duration
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.air,
                      color: AppColors.gold,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'In: ${_inhaleSeconds}s  Out: ${_exhaleSeconds}s',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.gold,
                          ),
                    ),
                    if (!_isUnlimited) ...[
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        width: 1,
                        height: 16,
                        color: AppColors.surfaceLight,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        _isRunning
                            ? 'Remaining: ${_formatTime(_remainingSeconds)}'
                            : 'Target: ${_targetDurationMinutes}min',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Breathing visualizer
              BreathingVisualizer(
                progress: _phaseProgress,
                phase: _phase,
                centerText: _isRunning ? '$_phaseSecondsRemaining' : null,
                secondaryText: _isRunning ? _phaseText : 'Tap Start',
              ),

              const SizedBox(height: AppSpacing.xl),

              // Stats
              if (_totalBreaths > 0 || _totalSeconds > 0)
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
                        label: 'Breaths',
                        value: '$_totalBreaths',
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: AppColors.surfaceLight,
                      ),
                      _StatItem(
                        label: 'Time',
                        value: _formatTime(_totalSeconds),
                      ),
                      if (!_isUnlimited) ...[
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.surfaceLight,
                        ),
                        _StatItem(
                          label: 'Remaining',
                          value: _formatTime(_remainingSeconds),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.lg),

              // Extension button (only during active timed session)
              if (_isRunning && !_isUnlimited)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: OutlinedButton.icon(
                    onPressed: () => _showExtendDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Extend Session'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.gold),
                    ),
                  ),
                ),

              // Control button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isRunning ? _stopSession : _startSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isRunning ? AppColors.error : AppColors.gold,
                  ),
                  child: Text(
                    _isRunning ? 'Stop' : 'Start',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Reminder
              BreathingReminder(
                isActive: _isRunning,
              ),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            'Configure Your Session',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Duration Selection
          Text(
            'Session Duration',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.gold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _durationOptions.map((duration) {
              final isSelected = _targetDurationMinutes == duration;
              final label = duration == 0 ? 'Unlimited' : '${duration}min';
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _targetDurationMinutes = duration;
                      _targetDurationSeconds = duration * 60;
                    });
                    _service.setPacedBreathingDuration(duration);
                  }
                },
                selectedColor: AppColors.gold,
                backgroundColor: AppColors.surfaceDark,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.backgroundDark : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Breathing pattern info
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Column(
              children: [
                Text(
                  'Breathing Pattern',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PatternItem(label: 'Inhale', seconds: _inhaleSeconds),
                    const SizedBox(width: AppSpacing.lg),
                    const Icon(Icons.arrow_forward, color: AppColors.textMuted, size: 16),
                    const SizedBox(width: AppSpacing.lg),
                    _PatternItem(label: 'Exhale', seconds: _exhaleSeconds),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${(_inhaleSeconds + _exhaleSeconds)}s per breath cycle',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Summary
          if (_targetDurationMinutes > 0)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'Session Preview',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '~${(_targetDurationSeconds / (_inhaleSeconds + _exhaleSeconds)).round()} breaths over $_targetDurationMinutes minutes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.gold,
                        ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.xxl),

          // Start button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _state = PacedState.idle);
              },
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  void _showExtendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Extend Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add more time to your session:'),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [2, 5, 10].map((mins) {
                return ActionChip(
                  label: Text('+$mins min'),
                  onPressed: () {
                    Navigator.pop(context);
                    _extendSession(mins);
                  },
                  backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                  labelStyle: const TextStyle(color: AppColors.gold),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
            fontSize: 24,
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

class _PatternItem extends StatelessWidget {
  final String label;
  final int seconds;

  const _PatternItem({
    required this.label,
    required this.seconds,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${seconds}s',
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 24,
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
