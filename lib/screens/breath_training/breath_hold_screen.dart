import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../db/database.dart';
import '../../utils/unique_id.dart';
import '../../services/beep_service.dart';
import '../../services/breath_training_service.dart';
import '../../services/breath_hold_award_service.dart';
import '../../services/vibration_service.dart';
import '../../services/training_session_service.dart';
import '../../widgets/breathing_visualizer.dart';
import '../../widgets/breathing_reminder.dart';
import '../../widgets/breath_hold_award_badge.dart';
import '../../models/breath_hold_award.dart';
import '../../providers/breath_training_provider.dart';
import '../../providers/skills_provider.dart';

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
  prep,       // Get ready countdown before starting
  pacedBreathing,
  holding,
  recovery,
  complete,
}

/// Prep countdown duration (seconds)
const int _prepCountdownSeconds = 5;

enum DifficultyLevel {
  beginner,     // +10% per round
  intermediate, // +20% per round
  advanced,     // +30% per round
}

class _BreathHoldScreenState extends State<BreathHoldScreen>
    with WidgetsBindingObserver {
  static const int _inhaleSeconds = 4;
  static const int _exhaleSeconds = 6;
  static const int _pacedBreathsPerCycle = 3;
  static const int _recoveryBreaths = 4;

  final _service = BreathTrainingService();
  final _beepService = BeepService();
  final _vibration = VibrationService();
  final _trainingSession = TrainingSessionService();

  Timer? _timer;
  SessionState _state = SessionState.setup;
  BreathPhase _breathPhase = BreathPhase.idle;
  bool _beepsEnabled = false;
  bool _vibrationsEnabled = true; // Default ON

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
  int _bestHoldThisSession = 0; // Track best individual hold
  int _totalSessionSeconds = 0; // Total elapsed session time

  // Newly earned awards for completion display
  List<BreathHoldAwardLevel> _newAwards = [];

  // Tick counter for smooth animation
  int _tickCount = 0;

  // Track if we paused due to app backgrounding
  bool _pausedOnBackground = false;
  SessionState? _stateBeforePause;
  BreathPhase? _phaseBeforePause;

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
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App going to background - pause if session is active
      if (_state != SessionState.setup &&
          _state != SessionState.idle &&
          _state != SessionState.complete) {
        _stateBeforePause = _state;
        _phaseBeforePause = _breathPhase;
        _timer?.cancel();
        _pausedOnBackground = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      // App coming back - show resume dialog if we auto-paused
      if (_pausedOnBackground) {
        _pausedOnBackground = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showResumeDialog();
        });
      }
    }
  }

  void _showResumeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Session Paused'),
        content: const Text(
          'Your breath training was paused while the app was in the background. '
          'Ready to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endSession();
            },
            child: Text('End Session', style: TextStyle(color: AppColors.error)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeFromPause();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  void _resumeFromPause() {
    if (_stateBeforePause != null) {
      setState(() {
        _state = _stateBeforePause!;
        _breathPhase = _phaseBeforePause ?? BreathPhase.idle;
      });
      // Restart the timer
      _timer = Timer.periodic(const Duration(milliseconds: 100), _tick);
    }
  }

  void _endSession() {
    _trainingSession.endSession();
    setState(() {
      _state = SessionState.idle;
      _breathPhase = BreathPhase.idle;
      _currentRound = 0;
      _pacedBreathCount = 0;
      _totalHoldTime = 0;
    });
  }

  Future<void> _loadSettings() async {
    final holdDuration = await _service.getHoldDuration();
    final rounds = await _service.getHoldSessionRounds();
    final difficultyIndex = await _service.getDifficultyLevel();
    final beepsEnabled = await _service.getBeepsEnabled();
    final vibrationsEnabled = await _vibration.isEnabled();
    if (mounted) {
      setState(() {
        _baseHoldDuration = holdDuration;
        _totalRounds = rounds;
        _difficulty = DifficultyLevel.values[difficultyIndex];
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
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _trainingSession.endSession();
    super.dispose();
  }

  void _startSession() {
    _vibration.medium();
    _trainingSession.startSession();
    setState(() {
      _state = SessionState.prep;
      _breathPhase = BreathPhase.idle;
      _currentRound = 0;
      _pacedBreathCount = 0;
      _phaseSecondsRemaining = _prepCountdownSeconds;
      _phaseProgress = 0.0;
      _totalHoldTime = 0;
      _bestHoldThisSession = 0;
      _totalSessionSeconds = 0;
      _tickCount = 0;
      _newAwards = [];
    });
    _timer = Timer.periodic(const Duration(milliseconds: 100), _tick);
  }

  void _extendSession(int additionalRounds) {
    setState(() {
      _totalRounds += additionalRounds;
    });
    _vibration.medium();
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
            const Text('Add more rounds to your session:'),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [1, 2, 3, 5].map((rounds) {
                return ActionChip(
                  label: Text('+$rounds ${rounds == 1 ? 'round' : 'rounds'}'),
                  onPressed: () {
                    Navigator.pop(context);
                    _extendSession(rounds);
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

  void _stopSession() {
    _timer?.cancel();
    _vibration.light();
    _trainingSession.endSession();
    // Clear provider state
    context.read<BreathTrainingProvider>().reset();
    setState(() {
      _state = SessionState.idle;
      _breathPhase = BreathPhase.idle;
    });
  }

  Future<bool> _onWillPop() async {
    final isActive = _state != SessionState.idle &&
                     _state != SessionState.complete &&
                     _state != SessionState.setup &&
                     _state != SessionState.prep;
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
                _stopSession();
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
    // Mark breath training as active in provider
    final provider = context.read<BreathTrainingProvider>();
    provider.startBreathHoldSession();
    provider.pauseForNavigation();
    setState(() {
      _state = SessionState.idle;
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
      _totalSessionSeconds++; // Track total elapsed time

      switch (_state) {
        case SessionState.prep:
          _handlePrep();
          break;
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

  void _handlePrep() {
    if (_phaseSecondsRemaining <= 0) {
      _vibration.inhale(); // Cue first inhale
      if (_beepsEnabled) _beepService.playInhaleBeep();
      // Prep done - start paced breathing
      _state = SessionState.pacedBreathing;
      _breathPhase = BreathPhase.inhale;
      _phaseSecondsRemaining = _inhaleSeconds;
      _phaseProgress = 0.0;
    }
  }

  void _updateProgress() {
    int totalPhaseMs;
    switch (_state) {
      case SessionState.prep:
        totalPhaseMs = _prepCountdownSeconds * 1000;
        break;
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
      if (_breathPhase == BreathPhase.inhale) {
        _vibration.exhale(); // Cue exhale phase
        if (_beepsEnabled) _beepService.playExhaleBeep();
        _breathPhase = BreathPhase.exhale;
        _phaseSecondsRemaining = _exhaleSeconds;
      } else {
        _pacedBreathCount++;

        if (_pacedBreathCount >= _pacedBreathsPerCycle) {
          // Move directly to holding after final exhale
          _vibration.holdStart(); // Three quick buzzes + extended
          _state = SessionState.holding;
          _breathPhase = BreathPhase.hold;
          _phaseSecondsRemaining = _currentHoldTarget;
          _pacedBreathCount = 0;
        } else {
          _vibration.inhale(); // Cue inhale phase
          if (_beepsEnabled) _beepService.playInhaleBeep();
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
      _vibration.heavy();

      // Track best hold (this round's target was completed)
      if (_currentHoldTarget > _bestHoldThisSession) {
        _bestHoldThisSession = _currentHoldTarget;
      }

      _currentRound++;

      if (_currentRound >= _totalRounds) {
        // Session complete - save to database
        _state = SessionState.complete;
        _timer?.cancel();
        _trainingSession.endSession();
        _vibration.double();
        _saveSessionToDatabase();
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

  Future<void> _saveSessionToDatabase() async {
    try {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final logId = UniqueId.generate();
      await db.insertBreathTrainingLog(
        BreathTrainingLogsCompanion.insert(
          id: logId,
          sessionType: 'breathHold',
          totalHoldSeconds: Value(_totalHoldTime),
          bestHoldThisSession: Value(_bestHoldThisSession),
          rounds: Value(_currentRound),
          difficulty: Value(_difficulty.name),
          completedAt: DateTime.now(),
        ),
      );
      debugPrint('Breath hold session saved: ${_totalHoldTime}s total, ${_bestHoldThisSession}s best');

      // Award XP for breath work
      if (mounted) {
        final skillsProvider = context.read<SkillsProvider>();
        await skillsProvider.awardBreathTrainingXp(
          logId: logId,
          bestHoldSeconds: _bestHoldThisSession,
        );

        // Check for new breath hold awards
        final awardService = BreathHoldAwardService(db);
        final newAwards = await awardService.checkAndAwardAchievements(
          bestHoldSeconds: _bestHoldThisSession,
          sessionLogId: logId,
        );
        if (newAwards.isNotEmpty && mounted) {
          setState(() {
            _newAwards = newAwards;
          });
        }
      }
    } catch (e) {
      debugPrint('Error saving breath hold session: $e');
    }
  }

  void _handleRecovery() {
    if (_phaseSecondsRemaining <= 0) {
      if (_breathPhase == BreathPhase.inhale) {
        _vibration.exhale(); // Cue exhale phase
        if (_beepsEnabled) _beepService.playExhaleBeep();
        _breathPhase = BreathPhase.exhale;
        _phaseSecondsRemaining = _exhaleSeconds;
      } else {
        _pacedBreathCount++;

        if (_pacedBreathCount >= _recoveryBreaths) {
          // Move directly to next hold (skip preparation breaths)
          _vibration.holdStart(); // Three quick buzzes + extended
          _state = SessionState.holding;
          _breathPhase = BreathPhase.hold;
          _phaseSecondsRemaining = _currentHoldTarget;
          _pacedBreathCount = 0;
        } else {
          _vibration.inhale(); // Cue inhale phase
          if (_beepsEnabled) _beepService.playInhaleBeep();
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
      case SessionState.prep:
        return 'Get Ready';
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
      case SessionState.prep:
        return 'Session starting soon';
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

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _state != SessionState.idle &&
                     _state != SessionState.complete &&
                     _state != SessionState.setup;

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
              if (_currentRound > 0 || _state == SessionState.complete || isActive)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Column(
                    children: [
                      Row(
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
                            label: 'Session',
                            value: _formatTime(_totalSessionSeconds),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.md),

              // Extension button (during active session)
              if (isActive)
                OutlinedButton.icon(
                  onPressed: _showExtendDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Rounds'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold),
                  ),
                ),

              // New awards display (on completion)
              if (_state == SessionState.complete && _newAwards.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _NewAwardsDisplay(awards: _newAwards),
              ],

              const SizedBox(height: AppSpacing.md),

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

          // Feedback toggles
          Text(
            'Session Feedback',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.gold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Column(
              children: [
                _FeedbackToggle(
                  icon: Icons.vibration,
                  label: 'Vibrations',
                  subtitle: 'Haptic feedback for phase changes',
                  value: _vibrationsEnabled,
                  onChanged: (value) async {
                    setState(() => _vibrationsEnabled = value);
                    await _vibration.setEnabled(value);
                  },
                ),
                const Divider(height: AppSpacing.lg),
                _FeedbackToggle(
                  icon: Icons.volume_up,
                  label: 'Audio Beeps',
                  subtitle: 'Sound cues for inhale/exhale',
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
          ),

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
                      ? AppColors.gold.withValues(alpha: 0.3)
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

class _FeedbackToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FeedbackToggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: value ? AppColors.gold : AppColors.textMuted, size: 24),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.gold,
        ),
      ],
    );
  }
}

/// Flowing celebration display for newly earned breath hold awards
class _NewAwardsDisplay extends StatefulWidget {
  final List<BreathHoldAwardLevel> awards;

  const _NewAwardsDisplay({required this.awards});

  @override
  State<_NewAwardsDisplay> createState() => _NewAwardsDisplayState();
}

class _NewAwardsDisplayState extends State<_NewAwardsDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _flowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _flowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sort awards by seconds to show highest first
    final sortedAwards = List<BreathHoldAwardLevel>.from(widget.awards)
      ..sort((a, b) => b.seconds.compareTo(a.seconds));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Header with flowing vapor effect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _FlowingVaporParticles(progress: _flowAnimation.value),
                      const SizedBox(width: 8),
                      Text(
                        'NEW ${sortedAwards.length > 1 ? 'AWARDS' : 'AWARD'}',
                        style: TextStyle(
                          fontFamily: AppFonts.pixel,
                          fontSize: 14,
                          color: AppColors.gold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FlowingVaporParticles(
                        progress: _flowAnimation.value,
                        mirror: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Award badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: sortedAwards.map((award) {
                      return BreathHoldAwardBadge(
                        level: award,
                        isCompact: sortedAwards.length > 2,
                        showDetails: sortedAwards.length <= 2,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Subtle flowing vapor particles animation
class _FlowingVaporParticles extends StatelessWidget {
  final double progress;
  final bool mirror;

  const _FlowingVaporParticles({
    required this.progress,
    this.mirror = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _FlowingVaporPainter(
        progress: progress,
        mirror: mirror,
        color: AppColors.gold,
      ),
    );
  }
}

class _FlowingVaporPainter extends CustomPainter {
  final double progress;
  final bool mirror;
  final Color color;

  _FlowingVaporPainter({
    required this.progress,
    required this.mirror,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Mirror transformation
    if (mirror) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    final paint = Paint()
      ..color = color.withValues(alpha: 0.4 + 0.3 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Three flowing vapor wisps that animate
    final offset1 = progress * 0.2;
    final offset2 = progress * 0.15;
    final offset3 = progress * 0.25;

    // First wisp
    final path1 = Path()
      ..moveTo(w * 0.3, h * (0.8 - offset1))
      ..quadraticBezierTo(
        w * 0.15,
        h * (0.5 - offset1),
        w * (0.35 + offset1 * 0.5),
        h * (0.25 - offset1),
      );
    canvas.drawPath(path1, paint..color = color.withValues(alpha: 0.3 + 0.2 * progress));

    // Second wisp (center, most prominent)
    final path2 = Path()
      ..moveTo(w * 0.5, h * (0.85 - offset2))
      ..quadraticBezierTo(
        w * 0.6,
        h * (0.55 - offset2),
        w * (0.45 - offset2 * 0.3),
        h * (0.2 - offset2),
      );
    canvas.drawPath(path2, paint..color = color.withValues(alpha: 0.5 + 0.3 * progress));

    // Third wisp
    final path3 = Path()
      ..moveTo(w * 0.7, h * (0.75 - offset3))
      ..quadraticBezierTo(
        w * 0.8,
        h * (0.45 - offset3),
        w * (0.6 + offset3 * 0.4),
        h * (0.15 - offset3),
      );
    canvas.drawPath(path3, paint..color = color.withValues(alpha: 0.25 + 0.15 * progress));

    // Small floating dots
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.4 * progress)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(w * (0.4 + offset1 * 0.5), h * (0.35 - offset1 * 0.5)),
      1.5,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(w * (0.55 - offset2 * 0.3), h * (0.4 - offset2 * 0.4)),
      1.0,
      dotPaint..color = color.withValues(alpha: 0.3 * progress),
    );
  }

  @override
  bool shouldRepaint(covariant _FlowingVaporPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
