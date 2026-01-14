import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/bow_training_provider.dart';
import '../db/database.dart';
import 'bow_training_screen.dart';
import 'bow_training_library_screen.dart';

/// Home screen for Bow Training - lightweight, no heavy data loading
class BowTrainingHomeScreen extends StatefulWidget {
  const BowTrainingHomeScreen({super.key});

  @override
  State<BowTrainingHomeScreen> createState() => _BowTrainingHomeScreenState();
}

class _BowTrainingHomeScreenState extends State<BowTrainingHomeScreen> {
  List<OlyTrainingLog> _recentLogs = [];
  UserTrainingProgressData? _userProgress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMinimalData();
  }

  /// Only load recent logs and progress - NOT the full session library
  Future<void> _loadMinimalData() async {
    final db = context.read<AppDatabase>();
    await db.ensureUserTrainingProgressExists();

    final logs = await db.getRecentOlyTrainingLogs(limit: 3);
    final progress = await db.getUserTrainingProgress();

    if (mounted) {
      setState(() {
        _recentLogs = logs;
        _userProgress = progress;
        _isLoading = false;
      });
    }
  }

  void _startQuickDrill(QuickDrillPreset preset) {
    final provider = context.read<BowTrainingProvider>();
    // Map preset to CustomSessionConfig
    final config = CustomSessionConfig(
      durationMinutes: (preset.reps * (preset.holdSeconds + preset.restSeconds) / 60).ceil(),
      ratio: _getRatioForPreset(preset),
      movementStimulus: MovementStimulus.none,
    );
    provider.startCustomSession(config);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BowTrainingScreen(),
      ),
    ).then((_) => _loadMinimalData());
  }

  HoldRestRatio _getRatioForPreset(QuickDrillPreset preset) {
    // Find closest ratio match from available options
    switch (preset) {
      case QuickDrillPreset.warmup:
        return HoldRestRatio.ratio15_45; // Light warmup with more rest
      case QuickDrillPreset.standard:
        return HoldRestRatio.ratio25_35; // Balanced hold/rest
      case QuickDrillPreset.endurance:
        return HoldRestRatio.ratio30_30; // More hold time
      case QuickDrillPreset.burnout:
        return HoldRestRatio.ratio30_30; // Max effort
    }
  }

  void _openLibrary() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BowTrainingLibraryScreen()),
    ).then((_) => _loadMinimalData());
  }

  void _openCustomTimer() {
    // TODO: Implement custom timer screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Custom timer coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bow Training'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  if (_userProgress != null) ...[
                    _ProgressCard(progress: _userProgress!),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Quick Drills section
                  _SectionHeader(title: 'Quick Drills'),
                  const SizedBox(height: AppSpacing.sm),
                  _QuickDrillsGrid(onSelect: _startQuickDrill),

                  const SizedBox(height: AppSpacing.lg),

                  // Actions row
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.timer_outlined,
                          label: 'Custom Timer',
                          sublabel: 'Build your own',
                          onTap: _openCustomTimer,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.library_books_outlined,
                          label: 'Session Library',
                          sublabel: 'Browse all (1.0-2.5)',
                          onTap: _openLibrary,
                          isHighlight: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Recent sessions
                  if (_recentLogs.isNotEmpty) ...[
                    _SectionHeader(title: 'Recent'),
                    const SizedBox(height: AppSpacing.sm),
                    ..._recentLogs.map((log) => _RecentLogTile(log: log)),
                  ],

                  // Empty state if no history
                  if (_recentLogs.isEmpty && _userProgress == null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Start with a quick drill',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// =============================================================================
// Quick Drill Presets - hardcoded, no database lookup needed
// =============================================================================

enum QuickDrillPreset {
  warmup,
  standard,
  endurance,
  burnout,
}

extension QuickDrillPresetExt on QuickDrillPreset {
  String get name {
    switch (this) {
      case QuickDrillPreset.warmup:
        return 'Warm Up';
      case QuickDrillPreset.standard:
        return 'Standard';
      case QuickDrillPreset.endurance:
        return 'Endurance';
      case QuickDrillPreset.burnout:
        return 'Burnout';
    }
  }

  String get description {
    switch (this) {
      case QuickDrillPreset.warmup:
        return '3x 10s holds';
      case QuickDrillPreset.standard:
        return '5x 15s holds';
      case QuickDrillPreset.endurance:
        return '8x 20s holds';
      case QuickDrillPreset.burnout:
        return '3x max holds';
    }
  }

  IconData get icon {
    switch (this) {
      case QuickDrillPreset.warmup:
        return Icons.wb_sunny_outlined;
      case QuickDrillPreset.standard:
        return Icons.play_arrow;
      case QuickDrillPreset.endurance:
        return Icons.trending_up;
      case QuickDrillPreset.burnout:
        return Icons.local_fire_department;
    }
  }

  int get reps {
    switch (this) {
      case QuickDrillPreset.warmup:
        return 3;
      case QuickDrillPreset.standard:
        return 5;
      case QuickDrillPreset.endurance:
        return 8;
      case QuickDrillPreset.burnout:
        return 3;
    }
  }

  int get holdSeconds {
    switch (this) {
      case QuickDrillPreset.warmup:
        return 10;
      case QuickDrillPreset.standard:
        return 15;
      case QuickDrillPreset.endurance:
        return 20;
      case QuickDrillPreset.burnout:
        return 60; // Max hold target
    }
  }

  int get restSeconds {
    switch (this) {
      case QuickDrillPreset.warmup:
        return 15;
      case QuickDrillPreset.standard:
        return 10;
      case QuickDrillPreset.endurance:
        return 8;
      case QuickDrillPreset.burnout:
        return 30;
    }
  }

  bool get isMaxHold => this == QuickDrillPreset.burnout;
}

// =============================================================================
// UI Components
// =============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.gold,
            letterSpacing: 0.5,
          ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final UserTrainingProgressData progress;

  const _ProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Center(
              child: Text(
                progress.currentLevel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Level',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                Text(
                  '${progress.totalSessionsCompleted} sessions completed',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickDrillsGrid extends StatelessWidget {
  final Function(QuickDrillPreset) onSelect;

  const _QuickDrillsGrid({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: QuickDrillPreset.values.map((preset) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 48) / 2,
          child: _QuickDrillCard(
            preset: preset,
            onTap: () => onSelect(preset),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickDrillCard extends StatelessWidget {
  final QuickDrillPreset preset;
  final VoidCallback onTap;

  const _QuickDrillCard({required this.preset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceDark,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(preset.icon, color: AppColors.gold, size: 20),
                  const Spacer(),
                  Icon(Icons.play_circle_outline,
                      color: AppColors.textMuted, size: 16),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                preset.name,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                preset.description,
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
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  final bool isHighlight;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isHighlight
          ? AppColors.gold.withOpacity(0.1)
          : AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        side: isHighlight
            ? BorderSide(color: AppColors.gold.withOpacity(0.5))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isHighlight ? AppColors.gold : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color:
                          isHighlight ? AppColors.gold : AppColors.textPrimary,
                    ),
              ),
              Text(
                sublabel,
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
}

class _RecentLogTile extends StatelessWidget {
  final OlyTrainingLog log;

  const _RecentLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(log.completedAt);
    final completionRate = log.plannedExercises > 0
        ? (log.completedExercises / log.plannedExercises * 100).round()
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
            Icon(
              _getSuggestionIcon(log.progressionSuggestion),
              color: _getSuggestionColor(log.progressionSuggestion),
              size: 16,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                log.sessionName,
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

  IconData _getSuggestionIcon(String? suggestion) {
    switch (suggestion) {
      case 'progress':
        return Icons.arrow_upward;
      case 'regress':
        return Icons.arrow_downward;
      default:
        return Icons.check_circle_outline;
    }
  }

  Color _getSuggestionColor(String? suggestion) {
    switch (suggestion) {
      case 'progress':
        return AppColors.success;
      case 'regress':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
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
