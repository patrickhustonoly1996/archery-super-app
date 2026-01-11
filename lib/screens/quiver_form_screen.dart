import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../db/database.dart';

class QuiverFormScreen extends StatefulWidget {
  final Quiver? quiver;

  const QuiverFormScreen({super.key, this.quiver});

  @override
  State<QuiverFormScreen> createState() => _QuiverFormScreenState();
}

class _QuiverFormScreenState extends State<QuiverFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedBowId;
  int _shaftCount = 12;
  bool _setAsDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.quiver?.name ?? '');
    _selectedBowId = widget.quiver?.bowId;
    _shaftCount = widget.quiver?.shaftCount ?? 12;
    _setAsDefault = widget.quiver?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<EquipmentProvider>();

      if (widget.quiver == null) {
        // Create new quiver
        await provider.createQuiver(
          name: _nameController.text.trim(),
          bowId: _selectedBowId,
          shaftCount: _shaftCount,
          setAsDefault: _setAsDefault,
        );
      } else {
        // Update existing quiver
        await provider.updateQuiver(
          id: widget.quiver!.id,
          name: _nameController.text.trim(),
          bowId: _selectedBowId,
        );
        if (_setAsDefault) {
          await provider.setDefaultQuiver(widget.quiver!.id);
        }
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Quiver Name',
                hintText: 'e.g., Indoor XX75',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a quiver name';
                }
                return null;
              },
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.gold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SwitchListTile(
              title: const Text('Set as default quiver'),
              subtitle: const Text('Use this quiver by default for new sessions'),
              value: _setAsDefault,
              activeColor: AppColors.gold,
              onChanged: (value) {
                setState(() => _setAsDefault = value);
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (!isEditing) ...[
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Creating this quiver will automatically generate $_shaftCount numbered arrows (1-$_shaftCount).',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
