import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/database.dart';
import '../theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/offline_indicator.dart';
import 'plotting_screen.dart';

class SessionStartScreen extends StatefulWidget {
  const SessionStartScreen({super.key});

  @override
  State<SessionStartScreen> createState() => _SessionStartScreenState();
}

class _SessionStartScreenState extends State<SessionStartScreen> {
  List<RoundType> _roundTypes = [];
  String? _selectedRoundId;
  String _sessionType = 'practice';
  bool _isLoading = true;

  // Equipment selection
  String? _selectedBowId;
  String? _selectedQuiverId;
  bool _shaftTaggingEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadRoundTypes();
  }

  Future<void> _loadRoundTypes() async {
    final db = context.read<AppDatabase>();
    final types = await db.getAllRoundTypes();
    setState(() {
      _roundTypes = types;
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
          vertical: AppSpacing.sm,
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
        color: isSelected ? AppColors.gold.withOpacity(0.1) : AppColors.surfaceDark,
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
                      color: AppColors.gold.withOpacity(0.2),
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
