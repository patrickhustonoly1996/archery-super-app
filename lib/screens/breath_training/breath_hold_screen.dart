import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/breath_training_service.dart';
import '../../widgets/breathing_visualizer.dart';
import '../../widgets/breathing_reminder.dart';

/// Breath hold session with progressive difficulty
/// Structure: paced breaths -> exhale hold -> paced recovery -> repeat
/// Hold duration increases each round
class BreathHoldScreen extends StatefulWidget {
  const BreathHoldScreen({super.key});

  @override
  State<BreathHoldScreen> createState() => _BreathHoldScreenState();
}

enum SessionState {
  setup,      // Initial setup screen
  idle,       // Ready to start session
  pacedBreathing,
  holding,
  recovery,
  complete,
}

enum DifficultyLevel {
  beginner,     // +10% per round
  intermediate, // +20% per round
  advanced,     // +30% per round
}

class _BreathHoldScreenState extends State<BreathHoldScreen> {
  static const int _inhaleSeconds = 4;
  static const int _exhaleSeconds = 6;
  static const int _pacedBreathsPerCycle = 3;
  static const int _recoveryBreaths = 4;

  final _service = BreathTrainingService();

  Timer? _timer;
  SessionState _state = SessionState.setup;
  BreathPhase _breathPhase = BreathPhase.idle;

  // Settings - configured in setup
  int _baseHoldDuration = 15;
  int _totalRounds = 5;
  DifficultyLevel _difficulty = DifficultyLevel.intermediate;

  // Available start durations
  static const List<int> _startDurations = [5, 10, 15, 20, 25, 30];

  // Session progress
  int _currentRound = 0;
  int _pacedBreathCount = 0;
  int _phaseSecondsRemaining = 0;
  double _phaseProgress = 0.0;
  int _totalHoldTime = 0;

  // Tick counter for smooth animation
  int _tickCount = 0;

  // Get progression increment based on difficulty
  double get _progressionIncrement {
    switch (_difficulty) {
      case DifficultyLevel.beginner:
        return 0.1; // +10% per round
      case DifficultyLevel.intermediate:
        return 0.2; // +20% per round
      case DifficultyLevel.advanced:
        return 0.3; // +30% per round
    }
  }

  // Current hold target (increases each round based on difficulty)
  int get _currentHoldTarget {
    final progressionFactor = 1.0 + (_currentRound * _progressionIncrement);
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
    final difficultyIndex = await _service.getDifficultyLevel();
    if (mounted) {
      setState(() {
        _baseHoldDuration = holdDuration;
        _totalRounds = rounds;
        _difficulty = DifficultyLevel.values[difficultyIndex];
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
      _tickCount = 0;
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
    _tickCount++;

    if (_tickCount % 10 != 0) {
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
      case SessionState.holding:
        totalPhaseMs = _currentHoldTarget * 1000;
        break;
      default:
        return;
    }

    // Calculate elapsed time including sub-second ticks for smooth animation
    final subSecondMs = (_tickCount % 10) * 100;
    final elapsedMs = totalPhaseMs - (_phaseSecondsRemaining * 1000) + subSecondMs;
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
          // Move directly to holding after final exhale
          HapticFeedback.mediumImpact();
          _state = SessionState.holding;
          _breathPhase = BreathPhase.hold;
          _phaseSecondsRemaining = _currentHoldTarget;
          _pacedBreathCount = 0;
        } else {
          _breathPhase = BreathPhase.inhale;
          _phaseSecondsRemaining = _inhaleSeconds;
        }
      }
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
      case SessionState.setup:
        return 'Setup';
      case SessionState.idle:
        return 'Ready';
      case SessionState.pacedBreathing:
        return _breathPhase == BreathPhase.inhale ? 'Breathe In' : 'Breathe Out';
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
      case SessionState.setup:
        return 'Configure your session';
      case SessionState.idle:
        return 'Tap Start to begin';
      case SessionState.pacedBreathing:
        return 'Preparing for hold';
      case SessionState.holding:
        return 'Target: ${_currentHoldTarget}s';
      case SessionState.recovery:
        return 'Recovery breath ${_pacedBreathCount + 1}/$_recoveryBreaths';
      case SessionState.complete:
        return 'Total hold time: ${_totalHoldTime}s';
    }
  }

  String get _difficultyLabel {
    switch (_difficulty) {
      case DifficultyLevel.beginner:
        return 'Beginner (+10%/round)';
      case DifficultyLevel.intermediate:
        return 'Intermediate (+20%/round)';
      case DifficultyLevel.advanced:
        return 'Advanced (+30%/round)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _state != SessionState.idle &&
                     _state != SessionState.complete &&
                     _state != SessionState.setup;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Breath Holds'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _state == SessionState.setup
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
              // Progress indicator
              _RoundProgress(
                currentRound: _currentRound,
                totalRounds: _totalRounds,
                isComplete: _state == SessionState.complete,
              ),

              const SizedBox(height: AppSpacing.lg),

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

              const SizedBox(height: AppSpacing.xl),

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

              BreathingReminder(
                isActive: isActive,
                isPostHold: _state == SessionState.recovery,
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

          // Start Duration Selection
          Text(
            'Starting Hold Duration',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.gold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _startDurations.map((duration) {
              final isSelected = _baseHoldDuration == duration;
              return ChoiceChip(
                label: Text('${duration}s'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _baseHoldDuration = duration);
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

          const SizedBox(height: AppSpacing.xl),

          // Difficulty Selection
          Text(
            'Difficulty Level',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.gold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...DifficultyLevel.values.map((level) {
            final isSelected = _difficulty == level;
            String label;
            String description;
            switch (level) {
              case DifficultyLevel.beginner:
                label = 'Beginner';
                description = 'Hold increases by 10% each round';
              case DifficultyLevel.intermediate:
                label = 'Intermediate';
                description = 'Hold increases by 20% each round';
              case DifficultyLevel.advanced:
                label = 'Advanced';
                description = 'Hold increases by 30% each round';
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                onTap: () {
                  setState(() => _difficulty = level);
                  _service.setDifficultyLevel(level.index);
                },
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gold.withValues(alpha: 0.15) : AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<DifficultyLevel>(
                        value: level,
                        groupValue: _difficulty,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _difficulty = value);
                            _service.setDifficultyLevel(value.index);
                          }
                        },
                        activeColor: AppColors.gold,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? AppColors.gold : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: AppSpacing.xl),

          // Summary
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Column(
              children: [
                Text(
                  'Session Preview',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$_totalRounds rounds: ${_baseHoldDuration}s → ${(_baseHoldDuration * (1.0 + (_totalRounds - 1) * _progressionIncrement)).round()}s',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.gold,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Start button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _state = SessionState.idle);
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
