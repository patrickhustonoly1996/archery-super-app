import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../providers/skills_provider.dart';
import '../db/database.dart';
import '../mixins/form_validation_mixin.dart';
import '../widgets/loading_button.dart';
import '../widgets/photo_hint_button.dart';
import '../models/bow_specifications.dart';
import '../utils/unique_id.dart';

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

  // Equipment - basic
  late TextEditingController _riserModelController;
  late TextEditingController _limbModelController;
  late TextEditingController _poundageController;

  // Equipment - extended
  String? _riserLength;
  String? _limbLength;
  late TextEditingController _markedLimbWeightController;
  late TextEditingController _drawWeightOnFingersController;
  late TextEditingController _peakWeightController;
  late TextEditingController _stringMaterialController;
  late TextEditingController _stringStrandsController;

  // Tuning - basic
  late TextEditingController _braceHeightController;
  late TextEditingController _tillerTopController;
  late TextEditingController _tillerBottomController;
  late TextEditingController _nockingPointController;
  late TextEditingController _buttonPositionController;
  late TextEditingController _buttonTensionController;
  late TextEditingController _clickerPositionController;

  // Tuning - extended
  late TextEditingController _buttonModelController;
  String? _centreShot;
  late TextEditingController _clickerModelController;

  // Accessories
  late TextEditingController _sightModelController;
  late TextEditingController _sightExtensionController;

  // Stabilizers
  late TextEditingController _longRodController;
  late TextEditingController _sideRodController;
  late TextEditingController _vBarAngleController;
  late TextEditingController _stabWeightsController;

  // Arrows
  late TextEditingController _arrowModelController;
  late TextEditingController _arrowSpineController;
  late TextEditingController _arrowLengthController;

  // Notes
  late TextEditingController _notesController;

  // Photo paths for tuning positions
  String? _buttonPositionPhotoPath;
  String? _centreShotPhotoPath;
  String? _clickerPositionPhotoPath;
  String? _restPositionPhotoPath;

  // Temporary bow ID for new bows (used for photo storage)
  late String _bowId;

  bool _isLoading = false;

  // Track which optional sections are expanded
  bool _showEquipmentDetails = false;
  bool _showAccessories = false;
  bool _showStabilizers = false;
  bool _showArrows = false;
  bool _showNotes = false;

  @override
  void initState() {
    super.initState();
    final bow = widget.bow;
    final specs = bow != null ? BowSpecifications.fromJson(bow.settings) : BowSpecifications();

    // Set bow ID for photo storage
    _bowId = bow?.id ?? UniqueId.withPrefix('bow');

    _nameController = TextEditingController(text: bow?.name ?? '');
    _bowType = bow?.bowType ?? 'recurve';
    _setAsDefault = bow?.isDefault ?? false;

    // Equipment - basic (from dedicated columns)
    _riserModelController = TextEditingController(text: bow?.riserModel ?? '');
    _limbModelController = TextEditingController(text: bow?.limbModel ?? '');
    _poundageController = TextEditingController(
      text: bow?.poundage?.toStringAsFixed(0) ?? '',
    );

    // Equipment - extended (from specs JSON)
    _riserLength = specs.riserLength;
    _limbLength = specs.limbLength;
    _markedLimbWeightController = TextEditingController(
      text: specs.markedLimbWeight?.toStringAsFixed(0) ?? '',
    );
    _drawWeightOnFingersController = TextEditingController(
      text: specs.drawWeightOnFingers?.toStringAsFixed(0) ?? '',
    );
    _peakWeightController = TextEditingController(
      text: specs.peakWeight?.toStringAsFixed(0) ?? '',
    );
    _stringMaterialController = TextEditingController(text: specs.stringMaterial ?? '');
    _stringStrandsController = TextEditingController(
      text: specs.stringStrands?.toString() ?? '',
    );

    // Tuning - basic (from dedicated columns)
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

    // Tuning - extended (from specs JSON)
    _buttonModelController = TextEditingController(text: specs.buttonModel ?? '');
    _centreShot = specs.centreShot;
    _clickerModelController = TextEditingController(text: specs.clickerModel ?? '');

    // Accessories (from specs JSON)
    _sightModelController = TextEditingController(text: specs.sightModel ?? '');
    _sightExtensionController = TextEditingController(text: specs.sightExtensionLength ?? '');

    // Stabilizers (from specs JSON)
    _longRodController = TextEditingController(
      text: specs.longRodLength?.toStringAsFixed(0) ?? '',
    );
    _sideRodController = TextEditingController(
      text: specs.sideRodLength?.toStringAsFixed(0) ?? '',
    );
    _vBarAngleController = TextEditingController(
      text: specs.vBarAngle?.toStringAsFixed(0) ?? '',
    );
    _stabWeightsController = TextEditingController(text: specs.stabilizerWeights ?? '');

    // Arrows (from specs JSON)
    _arrowModelController = TextEditingController(text: specs.arrowModel ?? '');
    _arrowSpineController = TextEditingController(text: specs.arrowSpine ?? '');
    _arrowLengthController = TextEditingController(
      text: specs.arrowLength?.toStringAsFixed(2) ?? '',
    );

    // Notes
    _notesController = TextEditingController(text: specs.notes ?? '');

    // Photo paths
    _buttonPositionPhotoPath = specs.buttonPositionPhotoPath;
    _centreShotPhotoPath = specs.centreShotPhotoPath;
    _clickerPositionPhotoPath = specs.clickerPositionPhotoPath;
    _restPositionPhotoPath = specs.restPositionPhotoPath;

    // Auto-expand sections that have data when editing
    if (bow != null) {
      _showEquipmentDetails = _riserLength != null ||
          _limbLength != null ||
          specs.markedLimbWeight != null ||
          specs.drawWeightOnFingers != null ||
          specs.peakWeight != null ||
          specs.stringMaterial != null ||
          specs.stringStrands != null;
      _showAccessories = specs.sightModel != null || specs.sightExtensionLength != null;
      _showStabilizers = specs.longRodLength != null ||
          specs.sideRodLength != null ||
          specs.vBarAngle != null ||
          specs.stabilizerWeights != null;
      _showArrows = specs.arrowModel != null ||
          specs.arrowSpine != null ||
          specs.arrowLength != null;
      _showNotes = specs.notes != null && specs.notes!.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _riserModelController.dispose();
    _limbModelController.dispose();
    _poundageController.dispose();
    _markedLimbWeightController.dispose();
    _drawWeightOnFingersController.dispose();
    _peakWeightController.dispose();
    _stringMaterialController.dispose();
    _stringStrandsController.dispose();
    _braceHeightController.dispose();
    _tillerTopController.dispose();
    _tillerBottomController.dispose();
    _nockingPointController.dispose();
    _buttonPositionController.dispose();
    _buttonTensionController.dispose();
    _clickerPositionController.dispose();
    _buttonModelController.dispose();
    _clickerModelController.dispose();
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
      final provider = context.read<EquipmentProvider>();

      // Parse numeric values for dedicated columns
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

      final skillsProvider = context.read<SkillsProvider>();
      final bowName = _nameController.text.trim();

      // Build complete specs for settings JSON
      final existingSpecs = widget.bow != null
          ? BowSpecifications.fromJson(widget.bow!.settings)
          : BowSpecifications();

      final updatedSpecs = BowSpecifications(
        // Photo paths
        buttonPositionPhotoPath: _buttonPositionPhotoPath,
        centreShotPhotoPath: _centreShotPhotoPath,
        clickerPositionPhotoPath: _clickerPositionPhotoPath,
        restPositionPhotoPath: _restPositionPhotoPath,
        weightsSetupPhotoPath: existingSpecs.weightsSetupPhotoPath,
        vBarSetupPhotoPath: existingSpecs.vBarSetupPhotoPath,
        // Keep brace height unit preference
        braceHeightUnit: existingSpecs.braceHeightUnit,
        // Equipment extended
        riserLength: _riserLength,
        limbLength: _limbLength,
        markedLimbWeight: double.tryParse(_markedLimbWeightController.text),
        drawWeightOnFingers: double.tryParse(_drawWeightOnFingersController.text),
        peakWeight: double.tryParse(_peakWeightController.text),
        stringMaterial: _stringMaterialController.text.trim().isEmpty
            ? null : _stringMaterialController.text.trim(),
        stringStrands: int.tryParse(_stringStrandsController.text),
        // Tuning extended
        buttonModel: _buttonModelController.text.trim().isEmpty
            ? null : _buttonModelController.text.trim(),
        centreShot: _centreShot,
        clickerModel: _clickerModelController.text.trim().isEmpty
            ? null : _clickerModelController.text.trim(),
        // Accessories
        sightModel: _sightModelController.text.trim().isEmpty
            ? null : _sightModelController.text.trim(),
        sightExtensionLength: _sightExtensionController.text.trim().isEmpty
            ? null : _sightExtensionController.text.trim(),
        // Stabilizers
        longRodLength: double.tryParse(_longRodController.text),
        sideRodLength: double.tryParse(_sideRodController.text),
        vBarAngle: double.tryParse(_vBarAngleController.text),
        stabilizerWeights: _stabWeightsController.text.trim().isEmpty
            ? null : _stabWeightsController.text.trim(),
        // Arrows
        arrowModel: _arrowModelController.text.trim().isEmpty
            ? null : _arrowModelController.text.trim(),
        arrowSpine: _arrowSpineController.text.trim().isEmpty
            ? null : _arrowSpineController.text.trim(),
        arrowLength: double.tryParse(_arrowLengthController.text),
        // Notes
        notes: _notesController.text.trim().isEmpty
            ? null : _notesController.text.trim(),
      );

      final settings = updatedSpecs.toJson();

      if (widget.bow == null) {
        // Create new bow
        await provider.createBow(
          name: bowName,
          bowType: _bowType,
          setAsDefault: _setAsDefault,
          settings: settings.isNotEmpty ? settings : null,
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
        // Award Equipment XP for adding a new bow
        await skillsProvider.awardEquipmentXp(reason: 'Added bow: $bowName');
      } else {
        // Update existing bow
        await provider.updateBow(
          id: widget.bow!.id,
          name: bowName,
          bowType: _bowType,
          settings: settings.isNotEmpty ? settings : null,
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
        // Award Equipment XP for updating bow settings
        await skillsProvider.awardEquipmentXp(reason: 'Updated bow: $bowName');
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
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _riserLength,
                    decoration: const InputDecoration(
                      labelText: 'Riser Length',
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('-')),
                      ...RiserLengthOptions.values.map((v) => DropdownMenuItem(
                            value: v,
                            child: Text('$v"'),
                          )),
                    ],
                    onChanged: (v) => setState(() => _riserLength = v),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _limbLength,
                    decoration: const InputDecoration(
                      labelText: 'Limb Length',
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('-')),
                      ...LimbLengthOptions.values.map((v) => DropdownMenuItem(
                            value: v,
                            child: Text(LimbLengthOptions.displayName(v)),
                          )),
                    ],
                    onChanged: (v) => setState(() => _limbLength = v),
                  ),
                ),
              ],
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

            // Equipment Details (expandable)
            _buildExpandableSection(
              title: 'More Equipment Details',
              isExpanded: _showEquipmentDetails,
              onToggle: () => setState(() => _showEquipmentDetails = !_showEquipmentDetails),
              children: [
                _buildNumberField(
                  controller: _markedLimbWeightController,
                  label: 'Marked Limb Weight',
                  suffix: '#',
                  hint: 'e.g., 44',
                  helperText: 'Weight printed on limbs (at 28")',
                ),
                if (_bowType == 'recurve' || _bowType == 'barebow')
                  _buildNumberField(
                    controller: _drawWeightOnFingersController,
                    label: 'Draw Weight on Fingers',
                    suffix: '#',
                    hint: 'e.g., 48',
                    helperText: 'Actual weight at your draw length',
                  ),
                if (_bowType == 'compound')
                  _buildNumberField(
                    controller: _peakWeightController,
                    label: 'Peak Weight',
                    suffix: '#',
                    hint: 'e.g., 60',
                    helperText: 'Peak draw weight on cams',
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

            // Button section
            _buildSectionHeader(context, 'BUTTON / CENTRE SHOT'),
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(
              controller: _buttonModelController,
              label: 'Button Model',
              hint: 'e.g., Beiter, Shibuya DX',
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: PhotoHintButton(
                    photoPath: _buttonPositionPhotoPath,
                    bowId: _bowId,
                    fieldName: 'buttonPosition',
                    label: 'Button Position',
                    onPhotoChanged: (path) => setState(() => _buttonPositionPhotoPath = path),
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
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: PhotoHintButton(
                    photoPath: _centreShotPhotoPath,
                    bowId: _bowId,
                    fieldName: 'centreShot',
                    label: 'Centre Shot',
                    onPhotoChanged: (path) => setState(() => _centreShotPhotoPath = path),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _centreShot,
              decoration: const InputDecoration(
                labelText: 'Centre Shot',
                helperText: 'Arrow position relative to string alignment',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Not set')),
                ...CentreShotOptions.values.map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(CentreShotOptions.displayName(v)),
                    )),
              ],
              onChanged: (v) => setState(() => _centreShot = v),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Clicker section
            _buildSectionHeader(context, 'CLICKER'),
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(
              controller: _clickerModelController,
              label: 'Clicker Model',
              hint: 'e.g., Beiter, Shibuya',
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
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
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: PhotoHintButton(
                    photoPath: _clickerPositionPhotoPath,
                    bowId: _bowId,
                    fieldName: 'clickerPosition',
                    label: 'Clicker Position',
                    onPhotoChanged: (path) => setState(() => _clickerPositionPhotoPath = path),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rest Position',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Photo only',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: PhotoHintButton(
                    photoPath: _restPositionPhotoPath,
                    bowId: _bowId,
                    fieldName: 'restPosition',
                    label: 'Rest Position',
                    onPhotoChanged: (path) => setState(() => _restPositionPhotoPath = path),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Accessories (expandable)
            _buildExpandableSection(
              title: 'SIGHT',
              isExpanded: _showAccessories,
              onToggle: () => setState(() => _showAccessories = !_showAccessories),
              children: [
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
              ],
            ),

            // Stabilizers (expandable)
            _buildExpandableSection(
              title: 'STABILIZERS',
              isExpanded: _showStabilizers,
              onToggle: () => setState(() => _showStabilizers = !_showStabilizers),
              children: [
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
              ],
            ),

            // Arrow Setup (expandable)
            _buildExpandableSection(
              title: 'ARROW SETUP',
              isExpanded: _showArrows,
              onToggle: () => setState(() => _showArrows = !_showArrows),
              children: [
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
              ],
            ),

            // Notes (expandable)
            _buildExpandableSection(
              title: 'NOTES',
              isExpanded: _showNotes,
              onToggle: () => setState(() => _showNotes = !_showNotes),
              children: [
                _buildTextField(
                  controller: _notesController,
                  label: 'General Notes',
                  hint: 'Any additional setup notes...',
                  maxLines: 4,
                ),
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

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceBright.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
        const SizedBox(height: AppSpacing.md),
      ],
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
}
