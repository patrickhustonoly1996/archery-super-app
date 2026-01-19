import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/equipment_provider.dart';
import '../db/database.dart';

class StringFormScreen extends StatefulWidget {
  final String bowId;
  final BowString? bowString;

  const StringFormScreen({
    super.key,
    required this.bowId,
    this.bowString,
  });

  @override
  State<StringFormScreen> createState() => _StringFormScreenState();
}

class _StringFormScreenState extends State<StringFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _materialController;
  late TextEditingController _strandCountController;
  late TextEditingController _servingMaterialController;
  late TextEditingController _stringLengthController;
  late TextEditingController _colorController;
  late TextEditingController _notesController;

  DateTime? _purchaseDate;

  @override
  void initState() {
    super.initState();
    final s = widget.bowString;

    _nameController = TextEditingController(text: s?.name ?? '');
    _materialController = TextEditingController(text: s?.material ?? '');
    _strandCountController = TextEditingController(
      text: s?.strandCount?.toString() ?? '',
    );
    _servingMaterialController = TextEditingController(
      text: s?.servingMaterial ?? '',
    );
    _stringLengthController = TextEditingController(
      text: s?.stringLength?.toStringAsFixed(1) ?? '',
    );
    _colorController = TextEditingController(text: s?.color ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');
    _purchaseDate = s?.purchaseDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _materialController.dispose();
    _strandCountController.dispose();
    _servingMaterialController.dispose();
    _stringLengthController.dispose();
    _colorController.dispose();
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

    setState(() => _isLoading = true);

    try {
      final provider = context.read<EquipmentProvider>();

      final name = _nullIfEmpty(_nameController.text);
      final material = _nullIfEmpty(_materialController.text);
      final strandCount = int.tryParse(_strandCountController.text);
      final servingMaterial = _nullIfEmpty(_servingMaterialController.text);
      final stringLength = double.tryParse(_stringLengthController.text);
      final color = _nullIfEmpty(_colorController.text);
      final notes = _nullIfEmpty(_notesController.text);

      if (widget.bowString == null) {
        await provider.createBowString(
          bowId: widget.bowId,
          name: name,
          material: material,
          strandCount: strandCount,
          servingMaterial: servingMaterial,
          stringLength: stringLength,
          color: color,
          purchaseDate: _purchaseDate,
          notes: notes,
        );
      } else {
        await provider.updateBowString(
          id: widget.bowString!.id,
          name: name,
          material: material,
          strandCount: strandCount,
          servingMaterial: servingMaterial,
          stringLength: stringLength,
          color: color,
          purchaseDate: _purchaseDate,
          notes: notes,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
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
    final isEditing = widget.bowString != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit String' : 'Add String'),
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
                labelText: 'String Name (optional)',
                hintText: 'e.g., Competition String, Backup',
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: AppSpacing.xl),
            _buildSectionHeader(context, 'SPECIFICATIONS'),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _materialController,
              decoration: const InputDecoration(
                labelText: 'Material',
                hintText: 'e.g., 8125G, BCY-X, Fast Flight Plus',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _strandCountController,
                    decoration: const InputDecoration(
                      labelText: 'Strand Count',
                      hintText: '18',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _stringLengthController,
                    decoration: const InputDecoration(
                      labelText: 'Length (AMO)',
                      hintText: '68',
                      suffixText: '"',
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
            TextFormField(
              controller: _servingMaterialController,
              decoration: const InputDecoration(
                labelText: 'Serving Material',
                hintText: 'e.g., Angel Majesty, NG+',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Color',
                hintText: 'e.g., Black, Red/Blue',
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: AppSpacing.xl),
            _buildSectionHeader(context, 'PURCHASE INFO'),
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

            const SizedBox(height: AppSpacing.xl),
            _buildSectionHeader(context, 'NOTES'),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Any other details...',
              ),
              maxLines: 3,
            ),

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
}
