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

  void _startQuickDrill(PresetTrainingBlock preset) {
    final provider = context.read<BowTrainingProvider>();
    // Use preset's built-in configuration
    final config = CustomSessionConfig(
      durationMinutes: preset.durationMinutes,
      ratio: preset.ratio,
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

  void _openLibrary() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BowTrainingLibraryScreen()),
    ).then((_) => _loadMinimalData());
  }

  void _openCustomTimer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _CustomSessionBuilder(
        onStart: (config) {
          Navigator.pop(context);
          final provider = context.read<BowTrainingProvider>();
          provider.startCustomSession(config);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BowTrainingScreen()),
          ).then((_) => _loadMinimalData());
        },
      ),
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

                  // Preset Training Blocks section
                  _SectionHeader(title: 'Preset Training Blocks'),
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
                            'Select a training block',
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
// Preset Training Blocks - Patrick's specific training configurations
// =============================================================================

enum PresetTrainingBlock {
  patricksWarmup,
  standardFitness,
  introVolume,
  introFitness,
  beginnersIntro,
}

extension PresetTrainingBlockExt on PresetTrainingBlock {
  String get name {
    switch (this) {
      case PresetTrainingBlock.patricksWarmup:
        return "Patrick's Warm Up";
      case PresetTrainingBlock.standardFitness:
        return 'Standard Fitness';
      case PresetTrainingBlock.introVolume:
        return 'Introduction Volume';
      case PresetTrainingBlock.introFitness:
        return 'Introduction Fitness';
      case PresetTrainingBlock.beginnersIntro:
        return 'Beginners Intro';
    }
  }

  String get description {
    switch (this) {
      case PresetTrainingBlock.patricksWarmup:
        return '5 min @ 30:30';
      case PresetTrainingBlock.standardFitness:
        return '10 min @ 20:40 (60s break)';
      case PresetTrainingBlock.introVolume:
        return '5 min @ 15:45';
      case PresetTrainingBlock.introFitness:
        return '10 min @ 15:45 (45s break)';
      case PresetTrainingBlock.beginnersIntro:
        return 'Structured intro session';
    }
  }

  IconData get icon {
    switch (this) {
      case PresetTrainingBlock.patricksWarmup:
        return Icons.wb_sunny_outlined;
      case PresetTrainingBlock.standardFitness:
        return Icons.fitness_center;
      case PresetTrainingBlock.introVolume:
        return Icons.start;
      case PresetTrainingBlock.introFitness:
        return Icons.directions_run;
      case PresetTrainingBlock.beginnersIntro:
        return Icons.school;
    }
  }

  int get durationMinutes {
    switch (this) {
      case PresetTrainingBlock.patricksWarmup:
        return 5;
      case PresetTrainingBlock.standardFitness:
        return 10;
      case PresetTrainingBlock.introVolume:
        return 5;
      case PresetTrainingBlock.introFitness:
        return 10;
      case PresetTrainingBlock.beginnersIntro:
        return 15; // Structured session ~15 min
    }
  }

  int get holdSeconds {
    switch (this) {
      case PresetTrainingBlock.patricksWarmup:
        return 30;
      case PresetTrainingBlock.standardFitness:
        return 20;
      case PresetTrainingBlock.introVolume:
        return 15;
      case PresetTrainingBlock.introFitness:
        return 15;
      case PresetTrainingBlock.beginnersIntro:
        return 10; // Starting hold for beginners
    }
  }

  int get restSeconds {
    switch (this) {
      case PresetTrainingBlock.patricksWarmup:
        return 30;
      case PresetTrainingBlock.standardFitness:
        return 40;
      case PresetTrainingBlock.introVolume:
        return 45;
      case PresetTrainingBlock.introFitness:
        return 45;
      case PresetTrainingBlock.beginnersIntro:
        return 45;
    }
  }

  /// Extra break at halfway point (0 = no break)
  int get halfwayBreakSeconds {
    switch (this) {
      case PresetTrainingBlock.patricksWarmup:
        return 0;
      case PresetTrainingBlock.standardFitness:
        return 60;
      case PresetTrainingBlock.introVolume:
        return 0;
      case PresetTrainingBlock.introFitness:
        return 45;
      case PresetTrainingBlock.beginnersIntro:
        return 60; // Break after first part
    }
  }

  /// Whether this block is a structured multi-exercise session
  bool get isStructuredSession => this == PresetTrainingBlock.beginnersIntro;

  /// Whether this block supports alternative ratios
  bool get hasAlternativeRatios => this == PresetTrainingBlock.standardFitness;

  /// Alternative hold:rest ratios for Standard Fitness (35:25, 30:30)
  List<String> get alternativeRatios => ['35:25', '30:30'];

  HoldRestRatio get ratio {
    switch (this) {
      case PresetTrainingBlock.patricksWarmup:
        return HoldRestRatio.ratio30_30;
      case PresetTrainingBlock.standardFitness:
        return HoldRestRatio.ratio20_40;
      case PresetTrainingBlock.introVolume:
        return HoldRestRatio.ratio15_45;
      case PresetTrainingBlock.introFitness:
        return HoldRestRatio.ratio15_45;
      case PresetTrainingBlock.beginnersIntro:
        return HoldRestRatio.ratio15_45; // Default, actual session has mixed ratios
    }
  }

  /// Get the structured exercise sequence for Beginners Intro
  /// Returns list of (holdSeconds, restSeconds, reps) tuples
  List<(int, int, int)> get exerciseSequence {
    if (this != PresetTrainingBlock.beginnersIntro) return [];
    return [
      (10, 45, 3),  // 10:45 x3
      (12, 50, 2),  // 12:50 x2
      // 60s break happens here
      (10, 30, 2),  // 10:30 x2
      (15, 60, 3),  // 15:60 x3
    ];
  }
}

// Legacy alias for compatibility
typedef QuickDrillPreset = PresetTrainingBlock;

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

// =============================================================================
// Custom Session Builder - Bottom sheet for custom timer configuration
// =============================================================================

class _CustomSessionBuilder extends StatefulWidget {
  final Function(CustomSessionConfig) onStart;

  const _CustomSessionBuilder({required this.onStart});

  @override
  State<_CustomSessionBuilder> createState() => _CustomSessionBuilderState();
}

class _CustomSessionBuilderState extends State<_CustomSessionBuilder> {
  int _durationMinutes = 10;
  HoldRestRatio _selectedRatio = HoldRestRatio.ratio30_30;
  MovementStimulus _selectedStimulus = MovementStimulus.none;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Custom Timer',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.gold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Duration slider
          Text(
            'Duration: $_durationMinutes min',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          Slider(
            value: _durationMinutes.toDouble(),
            min: 5,
            max: 30,
            divisions: 5,
            activeColor: AppColors.gold,
            inactiveColor: AppColors.gold.withOpacity(0.3),
            onChanged: (value) => setState(() => _durationMinutes = value.toInt()),
          ),
          const SizedBox(height: AppSpacing.md),

          // Hold:Rest ratio
          Text(
            'Hold:Rest Ratio',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: HoldRestRatio.all.map((ratio) {
              final isSelected = ratio == _selectedRatio;
              return ChoiceChip(
                label: Text(ratio.label),
                selected: isSelected,
                selectedColor: AppColors.gold,
                backgroundColor: AppColors.surfaceDark,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.backgroundDark : AppColors.textMuted,
                ),
                onSelected: (_) => setState(() => _selectedRatio = ratio),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Movement stimulus
          Text(
            'Movement Stimulus',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: MovementStimulus.values.map((stimulus) {
              final isSelected = stimulus == _selectedStimulus;
              return ChoiceChip(
                label: Text(stimulus.name.toUpperCase()),
                selected: isSelected,
                selectedColor: AppColors.gold,
                backgroundColor: AppColors.surfaceDark,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.backgroundDark : AppColors.textMuted,
                ),
                onSelected: (_) => setState(() => _selectedStimulus = stimulus),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onStart(CustomSessionConfig(
                  durationMinutes: _durationMinutes,
                  ratio: _selectedRatio,
                  movementStimulus: _selectedStimulus,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.backgroundDark,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: const Text('START SESSION'),
            ),
          ),
        ],
      ),
    );
  }
}
