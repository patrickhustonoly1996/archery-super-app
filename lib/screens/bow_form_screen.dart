import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../db/database.dart';
import '../mixins/form_validation_mixin.dart';
import '../widgets/loading_button.dart';

class BowFormScreen extends StatefulWidget {
  final Bow? bow;

  const BowFormScreen({super.key, this.bow});

  @override
  State<BowFormScreen> createState() => _BowFormScreenState();
}

class _BowFormScreenState extends State<BowFormScreen> with FormValidationMixin {
  final _formKey = GlobalKey<FormState>();

  // Basic info
  late TextEditingController _nameController;
  String _bowType = 'recurve';
  bool _setAsDefault = false;

  // Equipment
  late TextEditingController _riserModelController;
  late TextEditingController _limbModelController;
  late TextEditingController _poundageController;

  // Tuning
  late TextEditingController _braceHeightController;
  late TextEditingController _tillerTopController;
  late TextEditingController _tillerBottomController;
  late TextEditingController _nockingPointController;
  late TextEditingController _buttonPositionController;
  late TextEditingController _buttonTensionController;
  late TextEditingController _clickerPositionController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final bow = widget.bow;

    _nameController = TextEditingController(text: bow?.name ?? '');
    _bowType = bow?.bowType ?? 'recurve';
    _setAsDefault = bow?.isDefault ?? false;

    // Equipment - read from dedicated columns
    _riserModelController = TextEditingController(text: bow?.riserModel ?? '');
    _limbModelController = TextEditingController(text: bow?.limbModel ?? '');
    _poundageController = TextEditingController(
      text: bow?.poundage?.toStringAsFixed(0) ?? '',
    );

    // Tuning - read from dedicated columns
    _braceHeightController = TextEditingController(
      text: bow?.braceHeight?.toStringAsFixed(1) ?? '',
    );
    _tillerTopController = TextEditingController(
      text: bow?.tillerTop?.toStringAsFixed(1) ?? '',
    );
    _tillerBottomController = TextEditingController(
      text: bow?.tillerBottom?.toStringAsFixed(1) ?? '',
    );
    _nockingPointController = TextEditingController(
      text: bow?.nockingPointHeight?.toStringAsFixed(1) ?? '',
    );
    _buttonPositionController = TextEditingController(
      text: bow?.buttonPosition?.toStringAsFixed(1) ?? '',
    );
    _buttonTensionController = TextEditingController(
      text: bow?.buttonTension ?? '',
    );
    _clickerPositionController = TextEditingController(
      text: bow?.clickerPosition?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _riserModelController.dispose();
    _limbModelController.dispose();
    _poundageController.dispose();
    _braceHeightController.dispose();
    _tillerTopController.dispose();
    _tillerBottomController.dispose();
    _nockingPointController.dispose();
    _buttonPositionController.dispose();
    _buttonTensionController.dispose();
    _clickerPositionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<EquipmentProvider>();

      // Parse numeric values
      final poundage = double.tryParse(_poundageController.text);
      final braceHeight = double.tryParse(_braceHeightController.text);
      final tillerTop = double.tryParse(_tillerTopController.text);
      final tillerBottom = double.tryParse(_tillerBottomController.text);
      final nockingPoint = double.tryParse(_nockingPointController.text);
      final buttonPosition = double.tryParse(_buttonPositionController.text);
      final clickerPosition = double.tryParse(_clickerPositionController.text);

      // Get text values (null if empty)
      final riserModel = _riserModelController.text.trim().isEmpty
          ? null : _riserModelController.text.trim();
      final limbModel = _limbModelController.text.trim().isEmpty
          ? null : _limbModelController.text.trim();
      final buttonTension = _buttonTensionController.text.trim().isEmpty
          ? null : _buttonTensionController.text.trim();

      if (widget.bow == null) {
        // Create new bow
        await provider.createBow(
          name: _nameController.text.trim(),
          bowType: _bowType,
          setAsDefault: _setAsDefault,
          riserModel: riserModel,
          limbModel: limbModel,
          poundage: poundage,
          braceHeight: braceHeight,
          tillerTop: tillerTop,
          tillerBottom: tillerBottom,
          nockingPointHeight: nockingPoint,
          buttonPosition: buttonPosition,
          buttonTension: buttonTension,
          clickerPosition: clickerPosition,
        );
      } else {
        // Update existing bow
        await provider.updateBow(
          id: widget.bow!.id,
          name: _nameController.text.trim(),
          bowType: _bowType,
          riserModel: riserModel,
          limbModel: limbModel,
          poundage: poundage,
          braceHeight: braceHeight,
          tillerTop: tillerTop,
          tillerBottom: tillerBottom,
          nockingPointHeight: nockingPoint,
          buttonPosition: buttonPosition,
          buttonTension: buttonTension,
          clickerPosition: clickerPosition,
        );
        if (_setAsDefault) {
          await provider.setDefaultBow(widget.bow!.id);
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving bow: $e'),
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
    final isEditing = widget.bow != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Bow' : 'Add Bow'),
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
            LoadingButton(
              label: 'Save',
              isLoading: _isLoading,
              onPressed: _save,
              style: LoadingButtonStyle.text,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Basic Info Section
            _buildSectionHeader(context, 'BASIC INFO'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Bow Name',
                hintText: 'e.g., Indoor Recurve',
              ),
              textCapitalization: TextCapitalization.words,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => validateRequired(value, fieldName: 'Name'),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _bowType,
              decoration: const InputDecoration(
                labelText: 'Bow Type',
              ),
              items: const [
                DropdownMenuItem(value: 'recurve', child: Text('Recurve')),
                DropdownMenuItem(value: 'compound', child: Text('Compound')),
                DropdownMenuItem(value: 'barebow', child: Text('Barebow')),
                DropdownMenuItem(value: 'longbow', child: Text('Longbow')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _bowType = value);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              title: const Text('Set as default bow'),
              subtitle: const Text('Use this bow by default for new sessions'),
              value: _setAsDefault,
              activeThumbColor: AppColors.gold,
              onChanged: (value) {
                setState(() => _setAsDefault = value);
              },
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Equipment Section
            _buildSectionHeader(context, 'EQUIPMENT'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _riserModelController,
              decoration: const InputDecoration(
                labelText: 'Riser Model',
                hintText: 'e.g., Hoyt Formula Xi 25"',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _limbModelController,
              decoration: const InputDecoration(
                labelText: 'Limb Model',
                hintText: 'e.g., Uukha VX1000',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _poundageController,
              decoration: const InputDecoration(
                labelText: 'Draw Weight',
                hintText: 'e.g., 48',
                suffixText: 'lbs',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Tuning Section
            _buildSectionHeader(context, 'TUNING', isPrimary: true),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _braceHeightController,
                    decoration: const InputDecoration(
                      labelText: 'Brace Height',
                      hintText: '225',
                      suffixText: 'mm',
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
                    controller: _nockingPointController,
                    decoration: const InputDecoration(
                      labelText: 'Nocking Point',
                      hintText: '3',
                      suffixText: 'mm',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tillerTopController,
                    decoration: const InputDecoration(
                      labelText: 'Tiller Top',
                      hintText: '175',
                      suffixText: 'mm',
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
                    controller: _tillerBottomController,
                    decoration: const InputDecoration(
                      labelText: 'Tiller Bottom',
                      hintText: '170',
                      suffixText: 'mm',
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _buttonPositionController,
                    decoration: const InputDecoration(
                      labelText: 'Button Position',
                      hintText: '10',
                      suffixText: 'mm',
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
                    controller: _buttonTensionController,
                    decoration: const InputDecoration(
                      labelText: 'Button Tension',
                      hintText: 'Medium',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _clickerPositionController,
              decoration: const InputDecoration(
                labelText: 'Clicker Position',
                hintText: '45',
                suffixText: 'mm',
                helperText: 'Distance from button center',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.gold.withOpacity(0.1)
            : AppColors.surfaceBright.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isPrimary ? AppColors.gold : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
