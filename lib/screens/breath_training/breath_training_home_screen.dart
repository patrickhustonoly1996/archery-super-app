import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/breath_training_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bestExhale = await _service.getPatrickBestExhale();
    final holdDuration = await _service.getHoldDuration();
    if (mounted) {
      setState(() {
        _bestExhale = bestExhale;
        _holdDuration = holdDuration;
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
              // Header
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

              const SizedBox(height: AppSpacing.xxl),

              // Session type cards
              Column(
                  children: [
                    // Paced Breathing
                    _SessionCard(
                      icon: Icons.air,
                      title: 'Paced Breathing',
                      description: 'Breathe in for 4, out for 6. Calming rhythm.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PacedBreathingScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Breath Holds
                    _SessionCard(
                      icon: Icons.pause_circle_outline,
                      title: 'Breath Holds',
                      description:
                          'Progressive exhale holds (${_holdDuration}s). Builds CO2 tolerance.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BreathHoldScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Patrick Breath Test
                    _SessionCard(
                      icon: Icons.timer_outlined,
                      title: 'Long Exhale Test',
                      subtitle: 'The Patrick Breath',
                      description: _bestExhale > 0
                          ? 'How long can you exhale? Best: ${_bestExhale}s'
                          : 'How long can you exhale? Test yourself.',
                      highlight: true,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PatrickBreathScreen(),
                          ),
                        );
                        _loadSettings(); // Refresh best time after returning
                      },
                    ),
                  ],
                ),

              const SizedBox(height: AppSpacing.lg),

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
  final VoidCallback onTap;
  final bool highlight;

  const _SessionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.description,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight
          ? AppColors.gold.withOpacity(0.1)
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
                    color: AppColors.gold.withOpacity(0.5),
                    width: 1,
                  ),
                )
              : null,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  icon,
                  color: AppColors.gold,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge,
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
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
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
