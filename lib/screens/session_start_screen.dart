import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/expected_sight_mark.dart';
import 'plotting_screen.dart';
import 'settings_screen.dart' show kArrowTrackingDefaultPref;

class SessionStartScreen extends StatefulWidget {
  const SessionStartScreen({super.key});

  @override
  State<SessionStartScreen> createState() => _SessionStartScreenState();
}

class _SessionStartScreenState extends State<SessionStartScreen> {
  List<RoundType> _roundTypes = [];
  List<RoundType> _frequentRounds = []; // Most shot rounds in past 14 days
  String? _selectedRoundId;
  String _sessionType = 'practice';
  bool _isLoading = true;

  // Equipment selection
  String? _selectedBowId;
  String? _selectedQuiverId;
  bool _shaftTaggingEnabled = false;
  bool _arrowTrackingDefault = false; // Loaded from persistent setting

  // Timer settings
  bool _timerEnabled = false;
  int _timerDuration = 120; // Default 120s (indoor)

  // Free practice selection
  int _freePracticeArrowsPerEnd = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = context.read<AppDatabase>();
    final equipmentProvider = context.read<EquipmentProvider>();
    final types = await db.getAllRoundTypes();
    final frequentRounds = await db.getMostFrequentRecentRoundTypes(days: 14, limit: 5);
    final arrowTrackingDefault = await db.getBoolPreference(kArrowTrackingDefaultPref, defaultValue: false);
    final timerEnabled = await db.getBoolPreference(kScoringTimerEnabledPref, defaultValue: false);
    final timerDuration = await db.getIntPreference(kScoringTimerDurationPref, defaultValue: 120);

    // Pre-populate with default equipment
    final defaultBowId = equipmentProvider.defaultBow?.id;
    final defaultQuiverId = equipmentProvider.defaultQuiver?.id;

    setState(() {
      _roundTypes = types;
      _frequentRounds = frequentRounds;
      _arrowTrackingDefault = arrowTrackingDefault;
      _timerEnabled = timerEnabled;
      _timerDuration = timerDuration;
      _selectedBowId = defaultBowId;
      _selectedQuiverId = defaultQuiverId;
      // Enable shaft tagging if quiver selected and user preference is on
      if (defaultQuiverId != null) {
        _shaftTaggingEnabled = arrowTrackingDefault;
      }
      _isLoading = false;
    });
  }

  Future<void> _startSession() async {
    if (_selectedRoundId == null) return;

    final provider = context.read<SessionProvider>();
    await provider.startSession(
      roundTypeId: _selectedRoundId!,
      sessionType: _sessionType,
      bowId: _selectedBowId,
      quiverId: _selectedQuiverId,
      shaftTaggingEnabled: _shaftTaggingEnabled,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PlottingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Session'),
        leading: IconButton(
          icon: const Icon(Icons.close, semanticLabel: 'Close'),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Offline indicator
          Consumer<ConnectivityProvider>(
            builder: (context, connectivity, _) => OfflineIndicator(
              isOffline: connectivity.isOffline,
              isSyncing: connectivity.isSyncing,
            ),
          ),
          // Start button in app bar
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: ElevatedButton(
                onPressed: _selectedRoundId != null ? _startSession : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                ),
                child: const Text('Start'),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Start carousel
                  if (_frequentRounds.isNotEmpty) ...[
                    Text(
                      'Quick Start',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Recent rounds
                          ..._frequentRounds.map((round) => Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: _QuickStartCard(
                              title: round.name,
                              subtitle: '${round.distance}m',
                              isSelected: _selectedRoundId == round.id,
                              onTap: () => setState(() => _selectedRoundId = round.id),
                            ),
                          )),
                          // Free Practice card
                          _FreePracticeCard(
                            arrowsPerEnd: _freePracticeArrowsPerEnd,
                            isSelected: _selectedRoundId?.startsWith('practice_') ?? false,
                            onArrowsChanged: (arrows) {
                              setState(() {
                                _freePracticeArrowsPerEnd = arrows;
                                // Select appropriate practice round
                                final practiceId = arrows == 6
                                    ? 'practice_outdoor_6'
                                    : arrows == 5
                                        ? 'practice_indoor_5'
                                        : 'practice_indoor_3';
                                _selectedRoundId = practiceId;
                              });
                            },
                            onTap: () {
                              setState(() {
                                final practiceId = _freePracticeArrowsPerEnd == 6
                                    ? 'practice_outdoor_6'
                                    : _freePracticeArrowsPerEnd == 5
                                        ? 'practice_indoor_5'
                                        : 'practice_indoor_3';
                                _selectedRoundId = practiceId;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Session type
                  Text(
                    'Session Type',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _TypeChip(
                        label: 'Practice',
                        isSelected: _sessionType == 'practice',
                        onTap: () => setState(() => _sessionType = 'practice'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _TypeChip(
                        label: 'Competition',
                        isSelected: _sessionType == 'competition',
                        onTap: () =>
                            setState(() => _sessionType = 'competition'),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Equipment section
                  Text(
                    'Equipment (Optional)',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Consumer<EquipmentProvider>(
                    builder: (context, equipmentProvider, _) {
                      final bows = equipmentProvider.bows;
                      final quivers = equipmentProvider.quivers;

                      if (bows.isEmpty && quivers.isEmpty) {
                        return Text(
                          'No equipment configured. Go to Equipment to add bows and quivers.',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bow dropdown
                          if (bows.isNotEmpty)
                            DropdownButtonFormField<String?>(
                              initialValue: _selectedBowId,
                              decoration: const InputDecoration(
                                labelText: 'Bow',
                                hintText: 'Select a bow',
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('None'),
                                ),
                                ...bows.map((bow) {
                                  return DropdownMenuItem<String?>(
                                    value: bow.id,
                                    child: Text(bow.name),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedBowId = value);
                              },
                            ),
                          const SizedBox(height: AppSpacing.md),
                          // Quiver dropdown
                          if (quivers.isNotEmpty)
                            DropdownButtonFormField<String?>(
                              initialValue: _selectedQuiverId,
                              decoration: const InputDecoration(
                                labelText: 'Quiver',
                                hintText: 'Select a quiver',
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('None'),
                                ),
                                ...quivers.where((q) {
                                  // Filter by selected bow if set
                                  if (_selectedBowId == null) return true;
                                  return q.bowId == null ||
                                      q.bowId == _selectedBowId;
                                }).map((quiver) {
                                  return DropdownMenuItem<String?>(
                                    value: quiver.id,
                                    child: Text(
                                        '${quiver.name} (${quiver.shaftCount} arrows)'),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedQuiverId = value;
                                  if (value == null) {
                                    _shaftTaggingEnabled = false;
                                  } else {
                                    // Apply the persistent default setting when selecting a quiver
                                    _shaftTaggingEnabled = _arrowTrackingDefault;
                                  }
                                });
                              },
                            ),
                          // Shaft tagging toggle (only show if quiver selected)
                          if (_selectedQuiverId != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            SwitchListTile(
                              title: const Text('Enable shaft tagging'),
                              subtitle: const Text(
                                  'Track individual arrow performance'),
                              value: _shaftTaggingEnabled,
                              activeThumbColor: AppColors.gold,
                              onChanged: (value) {
                                setState(() => _shaftTaggingEnabled = value);
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Timer settings
                  Text(
                    'Scoring Timer (Optional)',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _TimerSettingsSection(
                    timerEnabled: _timerEnabled,
                    timerDuration: _timerDuration,
                    selectedRound: _selectedRoundId != null && _roundTypes.isNotEmpty
                        ? _roundTypes.firstWhere(
                            (r) => r.id == _selectedRoundId,
                            orElse: () => _roundTypes.first,
                          )
                        : null,
                    onTimerEnabledChanged: (value) async {
                      setState(() => _timerEnabled = value);
                      final db = context.read<AppDatabase>();
                      await db.setBoolPreference(kScoringTimerEnabledPref, value);
                    },
                    onTimerDurationChanged: (value) async {
                      setState(() => _timerDuration = value);
                      final db = context.read<AppDatabase>();
                      await db.setIntPreference(kScoringTimerDurationPref, value);
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Expected sight mark (show when bow and round are selected)
                  if (_selectedBowId != null && _selectedRoundId != null && _roundTypes.isNotEmpty)
                    Builder(
                      builder: (context) {
                        final round = _roundTypes.firstWhere(
                          (r) => r.id == _selectedRoundId,
                          orElse: () => _roundTypes.first,
                        );
                        return ExpectedSightMark(
                          bowId: _selectedBowId,
                          distance: round.distance.toDouble(),
                        );
                      },
                    ),

                  // Round selection
                  Text(
                    'Select Round',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Group rounds by category
                  ..._buildRoundGroups(),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildRoundGroups() {
    final groups = <String, List<RoundType>>{};

    for (final rt in _roundTypes) {
      groups.putIfAbsent(rt.category, () => []);
      groups[rt.category]!.add(rt);
    }

    final widgets = <Widget>[];

    // Sort by category order
    final sortedCategories = groups.keys.toList()
      ..sort((a, b) {
        final aIndex = _categoryOrder.indexOf(a);
        final bIndex = _categoryOrder.indexOf(b);
        if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });

    for (final category in sortedCategories) {
      final rounds = groups[category]!;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
          child: Text(
            _categoryName(category),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );

      for (final rt in rounds) {
        widgets.add(
          _RoundTile(
            roundType: rt,
            isSelected: _selectedRoundId == rt.id,
            onTap: () => setState(() => _selectedRoundId = rt.id),
          ),
        );
      }
    }

    return widgets;
  }

  String _categoryName(String category) {
    switch (category) {
      case 'wa_indoor':
        return 'WA Indoor';
      case 'wa_outdoor':
        return 'WA Outdoor';
      case 'agb_indoor':
        return 'AGB Indoor';
      case 'agb_imperial':
        return 'AGB Imperial';
      case 'agb_metric':
        return 'AGB Metric';
      case 'nfaa_indoor':
        return 'NFAA Indoor';
      case 'nfaa_field':
        return 'NFAA Field';
      case 'practice':
        return 'Practice';
      default:
        return category;
    }
  }

  // Order categories logically
  static const _categoryOrder = [
    'wa_indoor',
    'wa_outdoor',
    'agb_indoor',
    'agb_imperial',
    'agb_metric',
    'nfaa_indoor',
    'nfaa_field',
    'practice',
  ];
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.surfaceLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.backgroundDark : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _RoundTile extends StatelessWidget {
  final RoundType roundType;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoundTile({
    required this.roundType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: isSelected ? AppColors.gold.withValues(alpha: 0.1) : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(
                color: isSelected ? AppColors.gold : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roundType.name,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${roundType.distance}m  •  ${roundType.arrowsPerEnd} arrows/end  •  ${roundType.totalEnds} ends',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (roundType.faceCount > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Tri-spot',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.gold,
                            fontSize: 10,
                          ),
                    ),
                  ),
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.sm),
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Timer settings section for session start
class _TimerSettingsSection extends StatelessWidget {
  final bool timerEnabled;
  final int timerDuration;
  final RoundType? selectedRound;
  final ValueChanged<bool> onTimerEnabledChanged;
  final ValueChanged<int> onTimerDurationChanged;

  const _TimerSettingsSection({
    required this.timerEnabled,
    required this.timerDuration,
    required this.selectedRound,
    required this.onTimerEnabledChanged,
    required this.onTimerDurationChanged,
  });

  // Suggest duration based on round type
  int get _suggestedDuration {
    if (selectedRound == null) return 120;
    // Indoor: 120s typical, Outdoor: 240s typical
    return selectedRound!.isIndoor ? 120 : 240;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timer toggle
          SwitchListTile(
            title: const Text('Enable Timer'),
            subtitle: const Text('Competition-style countdown for shooting'),
            value: timerEnabled,
            activeThumbColor: AppColors.gold,
            onChanged: (value) {
              onTimerEnabledChanged(value);
              // Auto-suggest duration when enabling
              if (value && selectedRound != null) {
                onTimerDurationChanged(_suggestedDuration);
              }
            },
            contentPadding: EdgeInsets.zero,
          ),

          // Duration selector (only show when enabled)
          if (timerEnabled) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Timer Duration',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _DurationChip(
                  label: '90s',
                  isSelected: timerDuration == 90,
                  onTap: () => onTimerDurationChanged(90),
                ),
                const SizedBox(width: AppSpacing.sm),
                _DurationChip(
                  label: '120s',
                  isSelected: timerDuration == 120,
                  onTap: () => onTimerDurationChanged(120),
                ),
                const SizedBox(width: AppSpacing.sm),
                _DurationChip(
                  label: '180s',
                  isSelected: timerDuration == 180,
                  onTap: () => onTimerDurationChanged(180),
                ),
                const SizedBox(width: AppSpacing.sm),
                _DurationChip(
                  label: '240s',
                  isSelected: timerDuration == 240,
                  onTap: () => onTimerDurationChanged(240),
                ),
              ],
            ),
            if (selectedRound != null && timerDuration != _suggestedDuration)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Suggested for ${selectedRound!.isIndoor ? "indoor" : "outdoor"}: ${_suggestedDuration}s',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gold,
                        fontSize: 11,
                      ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.surfaceLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 12,
            color: isSelected ? AppColors.backgroundDark : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Quick start card for recent rounds
class _QuickStartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickStartCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.1) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.surfaceLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13,
                color: isSelected ? AppColors.gold : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Free practice card with arrows-per-end selector
class _FreePracticeCard extends StatelessWidget {
  final int arrowsPerEnd;
  final bool isSelected;
  final ValueChanged<int> onArrowsChanged;
  final VoidCallback onTap;

  const _FreePracticeCard({
    required this.arrowsPerEnd,
    required this.isSelected,
    required this.onArrowsChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.1) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.surfaceLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Free Practice',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13,
                color: isSelected ? AppColors.gold : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ArrowCountChip(
                  count: 3,
                  isSelected: arrowsPerEnd == 3,
                  onTap: () => onArrowsChanged(3),
                ),
                const SizedBox(width: 4),
                _ArrowCountChip(
                  count: 5,
                  isSelected: arrowsPerEnd == 5,
                  onTap: () => onArrowsChanged(5),
                ),
                const SizedBox(width: 4),
                _ArrowCountChip(
                  count: 6,
                  isSelected: arrowsPerEnd == 6,
                  onTap: () => onArrowsChanged(6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small chip for arrow count selection
class _ArrowCountChip extends StatelessWidget {
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _ArrowCountChip({
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.textMuted,
          ),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 12,
            color: isSelected ? AppColors.backgroundDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
