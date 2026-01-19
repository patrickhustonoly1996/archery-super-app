import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/bow_training_provider.dart';
import '../providers/skills_provider.dart';
import '../db/database.dart';
import '../utils/error_handler.dart';
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
    final isPrep = provider.phase == TimerPhase.prep;
    final isHold = provider.phase == TimerPhase.hold;
    final isBreak = provider.phase == TimerPhase.exerciseBreak;
    final phaseColor = isPrep
        ? const Color(0xFF26C6DA) // Cyan for prep/get ready
        : isHold
            ? AppColors.gold
            : isBreak
                ? const Color(0xFF26C6DA) // Cyan for exercise transitions
                : AppColors.textSecondary;

    final isCustom = provider.isCustomSession;

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
                        isCustom
                            ? provider.customConfig!.displayName
                            : (provider.activeSession?.name ?? ''),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      Text(
                        isCustom
                            ? 'Quick Session'
                            : 'Exercise ${provider.currentExerciseNumber} of ${provider.totalExercises}',
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

            // Exercise info / Movement cue
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  if (isPrep) ...[
                    // Show prep message
                    Text(
                      'Prepare to draw',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Session starting soon',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (isCustom) ...[
                    // Show movement cue for custom sessions
                    if (provider.movementCue != null && isHold) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          provider.movementCue!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w500,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ] else ...[
                      Text(
                        isHold ? 'Hold steady' : 'Recover',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ] else ...[
                    // Standard OLY session exercise info
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
              isCustom
                  ? 'Rep ${provider.customRep} of ${provider.customTotalReps}'
                  : 'Rep ${provider.currentRep} of ${provider.currentExerciseReps}',
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
    final wasPausedByBackground = provider.wasPausedByBackground;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Subtle message when paused by backgrounding
        if (isPaused && wasPausedByBackground)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              'Paused (app backgrounded)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ),
        Row(
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
        ),
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
    final isCustom = provider.isCustomSession;
    final session = provider.activeSession;
    final customConfig = provider.customConfig;

    // For custom sessions, we don't require activeSession
    if (!isCustom && session == null) return const SizedBox.shrink();

    final sessionName = isCustom
        ? customConfig!.displayName
        : session!.name;

    final totalReps = isCustom
        ? provider.customTotalReps
        : provider.totalExercises;

    final completedReps = provider.completedExercisesCount;

    final completionRate = totalReps > 0
        ? (completedReps / totalReps * 100).round()
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
                sessionName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.gold,
                    ),
                textAlign: TextAlign.center,
              ),

              if (isCustom) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Quick Session',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Stats
              _StatRow(
                label: isCustom ? 'Reps Completed' : 'Exercises Completed',
                value: '$completedReps / $totalReps',
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

              // Feedback section - shown for all session types
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

              // Log/Save session button
              ElevatedButton(
                onPressed: () async {
                  // Capture hold time before provider resets state
                  final totalHoldSeconds = provider.totalHoldSecondsActual;

                  final result = await ErrorHandler.run(
                    context,
                    () => isCustom
                        ? provider.completeCustomSession(
                            feedbackShaking: feedbackShaking,
                            feedbackStructure: feedbackStructure,
                            feedbackRest: feedbackRest,
                            notes: notesController.text.isEmpty
                                ? null
                                : notesController.text,
                          )
                        : provider.completeSession(
                            feedbackShaking: feedbackShaking,
                            feedbackStructure: feedbackStructure,
                            feedbackRest: feedbackRest,
                            notes: notesController.text.isEmpty
                                ? null
                                : notesController.text,
                          ),
                    successMessage: 'Session logged',
                    errorMessage: 'Failed to save session',
                  );
                  if (result.success) {
                    // Award XP for bow fitness
                    if (context.mounted) {
                      final skillsProvider = context.read<SkillsProvider>();
                      await skillsProvider.awardBowTrainingXp(
                        logId: 'bow_training_${DateTime.now().millisecondsSinceEpoch}',
                        totalHoldSeconds: totalHoldSeconds,
                        feedbackShaking: feedbackShaking,
                        feedbackStructure: feedbackStructure,
                        feedbackRest: feedbackRest,
                      );
                    }
                    onComplete();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
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
              overlayColor: _getValueColor(value).withValues(alpha: 0.2),
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
