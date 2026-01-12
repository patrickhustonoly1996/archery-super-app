import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../db/database.dart';

class BowFormScreen extends StatefulWidget {
  final Bow? bow;

  const BowFormScreen({super.key, this.bow});

  @override
  State<BowFormScreen> createState() => _BowFormScreenState();
}

class _BowFormScreenState extends State<BowFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String _bowType = 'recurve';
  bool _setAsDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bow?.name ?? '');
    _bowType = widget.bow?.bowType ?? 'recurve';
    _setAsDefault = widget.bow?.isDefault ?? false;
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

      if (widget.bow == null) {
        // Create new bow
        await provider.createBow(
          name: _nameController.text.trim(),
          bowType: _bowType,
          setAsDefault: _setAsDefault,
        );
      } else {
        // Update existing bow
        await provider.updateBow(
          id: widget.bow!.id,
          name: _nameController.text.trim(),
          bowType: _bowType,
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
                labelText: 'Bow Name',
                hintText: 'e.g., Indoor Recurve',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a bow name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              value: _bowType,
              decoration: const InputDecoration(
                labelText: 'Bow Type',
              ),
              items: const [
                DropdownMenuItem(value: 'recurve', child: Text('Recurve')),
                DropdownMenuItem(value: 'compound', child: Text('Compound')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _bowType = value);
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
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
            const SizedBox(height: AppSpacing.xxl),
            if (!isEditing)
              Text(
                'You can configure additional settings like tiller and brace height after creating the bow.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
