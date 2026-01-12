import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/bow_training_provider.dart';
import '../db/database.dart';
import 'bow_training_intro_screen.dart';

/// Main OLY bow training screen
/// Now shows the intro screen by default for quick-start access
class BowTrainingScreen extends StatefulWidget {
  final OlySessionTemplate? initialSession;

  const BowTrainingScreen({super.key, this.initialSession});

  @override
  State<BowTrainingScreen> createState() => _BowTrainingScreenState();
}

class _BowTrainingScreenState extends State<BowTrainingScreen> {
  final TextEditingController _notesController = TextEditingController();

  // Feedback slider values
  int _feedbackShaking = 5;
  int _feedbackStructure = 5;
  int _feedbackRest = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BowTrainingProvider>();
      provider.loadData();

      // Auto-start if session provided
      if (widget.initialSession != null && !provider.isActive) {
        provider.startSession(widget.initialSession!);
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop(BowTrainingProvider provider) async {
    if (provider.isActive) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Leave Training?'),
          content: const Text('Your session progress will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () {
                provider.cancelSession();
                Navigator.pop(context, true);
              },
              child: Text(
                'Leave',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  void _resetFeedback() {
    _feedbackShaking = 5;
    _feedbackStructure = 5;
    _feedbackRest = 5;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BowTrainingProvider>(
      builder: (context, provider, _) {
        // Show intro screen if no active session (quick-start flow)
        if (!provider.isActive && provider.phase != TimerPhase.complete) {
          return const BowTrainingIntroScreen();
        }

        // Show completion screen with feedback
        if (provider.phase == TimerPhase.complete) {
          return _CompletionView(
            provider: provider,
            notesController: _notesController,
            feedbackShaking: _feedbackShaking,
            feedbackStructure: _feedbackStructure,
            feedbackRest: _feedbackRest,
            onShakingChanged: (v) => setState(() => _feedbackShaking = v),
            onStructureChanged: (v) => setState(() => _feedbackStructure = v),
            onRestChanged: (v) => setState(() => _feedbackRest = v),
            onComplete: () {
              _notesController.clear();
              _resetFeedback();
            },
          );
        }

        // Show active timer
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await _onWillPop(provider);
            if (shouldPop && context.mounted) {
              Navigator.pop(context);
            }
          },
          child: _ActiveTimerView(provider: provider),
        );
      },
    );
  }
}

/// Active timer view - shows current exercise and countdown
class _ActiveTimerView extends StatelessWidget {
  final BowTrainingProvider provider;

  const _ActiveTimerView({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isHold = provider.phase == TimerPhase.hold;
    final isBreak = provider.phase == TimerPhase.exerciseBreak;
    final phaseColor = isHold
        ? AppColors.gold
        : isBreak
            ? const Color(0xFF26C6DA) // Cyan for exercise transitions
            : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => _showCancelDialog(context, provider),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        provider.activeSession?.name ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      Text(
                        'Exercise ${provider.currentExerciseNumber} of ${provider.totalExercises}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),

            // Exercise info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  Text(
                    provider.currentExerciseName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (provider.currentExerciseDetails != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      provider.currentExerciseDetails!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            const Spacer(),

            // Phase indicator
            Text(
              provider.phaseDisplayName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: phaseColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Countdown display
            _CountdownDisplay(
              time: provider.formattedTime,
              progress: provider.phaseProgress,
              color: phaseColor,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Rep progress
            Text(
              'Rep ${provider.currentRep} of ${provider.currentExerciseReps}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Session progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: LinearProgressIndicator(
                value: provider.sessionProgress,
                backgroundColor: AppColors.surfaceDark,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),

            const Spacer(),

            // Controls
            _TimerControls(provider: provider),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, BowTrainingProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Cancel Session?'),
        content: const Text('Your progress will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              provider.cancelSession();
              Navigator.pop(context);
            },
            child: Text(
              'Cancel Session',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownDisplay extends StatelessWidget {
  final String time;
  final double progress;
  final Color color;

  const _CountdownDisplay({
    required this.time,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 240,
          height: 240,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: AppColors.surfaceDark,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TimerControls extends StatelessWidget {
  final BowTrainingProvider provider;

  const _TimerControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isPaused = provider.timerState == TimerState.paused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: provider.skipPhase,
          icon: const Icon(Icons.skip_next),
          iconSize: 32,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.lg),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: isPaused ? provider.resumeTimer : provider.pauseTimer,
            icon: Icon(
              isPaused ? Icons.play_arrow : Icons.pause,
              color: AppColors.backgroundDark,
            ),
            iconSize: 40,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        const SizedBox(width: 48),
      ],
    );
  }
}

/// Completion view with feedback sliders
class _CompletionView extends StatelessWidget {
  final BowTrainingProvider provider;
  final TextEditingController notesController;
  final int feedbackShaking;
  final int feedbackStructure;
  final int feedbackRest;
  final ValueChanged<int> onShakingChanged;
  final ValueChanged<int> onStructureChanged;
  final ValueChanged<int> onRestChanged;
  final VoidCallback onComplete;

  const _CompletionView({
    required this.provider,
    required this.notesController,
    required this.feedbackShaking,
    required this.feedbackStructure,
    required this.feedbackRest,
    required this.onShakingChanged,
    required this.onStructureChanged,
    required this.onRestChanged,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final session = provider.activeSession;
    if (session == null) return const SizedBox.shrink();

    final completionRate = provider.totalExercises > 0
        ? (provider.completedExercisesCount / provider.totalExercises * 100)
            .round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Complete'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success icon
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 64,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Session name
              Text(
                session.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.gold,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Stats
              _StatRow(
                label: 'Exercises Completed',
                value:
                    '${provider.completedExercisesCount} / ${provider.totalExercises}',
                highlight: completionRate >= 100,
              ),
              _StatRow(
                label: 'Total Hold Time',
                value: BowTrainingProvider.formatDuration(
                    provider.totalHoldSecondsActual),
              ),
              _StatRow(
                label: 'Completion',
                value: '$completionRate%',
                highlight: completionRate >= 100,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Feedback section
              Text(
                'How did it feel?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),

              _FeedbackSlider(
                label: 'Shaking',
                value: feedbackShaking,
                onChanged: onShakingChanged,
                lowLabel: 'None',
                highLabel: 'Severe',
              ),

              _FeedbackSlider(
                label: 'Structure',
                value: feedbackStructure,
                onChanged: onStructureChanged,
                lowLabel: 'Perfect',
                highLabel: 'Collapsing',
              ),

              _FeedbackSlider(
                label: 'Rest',
                value: feedbackRest,
                onChanged: onRestChanged,
                lowLabel: 'Too much',
                highLabel: 'Not enough',
              ),

              const SizedBox(height: AppSpacing.xl),

              // Notes field
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  hintText: 'Add notes (optional)',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Log session button
              ElevatedButton(
                onPressed: () async {
                  await provider.completeSession(
                    feedbackShaking: feedbackShaking,
                    feedbackStructure: feedbackStructure,
                    feedbackRest: feedbackRest,
                    notes: notesController.text.isEmpty
                        ? null
                        : notesController.text,
                  );
                  onComplete();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Log Session'),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Discard button
              TextButton(
                onPressed: () {
                  provider.cancelSession();
                  onComplete();
                  Navigator.pop(context);
                },
                child: Text(
                  'Discard',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackSlider extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String lowLabel;
  final String highLabel;

  const _FeedbackSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.lowLabel,
    required this.highLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '$value',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _getValueColor(value),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _getValueColor(value),
              inactiveTrackColor: AppColors.surfaceDark,
              thumbColor: _getValueColor(value),
              overlayColor: _getValueColor(value).withOpacity(0.2),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lowLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              Text(
                highLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getValueColor(int value) {
    if (value <= 3) return AppColors.success;
    if (value <= 6) return AppColors.gold;
    return AppColors.error;
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: highlight ? AppColors.gold : AppColors.textPrimary,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}
