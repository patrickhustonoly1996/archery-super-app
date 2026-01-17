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
/// Continuous session until user stops
class PacedBreathingScreen extends StatefulWidget {
  const PacedBreathingScreen({super.key});

  @override
  State<PacedBreathingScreen> createState() => _PacedBreathingScreenState();
}

class _PacedBreathingScreenState extends State<PacedBreathingScreen> {
  static const int _inhaleSeconds = 4;
  static const int _exhaleSeconds = 6;

  final _service = BreathTrainingService();
  final _beepService = BeepService();

  Timer? _timer;
  bool _isRunning = false;
  bool _beepsEnabled = false;
  BreathPhase _phase = BreathPhase.idle;
  int _phaseSecondsRemaining = 0;
  double _phaseProgress = 0.0;
  int _totalBreaths = 0;
  int _totalSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final beepsEnabled = await _service.getBeepsEnabled();
    if (mounted) {
      setState(() => _beepsEnabled = beepsEnabled);
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

  void _startSession() {
    setState(() {
      _isRunning = true;
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
      _isRunning = false;
      _phase = BreathPhase.idle;
    });
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
          child: SingleChildScrollView(
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
              // Info bar
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
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.lg),

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
