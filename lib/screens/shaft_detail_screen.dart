import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../providers/skills_provider.dart';
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

  // Core specs
  late TextEditingController _spineController;
  late TextEditingController _lengthController;
  late TextEditingController _totalWeightController;

  // Point
  late TextEditingController _pointWeightController;
  String? _pointType;

  // Nock
  late TextEditingController _nockColorController;
  late TextEditingController _nockBrandController;

  // Fletching
  late TextEditingController _fletchingTypeController;
  late TextEditingController _fletchingColorController;
  late TextEditingController _fletchingSizeController;
  late TextEditingController _fletchingAngleController;

  // Wrap
  bool _hasWrap = false;
  late TextEditingController _wrapColorController;

  // Notes & date
  late TextEditingController _notesController;
  DateTime? _purchaseDate;

  // For batch mode
  Set<int> _selectedShafts = {};
  bool _isBatchMode = false;

  static const _pointTypes = ['break-off', 'glue-in', 'screw-in'];

  @override
  void initState() {
    super.initState();
    _isBatchMode = widget.shaft == null;
    final s = widget.shaft;

    _spineController = TextEditingController(text: s?.spine?.toString() ?? '');
    _lengthController = TextEditingController(text: s?.lengthInches?.toString() ?? '');
    _totalWeightController = TextEditingController(
      text: s?.totalWeight?.toStringAsFixed(1) ?? '',
    );
    _pointWeightController = TextEditingController(text: s?.pointWeight?.toString() ?? '');
    _pointType = s?.pointType;
    _nockColorController = TextEditingController(text: s?.nockColor ?? '');
    _nockBrandController = TextEditingController(text: s?.nockBrand ?? '');
    _fletchingTypeController = TextEditingController(text: s?.fletchingType ?? '');
    _fletchingColorController = TextEditingController(text: s?.fletchingColor ?? '');
    _fletchingSizeController = TextEditingController(text: s?.fletchingSize ?? '');
    _fletchingAngleController = TextEditingController(
      text: s?.fletchingAngle?.toStringAsFixed(1) ?? '',
    );
    _hasWrap = s?.hasWrap ?? false;
    _wrapColorController = TextEditingController(text: s?.wrapColor ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');
    _purchaseDate = s?.purchaseDate;
  }

  @override
  void dispose() {
    _spineController.dispose();
    _lengthController.dispose();
    _totalWeightController.dispose();
    _pointWeightController.dispose();
    _nockColorController.dispose();
    _nockBrandController.dispose();
    _fletchingTypeController.dispose();
    _fletchingColorController.dispose();
    _fletchingSizeController.dispose();
    _fletchingAngleController.dispose();
    _wrapColorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _selectPurchaseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              surface: AppColors.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _purchaseDate = date);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final equipmentProvider = context.read<EquipmentProvider>();

    final spine = int.tryParse(_spineController.text);
    final length = double.tryParse(_lengthController.text);
    final totalWeight = double.tryParse(_totalWeightController.text);
    final pointWeight = int.tryParse(_pointWeightController.text);
    final fletchingAngle = double.tryParse(_fletchingAngleController.text);

    final fletchingType = _nullIfEmpty(_fletchingTypeController.text);
    final fletchingColor = _nullIfEmpty(_fletchingColorController.text);
    final fletchingSize = _nullIfEmpty(_fletchingSizeController.text);
    final nockColor = _nullIfEmpty(_nockColorController.text);
    final nockBrand = _nullIfEmpty(_nockBrandController.text);
    final wrapColor = _hasWrap ? _nullIfEmpty(_wrapColorController.text) : null;

    if (_isBatchMode) {
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

      // Get skills provider before async gap
      final skillsProvider = context.read<SkillsProvider>();

      await equipmentProvider.batchUpdateShaftSpecs(
        shaftIds: selectedShaftIds,
        spine: spine,
        lengthInches: length,
        totalWeight: totalWeight,
        pointWeight: pointWeight,
        pointType: _pointType,
        fletchingType: fletchingType,
        fletchingColor: fletchingColor,
        fletchingSize: fletchingSize,
        fletchingAngle: fletchingAngle,
        nockColor: nockColor,
        nockBrand: nockBrand,
        hasWrap: _hasWrap,
        wrapColor: wrapColor,
      );

      // Award Equipment XP for updating shaft specifications
      await skillsProvider.awardEquipmentXp(
        reason: 'Updated ${selectedShaftIds.length} shafts in ${widget.quiver.name}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated ${selectedShaftIds.length} shafts')),
        );
        Navigator.pop(context);
      }
    } else {
      final notes = _nullIfEmpty(_notesController.text);
      // Get skills provider before async gap
      final skillsProvider = context.read<SkillsProvider>();

      await equipmentProvider.updateShaftSpecs(
        shaftId: widget.shaft!.id,
        spine: spine,
        lengthInches: length,
        totalWeight: totalWeight,
        pointWeight: pointWeight,
        pointType: _pointType,
        fletchingType: fletchingType,
        fletchingColor: fletchingColor,
        fletchingSize: fletchingSize,
        fletchingAngle: fletchingAngle,
        nockColor: nockColor,
        nockBrand: nockBrand,
        hasWrap: _hasWrap,
        wrapColor: wrapColor,
        notes: notes,
        purchaseDate: _purchaseDate,
      );

      // Award Equipment XP for updating shaft specifications
      await skillsProvider.awardEquipmentXp(
        reason: 'Updated shaft #${widget.shaft!.number} in ${widget.quiver.name}',
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

            // Core Specs Section
            _buildSectionHeader(context, 'CORE SPECS'),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _spineController,
                    label: 'Spine',
                    hint: '500',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildTextField(
                    controller: _lengthController,
                    label: 'Length',
                    hint: '28.5',
                    suffix: '"',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _totalWeightController,
              label: 'Total Weight',
              hint: '320',
              suffix: 'gr',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Point Section
            _buildSectionHeader(context, 'POINT'),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _pointWeightController,
                    label: 'Weight',
                    hint: '110',
                    suffix: 'gr',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _pointType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('—')),
                      ..._pointTypes.map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          )),
                    ],
                    onChanged: (v) => setState(() => _pointType = v),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Nock Section
            _buildSectionHeader(context, 'NOCK'),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _nockBrandController,
                    label: 'Brand',
                    hint: 'Beiter',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildTextField(
                    controller: _nockColorController,
                    label: 'Color',
                    hint: 'Blue',
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Fletching Section
            _buildSectionHeader(context, 'FLETCHING'),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _fletchingTypeController,
                    label: 'Type',
                    hint: 'Spin Wings',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildTextField(
                    controller: _fletchingSizeController,
                    label: 'Size',
                    hint: '1.75"',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _fletchingColorController,
                    label: 'Color',
                    hint: 'Red/White',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildTextField(
                    controller: _fletchingAngleController,
                    label: 'Helical',
                    hint: '2',
                    suffix: '\u00B0',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Wrap Section
            _buildSectionHeader(context, 'WRAP'),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              title: const Text('Has arrow wrap'),
              value: _hasWrap,
              activeThumbColor: AppColors.gold,
              onChanged: (v) => setState(() => _hasWrap = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_hasWrap)
              _buildTextField(
                controller: _wrapColorController,
                label: 'Wrap Color/Design',
                hint: 'Gold stripe',
              ),

            if (!_isBatchMode) ...[
              const SizedBox(height: AppSpacing.xl),

              // Purchase & Notes Section
              _buildSectionHeader(context, 'NOTES'),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: _selectPurchaseDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Purchase Date',
                    suffixIcon: Icon(Icons.calendar_today, size: 20),
                  ),
                  child: Text(
                    _purchaseDate != null
                        ? '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'
                        : 'Tap to select',
                    style: TextStyle(
                      color: _purchaseDate != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildTextField(
                controller: _notesController,
                label: 'Notes',
                hint: 'Additional notes',
                maxLines: 3,
              ),
            ],

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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
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
          onSelected: isRetired
              ? null
              : (selected) {
                  setState(() {
                    if (selected) {
                      _selectedShafts.add(shaft.number);
                    } else {
                      _selectedShafts.remove(shaft.number);
                    }
                  });
                },
          backgroundColor: isRetired
              ? AppColors.surfaceLight.withValues(alpha: 0.3)
              : AppColors.surfaceDark,
          selectedColor: AppColors.gold.withValues(alpha: 0.2),
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
