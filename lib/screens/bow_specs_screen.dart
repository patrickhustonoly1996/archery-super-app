import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../db/database.dart';
import '../models/bow_specifications.dart';

/// Screen for editing bow specifications
class BowSpecsScreen extends StatefulWidget {
  final Bow bow;
  final String initialSection;

  const BowSpecsScreen({
    super.key,
    required this.bow,
    this.initialSection = 'all',
  });

  @override
  State<BowSpecsScreen> createState() => _BowSpecsScreenState();
}

class _BowSpecsScreenState extends State<BowSpecsScreen> {
  final _formKey = GlobalKey<FormState>();
  late BowSpecifications _specs;
  bool _isLoading = false;

  // Controllers for primary settings
  final _braceHeightController = TextEditingController();
  final _nockingPointController = TextEditingController();
  final _tillerTopController = TextEditingController();
  final _tillerBottomController = TextEditingController();

  // Controllers for equipment
  final _riserModelController = TextEditingController();
  final _limbModelController = TextEditingController();
  final _limbPoundageController = TextEditingController();
  final _stringMaterialController = TextEditingController();
  final _stringStrandsController = TextEditingController();

  // Controllers for button
  final _buttonModelController = TextEditingController();
  final _buttonTensionController = TextEditingController();

  // Controllers for accessories
  final _clickerModelController = TextEditingController();
  final _clickerPositionController = TextEditingController();
  final _sightModelController = TextEditingController();
  final _sightExtensionController = TextEditingController();

  // Controllers for stabilizers
  final _longRodController = TextEditingController();
  final _sideRodController = TextEditingController();
  final _vBarAngleController = TextEditingController();
  final _stabWeightsController = TextEditingController();

  // Controllers for arrows
  final _arrowModelController = TextEditingController();
  final _arrowSpineController = TextEditingController();
  final _arrowLengthController = TextEditingController();

  // Controller for notes
  final _notesController = TextEditingController();

  // Dropdown values
  String? _riserLength;
  String? _limbLength;
  String? _centreShot;

  @override
  void initState() {
    super.initState();
    _specs = BowSpecifications.fromJson(widget.bow.settings);
    _initializeControllers();
  }

  void _initializeControllers() {
    // Primary
    _braceHeightController.text = _specs.braceHeight?.toStringAsFixed(1) ?? '';
    _nockingPointController.text = _specs.nockingPoint?.toStringAsFixed(1) ?? '';
    _tillerTopController.text = _specs.tillerTop?.toStringAsFixed(1) ?? '';
    _tillerBottomController.text = _specs.tillerBottom?.toStringAsFixed(1) ?? '';

    // Equipment
    _riserModelController.text = _specs.riserModel ?? '';
    _riserLength = _specs.riserLength;
    _limbModelController.text = _specs.limbModel ?? '';
    _limbLength = _specs.limbLength;
    _limbPoundageController.text = _specs.limbPoundage?.toStringAsFixed(0) ?? '';
    _stringMaterialController.text = _specs.stringMaterial ?? '';
    _stringStrandsController.text = _specs.stringStrands?.toString() ?? '';

    // Button
    _buttonModelController.text = _specs.buttonModel ?? '';
    _buttonTensionController.text = _specs.buttonSpringTension ?? '';
    _centreShot = _specs.centreShot;

    // Accessories
    _clickerModelController.text = _specs.clickerModel ?? '';
    _clickerPositionController.text = _specs.clickerPosition?.toStringAsFixed(0) ?? '';
    _sightModelController.text = _specs.sightModel ?? '';
    _sightExtensionController.text = _specs.sightExtensionLength ?? '';

    // Stabilizers
    _longRodController.text = _specs.longRodLength?.toStringAsFixed(0) ?? '';
    _sideRodController.text = _specs.sideRodLength?.toStringAsFixed(0) ?? '';
    _vBarAngleController.text = _specs.vBarAngle?.toStringAsFixed(0) ?? '';
    _stabWeightsController.text = _specs.stabilizerWeights ?? '';

    // Arrows
    _arrowModelController.text = _specs.arrowModel ?? '';
    _arrowSpineController.text = _specs.arrowSpine ?? '';
    _arrowLengthController.text = _specs.arrowLength?.toStringAsFixed(2) ?? '';

    // Notes
    _notesController.text = _specs.notes ?? '';
  }

  @override
  void dispose() {
    _braceHeightController.dispose();
    _nockingPointController.dispose();
    _tillerTopController.dispose();
    _tillerBottomController.dispose();
    _riserModelController.dispose();
    _limbModelController.dispose();
    _limbPoundageController.dispose();
    _stringMaterialController.dispose();
    _stringStrandsController.dispose();
    _buttonModelController.dispose();
    _buttonTensionController.dispose();
    _clickerModelController.dispose();
    _clickerPositionController.dispose();
    _sightModelController.dispose();
    _sightExtensionController.dispose();
    _longRodController.dispose();
    _sideRodController.dispose();
    _vBarAngleController.dispose();
    _stabWeightsController.dispose();
    _arrowModelController.dispose();
    _arrowSpineController.dispose();
    _arrowLengthController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newSpecs = BowSpecifications(
        // Primary
        braceHeight: double.tryParse(_braceHeightController.text),
        nockingPoint: double.tryParse(_nockingPointController.text),
        tillerTop: double.tryParse(_tillerTopController.text),
        tillerBottom: double.tryParse(_tillerBottomController.text),
        // Equipment
        riserModel: _riserModelController.text.isEmpty ? null : _riserModelController.text,
        riserLength: _riserLength,
        limbModel: _limbModelController.text.isEmpty ? null : _limbModelController.text,
        limbLength: _limbLength,
        limbPoundage: double.tryParse(_limbPoundageController.text),
        stringMaterial: _stringMaterialController.text.isEmpty ? null : _stringMaterialController.text,
        stringStrands: int.tryParse(_stringStrandsController.text),
        // Button
        buttonModel: _buttonModelController.text.isEmpty ? null : _buttonModelController.text,
        buttonSpringTension: _buttonTensionController.text.isEmpty ? null : _buttonTensionController.text,
        centreShot: _centreShot,
        // Accessories
        clickerModel: _clickerModelController.text.isEmpty ? null : _clickerModelController.text,
        clickerPosition: double.tryParse(_clickerPositionController.text),
        sightModel: _sightModelController.text.isEmpty ? null : _sightModelController.text,
        sightExtensionLength: _sightExtensionController.text.isEmpty ? null : _sightExtensionController.text,
        // Stabilizers
        longRodLength: double.tryParse(_longRodController.text),
        sideRodLength: double.tryParse(_sideRodController.text),
        vBarAngle: double.tryParse(_vBarAngleController.text),
        stabilizerWeights: _stabWeightsController.text.isEmpty ? null : _stabWeightsController.text,
        // Arrows
        arrowModel: _arrowModelController.text.isEmpty ? null : _arrowModelController.text,
        arrowSpine: _arrowSpineController.text.isEmpty ? null : _arrowSpineController.text,
        arrowLength: double.tryParse(_arrowLengthController.text),
        // Notes
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await context.read<EquipmentProvider>().updateBow(
            id: widget.bow.id,
            settings: newSpecs.toJson(),
          );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving specifications: $e'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bow Specifications'),
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
            // Primary Settings
            _buildSectionHeader('PRIMARY SETTINGS', isPrimary: true),
            _buildHelpText(
              'These are the most important settings to track. '
              'Record these after every equipment change.',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildNumberField(
              controller: _braceHeightController,
              label: 'Brace Height',
              suffix: 'mm',
              hint: 'e.g., 215',
              helperText: 'Distance from grip pivot to string',
            ),
            _buildNumberField(
              controller: _nockingPointController,
              label: 'Nocking Point',
              suffix: 'mm',
              hint: 'e.g., 3',
              helperText: 'Above square (use negative for below)',
              allowNegative: true,
            ),
            _buildNumberField(
              controller: _tillerTopController,
              label: 'Tiller (Top)',
              suffix: 'mm',
              hint: 'e.g., 175',
              helperText: 'Distance from top limb base to string',
            ),
            _buildNumberField(
              controller: _tillerBottomController,
              label: 'Tiller (Bottom)',
              suffix: 'mm',
              hint: 'e.g., 170',
              helperText: 'Distance from bottom limb base to string',
            ),

            const SizedBox(height: AppSpacing.xl),

            // Equipment
            _buildSectionHeader('EQUIPMENT'),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _riserModelController,
              label: 'Riser Model',
              hint: 'e.g., Hoyt Formula Xi',
            ),
            _buildDropdownField(
              value: _riserLength,
              label: 'Riser Length',
              items: RiserLengthOptions.values
                  .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text('$v"'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _riserLength = v),
            ),
            _buildTextField(
              controller: _limbModelController,
              label: 'Limb Model',
              hint: 'e.g., Uukha VX1000',
            ),
            _buildDropdownField(
              value: _limbLength,
              label: 'Limb Length',
              items: LimbLengthOptions.values
                  .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(LimbLengthOptions.displayName(v)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _limbLength = v),
            ),
            _buildNumberField(
              controller: _limbPoundageController,
              label: 'Limb Poundage',
              suffix: '#',
              hint: 'e.g., 44',
              helperText: 'Draw weight at 28"',
            ),
            _buildTextField(
              controller: _stringMaterialController,
              label: 'String Material',
              hint: 'e.g., BCY-X, 8125, Fast Flight',
            ),
            _buildNumberField(
              controller: _stringStrandsController,
              label: 'String Strands',
              hint: 'e.g., 18',
              isInteger: true,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Button / Centre Shot
            _buildSectionHeader('BUTTON / CENTRE SHOT'),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _buttonModelController,
              label: 'Button Model',
              hint: 'e.g., Beiter, Shibuya DX',
            ),
            _buildTextField(
              controller: _buttonTensionController,
              label: 'Spring Tension',
              hint: 'e.g., Medium, 4/10, Soft',
            ),
            _buildDropdownField(
              value: _centreShot,
              label: 'Centre Shot',
              items: [
                const DropdownMenuItem(value: null, child: Text('Not set')),
                ...CentreShotOptions.values.map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(CentreShotOptions.displayName(v)),
                    )),
              ],
              onChanged: (v) => setState(() => _centreShot = v),
              helperText: 'Arrow position relative to string alignment',
            ),

            const SizedBox(height: AppSpacing.xl),

            // Accessories
            _buildSectionHeader('ACCESSORIES'),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _clickerModelController,
              label: 'Clicker Model',
              hint: 'e.g., Beiter, Shibuya',
            ),
            _buildNumberField(
              controller: _clickerPositionController,
              label: 'Clicker Position',
              suffix: 'mm',
              hint: 'e.g., 45',
              helperText: 'Distance from button center',
            ),
            _buildTextField(
              controller: _sightModelController,
              label: 'Sight Model',
              hint: 'e.g., Shibuya Ultima RC',
            ),
            _buildTextField(
              controller: _sightExtensionController,
              label: 'Sight Extension',
              hint: 'e.g., 6, 9',
              helperText: 'Extension length in inches',
            ),

            const SizedBox(height: AppSpacing.xl),

            // Stabilizers
            _buildSectionHeader('STABILIZERS'),
            const SizedBox(height: AppSpacing.md),
            _buildNumberField(
              controller: _longRodController,
              label: 'Long Rod Length',
              suffix: '"',
              hint: 'e.g., 30',
            ),
            _buildNumberField(
              controller: _sideRodController,
              label: 'Side Rod Length',
              suffix: '"',
              hint: 'e.g., 12',
            ),
            _buildNumberField(
              controller: _vBarAngleController,
              label: 'V-Bar Angle',
              suffix: '°',
              hint: 'e.g., 35',
            ),
            _buildTextField(
              controller: _stabWeightsController,
              label: 'Weights Setup',
              hint: 'e.g., 4oz long, 2oz each side',
              maxLines: 2,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Arrow Setup
            _buildSectionHeader('ARROW SETUP'),
            _buildHelpText('Reference arrow specs for this bow setup'),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _arrowModelController,
              label: 'Arrow Model',
              hint: 'e.g., Easton X10, ACE',
            ),
            _buildTextField(
              controller: _arrowSpineController,
              label: 'Arrow Spine',
              hint: 'e.g., 600, 700, 800',
            ),
            _buildNumberField(
              controller: _arrowLengthController,
              label: 'Arrow Length',
              suffix: '"',
              hint: 'e.g., 28.5',
              decimalPlaces: 2,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Notes
            _buildSectionHeader('NOTES'),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _notesController,
              label: 'General Notes',
              hint: 'Any additional setup notes...',
              maxLines: 4,
            ),

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

  Widget _buildHelpText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
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
    bool allowNegative = false,
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
          signed: allowNegative,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(allowNegative ? r'^-?\d*\.?\d*$' : r'^\d*\.?\d*$'),
          ),
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
