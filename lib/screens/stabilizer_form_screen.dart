import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../providers/skills_provider.dart';
import '../db/database.dart';

class StabilizerFormScreen extends StatefulWidget {
  final String bowId;
  final Stabilizer? stabilizer;

  const StabilizerFormScreen({
    super.key,
    required this.bowId,
    this.stabilizer,
  });

  @override
  State<StabilizerFormScreen> createState() => _StabilizerFormScreenState();
}

class _StabilizerFormScreenState extends State<StabilizerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Name
  late TextEditingController _nameController;

  // Long rod
  late TextEditingController _longRodModelController;
  late TextEditingController _longRodLengthController;
  late TextEditingController _longRodWeightController;
  late TextEditingController _longRodWeightsController;

  // Left side rod
  late TextEditingController _leftSideRodModelController;
  late TextEditingController _leftSideRodLengthController;
  late TextEditingController _leftSideRodWeightController;
  late TextEditingController _leftWeightsController;
  late TextEditingController _leftAngleHController;
  late TextEditingController _leftAngleVController;

  // Right side rod
  late TextEditingController _rightSideRodModelController;
  late TextEditingController _rightSideRodLengthController;
  late TextEditingController _rightSideRodWeightController;
  late TextEditingController _rightWeightsController;
  late TextEditingController _rightAngleHController;
  late TextEditingController _rightAngleVController;

  // Extender
  late TextEditingController _extenderLengthController;

  // V-bar
  late TextEditingController _vbarModelController;

  // Dampers
  late TextEditingController _damperModelController;
  late TextEditingController _damperPositionsController;

  // Notes
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final s = widget.stabilizer;

    _nameController = TextEditingController(text: s?.name ?? '');

    // Long rod
    _longRodModelController = TextEditingController(text: s?.longRodModel ?? '');
    _longRodLengthController = TextEditingController(
      text: s?.longRodLength?.toStringAsFixed(0) ?? '',
    );
    _longRodWeightController = TextEditingController(
      text: s?.longRodWeight?.toStringAsFixed(1) ?? '',
    );
    _longRodWeightsController = TextEditingController(text: s?.longRodWeights ?? '');

    // Left side rod - use new fields if available, fall back to legacy
    _leftSideRodModelController = TextEditingController(
      text: s?.leftSideRodModel ?? s?.sideRodModel ?? '',
    );
    _leftSideRodLengthController = TextEditingController(
      text: (s?.leftSideRodLength ?? s?.sideRodLength)?.toStringAsFixed(0) ?? '',
    );
    _leftSideRodWeightController = TextEditingController(
      text: (s?.leftSideRodWeight ?? s?.sideRodWeight)?.toStringAsFixed(1) ?? '',
    );
    _leftWeightsController = TextEditingController(text: s?.leftWeights ?? '');
    _leftAngleHController = TextEditingController(
      text: (s?.leftAngleHorizontal ?? s?.vbarAngleHorizontal)?.toStringAsFixed(0) ?? '',
    );
    _leftAngleVController = TextEditingController(
      text: (s?.leftAngleVertical ?? s?.vbarAngleVertical)?.toStringAsFixed(0) ?? '',
    );

    // Right side rod - use new fields if available, fall back to legacy
    _rightSideRodModelController = TextEditingController(
      text: s?.rightSideRodModel ?? s?.sideRodModel ?? '',
    );
    _rightSideRodLengthController = TextEditingController(
      text: (s?.rightSideRodLength ?? s?.sideRodLength)?.toStringAsFixed(0) ?? '',
    );
    _rightSideRodWeightController = TextEditingController(
      text: (s?.rightSideRodWeight ?? s?.sideRodWeight)?.toStringAsFixed(1) ?? '',
    );
    _rightWeightsController = TextEditingController(text: s?.rightWeights ?? '');
    _rightAngleHController = TextEditingController(
      text: (s?.rightAngleHorizontal ?? s?.vbarAngleHorizontal)?.toStringAsFixed(0) ?? '',
    );
    _rightAngleVController = TextEditingController(
      text: (s?.rightAngleVertical ?? s?.vbarAngleVertical)?.toStringAsFixed(0) ?? '',
    );

    _extenderLengthController = TextEditingController(
      text: s?.extenderLength?.toStringAsFixed(1) ?? '',
    );
    _vbarModelController = TextEditingController(text: s?.vbarModel ?? '');
    _damperModelController = TextEditingController(text: s?.damperModel ?? '');
    _damperPositionsController = TextEditingController(text: s?.damperPositions ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _longRodModelController.dispose();
    _longRodLengthController.dispose();
    _longRodWeightController.dispose();
    _longRodWeightsController.dispose();
    _leftSideRodModelController.dispose();
    _leftSideRodLengthController.dispose();
    _leftSideRodWeightController.dispose();
    _leftWeightsController.dispose();
    _leftAngleHController.dispose();
    _leftAngleVController.dispose();
    _rightSideRodModelController.dispose();
    _rightSideRodLengthController.dispose();
    _rightSideRodWeightController.dispose();
    _rightWeightsController.dispose();
    _rightAngleHController.dispose();
    _rightAngleVController.dispose();
    _extenderLengthController.dispose();
    _vbarModelController.dispose();
    _damperModelController.dispose();
    _damperPositionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<EquipmentProvider>();

      final name = _nullIfEmpty(_nameController.text);
      final longRodModel = _nullIfEmpty(_longRodModelController.text);
      final longRodLength = double.tryParse(_longRodLengthController.text);
      final longRodWeight = double.tryParse(_longRodWeightController.text);
      final longRodWeights = _nullIfEmpty(_longRodWeightsController.text);

      // Left side
      final leftSideRodModel = _nullIfEmpty(_leftSideRodModelController.text);
      final leftSideRodLength = double.tryParse(_leftSideRodLengthController.text);
      final leftSideRodWeight = double.tryParse(_leftSideRodWeightController.text);
      final leftWeights = _nullIfEmpty(_leftWeightsController.text);
      final leftAngleH = double.tryParse(_leftAngleHController.text);
      final leftAngleV = double.tryParse(_leftAngleVController.text);

      // Right side
      final rightSideRodModel = _nullIfEmpty(_rightSideRodModelController.text);
      final rightSideRodLength = double.tryParse(_rightSideRodLengthController.text);
      final rightSideRodWeight = double.tryParse(_rightSideRodWeightController.text);
      final rightWeights = _nullIfEmpty(_rightWeightsController.text);
      final rightAngleH = double.tryParse(_rightAngleHController.text);
      final rightAngleV = double.tryParse(_rightAngleVController.text);

      final extenderLength = double.tryParse(_extenderLengthController.text);
      final vbarModel = _nullIfEmpty(_vbarModelController.text);
      final damperModel = _nullIfEmpty(_damperModelController.text);
      final damperPositions = _nullIfEmpty(_damperPositionsController.text);
      final notes = _nullIfEmpty(_notesController.text);

      final skillsProvider = context.read<SkillsProvider>();
      final stabName = name ?? 'Stabilizer setup';

      if (widget.stabilizer == null) {
        await provider.createStabilizer(
          bowId: widget.bowId,
          name: name,
          longRodModel: longRodModel,
          longRodLength: longRodLength,
          longRodWeight: longRodWeight,
          longRodWeights: longRodWeights,
          leftSideRodModel: leftSideRodModel,
          leftSideRodLength: leftSideRodLength,
          leftSideRodWeight: leftSideRodWeight,
          leftWeights: leftWeights,
          leftAngleHorizontal: leftAngleH,
          leftAngleVertical: leftAngleV,
          rightSideRodModel: rightSideRodModel,
          rightSideRodLength: rightSideRodLength,
          rightSideRodWeight: rightSideRodWeight,
          rightWeights: rightWeights,
          rightAngleHorizontal: rightAngleH,
          rightAngleVertical: rightAngleV,
          extenderLength: extenderLength,
          vbarModel: vbarModel,
          damperModel: damperModel,
          damperPositions: damperPositions,
          notes: notes,
        );
        // Award Equipment XP for adding a new stabilizer setup
        await skillsProvider.awardEquipmentXp(reason: 'Added stabilizer: $stabName');
      } else {
        await provider.updateStabilizer(
          id: widget.stabilizer!.id,
          name: name,
          longRodModel: longRodModel,
          longRodLength: longRodLength,
          longRodWeight: longRodWeight,
          longRodWeights: longRodWeights,
          leftSideRodModel: leftSideRodModel,
          leftSideRodLength: leftSideRodLength,
          leftSideRodWeight: leftSideRodWeight,
          leftWeights: leftWeights,
          leftAngleHorizontal: leftAngleH,
          leftAngleVertical: leftAngleV,
          rightSideRodModel: rightSideRodModel,
          rightSideRodLength: rightSideRodLength,
          rightSideRodWeight: rightSideRodWeight,
          rightWeights: rightWeights,
          rightAngleHorizontal: rightAngleH,
          rightAngleVertical: rightAngleV,
          extenderLength: extenderLength,
          vbarModel: vbarModel,
          damperModel: damperModel,
          damperPositions: damperPositions,
          notes: notes,
        );
        // Award Equipment XP for updating stabilizer settings
        await skillsProvider.awardEquipmentXp(reason: 'Updated stabilizer: $stabName');
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.stabilizer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Stabilizer Setup' : 'Add Stabilizer Setup'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Setup Name (optional)',
                hintText: 'e.g., Indoor Setup, Outdoor Setup',
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: AppSpacing.xl),
            _buildSectionHeader(context, 'LONG ROD'),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _longRodModelController,
              decoration: const InputDecoration(
                labelText: 'Model',
                hintText: 'e.g., Doinker Platinum, Beiter',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _longRodLengthController,
                    decoration: const InputDecoration(
                      labelText: 'Length',
                      hintText: '30',
                      suffixText: '"',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _longRodWeightController,
                    decoration: const InputDecoration(
                      labelText: 'Rod Weight',
                      hintText: '8',
                      suffixText: 'oz',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _longRodWeightsController,
              decoration: const InputDecoration(
                labelText: 'Weights',
                hintText: 'e.g., 4x 1oz stacked at end',
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            _buildSectionHeader(context, 'LEFT SIDE ROD'),
            const SizedBox(height: AppSpacing.sm),

            _buildSideRodSection(
              modelController: _leftSideRodModelController,
              lengthController: _leftSideRodLengthController,
              weightController: _leftSideRodWeightController,
              weightsController: _leftWeightsController,
              angleHController: _leftAngleHController,
              angleVController: _leftAngleVController,
            ),

            const SizedBox(height: AppSpacing.xl),
            _buildSectionHeader(context, 'RIGHT SIDE ROD'),
            const SizedBox(height: AppSpacing.sm),

            _buildSideRodSection(
              modelController: _rightSideRodModelController,
              lengthController: _rightSideRodLengthController,
              weightController: _rightSideRodWeightController,
              weightsController: _rightWeightsController,
              angleHController: _rightAngleHController,
              angleVController: _rightAngleVController,
            ),

            const SizedBox(height: AppSpacing.xl),
            _buildSectionHeader(context, 'V-BAR & EXTENDER'),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _vbarModelController,
              decoration: const InputDecoration(
                labelText: 'V-Bar Model',
                hintText: 'e.g., Beiter, Doinker',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _extenderLengthController,
              decoration: const InputDecoration(
                labelText: 'Extender Length',
                hintText: '4',
                suffixText: '"',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            _buildSectionHeader(context, 'DAMPERS'),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _damperModelController,
              decoration: const InputDecoration(
                labelText: 'Model',
                hintText: 'e.g., Doinker A-Bomb',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _damperPositionsController,
              decoration: const InputDecoration(
                labelText: 'Positions',
                hintText: 'e.g., End of long rod, between weights',
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            _buildSectionHeader(context, 'NOTES'),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Any other details...',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSideRodSection({
    required TextEditingController modelController,
    required TextEditingController lengthController,
    required TextEditingController weightController,
    required TextEditingController weightsController,
    required TextEditingController angleHController,
    required TextEditingController angleVController,
  }) {
    return Column(
      children: [
        TextFormField(
          controller: modelController,
          decoration: const InputDecoration(
            labelText: 'Model',
            hintText: 'e.g., Doinker Platinum',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: lengthController,
                decoration: const InputDecoration(
                  labelText: 'Length',
                  hintText: '12',
                  suffixText: '"',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Rod Weight',
                  hintText: '4',
                  suffixText: 'oz',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: weightsController,
          decoration: const InputDecoration(
            labelText: 'Weights',
            hintText: 'e.g., 2x 1oz',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: angleHController,
                decoration: const InputDecoration(
                  labelText: 'Horizontal Angle',
                  hintText: '35',
                  suffixText: '\u00B0',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                controller: angleVController,
                decoration: const InputDecoration(
                  labelText: 'Vertical Angle',
                  hintText: '10',
                  suffixText: '\u00B0',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
