import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
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

  // Side rods
  late TextEditingController _sideRodModelController;
  late TextEditingController _sideRodLengthController;
  late TextEditingController _sideRodWeightController;

  // Extender
  late TextEditingController _extenderLengthController;

  // V-bar
  late TextEditingController _vbarModelController;
  late TextEditingController _vbarAngleHController;
  late TextEditingController _vbarAngleVController;

  // Weights & dampers
  late TextEditingController _weightArrangementController;
  late TextEditingController _damperModelController;
  late TextEditingController _damperPositionsController;

  // Notes
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final s = widget.stabilizer;

    _nameController = TextEditingController(text: s?.name ?? '');

    _longRodModelController = TextEditingController(text: s?.longRodModel ?? '');
    _longRodLengthController = TextEditingController(
      text: s?.longRodLength?.toStringAsFixed(0) ?? '',
    );
    _longRodWeightController = TextEditingController(
      text: s?.longRodWeight?.toStringAsFixed(1) ?? '',
    );

    _sideRodModelController = TextEditingController(text: s?.sideRodModel ?? '');
    _sideRodLengthController = TextEditingController(
      text: s?.sideRodLength?.toStringAsFixed(0) ?? '',
    );
    _sideRodWeightController = TextEditingController(
      text: s?.sideRodWeight?.toStringAsFixed(1) ?? '',
    );

    _extenderLengthController = TextEditingController(
      text: s?.extenderLength?.toStringAsFixed(1) ?? '',
    );

    _vbarModelController = TextEditingController(text: s?.vbarModel ?? '');
    _vbarAngleHController = TextEditingController(
      text: s?.vbarAngleHorizontal?.toStringAsFixed(0) ?? '',
    );
    _vbarAngleVController = TextEditingController(
      text: s?.vbarAngleVertical?.toStringAsFixed(0) ?? '',
    );

    _weightArrangementController = TextEditingController(
      text: s?.weightArrangement ?? '',
    );
    _damperModelController = TextEditingController(text: s?.damperModel ?? '');
    _damperPositionsController = TextEditingController(
      text: s?.damperPositions ?? '',
    );

    _notesController = TextEditingController(text: s?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _longRodModelController.dispose();
    _longRodLengthController.dispose();
    _longRodWeightController.dispose();
    _sideRodModelController.dispose();
    _sideRodLengthController.dispose();
    _sideRodWeightController.dispose();
    _extenderLengthController.dispose();
    _vbarModelController.dispose();
    _vbarAngleHController.dispose();
    _vbarAngleVController.dispose();
    _weightArrangementController.dispose();
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
      final sideRodModel = _nullIfEmpty(_sideRodModelController.text);
      final sideRodLength = double.tryParse(_sideRodLengthController.text);
      final sideRodWeight = double.tryParse(_sideRodWeightController.text);
      final extenderLength = double.tryParse(_extenderLengthController.text);
      final vbarModel = _nullIfEmpty(_vbarModelController.text);
      final vbarAngleH = double.tryParse(_vbarAngleHController.text);
      final vbarAngleV = double.tryParse(_vbarAngleVController.text);
      final weightArrangement = _nullIfEmpty(_weightArrangementController.text);
      final damperModel = _nullIfEmpty(_damperModelController.text);
      final damperPositions = _nullIfEmpty(_damperPositionsController.text);
      final notes = _nullIfEmpty(_notesController.text);

      if (widget.stabilizer == null) {
        await provider.createStabilizer(
          bowId: widget.bowId,
          name: name,
          longRodModel: longRodModel,
          longRodLength: longRodLength,
          longRodWeight: longRodWeight,
          sideRodModel: sideRodModel,
          sideRodLength: sideRodLength,
          sideRodWeight: sideRodWeight,
          extenderLength: extenderLength,
          vbarModel: vbarModel,
          vbarAngleHorizontal: vbarAngleH,
          vbarAngleVertical: vbarAngleV,
          weightArrangement: weightArrangement,
          damperModel: damperModel,
          damperPositions: damperPositions,
          notes: notes,
        );
      } else {
        await provider.updateStabilizer(
          id: widget.stabilizer!.id,
          name: name,
          longRodModel: longRodModel,
          longRodLength: longRodLength,
          longRodWeight: longRodWeight,
          sideRodModel: sideRodModel,
          sideRodLength: sideRodLength,
          sideRodWeight: sideRodWeight,
          extenderLength: extenderLength,
          vbarModel: vbarModel,
          vbarAngleHorizontal: vbarAngleH,
          vbarAngleVertical: vbarAngleV,
          weightArrangement: weightArrangement,
          damperModel: damperModel,
          damperPositions: damperPositions,
          notes: notes,
        );
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
                      labelText: 'Weight',
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

            const SizedBox(height: AppSpacing.xl),
            _buildSectionHeader(context, 'SIDE RODS'),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _sideRodModelController,
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
                    controller: _sideRodLengthController,
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
                    controller: _sideRodWeightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (each)',
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vbarAngleHController,
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
                    controller: _vbarAngleVController,
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
            _buildSectionHeader(context, 'WEIGHTS & DAMPERS'),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _weightArrangementController,
              decoration: const InputDecoration(
                labelText: 'Weight Arrangement',
                hintText: 'e.g., 3x1oz long, 2x1oz each side',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _damperModelController,
              decoration: const InputDecoration(
                labelText: 'Damper Model',
                hintText: 'e.g., Doinker A-Bomb',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _damperPositionsController,
              decoration: const InputDecoration(
                labelText: 'Damper Positions',
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withOpacity(0.5),
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
