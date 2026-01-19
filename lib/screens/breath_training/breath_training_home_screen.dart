import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/breath_training_service.dart';
import '../../db/database.dart';
import 'paced_breathing_screen.dart';
import 'breath_hold_screen.dart';
import 'patrick_breath_screen.dart';

/// Main entry point for breath training
/// User selects between three session types
class BreathTrainingHomeScreen extends StatefulWidget {
  const BreathTrainingHomeScreen({super.key});

  @override
  State<BreathTrainingHomeScreen> createState() =>
      _BreathTrainingHomeScreenState();
}

class _BreathTrainingHomeScreenState extends State<BreathTrainingHomeScreen> {
  final _service = BreathTrainingService();
  int _bestExhale = 0;
  int _holdDuration = 15;
  int _totalSessions = 0;
  int _thisWeekSessions = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bestExhale = await _service.getPatrickBestExhale();
    final holdDuration = await _service.getHoldDuration();

    // Load session stats
    int totalSessions = 0;
    int thisWeekSessions = 0;
    try {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final allLogs = await db.getAllBreathTrainingLogs();
      totalSessions = allLogs.length;

      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      thisWeekSessions = allLogs.where((log) => log.completedAt.isAfter(oneWeekAgo)).length;
    } catch (e) {
      // Database not available
    }

    if (mounted) {
      setState(() {
        _bestExhale = bestExhale;
        _holdDuration = holdDuration;
        _totalSessions = totalSessions;
        _thisWeekSessions = thisWeekSessions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breath Training'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with stats row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calmness and Focus',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.gold,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Nasal breathing only. Always.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Quick stats
                  if (_totalSessions > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$_thisWeekSessions',
                            style: TextStyle(
                              fontFamily: AppFonts.mono,
                              fontSize: 20,
                              color: AppColors.gold,
                            ),
                          ),
                          Text(
                            'this week',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Session type cards - expanded with more details
              _SessionCard(
                icon: Icons.air,
                title: 'Paced Breathing',
                description: 'Breathe in for 4, out for 6. Calming rhythm that activates the parasympathetic nervous system.',
                benefit: 'Best for: Pre-competition calm, daily practice',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PacedBreathingScreen(),
                    ),
                  );
                  _loadSettings();
                },
              ),

              const SizedBox(height: AppSpacing.md),

              _SessionCard(
                icon: Icons.pause_circle_outline,
                title: 'Breath Holds',
                description: 'Progressive exhale holds starting at ${_holdDuration}s. Builds CO2 tolerance for better oxygen delivery.',
                benefit: 'Best for: Improving breath control under pressure',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BreathHoldScreen(),
                    ),
                  );
                  _loadSettings();
                },
              ),

              const SizedBox(height: AppSpacing.md),

              _SessionCard(
                icon: Icons.timer_outlined,
                title: 'Long Exhale Test',
                subtitle: 'The Patrick Breath',
                description: _bestExhale > 0
                    ? 'Test your controlled exhale duration. Personal best: ${_bestExhale}s'
                    : 'Test how long you can slowly exhale through your nose. Track your progress.',
                benefit: 'Best for: Measuring progress, building awareness',
                highlight: true,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PatrickBreathScreen(),
                    ),
                  );
                  _loadSettings();
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // Tip of the day
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.gold,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tip',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'During competition, a slow exhale before release helps steady your shot. Practice this rhythm daily.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Info footer
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Breathe through your nose at all times. This is the foundation of the Buteyko method.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _SettingsSheet(
        service: _service,
        onSettingsChanged: _loadSettings,
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String description;
  final String? benefit;
  final VoidCallback onTap;
  final bool highlight;

  const _SessionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.description,
    this.benefit,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight
          ? AppColors.gold.withValues(alpha: 0.1)
          : AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: highlight
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.5),
                    width: 1,
                  ),
                )
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  icon,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gold,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (benefit != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        benefit!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  final BreathTrainingService service;
  final VoidCallback onSettingsChanged;

  const _SettingsSheet({
    required this.service,
    required this.onSettingsChanged,
  });

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  int _holdDuration = 15;
  int _rounds = 5;
  int _difficulty = 1; // 0=beginner, 1=intermediate, 2=advanced

  static const List<String> _difficultyLabels = ['Beginner', 'Intermediate', 'Advanced'];
  static const List<String> _difficultyDescriptions = ['+10%/round', '+20%/round', '+30%/round'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final holdDuration = await widget.service.getHoldDuration();
    final rounds = await widget.service.getHoldSessionRounds();
    final difficulty = await widget.service.getDifficultyLevel();
    if (mounted) {
      setState(() {
        _holdDuration = holdDuration;
        _rounds = rounds;
        _difficulty = difficulty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Hold duration
          Text(
            'Breath Hold Duration',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                '${_holdDuration}s',
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 24,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Slider(
                  value: _holdDuration.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  activeColor: AppColors.gold,
                  onChanged: (value) {
                    setState(() => _holdDuration = value.round());
                  },
                  onChangeEnd: (value) async {
                    await widget.service.setHoldDuration(value.round());
                    widget.onSettingsChanged();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Session rounds
          Text(
            'Session Rounds',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                '$_rounds',
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 24,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Slider(
                  value: _rounds.toDouble(),
                  min: 3,
                  max: 10,
                  divisions: 7,
                  activeColor: AppColors.gold,
                  onChanged: (value) {
                    setState(() => _rounds = value.round());
                  },
                  onChangeEnd: (value) async {
                    await widget.service.setHoldSessionRounds(value.round());
                    widget.onSettingsChanged();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Difficulty level
          Text(
            'Difficulty Level',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: List.generate(3, (index) {
              final isSelected = _difficulty == index;
              return ChoiceChip(
                label: Text('${_difficultyLabels[index]} (${_difficultyDescriptions[index]})'),
                selected: isSelected,
                onSelected: (selected) async {
                  if (selected) {
                    setState(() => _difficulty = index);
                    await widget.service.setDifficultyLevel(index);
                    widget.onSettingsChanged();
                  }
                },
                selectedColor: AppColors.gold,
                backgroundColor: AppColors.surfaceDark,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.backgroundDark : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              );
            }),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Info
          Text(
            'These settings apply to Breath Hold sessions. The session will progressively increase difficulty.',
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
