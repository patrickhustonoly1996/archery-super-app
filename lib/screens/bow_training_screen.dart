import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/bow_training_provider.dart';
import '../providers/skills_provider.dart';
import '../db/database.dart';
import '../utils/error_handler.dart';
import '../utils/unique_id.dart';
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
    final isHalfDraw = provider.phase == TimerPhase.halfDraw;
    final isBreak = provider.phase == TimerPhase.exerciseBreak;
    final phaseColor = isPrep
        ? const Color(0xFF26C6DA) // Cyan for prep/get ready
        : isHold
            ? AppColors.gold
            : isHalfDraw
                ? const Color(0xFF26C6DA) // Cyan for half draw
                : isBreak
                    ? const Color(0xFF26C6DA) // Cyan for exercise transitions
                    : AppColors.textSecondary;

    final isCustom = provider.isCustomSession;
    final isSevenTwo = provider.isSevenTwoSession;

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
                        isSevenTwo
                            ? provider.sevenTwoConfig!.displayName
                            : isCustom
                                ? provider.customConfig!.displayName
                                : (provider.activeSession?.name ?? ''),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isSevenTwo ? const Color(0xFF26C6DA) : AppColors.textSecondary,
                            ),
                      ),
                      Text(
                        isSevenTwo
                            ? provider.sevenTwoProgressText
                            : isCustom
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
                      isSevenTwo ? '7-2s Drill starting' : 'Session starting soon',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (isSevenTwo) ...[
                    // 7-2s drill phase-specific messages
                    Text(
                      isHold
                          ? 'Full draw - hold strong'
                          : isHalfDraw
                              ? 'Half draw - stay controlled'
                              : 'Recover for next block',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (provider.phase == TimerPhase.rest) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Block ${provider.sevenTwoCurrentBlock} of ${provider.sevenTwoTotalBlocks} complete',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF26C6DA),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
              isSevenTwo
                  ? 'Rep ${provider.sevenTwoCurrentRep} of ${provider.sevenTwoRepsPerBlock}'
                  : isCustom
                      ? 'Rep ${provider.customRep} of ${provider.customTotalReps}'
                      : 'Rep ${provider.currentRep} of ${provider.currentExerciseReps}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isSevenTwo ? const Color(0xFF26C6DA) : AppColors.textSecondary,
                  ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Session progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: LinearProgressIndicator(
                value: provider.sessionProgress,
                backgroundColor: AppColors.surfaceDark,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isSevenTwo ? const Color(0xFF26C6DA) : AppColors.gold,
                ),
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
    final isCustom = provider.isCustomSession;
    final sessionName = isCustom
        ? provider.customConfig?.displayName ?? 'Custom Session'
        : (provider.activeSession?.name ?? 'Session');
    final progress = (provider.sessionProgress * 100).round();
    final holdTime = provider.totalHoldSecondsActual;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.pause_circle_outline, color: AppColors.gold, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sessionName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                      Text(
                        '$progress% complete',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Progress info
            if (holdTime > 0) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: AppColors.gold, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Hold time: ${BowTrainingProvider.formatDuration(holdTime)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.gold,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Continue Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.backgroundDark,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Save partial session if meaningful progress made
            if (progress >= 20 && holdTime >= 30) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Skip to complete phase to allow saving
                    provider.forceComplete();
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save & End Early'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.surfaceBright),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  provider.cancelSession();
                  Navigator.pop(context);
                },
                child: Text(
                  'Discard Session',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
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
        // Clear "PAUSED" state indication
        if (isPaused)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Text(
                wasPausedByBackground ? 'PAUSED (app backgrounded)' : 'PAUSED',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
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
        // Show hint to cancel from paused state
        if (isPaused)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              'Tap Cancel above to end session',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ),
      ],
    );
  }
}

/// Completion view with feedback sliders
class _CompletionView extends StatefulWidget {
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
  State<_CompletionView> createState() => _CompletionViewState();
}

class _CompletionViewState extends State<_CompletionView> {
  bool _isSaving = false;

  Future<void> _saveSession(BuildContext context, BowTrainingProvider provider, bool isCustom, bool isSevenTwo) async {
    if (_isSaving) return; // Prevent double-tap

    setState(() => _isSaving = true);

    // Capture hold time before provider resets state
    final totalHoldSeconds = provider.totalHoldSecondsActual;

    try {
      final result = await ErrorHandler.run(
        context,
        () => isSevenTwo
            ? provider.completeSevenTwoSession(
                feedbackShaking: widget.feedbackShaking,
                feedbackStructure: widget.feedbackStructure,
                feedbackRest: widget.feedbackRest,
                notes: widget.notesController.text.isEmpty
                    ? null
                    : widget.notesController.text,
              )
            : isCustom
                ? provider.completeCustomSession(
                    feedbackShaking: widget.feedbackShaking,
                    feedbackStructure: widget.feedbackStructure,
                    feedbackRest: widget.feedbackRest,
                    notes: widget.notesController.text.isEmpty
                        ? null
                        : widget.notesController.text,
                  )
                : provider.completeSession(
                    feedbackShaking: widget.feedbackShaking,
                    feedbackStructure: widget.feedbackStructure,
                    feedbackRest: widget.feedbackRest,
                    notes: widget.notesController.text.isEmpty
                        ? null
                        : widget.notesController.text,
                  ),
        successMessage: 'Session logged',
        errorMessage: 'Failed to save session',
      );

      if (result.success) {
        // Award XP for bow fitness (non-blocking, don't fail if this errors)
        try {
          if (context.mounted) {
            final skillsProvider = context.read<SkillsProvider>();
            await skillsProvider.awardBowTrainingXp(
              logId: 'bow_training_${DateTime.now().millisecondsSinceEpoch}',
              totalHoldSeconds: totalHoldSeconds,
              feedbackShaking: widget.feedbackShaking,
              feedbackStructure: widget.feedbackStructure,
              feedbackRest: widget.feedbackRest,
            );
          }
        } catch (e) {
          // XP award failure shouldn't prevent session completion
          debugPrint('XP award failed: $e');
        }

        widget.onComplete();
        if (context.mounted) {
          Navigator.pop(context);
        }
      } else {
        // Save failed - reset state so user can try again
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    } catch (e) {
      // Unexpected error - reset state
      debugPrint('Unexpected error saving session: $e');
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final isCustom = provider.isCustomSession;
    final isSevenTwo = provider.isSevenTwoSession;
    final session = provider.activeSession;
    final customConfig = provider.customConfig;
    final sevenTwoConfig = provider.sevenTwoConfig;

    // For custom/7-2s sessions, we don't require activeSession
    if (!isCustom && !isSevenTwo && session == null) return const SizedBox.shrink();

    final sessionName = isSevenTwo
        ? sevenTwoConfig!.displayName
        : isCustom
            ? customConfig!.displayName
            : session!.name;

    final totalReps = isSevenTwo
        ? sevenTwoConfig!.totalReps
        : isCustom
            ? provider.customTotalReps
            : provider.totalExercises;

    final completedReps = provider.completedExercisesCount;

    // Use cyan accent for 7-2s sessions
    final accentColor = isSevenTwo ? const Color(0xFF26C6DA) : AppColors.gold;

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
                      color: accentColor,
                    ),
                textAlign: TextAlign.center,
              ),

              if (isSevenTwo || isCustom) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isSevenTwo ? '7-2s Drill' : 'Quick Session',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Stats
              _StatRow(
                label: isSevenTwo || isCustom ? 'Reps Completed' : 'Exercises Completed',
                value: '$completedReps / $totalReps',
                highlight: completionRate >= 100,
                highlightColor: accentColor,
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
                highlightColor: accentColor,
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
                value: widget.feedbackShaking,
                onChanged: widget.onShakingChanged,
                lowLabel: 'None',
                highLabel: 'Severe',
              ),

              _FeedbackSlider(
                label: 'Structure',
                value: widget.feedbackStructure,
                onChanged: widget.onStructureChanged,
                lowLabel: 'Perfect',
                highLabel: 'Collapsing',
              ),

              _FeedbackSlider(
                label: 'Rest',
                value: widget.feedbackRest,
                onChanged: widget.onRestChanged,
                lowLabel: 'Too much',
                highLabel: 'Not enough',
              ),

              const SizedBox(height: AppSpacing.xl),

              // Notes field
              TextField(
                controller: widget.notesController,
                decoration: const InputDecoration(
                  hintText: 'Add notes (optional)',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                ),
                maxLines: 3,
                enabled: !_isSaving,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Log/Save session button
              ElevatedButton(
                onPressed: _isSaving ? null : () => _saveSession(context, provider, isCustom, isSevenTwo),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.backgroundDark,
                        ),
                      )
                    : const Text('Log Session'),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Discard button
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        provider.cancelSession();
                        widget.onComplete();
                        Navigator.pop(context);
                      },
                child: Text(
                  'Discard',
                  style: TextStyle(
                    color: _isSaving ? AppColors.textMuted.withValues(alpha: 0.5) : AppColors.textMuted,
                  ),
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
  final Color highlightColor;

  const _StatRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.highlightColor = AppColors.gold,
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
                  color: highlight ? highlightColor : AppColors.textPrimary,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}
