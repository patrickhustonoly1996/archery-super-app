import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../db/database.dart';

class ShaftDetailScreen extends StatefulWidget {
  final Quiver quiver;
  final Shaft? shaft; // null for batch mode

  const ShaftDetailScreen({
    super.key,
    required this.quiver,
    this.shaft,
  });

  @override
  State<ShaftDetailScreen> createState() => _ShaftDetailScreenState();
}

class _ShaftDetailScreenState extends State<ShaftDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for individual mode
  late TextEditingController _spineController;
  late TextEditingController _lengthController;
  late TextEditingController _pointWeightController;
  late TextEditingController _fletchingTypeController;
  late TextEditingController _fletchingColorController;
  late TextEditingController _nockColorController;
  late TextEditingController _notesController;

  // For batch mode
  Set<int> _selectedShafts = {};
  bool _isBatchMode = false;

  @override
  void initState() {
    super.initState();
    _isBatchMode = widget.shaft == null;

    // Initialize controllers with existing shaft data
    _spineController = TextEditingController(
      text: widget.shaft?.spine?.toString() ?? '',
    );
    _lengthController = TextEditingController(
      text: widget.shaft?.lengthInches?.toString() ?? '',
    );
    _pointWeightController = TextEditingController(
      text: widget.shaft?.pointWeight?.toString() ?? '',
    );
    _fletchingTypeController = TextEditingController(
      text: widget.shaft?.fletchingType ?? '',
    );
    _fletchingColorController = TextEditingController(
      text: widget.shaft?.fletchingColor ?? '',
    );
    _nockColorController = TextEditingController(
      text: widget.shaft?.nockColor ?? '',
    );
    _notesController = TextEditingController(
      text: widget.shaft?.notes ?? '',
    );
  }

  @override
  void dispose() {
    _spineController.dispose();
    _lengthController.dispose();
    _pointWeightController.dispose();
    _fletchingTypeController.dispose();
    _fletchingColorController.dispose();
    _nockColorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final equipmentProvider = context.read<EquipmentProvider>();

    final spine = _spineController.text.isNotEmpty
        ? int.tryParse(_spineController.text)
        : null;
    final length = _lengthController.text.isNotEmpty
        ? double.tryParse(_lengthController.text)
        : null;
    final pointWeight = _pointWeightController.text.isNotEmpty
        ? int.tryParse(_pointWeightController.text)
        : null;
    final fletchingType = _fletchingTypeController.text.isNotEmpty
        ? _fletchingTypeController.text
        : null;
    final fletchingColor = _fletchingColorController.text.isNotEmpty
        ? _fletchingColorController.text
        : null;
    final nockColor = _nockColorController.text.isNotEmpty
        ? _nockColorController.text
        : null;

    if (_isBatchMode) {
      // Batch update for selected shafts
      final allShafts = equipmentProvider.getShaftsForQuiver(widget.quiver.id);
      final selectedShaftIds = allShafts
          .where((s) => _selectedShafts.contains(s.number))
          .map((s) => s.id)
          .toList();

      if (selectedShaftIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one shaft')),
        );
        return;
      }

      await equipmentProvider.batchUpdateShaftSpecs(
        shaftIds: selectedShaftIds,
        spine: spine,
        lengthInches: length,
        pointWeight: pointWeight,
        fletchingType: fletchingType,
        fletchingColor: fletchingColor,
        nockColor: nockColor,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated ${selectedShaftIds.length} shafts'),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      // Individual update
      final notes = _notesController.text.isNotEmpty
          ? _notesController.text
          : null;

      await equipmentProvider.updateShaftSpecs(
        shaftId: widget.shaft!.id,
        spine: spine,
        lengthInches: length,
        pointWeight: pointWeight,
        fletchingType: fletchingType,
        fletchingColor: fletchingColor,
        nockColor: nockColor,
        notes: notes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shaft updated')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = context.watch<EquipmentProvider>();
    final allShafts = equipmentProvider.getShaftsForQuiver(widget.quiver.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isBatchMode
            ? 'Batch Edit Shafts'
            : 'Shaft ${widget.shaft!.number}'),
        actions: [
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
            if (_isBatchMode) ...[
              Text(
                'Select shafts to update',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildShaftSelector(allShafts),
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Specifications (applies to all selected)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            _buildTextField(
              controller: _spineController,
              label: 'Spine',
              hint: 'e.g., 500, 600',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: AppSpacing.md),

            _buildTextField(
              controller: _lengthController,
              label: 'Length (inches)',
              hint: 'e.g., 28.5',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.md),

            _buildTextField(
              controller: _pointWeightController,
              label: 'Point Weight (grains)',
              hint: 'e.g., 100, 120',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: AppSpacing.md),

            _buildTextField(
              controller: _fletchingTypeController,
              label: 'Fletching Type',
              hint: 'e.g., vanes, feathers',
            ),
            const SizedBox(height: AppSpacing.md),

            _buildTextField(
              controller: _fletchingColorController,
              label: 'Fletching Color',
              hint: 'e.g., blue, red/white',
            ),
            const SizedBox(height: AppSpacing.md),

            _buildTextField(
              controller: _nockColorController,
              label: 'Nock Color',
              hint: 'e.g., blue, green',
            ),

            if (!_isBatchMode) ...[
              const SizedBox(height: AppSpacing.md),
              _buildTextField(
                controller: _notesController,
                label: 'Notes',
                hint: 'Additional notes',
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
    );
  }

  Widget _buildShaftSelector(List<Shaft> shafts) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: shafts.map((shaft) {
        final isSelected = _selectedShafts.contains(shaft.number);
        final isRetired = shaft.retiredAt != null;

        return FilterChip(
          label: Text(shaft.number.toString()),
          selected: isSelected,
          onSelected: isRetired ? null : (selected) {
            setState(() {
              if (selected) {
                _selectedShafts.add(shaft.number);
              } else {
                _selectedShafts.remove(shaft.number);
              }
            });
          },
          backgroundColor: isRetired
              ? AppColors.surfaceLight.withOpacity(0.3)
              : AppColors.surfaceDark,
          selectedColor: AppColors.gold.withOpacity(0.2),
          checkmarkColor: AppColors.gold,
          labelStyle: TextStyle(
            color: isRetired
                ? AppColors.textMuted
                : (isSelected ? AppColors.gold : AppColors.textPrimary),
          ),
        );
      }).toList(),
    );
  }
}
