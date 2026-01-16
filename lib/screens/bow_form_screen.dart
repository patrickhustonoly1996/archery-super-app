import 'package:flutter/material.dart';
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
  late TextEditingController _nameController;
  late TextEditingController _braceHeightController;
  late TextEditingController _tillerTopController;
  late TextEditingController _tillerBottomController;
  late TextEditingController _drawWeightController;
  late TextEditingController _riserController;
  late TextEditingController _limbsController;
  late TextEditingController _stabilizerController;
  late TextEditingController _notesController;
  String _bowType = 'recurve';
  bool _setAsDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bow?.name ?? '');
    _bowType = widget.bow?.bowType ?? 'recurve';
    _setAsDefault = widget.bow?.isDefault ?? false;

    // Parse existing settings if editing
    final settings = _parseSettings(widget.bow?.settings);
    _braceHeightController = TextEditingController(text: settings['braceHeight'] ?? '');
    _tillerTopController = TextEditingController(text: settings['tillerTop'] ?? '');
    _tillerBottomController = TextEditingController(text: settings['tillerBottom'] ?? '');
    _drawWeightController = TextEditingController(text: settings['drawWeight'] ?? '');
    _riserController = TextEditingController(text: settings['riser'] ?? '');
    _limbsController = TextEditingController(text: settings['limbs'] ?? '');
    _stabilizerController = TextEditingController(text: settings['stabilizer'] ?? '');
    _notesController = TextEditingController(text: settings['notes'] ?? '');
  }

  Map<String, String> _parseSettings(String? settingsJson) {
    if (settingsJson == null || settingsJson.isEmpty) {
      return {};
    }
    try {
      // Simple key=value parsing (avoiding heavy json dependency)
      final result = <String, String>{};
      final pairs = settingsJson.split('|');
      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          result[parts[0]] = parts[1];
        }
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  String _buildSettings() {
    final parts = <String>[];
    if (_braceHeightController.text.isNotEmpty) {
      parts.add('braceHeight:${_braceHeightController.text}');
    }
    if (_tillerTopController.text.isNotEmpty) {
      parts.add('tillerTop:${_tillerTopController.text}');
    }
    if (_tillerBottomController.text.isNotEmpty) {
      parts.add('tillerBottom:${_tillerBottomController.text}');
    }
    if (_drawWeightController.text.isNotEmpty) {
      parts.add('drawWeight:${_drawWeightController.text}');
    }
    if (_riserController.text.isNotEmpty) {
      parts.add('riser:${_riserController.text}');
    }
    if (_limbsController.text.isNotEmpty) {
      parts.add('limbs:${_limbsController.text}');
    }
    if (_stabilizerController.text.isNotEmpty) {
      parts.add('stabilizer:${_stabilizerController.text}');
    }
    if (_notesController.text.isNotEmpty) {
      parts.add('notes:${_notesController.text}');
    }
    return parts.join('|');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _braceHeightController.dispose();
    _tillerTopController.dispose();
    _tillerBottomController.dispose();
    _drawWeightController.dispose();
    _riserController.dispose();
    _limbsController.dispose();
    _stabilizerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<EquipmentProvider>();
      final settings = _buildSettings();

      if (widget.bow == null) {
        // Create new bow
        await provider.createBow(
          name: _nameController.text.trim(),
          bowType: _bowType,
          settings: settings.isNotEmpty ? settings : null,
          setAsDefault: _setAsDefault,
        );
      } else {
        // Update existing bow
        await provider.updateBow(
          id: widget.bow!.id,
          name: _nameController.text.trim(),
          bowType: _bowType,
          settings: settings.isNotEmpty ? settings : null,
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
            Text(
              'Basic Info',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.gold,
                  ),
            ),
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
            Text(
              'Equipment',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.gold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _riserController,
              decoration: const InputDecoration(
                labelText: 'Riser',
                hintText: 'e.g., Hoyt Formula Xi 25"',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _limbsController,
              decoration: const InputDecoration(
                labelText: 'Limbs',
                hintText: 'e.g., Uukha VX1000 44#',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _stabilizerController,
              decoration: const InputDecoration(
                labelText: 'Stabilizer Setup',
                hintText: 'e.g., Doinker 30" long, 12" sides',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Tuning Section
            Text(
              'Tuning',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.gold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _drawWeightController,
                    decoration: const InputDecoration(
                      labelText: 'Draw Weight',
                      hintText: 'e.g., 48',
                      suffixText: 'lbs',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _braceHeightController,
                    decoration: const InputDecoration(
                      labelText: 'Brace Height',
                      hintText: 'e.g., 225',
                      suffixText: 'mm',
                    ),
                    keyboardType: TextInputType.number,
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
                      hintText: 'e.g., 3',
                      suffixText: 'mm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _tillerBottomController,
                    decoration: const InputDecoration(
                      labelText: 'Tiller Bottom',
                      hintText: 'e.g., 0',
                      suffixText: 'mm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Notes Section
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.gold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Any other setup details...',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
