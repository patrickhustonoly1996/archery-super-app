import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../providers/skills_provider.dart';
import '../db/database.dart';
import '../models/arrow_specifications.dart';
import '../models/bow_specifications.dart';

/// Screen for editing arrow specifications
class QuiverSpecsScreen extends StatefulWidget {
  final Quiver quiver;
  final String initialSection;

  const QuiverSpecsScreen({
    super.key,
    required this.quiver,
    this.initialSection = 'all',
  });

  @override
  State<QuiverSpecsScreen> createState() => _QuiverSpecsScreenState();
}

class _QuiverSpecsScreenState extends State<QuiverSpecsScreen> {
  final _formKey = GlobalKey<FormState>();
  late ArrowSpecifications _specs;
  bool _isLoading = false;

  // Controllers for shaft
  final _shaftModelController = TextEditingController();
  final _shaftDiameterController = TextEditingController();
  final _cutLengthController = TextEditingController();
  final _totalLengthController = TextEditingController();

  // Controllers for point
  final _pointModelController = TextEditingController();
  final _pointWeightController = TextEditingController();

  // Controllers for nock
  final _nockModelController = TextEditingController();
  final _nockSizeController = TextEditingController();
  final _nockColorController = TextEditingController();

  // Controllers for fletching
  final _fletchModelController = TextEditingController();
  final _fletchSizeController = TextEditingController();
  final _fletchAngleController = TextEditingController();
  final _fletchColorController = TextEditingController();
  final _fletchCountController = TextEditingController();

  // Controllers for wrap
  final _wrapModelController = TextEditingController();
  final _wrapColorController = TextEditingController();

  // Controller for notes
  final _notesController = TextEditingController();

  // Dropdown values
  String? _shaftSpine;
  String? _pointType;
  String? _nockType;
  String? _fletchType;
  bool? _hasWrap;

  @override
  void initState() {
    super.initState();
    _specs = ArrowSpecifications.fromJson(widget.quiver.settings);
    _initializeControllers();
  }

  void _initializeControllers() {
    // Shaft
    _shaftModelController.text = _specs.shaftModel ?? '';
    _shaftSpine = _specs.shaftSpine;
    _shaftDiameterController.text = _specs.shaftDiameter?.toStringAsFixed(1) ?? '';
    _cutLengthController.text = _specs.cutLength?.toStringAsFixed(2) ?? '';
    _totalLengthController.text = _specs.totalLength?.toStringAsFixed(2) ?? '';

    // Point
    _pointType = _specs.pointType;
    _pointModelController.text = _specs.pointModel ?? '';
    _pointWeightController.text = _specs.pointWeight?.toString() ?? '';

    // Nock
    _nockType = _specs.nockType;
    _nockModelController.text = _specs.nockModel ?? '';
    _nockSizeController.text = _specs.nockSize ?? '';
    _nockColorController.text = _specs.nockColor ?? '';

    // Fletching
    _fletchType = _specs.fletchType;
    _fletchModelController.text = _specs.fletchModel ?? '';
    _fletchSizeController.text = _specs.fletchSize?.toStringAsFixed(2) ?? '';
    _fletchAngleController.text = _specs.fletchAngle?.toStringAsFixed(1) ?? '';
    _fletchColorController.text = _specs.fletchColor ?? '';
    _fletchCountController.text = _specs.fletchCount?.toString() ?? '3';

    // Wrap
    _hasWrap = _specs.hasWrap;
    _wrapModelController.text = _specs.wrapModel ?? '';
    _wrapColorController.text = _specs.wrapColor ?? '';

    // Notes
    _notesController.text = _specs.notes ?? '';
  }

  /// Copy arrow details from the linked bow's settings
  Future<void> _copyFromBow() async {
    if (widget.quiver.bowId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This quiver is not linked to a bow'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final bow = await context.read<EquipmentProvider>().getBow(widget.quiver.bowId!);
    if (bow == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Linked bow not found'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final bowSpecs = BowSpecifications.fromJson(bow.settings);

    // Check if bow has any arrow specs to copy
    if (bowSpecs.arrowModel == null && bowSpecs.arrowSpine == null && bowSpecs.arrowLength == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No arrow details found in bow settings'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    setState(() {
      // Copy available fields from bow
      if (bowSpecs.arrowModel != null) {
        _shaftModelController.text = bowSpecs.arrowModel!;
      }
      if (bowSpecs.arrowSpine != null) {
        _shaftSpine = bowSpecs.arrowSpine;
      }
      if (bowSpecs.arrowLength != null) {
        _totalLengthController.text = bowSpecs.arrowLength!.toStringAsFixed(2);
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied arrow details from ${bow.name}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  void dispose() {
    _shaftModelController.dispose();
    _shaftDiameterController.dispose();
    _cutLengthController.dispose();
    _totalLengthController.dispose();
    _pointModelController.dispose();
    _pointWeightController.dispose();
    _nockModelController.dispose();
    _nockSizeController.dispose();
    _nockColorController.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newSpecs = ArrowSpecifications(
        // Shaft
        shaftModel: _shaftModelController.text.isEmpty ? null : _shaftModelController.text,
        shaftSpine: _shaftSpine,
        shaftDiameter: double.tryParse(_shaftDiameterController.text),
        cutLength: double.tryParse(_cutLengthController.text),
        totalLength: double.tryParse(_totalLengthController.text),
        // Point
        pointType: _pointType,
        pointModel: _pointModelController.text.isEmpty ? null : _pointModelController.text,
        pointWeight: int.tryParse(_pointWeightController.text),
        // Nock
        nockType: _nockType,
        nockModel: _nockModelController.text.isEmpty ? null : _nockModelController.text,
        nockSize: _nockSizeController.text.isEmpty ? null : _nockSizeController.text,
        nockColor: _nockColorController.text.isEmpty ? null : _nockColorController.text,
        // Fletching
        fletchType: _fletchType,
        fletchModel: _fletchModelController.text.isEmpty ? null : _fletchModelController.text,
        fletchSize: double.tryParse(_fletchSizeController.text),
        fletchAngle: double.tryParse(_fletchAngleController.text),
        fletchColor: _fletchColorController.text.isEmpty ? null : _fletchColorController.text,
        fletchCount: int.tryParse(_fletchCountController.text),
        // Wrap
        hasWrap: _hasWrap,
        wrapModel: _wrapModelController.text.isEmpty ? null : _wrapModelController.text,
        wrapColor: _wrapColorController.text.isEmpty ? null : _wrapColorController.text,
        // Notes
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await context.read<EquipmentProvider>().updateQuiver(
            id: widget.quiver.id,
            settings: newSpecs.toJson(),
          );

      // Award XP for updating arrow specifications
      if (mounted) {
        await context.read<SkillsProvider>().awardEquipmentXp(
              reason: 'Updated arrow specs: ${widget.quiver.name}',
            );
      }

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
        title: const Text('Arrow Specifications'),
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
            // Copy from bow option (if linked)
            if (widget.quiver.bowId != null) ...[
              _buildCopyFromBowCard(),
              const SizedBox(height: AppSpacing.lg),
            ],
            // Shaft Section
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
                ...CommonSpineValues.values.map((v) => DropdownMenuItem(
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

            // Point Section
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
              value: _pointWeightController.text.isEmpty ? null : _pointWeightController.text,
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

            // Nock Section
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

            // Fletching Section
            _buildSectionHeader('FLETCHING'),
            const SizedBox(height: AppSpacing.md),
            _buildDropdownField(
              value: _fletchType,
              label: 'Fletching Type',
              items: [
                const DropdownMenuItem(value: null, child: Text('Not set')),
                ...FletchTypeOptions.values.map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(FletchTypeOptions.displayName(v)),
                    )),
              ],
              onChanged: (v) => setState(() => _fletchType = v),
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
              value: _fletchCountController.text.isEmpty ? '3' : _fletchCountController.text,
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

            // Wrap Section
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

            // Appearance Section (for Auto-Plot)
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

            // Notes
            _buildSectionHeader('NOTES'),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _notesController,
              label: 'General Notes',
              hint: 'Any additional arrow setup notes...',
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

  Widget _buildCopyFromBowCard() {
    return FutureBuilder<Bow?>(
      future: context.read<EquipmentProvider>().getBow(widget.quiver.bowId!),
      builder: (context, snapshot) {
        final bow = snapshot.data;
        final bowName = bow?.name ?? 'linked bow';

        return Card(
          color: AppColors.surfaceLight,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Linked to $bowName',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Copy arrow details from bow settings',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _copyFromBow,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
