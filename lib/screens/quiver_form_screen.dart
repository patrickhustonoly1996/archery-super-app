import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../providers/skills_provider.dart';
import '../db/database.dart';
import '../mixins/form_validation_mixin.dart';
import '../widgets/loading_button.dart';
import '../models/arrow_specifications.dart';

class QuiverFormScreen extends StatefulWidget {
  final Quiver? quiver;

  const QuiverFormScreen({super.key, this.quiver});

  @override
  State<QuiverFormScreen> createState() => _QuiverFormScreenState();
}

class _QuiverFormScreenState extends State<QuiverFormScreen>
    with FormValidationMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedBowId;
  int _shaftCount = 12;
  bool _setAsDefault = false;
  bool _isLoading = false;

  // Arrow spec controllers - Shaft
  final _shaftModelController = TextEditingController();
  final _shaftDiameterController = TextEditingController();
  final _cutLengthController = TextEditingController();
  final _totalLengthController = TextEditingController();

  // Arrow spec controllers - Point
  final _pointModelController = TextEditingController();
  final _pointWeightController = TextEditingController();

  // Arrow spec controllers - Nock
  final _nockModelController = TextEditingController();
  final _nockSizeController = TextEditingController();
  final _nockColorController = TextEditingController();

  // Arrow spec controllers - Fletching
  final _fletchTypeController = TextEditingController();
  final _fletchModelController = TextEditingController();
  final _fletchSizeController = TextEditingController();
  final _fletchAngleController = TextEditingController();
  final _fletchColorController = TextEditingController();
  final _fletchCountController = TextEditingController();

  // Arrow spec controllers - Wrap
  final _wrapModelController = TextEditingController();
  final _wrapColorController = TextEditingController();

  // Arrow spec controllers - Notes
  final _notesController = TextEditingController();

  // Dropdown values
  String? _shaftSpine;
  String? _pointType;
  String? _nockType;
  bool? _hasWrap;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.quiver?.name ?? '');
    _selectedBowId = widget.quiver?.bowId;
    _shaftCount = widget.quiver?.shaftCount ?? 12;
    _setAsDefault = widget.quiver?.isDefault ?? false;

    // Initialize arrow specs if editing
    if (widget.quiver != null) {
      _initializeArrowSpecs();
    }
  }

  void _initializeArrowSpecs() {
    final specs = ArrowSpecifications.fromJson(widget.quiver?.settings);

    // Shaft
    _shaftModelController.text = specs.shaftModel ?? '';
    _shaftSpine = specs.shaftSpine;
    _shaftDiameterController.text =
        specs.shaftDiameter?.toStringAsFixed(1) ?? '';
    _cutLengthController.text = specs.cutLength?.toStringAsFixed(2) ?? '';
    _totalLengthController.text = specs.totalLength?.toStringAsFixed(2) ?? '';

    // Point
    _pointType = specs.pointType;
    _pointModelController.text = specs.pointModel ?? '';
    _pointWeightController.text = specs.pointWeight?.toString() ?? '';

    // Nock
    _nockType = specs.nockType;
    _nockModelController.text = specs.nockModel ?? '';
    _nockSizeController.text = specs.nockSize ?? '';
    _nockColorController.text = specs.nockColor ?? '';

    // Fletching
    _fletchTypeController.text = specs.fletchType ?? '';
    _fletchModelController.text = specs.fletchModel ?? '';
    _fletchSizeController.text = specs.fletchSize?.toStringAsFixed(2) ?? '';
    _fletchAngleController.text = specs.fletchAngle?.toStringAsFixed(1) ?? '';
    _fletchColorController.text = specs.fletchColor ?? '';
    _fletchCountController.text = specs.fletchCount?.toString() ?? '3';

    // Wrap
    _hasWrap = specs.hasWrap;
    _wrapModelController.text = specs.wrapModel ?? '';
    _wrapColorController.text = specs.wrapColor ?? '';

    // Notes
    _notesController.text = specs.notes ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shaftModelController.dispose();
    _shaftDiameterController.dispose();
    _cutLengthController.dispose();
    _totalLengthController.dispose();
    _pointModelController.dispose();
    _pointWeightController.dispose();
    _nockModelController.dispose();
    _nockSizeController.dispose();
    _nockColorController.dispose();
    _fletchTypeController.dispose();
    _fletchModelController.dispose();
    _fletchSizeController.dispose();
    _fletchAngleController.dispose();
    _fletchColorController.dispose();
    _fletchCountController.dispose();
    _wrapModelController.dispose();
    _wrapColorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  ArrowSpecifications _buildArrowSpecs() {
    return ArrowSpecifications(
      // Shaft
      shaftModel: _shaftModelController.text.isEmpty
          ? null
          : _shaftModelController.text,
      shaftSpine: _shaftSpine,
      shaftDiameter: double.tryParse(_shaftDiameterController.text),
      cutLength: double.tryParse(_cutLengthController.text),
      totalLength: double.tryParse(_totalLengthController.text),
      // Point
      pointType: _pointType,
      pointModel: _pointModelController.text.isEmpty
          ? null
          : _pointModelController.text,
      pointWeight: int.tryParse(_pointWeightController.text),
      // Nock
      nockType: _nockType,
      nockModel:
          _nockModelController.text.isEmpty ? null : _nockModelController.text,
      nockSize:
          _nockSizeController.text.isEmpty ? null : _nockSizeController.text,
      nockColor:
          _nockColorController.text.isEmpty ? null : _nockColorController.text,
      // Fletching
      fletchType: _fletchTypeController.text.isEmpty
          ? null
          : _fletchTypeController.text,
      fletchModel: _fletchModelController.text.isEmpty
          ? null
          : _fletchModelController.text,
      fletchSize: double.tryParse(_fletchSizeController.text),
      fletchAngle: double.tryParse(_fletchAngleController.text),
      fletchColor: _fletchColorController.text.isEmpty
          ? null
          : _fletchColorController.text,
      fletchCount: int.tryParse(_fletchCountController.text),
      // Wrap
      hasWrap: _hasWrap,
      wrapModel:
          _wrapModelController.text.isEmpty ? null : _wrapModelController.text,
      wrapColor:
          _wrapColorController.text.isEmpty ? null : _wrapColorController.text,
      // Notes
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<EquipmentProvider>();
      final skillsProvider = context.read<SkillsProvider>();
      final quiverName = _nameController.text.trim();
      final arrowSpecs = _buildArrowSpecs();

      if (widget.quiver == null) {
        // Create new quiver with arrow specs
        await provider.createQuiver(
          name: quiverName,
          bowId: _selectedBowId,
          shaftCount: _shaftCount,
          setAsDefault: _setAsDefault,
          settings: arrowSpecs.toJson(),
        );
        // Award Equipment XP for adding a new quiver
        await skillsProvider.awardEquipmentXp(reason: 'Added quiver: $quiverName');
      } else {
        // Update existing quiver
        await provider.updateQuiver(
          id: widget.quiver!.id,
          name: quiverName,
          bowId: _selectedBowId,
          settings: arrowSpecs.toJson(),
        );
        if (_setAsDefault) {
          await provider.setDefaultQuiver(widget.quiver!.id);
        }
        // Award Equipment XP for updating quiver settings
        await skillsProvider.awardEquipmentXp(reason: 'Updated quiver: $quiverName');
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving quiver: $e'),
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
    final isEditing = widget.quiver != null;
    final equipmentProvider = context.watch<EquipmentProvider>();
    final bows = equipmentProvider.bows;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Quiver' : 'Add Quiver'),
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
            // === QUIVER INFO ===
            _buildSectionHeader('QUIVER', isPrimary: true),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Quiver Name',
                hintText: 'e.g., Indoor XX75',
              ),
              textCapitalization: TextCapitalization.words,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => validateRequired(value, fieldName: 'Name'),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (bows.isNotEmpty)
              DropdownButtonFormField<String?>(
                value: _selectedBowId,
                decoration: const InputDecoration(
                  labelText: 'Link to Bow (Optional)',
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
              )
            else
              Card(
                color: AppColors.surfaceLight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'No bows configured. You can add a bow later to link it to this quiver.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            if (!isEditing) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Number of Arrows',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _shaftCount.toDouble(),
                      min: 6,
                      max: 24,
                      divisions: 6,
                      activeColor: AppColors.gold,
                      inactiveColor: AppColors.surfaceLight,
                      label: _shaftCount.toString(),
                      onChanged: (value) {
                        setState(() => _shaftCount = value.toInt());
                      },
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      _shaftCount.toString(),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.gold,
                              ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              title: const Text('Set as default quiver'),
              subtitle:
                  const Text('Use this quiver by default for new sessions'),
              value: _setAsDefault,
              activeThumbColor: AppColors.gold,
              onChanged: (value) {
                setState(() => _setAsDefault = value);
              },
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: AppSpacing.xl),

            // === SHAFT ===
            _buildSectionHeader('SHAFT', isPrimary: true),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _shaftModelController,
              label: 'Shaft Model',
              hint: 'e.g., Easton X10, ACE, ACG',
            ),
            _buildDropdownField(
              value: _shaftSpine,
              label: 'Spine',
              items: [
                const DropdownMenuItem(value: null, child: Text('Not set')),
                ...EastonSpineValues.allSpines.map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(v),
                    )),
              ],
              onChanged: (v) => setState(() => _shaftSpine = v),
            ),
            _buildNumberField(
              controller: _shaftDiameterController,
              label: 'Shaft Diameter',
              suffix: 'mm',
              hint: 'e.g., 4.0, 5.0',
            ),
            _buildNumberField(
              controller: _cutLengthController,
              label: 'Cut Length',
              suffix: '"',
              hint: 'e.g., 28.25',
              helperText: 'Shaft end to shaft end',
              decimalPlaces: 2,
            ),
            _buildNumberField(
              controller: _totalLengthController,
              label: 'Total Length',
              suffix: '"',
              hint: 'e.g., 29.5',
              helperText: 'Complete arrow with point',
              decimalPlaces: 2,
            ),

            const SizedBox(height: AppSpacing.xl),

            // === POINT ===
            _buildSectionHeader('POINT'),
            const SizedBox(height: AppSpacing.md),
            _buildDropdownField(
              value: _pointType,
              label: 'Point Type',
              items: [
                const DropdownMenuItem(value: null, child: Text('Not set')),
                ...PointTypeOptions.values.map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(PointTypeOptions.displayName(v)),
                    )),
              ],
              onChanged: (v) => setState(() => _pointType = v),
            ),
            _buildTextField(
              controller: _pointModelController,
              label: 'Point Model',
              hint: 'e.g., Easton Break-Off, TopHat',
            ),
            _buildDropdownField(
              value: _pointWeightController.text.isEmpty
                  ? null
                  : _pointWeightController.text,
              label: 'Point Weight',
              items: [
                const DropdownMenuItem(value: null, child: Text('Not set')),
                ...CommonPointWeights.values.map((v) => DropdownMenuItem(
                      value: v.toString(),
                      child: Text('$v gr'),
                    )),
              ],
              onChanged: (v) {
                setState(() => _pointWeightController.text = v ?? '');
              },
              helperText: 'Or enter custom weight below',
            ),
            _buildNumberField(
              controller: _pointWeightController,
              label: 'Custom Weight',
              suffix: 'gr',
              hint: 'e.g., 110',
              isInteger: true,
            ),

            const SizedBox(height: AppSpacing.xl),

            // === NOCK ===
            _buildSectionHeader('NOCK'),
            const SizedBox(height: AppSpacing.md),
            _buildDropdownField(
              value: _nockType,
              label: 'Nock Type',
              items: [
                const DropdownMenuItem(value: null, child: Text('Not set')),
                ...NockTypeOptions.values.map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(NockTypeOptions.displayName(v)),
                    )),
              ],
              onChanged: (v) => setState(() => _nockType = v),
            ),
            _buildTextField(
              controller: _nockModelController,
              label: 'Nock Model',
              hint: 'e.g., Beiter Pin Nock, Easton G',
            ),
            _buildTextField(
              controller: _nockSizeController,
              label: 'Nock Size',
              hint: 'e.g., S, M, L or specific size',
            ),

            const SizedBox(height: AppSpacing.xl),

            // === FLETCHING ===
            _buildSectionHeader('FLETCHING'),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _fletchTypeController,
              label: 'Fletching Type',
              hint: 'e.g., Spin Wing, Shield, Kurly Vane, Blazer',
            ),
            _buildTextField(
              controller: _fletchModelController,
              label: 'Fletching Model',
              hint: 'e.g., Spin Wing, Kurly Vane',
            ),
            _buildNumberField(
              controller: _fletchSizeController,
              label: 'Fletching Size',
              suffix: '"',
              hint: 'e.g., 1.75, 2.0',
              decimalPlaces: 2,
            ),
            _buildNumberField(
              controller: _fletchAngleController,
              label: 'Angle/Offset',
              suffix: '°',
              hint: 'e.g., 3, 5',
              helperText: 'Helical offset in degrees',
            ),
            _buildDropdownField(
              value: _fletchCountController.text.isEmpty
                  ? '3'
                  : _fletchCountController.text,
              label: 'Fletching Count',
              items: const [
                DropdownMenuItem(value: '3', child: Text('3 fletch')),
                DropdownMenuItem(value: '4', child: Text('4 fletch')),
              ],
              onChanged: (v) {
                setState(() => _fletchCountController.text = v ?? '3');
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // === WRAP ===
            _buildSectionHeader('WRAP'),
            const SizedBox(height: AppSpacing.md),
            _buildDropdownField(
              value: _hasWrap == null ? null : (_hasWrap! ? 'yes' : 'no'),
              label: 'Has Wrap',
              items: const [
                DropdownMenuItem(value: null, child: Text('Not specified')),
                DropdownMenuItem(value: 'yes', child: Text('Yes')),
                DropdownMenuItem(value: 'no', child: Text('No')),
              ],
              onChanged: (v) {
                setState(() {
                  if (v == null) {
                    _hasWrap = null;
                  } else {
                    _hasWrap = v == 'yes';
                  }
                });
              },
            ),
            if (_hasWrap == true) ...[
              _buildTextField(
                controller: _wrapModelController,
                label: 'Wrap Model',
                hint: 'e.g., Arrow Wraps, Custom',
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // === APPEARANCE (for Auto-Plot) ===
            _buildSectionHeader('APPEARANCE', isPrimary: true),
            const SizedBox(height: AppSpacing.md),
            _buildAutoPlotInfoCard(),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _nockColorController,
              label: 'Nock Color',
              hint: 'e.g., Red, Clear, Orange',
            ),
            _buildTextField(
              controller: _fletchColorController,
              label: 'Fletching Color',
              hint: 'e.g., Yellow, White/Red',
            ),
            _buildTextField(
              controller: _wrapColorController,
              label: 'Wrap Color',
              hint: 'e.g., Gold, Custom pattern',
            ),

            const SizedBox(height: AppSpacing.xl),

            // === NOTES ===
            _buildSectionHeader('NOTES'),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _notesController,
              label: 'General Notes',
              hint: 'Any additional arrow setup notes...',
              maxLines: 4,
            ),

            if (!isEditing) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Creating this quiver will automatically generate $_shaftCount numbered arrows (1-$_shaftCount).',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.gold.withValues(alpha: 0.1)
            : AppColors.surfaceBright.withValues(alpha: 0.5),
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

  Widget _buildAutoPlotInfoCard() {
    return Card(
      color: AppColors.gold.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.camera_alt,
              color: AppColors.gold,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Helps Auto-Plot identify your arrows',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Enter your arrow colors so Auto-Plot can distinguish your arrows from others on shared targets.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helperText,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
        ),
        maxLines: maxLines,
        textCapitalization: TextCapitalization.words,
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    String? suffix,
    String? hint,
    String? helperText,
    bool isInteger = false,
    int decimalPlaces = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
          suffixText: suffix,
        ),
        keyboardType: TextInputType.numberWithOptions(
          decimal: !isInteger,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
