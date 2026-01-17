import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../db/database.dart';
import '../models/tuning_session.dart';
import '../utils/tuning_suggestions.dart';
import '../utils/unique_id.dart';

/// Tuning checklist screen with bow type detection
class TuningChecklistScreen extends StatefulWidget {
  final Bow? bow;

  const TuningChecklistScreen({super.key, this.bow});

  @override
  State<TuningChecklistScreen> createState() => _TuningChecklistScreenState();
}

class _TuningChecklistScreenState extends State<TuningChecklistScreen> {
  late Bow? _selectedBow;
  String? _selectedTuningType;
  final _notesController = TextEditingController();

  // Paper tune specific fields
  String _tearDirection = TearDirection.clean;
  String _tearSize = TearSize.medium;

  // Checklist states
  final Map<String, bool> _checklistItems = {};
  final Map<String, String> _checklistNotes = {};

  @override
  void initState() {
    super.initState();
    _selectedBow = widget.bow;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String get _bowType {
    if (_selectedBow == null) return BowType.recurve;
    return _selectedBow!.bowType;
  }

  List<String> get _tuningTypes => TuningType.getTypesForBow(_bowType);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TUNING CHECKLIST',
          style: TextStyle(fontFamily: AppFonts.pixel, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBowSelector(),
            const SizedBox(height: AppSpacing.lg),
            _buildTuningTypeSelector(),
            const SizedBox(height: AppSpacing.lg),
            if (_selectedTuningType != null) ...[
              _buildTuningTypeContent(),
              const SizedBox(height: AppSpacing.xl),
              _buildGeneralNotes(),
              const SizedBox(height: AppSpacing.xl),
              _buildSaveButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBowSelector() {
    return Consumer<EquipmentProvider>(
      builder: (context, provider, _) {
        final bows = provider.bows;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BOW',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 16,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<Bow?>(
              initialValue: _selectedBow,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.surfaceDark,
              ),
              items: bows.map((bow) {
                return DropdownMenuItem(
                  value: bow,
                  child: Text(
                    '${bow.name} (${BowType.displayName(bow.bowType)})',
                    style: const TextStyle(fontFamily: AppFonts.body),
                  ),
                );
              }).toList(),
              onChanged: (bow) {
                setState(() {
                  _selectedBow = bow;
                  _selectedTuningType = null;
                  _checklistItems.clear();
                  _checklistNotes.clear();
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTuningTypeSelector() {
    if (_selectedBow == null) {
      return const Text(
        'Select a bow to continue',
        style: TextStyle(
          fontFamily: AppFonts.body,
          color: AppColors.textSecondary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TUNING TYPE (${BowType.displayName(_bowType)})',
          style: const TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 16,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _tuningTypes.map((type) {
            final isSelected = _selectedTuningType == type;
            return ChoiceChip(
              label: Text(
                TuningType.displayName(type),
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  color: isSelected ? AppColors.backgroundDark : AppColors.textPrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.gold,
              backgroundColor: AppColors.surfaceDark,
              onSelected: (selected) {
                setState(() {
                  _selectedTuningType = selected ? type : null;
                  _initializeChecklist();
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _initializeChecklist() {
    _checklistItems.clear();
    _checklistNotes.clear();

    if (_selectedTuningType == null) return;

    final items = _getChecklistItems(_selectedTuningType!);
    for (final item in items) {
      _checklistItems[item] = false;
    }
  }

  List<String> _getChecklistItems(String tuningType) {
    switch (tuningType) {
      case TuningType.braceHeight:
        return ['Measure pivot point to string', 'Record measurement', 'Check against manufacturer spec'];
      case TuningType.nockPoint:
        return ['Measure from arrow rest to nocking point', 'Check square alignment', 'Record measurement'];
      case TuningType.tiller:
        return ['Measure top limb (pocket to string)', 'Measure bottom limb (pocket to string)', 'Calculate difference', 'Record measurements'];
      case TuningType.centershot:
        return ['Check point alignment through rest', 'Adjust button/plunger position', 'Verify with arrow on rest'];
      case TuningType.plungerTension:
        return ['Test current tension', 'Adjust spring if needed', 'Record final setting'];
      case TuningType.paperTune:
        return ['Set up paper frame', 'Shoot through from 6-8 feet', 'Observe tear pattern', 'Record direction and size'];
      case TuningType.bareShaft:
        return ['Prepare fletched arrows', 'Prepare bare shafts', 'Shoot groups at 18m', 'Compare grouping'];
      case TuningType.walkBack:
        return ['Shoot at 10m', 'Shoot at 30m', 'Shoot at 50m', 'Shoot at 70m', 'Check vertical alignment'];
      case TuningType.camTiming:
        return ['Check top cam timing mark', 'Check bottom cam timing mark', 'Verify synchronization', 'Adjust if needed'];
      case TuningType.yokeTuning:
        return ['Check string level', 'Measure yoke leg lengths', 'Adjust for level cam', 'Verify cam position'];
      case TuningType.restPosition:
        return ['Check rest height', 'Check rest lateral position', 'Verify arrow clearance', 'Record final position'];
      case TuningType.peepHeight:
        return ['Check peep alignment with sight', 'Verify at full draw', 'Adjust D-loop if needed', 'Record final position'];
      case TuningType.frenchTune:
        return ['Shoot fletched arrow', 'Shoot bare shaft at same spot', 'Check impact difference', 'Adjust rest/nocking point'];
      default:
        return [];
    }
  }

  Widget _buildTuningTypeContent() {
    if (_selectedTuningType == TuningType.paperTune) {
      return _buildPaperTuneForm();
    } else {
      return _buildGenericChecklist();
    }
  }

  Widget _buildPaperTuneForm() {
    final suggestions = TuningSuggestions.getSuggestionsForPaperTune(
      bowType: _bowType,
      direction: _tearDirection,
      size: _tearSize,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TEAR DIRECTION',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 16,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            TearDirection.clean,
            TearDirection.up,
            TearDirection.down,
            TearDirection.left,
            TearDirection.right,
            TearDirection.upLeft,
            TearDirection.upRight,
            TearDirection.downLeft,
            TearDirection.downRight,
          ].map((direction) {
            final isSelected = _tearDirection == direction;
            return ChoiceChip(
              label: Text(
                TearDirection.displayName(direction),
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  color: isSelected ? AppColors.backgroundDark : AppColors.textPrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.gold,
              backgroundColor: AppColors.surfaceDark,
              onSelected: (selected) {
                setState(() {
                  _tearDirection = direction;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'TEAR SIZE',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 16,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            TearSize.small,
            TearSize.medium,
            TearSize.large,
          ].map((size) {
            final isSelected = _tearSize == size;
            return ChoiceChip(
              label: Text(
                TearSize.displayName(size),
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 11,
                  color: isSelected ? AppColors.backgroundDark : AppColors.textPrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.gold,
              backgroundColor: AppColors.surfaceDark,
              onSelected: (selected) {
                setState(() {
                  _tearSize = size;
                });
              },
            );
          }).toList(),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border.all(color: AppColors.gold, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SUGGESTIONS',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 14,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...suggestions.map((suggestion) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              color: AppColors.gold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: const TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _buildGenericChecklist(),
      ],
    );
  }

  Widget _buildGenericChecklist() {
    final items = _getChecklistItems(_selectedTuningType!);
    final tips = TuningSuggestions.getGeneralTips(_selectedTuningType!, _bowType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tips.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TIPS',
                  style: TextStyle(
                    fontFamily: AppFonts.pixel,
                    fontSize: 14,
                    color: AppColors.neonCyan,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...tips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              color: AppColors.neonCyan,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        const Text(
          'CHECKLIST',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 16,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map((item) => CheckboxListTile(
              value: _checklistItems[item] ?? false,
              onChanged: (checked) {
                setState(() {
                  _checklistItems[item] = checked ?? false;
                });
              },
              title: Text(
                item,
                style: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.gold,
              checkColor: AppColors.backgroundDark,
            )),
      ],
    );
  }

  Widget _buildGeneralNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NOTES',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 16,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _notesController,
          maxLines: 4,
          style: const TextStyle(
            fontFamily: AppFonts.body,
            color: AppColors.textPrimary,
          ),
          decoration: const InputDecoration(
            hintText: 'Additional notes about this tuning session...',
            hintStyle: TextStyle(
              fontFamily: AppFonts.body,
              color: AppColors.textSecondary,
            ),
            border: OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.surfaceDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveTuningSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.backgroundDark,
          padding: const EdgeInsets.all(AppSpacing.md),
        ),
        child: const Text(
          'SAVE TUNING SESSION',
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _saveTuningSession() async {
    if (_selectedBow == null || _selectedTuningType == null) return;

    final results = <String, dynamic>{
      'checklist': _checklistItems,
      'checklistNotes': _checklistNotes,
    };

    if (_selectedTuningType == TuningType.paperTune) {
      results['tearDirection'] = _tearDirection;
      results['tearSize'] = _tearSize;
    }

    final database = context.read<AppDatabase>();
    await database.insertTuningSession(
      TuningSessionsCompanion.insert(
        id: UniqueId.generate(),
        bowId: Value(_selectedBow!.id),
        date: DateTime.now(),
        bowType: _selectedBow!.bowType,
        tuningType: _selectedTuningType!,
        results: Value(jsonEncode(results)),
        notes: Value(_notesController.text.isNotEmpty ? _notesController.text : null),
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tuning session saved',
          style: TextStyle(fontFamily: AppFonts.body),
        ),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }
}
