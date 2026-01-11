import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/bow_training_provider.dart';
import '../db/database.dart';
import 'bow_training_presets_screen.dart';

/// Main bow training timer screen
class BowTrainingScreen extends StatefulWidget {
  final BowTrainingPreset? initialPreset;

  const BowTrainingScreen({super.key, this.initialPreset});

  @override
  State<BowTrainingScreen> createState() => _BowTrainingScreenState();
}

class _BowTrainingScreenState extends State<BowTrainingScreen> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BowTrainingProvider>();
      provider.loadPresets();

      // Auto-start if preset provided
      if (widget.initialPreset != null && !provider.isActive) {
        provider.startSession(widget.initialPreset!);
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop(BowTrainingProvider provider) async {
    // If timer is active, show confirmation dialog
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

  @override
  Widget build(BuildContext context) {
    return Consumer<BowTrainingProvider>(
      builder: (context, provider, _) {
        // Show preset selection if no active session
        if (!provider.isActive && provider.phase != TimerPhase.complete) {
          return _PresetSelectionView(provider: provider);
        }

        // Show completion screen
        if (provider.phase == TimerPhase.complete) {
          return _CompletionView(
            provider: provider,
            notesController: _notesController,
          );
        }

        // Show active timer with back button handling
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

/// Preset selection view
class _PresetSelectionView extends StatelessWidget {
  final BowTrainingProvider provider;

  const _PresetSelectionView({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bow Training'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BowTrainingPresetsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: provider.presets.isEmpty
            ? _EmptyPresetsView()
            : _PresetsList(provider: provider),
      ),
    );
  }
}

class _EmptyPresetsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No presets available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BowTrainingPresetsScreen(),
                ),
              );
            },
            child: const Text('Create Preset'),
          ),
        ],
      ),
    );
  }
}

class _PresetsList extends StatelessWidget {
  final BowTrainingProvider provider;

  const _PresetsList({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Recent sessions header
        if (provider.recentLogs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              'Recent Sessions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          ...provider.recentLogs.take(3).map((log) => _RecentLogCard(log: log)),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Presets header
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            'Training Presets',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),

        // Preset cards
        ...provider.presets.map((preset) => _PresetCard(
              preset: preset,
              onTap: () => provider.startSession(preset),
            )),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  final BowTrainingPreset preset;
  final VoidCallback onTap;

  const _PresetCard({
    required this.preset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalDuration = BowTrainingProvider.calculateTotalDuration(preset);
    final durationStr = BowTrainingProvider.formatDuration(totalDuration);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: AppColors.surfaceDark,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  preset.isDefault ? Icons.timer : Icons.timer_outlined,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.name,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${preset.holdSeconds}s hold / ${preset.restSeconds}s rest / ${preset.sets} sets',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    durationStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.gold,
                        ),
                  ),
                  const Icon(
                    Icons.play_arrow,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentLogCard extends StatelessWidget {
  final BowTrainingLog log;

  const _RecentLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(log.completedAt);
    final completionRate = log.plannedSets > 0
        ? (log.completedSets / log.plannedSets * 100).round()
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      color: AppColors.surfaceLight.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                log.presetName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Text(
              '$completionRate%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.gold,
                  ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              dateStr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

/// Active timer view
class _ActiveTimerView extends StatelessWidget {
  final BowTrainingProvider provider;

  const _ActiveTimerView({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isHold = provider.phase == TimerPhase.hold;
    final phaseColor = isHold ? AppColors.gold : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with cancel button
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
                  Text(
                    provider.activePreset?.name ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(width: 60), // Balance
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

            // Main countdown display
            _CountdownDisplay(
              time: provider.formattedTime,
              progress: provider.phaseProgress,
              color: phaseColor,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Set progress
            Text(
              'Set ${provider.currentSet} of ${provider.activePreset?.sets ?? 0}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Progress bar
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
        // Progress ring
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
        // Time display
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
        // Skip button
        IconButton(
          onPressed: provider.skipPhase,
          icon: const Icon(Icons.skip_next),
          iconSize: 32,
          color: AppColors.textMuted,
        ),

        const SizedBox(width: AppSpacing.lg),

        // Play/Pause button
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

        // Empty space for balance
        const SizedBox(width: 48),
      ],
    );
  }
}

/// Completion view
class _CompletionView extends StatelessWidget {
  final BowTrainingProvider provider;
  final TextEditingController notesController;

  const _CompletionView({
    required this.provider,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    final preset = provider.activePreset;
    if (preset == null) return const SizedBox.shrink();

    final completionRate = preset.sets > 0
        ? (provider.completedSets / preset.sets * 100).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Complete'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
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

              // Preset name
              Text(
                preset.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.gold,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Stats - use actual tracked values
              _StatRow(
                label: 'Completed Sets',
                value: '${provider.completedSets} / ${preset.sets}',
                highlight: completionRate >= 100,
              ),
              _StatRow(
                label: 'Total Hold Time',
                value: BowTrainingProvider.formatDuration(
                  provider.totalHoldSecondsActual,
                ),
              ),
              _StatRow(
                label: 'Completion',
                value: '$completionRate%',
                highlight: completionRate >= 100,
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

              const Spacer(),

              // Log session button
              ElevatedButton(
                onPressed: () async {
                  await provider.completeSession(
                    notes: notesController.text.isEmpty
                        ? null
                        : notesController.text,
                  );
                  notesController.clear();
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
                  notesController.clear();
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
