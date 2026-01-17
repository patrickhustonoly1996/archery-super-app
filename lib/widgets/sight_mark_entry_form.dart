import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/sight_marks_provider.dart';
import '../models/sight_mark.dart';
import '../models/weather_conditions.dart';

/// Form for adding or editing a sight mark
class SightMarkEntryForm extends StatefulWidget {
  final String bowId;
  final SightMark? existingMark;
  final DistanceUnit? defaultUnit;
  final double? defaultDistance;
  final VoidCallback? onSaved;
  final WeatherConditions? currentWeather;

  const SightMarkEntryForm({
    super.key,
    required this.bowId,
    this.existingMark,
    this.defaultUnit,
    this.defaultDistance,
    this.onSaved,
    this.currentWeather,
  });

  @override
  State<SightMarkEntryForm> createState() => _SightMarkEntryFormState();
}

class _SightMarkEntryFormState extends State<SightMarkEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController();
  final _sightValueController = TextEditingController();
  final _slopeController = TextEditingController();

  late DistanceUnit _unit;
  bool _isSaving = false;
  bool _showAdvanced = false;

  // Common outdoor distances for quick selection
  final List<double> _commonMeters = [18, 25, 30, 40, 50, 60, 70, 90];
  final List<double> _commonYards = [20, 30, 40, 50, 60, 70, 80, 100];

  @override
  void initState() {
    super.initState();

    if (widget.existingMark != null) {
      _unit = widget.existingMark!.unit;
      _distanceController.text = widget.existingMark!.distance.toStringAsFixed(0);
      _sightValueController.text = widget.existingMark!.sightValue;
      if (widget.existingMark!.slopeAngle != null) {
        _slopeController.text = widget.existingMark!.slopeAngle!.toStringAsFixed(0);
        _showAdvanced = true;
      }
    } else {
      _unit = widget.defaultUnit ?? DistanceUnit.meters;
      if (widget.defaultDistance != null) {
        _distanceController.text = widget.defaultDistance!.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _sightValueController.dispose();
    _slopeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingMark != null;
    final commonDistances =
        _unit == DistanceUnit.meters ? _commonMeters : _commonYards;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              isEditing ? 'Edit Sight Mark' : 'Add Sight Mark',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Unit selector
            Row(
              children: [
                Text(
                  'Unit:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(width: AppSpacing.md),
                SegmentedButton<DistanceUnit>(
                  segments: const [
                    ButtonSegment(
                      value: DistanceUnit.meters,
                      label: Text('Meters'),
                    ),
                    ButtonSegment(
                      value: DistanceUnit.yards,
                      label: Text('Yards'),
                    ),
                  ],
                  selected: {_unit},
                  onSelectionChanged: (selected) {
                    setState(() => _unit = selected.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Quick distance selection (only when adding new)
            if (!isEditing) ...[
              Text(
                'Common distances:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: commonDistances.map((d) {
                  final isSelected =
                      _distanceController.text == d.toStringAsFixed(0);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _distanceController.text = d.toStringAsFixed(0);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.gold
                            : AppColors.surfaceBright,
                        borderRadius: BorderRadius.circular(AppSpacing.xs),
                      ),
                      child: Text(
                        '${d.toStringAsFixed(0)}${_unit.abbreviation}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? AppColors.background
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Distance input
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _distanceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Distance',
                      suffixText: _unit.abbreviation,
                      filled: true,
                      fillColor: AppColors.surfaceBright.withOpacity(0.5),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final distance = double.tryParse(value);
                      if (distance == null || distance <= 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _sightValueController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Sight Mark',
                      hintText: '5.14 or 51.4',
                      filled: true,
                      fillColor: AppColors.surfaceBright.withOpacity(0.5),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                    autofocus: !isEditing && widget.defaultDistance != null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Advanced options toggle
            GestureDetector(
              onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              child: Row(
                children: [
                  Icon(
                    _showAdvanced
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Field conditions',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
            ),

            if (_showAdvanced) ...[
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _slopeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[-\d.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Slope Angle',
                  hintText: '-15 to +15',
                  suffixText: '°',
                  helperText: 'Negative = uphill, Positive = downhill',
                  filled: true,
                  fillColor: AppColors.surfaceBright.withOpacity(0.5),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final slope = double.tryParse(value);
                    if (slope == null || slope < -15 || slope > 15) {
                      return 'Must be -15 to +15';
                    }
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      )
                    : Text(isEditing ? 'Update' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = context.read<SightMarksProvider>();
      final distance = double.parse(_distanceController.text);
      final sightValue = _sightValueController.text;
      final slope = _slopeController.text.isNotEmpty
          ? double.tryParse(_slopeController.text)
          : null;

      if (widget.existingMark != null) {
        await provider.updateSightMark(
          id: widget.existingMark!.id,
          bowId: widget.bowId,
          distance: distance,
          unit: _unit,
          sightValue: sightValue,
          weather: widget.currentWeather,
          slopeAngle: slope,
        );
      } else {
        await provider.addSightMark(
          bowId: widget.bowId,
          distance: distance,
          unit: _unit,
          sightValue: sightValue,
          weather: widget.currentWeather,
          slopeAngle: slope,
          confidenceScore: 0.7, // Default confidence for manual entry
        );
      }

      widget.onSaved?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// Compact sight mark prompt shown after scoring ends
class SightMarkQuickPrompt extends StatelessWidget {
  final String bowId;
  final double distance;
  final DistanceUnit unit;
  final WeatherConditions? weather;
  final VoidCallback? onDismiss;
  final VoidCallback? onSaved;

  const SightMarkQuickPrompt({
    super.key,
    required this.bowId,
    required this.distance,
    required this.unit,
    this.weather,
    this.onDismiss,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceDark,
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.visibility, color: AppColors.gold, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Record sight mark for ${distance.toStringAsFixed(0)}${unit.abbreviation}?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDismiss,
                  visualDensity: VisualDensity.compact,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: const BorderSide(color: AppColors.surfaceBright),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Not now'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showEntryForm(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.background,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Record'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEntryForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.md)),
      ),
      builder: (ctx) => SightMarkEntryForm(
        bowId: bowId,
        defaultDistance: distance,
        defaultUnit: unit,
        currentWeather: weather,
        onSaved: () {
          Navigator.pop(ctx);
          onSaved?.call();
        },
      ),
    );
  }
}
