import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/bow_training_provider.dart';
import '../db/database.dart';

/// Screen for managing bow training presets
class BowTrainingPresetsScreen extends StatefulWidget {
  const BowTrainingPresetsScreen({super.key});

  @override
  State<BowTrainingPresetsScreen> createState() =>
      _BowTrainingPresetsScreenState();
}

class _BowTrainingPresetsScreenState extends State<BowTrainingPresetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BowTrainingProvider>().loadPresets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Presets'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<BowTrainingProvider>(
        builder: (context, provider, _) {
          if (provider.presets.isEmpty) {
            return _EmptyState(onCreatePressed: () => _showPresetEditor(context));
          }

          // Separate system and user presets
          final systemPresets =
              provider.presets.where((p) => p.isDefault).toList();
          final userPresets =
              provider.presets.where((p) => !p.isDefault).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // User presets
              if (userPresets.isNotEmpty) ...[
                _SectionHeader(title: 'My Presets'),
                ...userPresets.map((preset) => _PresetTile(
                      preset: preset,
                      onEdit: () => _showPresetEditor(context, preset: preset),
                      onDelete: () => _confirmDelete(context, provider, preset),
                    )),
                const SizedBox(height: AppSpacing.lg),
              ],

              // System presets
              if (systemPresets.isNotEmpty) ...[
                _SectionHeader(title: 'Default Presets'),
                ...systemPresets.map((preset) => _PresetTile(
                      preset: preset,
                      isSystem: true,
                      onDelete: () => _confirmDelete(context, provider, preset),
                    )),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPresetEditor(context),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.backgroundDark,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPresetEditor(BuildContext context, {BowTrainingPreset? preset}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PresetEditorScreen(preset: preset),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    BowTrainingProvider provider,
    BowTrainingPreset preset,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(preset.isDefault ? 'Hide Preset?' : 'Delete Preset?'),
        content: Text(
          preset.isDefault
              ? 'This preset will be hidden but can be restored later.'
              : 'This preset will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deletePreset(preset.id);
              Navigator.pop(context);
            },
            child: Text(
              preset.isDefault ? 'Hide' : 'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreatePressed;

  const _EmptyState({required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No presets yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: onCreatePressed,
            child: const Text('Create Preset'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final BowTrainingPreset preset;
  final bool isSystem;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PresetTile({
    required this.preset,
    this.isSystem = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final totalDuration = BowTrainingProvider.calculateTotalDuration(preset);
    final durationStr = BowTrainingProvider.formatDuration(totalDuration);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: AppColors.surfaceDark,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSystem
                ? AppColors.surfaceLight
                : AppColors.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Icon(
            isSystem ? Icons.timer : Icons.timer_outlined,
            color: isSystem ? AppColors.textMuted : AppColors.gold,
            size: 20,
          ),
        ),
        title: Text(preset.name),
        subtitle: Text(
          '${preset.holdSeconds}s / ${preset.restSeconds}s / ${preset.sets} sets  •  $durationStr',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSystem && onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.textMuted,
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: Icon(
                  isSystem ? Icons.visibility_off_outlined : Icons.delete_outline,
                  size: 20,
                ),
                color: AppColors.textMuted,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

/// Screen for creating or editing a preset
class PresetEditorScreen extends StatefulWidget {
  final BowTrainingPreset? preset;

  const PresetEditorScreen({super.key, this.preset});

  @override
  State<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends State<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late int _holdSeconds;
  late int _restSeconds;
  late int _sets;
  bool _hasBreaks = false;
  int _breakAfterSets = 5;
  int _breakDurationSeconds = 120;

  bool get isEditing => widget.preset != null;

  @override
  void initState() {
    super.initState();
    final preset = widget.preset;
    _nameController = TextEditingController(text: preset?.name ?? '');
    _holdSeconds = preset?.holdSeconds ?? 30;
    _restSeconds = preset?.restSeconds ?? 30;
    _sets = preset?.sets ?? 5;
    _hasBreaks = preset?.breakAfterSets != null;
    _breakAfterSets = preset?.breakAfterSets ?? 5;
    _breakDurationSeconds = preset?.breakDurationSeconds ?? 120;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Preset' : 'New Preset'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _savePreset,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Preset Name',
                hintText: 'e.g., 5 min @ 30:30',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Hold time
            _NumberSelector(
              label: 'Hold Time',
              value: _holdSeconds,
              unit: 'sec',
              min: 5,
              max: 120,
              step: 5,
              onChanged: (v) => setState(() => _holdSeconds = v),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Rest time (0 = continuous holds)
            _NumberSelector(
              label: 'Rest Time',
              value: _restSeconds,
              unit: 'sec',
              min: 0,
              max: 120,
              step: 5,
              onChanged: (v) => setState(() => _restSeconds = v),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Number of sets
            _NumberSelector(
              label: 'Number of Sets',
              value: _sets,
              unit: 'sets',
              min: 1,
              max: 30,
              step: 1,
              onChanged: (v) => setState(() {
                _sets = v;
                // Clamp breakAfterSets if needed
                if (_breakAfterSets >= v) {
                  _breakAfterSets = (v > 2) ? v - 1 : 2;
                }
              }),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Breaks toggle
            SwitchListTile(
              title: const Text('Add Breaks'),
              subtitle: const Text('Rest longer after every few sets'),
              value: _hasBreaks,
              activeColor: AppColors.gold,
              onChanged: (v) => setState(() => _hasBreaks = v),
              contentPadding: EdgeInsets.zero,
            ),

            // Break settings
            if (_hasBreaks) ...[
              const SizedBox(height: AppSpacing.md),
              _NumberSelector(
                label: 'Break After Every',
                value: _breakAfterSets,
                unit: 'sets',
                min: 2,
                // Can't have break after more sets than total
                max: _sets > 2 ? _sets - 1 : 2,
                step: 1,
                onChanged: (v) => setState(() => _breakAfterSets = v),
              ),
              const SizedBox(height: AppSpacing.md),
              _NumberSelector(
                label: 'Break Duration',
                value: _breakDurationSeconds,
                unit: 'sec',
                min: 30,
                max: 300,
                step: 30,
                onChanged: (v) => setState(() => _breakDurationSeconds = v),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // Total duration preview
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Duration',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  Text(
                    _calculateTotalDuration(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
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

  String _calculateTotalDuration() {
    int total = _sets * (_holdSeconds + _restSeconds);
    total -= _restSeconds; // No rest after final hold

    if (_hasBreaks) {
      final breakCount = (_sets - 1) ~/ _breakAfterSets;
      total += breakCount * _breakDurationSeconds;
    }

    return BowTrainingProvider.formatDuration(total);
  }

  void _savePreset() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<BowTrainingProvider>();

    if (isEditing) {
      provider.updatePreset(
        id: widget.preset!.id,
        name: _nameController.text.trim(),
        holdSeconds: _holdSeconds,
        restSeconds: _restSeconds,
        sets: _sets,
        hasBreaks: _hasBreaks,
        breakAfterSets: _hasBreaks ? _breakAfterSets : null,
        breakDurationSeconds: _hasBreaks ? _breakDurationSeconds : null,
      );
    } else {
      provider.createPreset(
        name: _nameController.text.trim(),
        holdSeconds: _holdSeconds,
        restSeconds: _restSeconds,
        sets: _sets,
        breakAfterSets: _hasBreaks ? _breakAfterSets : null,
        breakDurationSeconds: _hasBreaks ? _breakDurationSeconds : null,
      );
    }

    Navigator.pop(context);
  }
}

class _NumberSelector extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _NumberSelector({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - step) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.gold,
        ),
        SizedBox(
          width: 80,
          child: Text(
            '$value $unit',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + step) : null,
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.gold,
        ),
      ],
    );
  }
}
