import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/session_setup_sheet.dart';

class SessionStartScreen extends StatefulWidget {
  const SessionStartScreen({super.key});

  @override
  State<SessionStartScreen> createState() => _SessionStartScreenState();
}

class _SessionStartScreenState extends State<SessionStartScreen> {
  List<RoundType> _roundTypes = [];
  List<RoundType> _frequentRounds = [];
  String _sessionType = 'practice';
  bool _isLoading = true;

  // Free practice selection
  int _freePracticeArrowsPerEnd = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = context.read<AppDatabase>();
    final types = await db.getAllRoundTypes();
    final frequentRounds =
        await db.getMostFrequentRecentRoundTypes(days: 14, limit: 5);

    setState(() {
      _roundTypes = types;
      _frequentRounds = frequentRounds;
      _isLoading = false;
    });
  }

  Future<void> _onRoundSelected(RoundType roundType) async {
    final started = await SessionSetupSheet.show(
      context: context,
      roundType: roundType,
      sessionType: _sessionType,
    );

    // If session was started, close this screen
    if (started && mounted) {
      Navigator.pop(context);
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
          const SizedBox(width: AppSpacing.md),
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
                  // Session type selector
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
                                padding:
                                    const EdgeInsets.only(right: AppSpacing.sm),
                                child: _QuickStartCard(
                                  title: round.name,
                                  subtitle: '${round.distance}m',
                                  onTap: () => _onRoundSelected(round),
                                ),
                              )),
                          // Free Practice card
                          _FreePracticeCard(
                            arrowsPerEnd: _freePracticeArrowsPerEnd,
                            onArrowsChanged: (arrows) {
                              setState(() => _freePracticeArrowsPerEnd = arrows);
                            },
                            onTap: () {
                              final practiceId = _freePracticeArrowsPerEnd == 6
                                  ? 'practice_outdoor_6'
                                  : _freePracticeArrowsPerEnd == 5
                                      ? 'practice_indoor_5'
                                      : 'practice_indoor_3';
                              final practiceRound = _roundTypes.firstWhere(
                                (r) => r.id == practiceId,
                                orElse: () => _roundTypes.first,
                              );
                              _onRoundSelected(practiceRound);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

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
          padding:
              const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
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
            onTap: () => _onRoundSelected(rt),
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
            color:
                isSelected ? AppColors.backgroundDark : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _RoundTile extends StatelessWidget {
  final RoundType roundType;
  final VoidCallback onTap;

  const _RoundTile({
    required this.roundType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
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
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
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
  final VoidCallback onTap;

  const _QuickStartCard({
    required this.title,
    required this.subtitle,
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
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: AppColors.surfaceLight,
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
                color: AppColors.textPrimary,
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
  final ValueChanged<int> onArrowsChanged;
  final VoidCallback onTap;

  const _FreePracticeCard({
    required this.arrowsPerEnd,
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
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: AppColors.surfaceLight,
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
                color: AppColors.textPrimary,
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
            color:
                isSelected ? AppColors.backgroundDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
