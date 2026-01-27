import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/field_course.dart';
import '../models/field_course_target.dart';
import '../models/sight_mark.dart';
import '../providers/field_course_provider.dart';

class FieldTargetSetupSheet extends StatefulWidget {
  final int targetNumber;
  final FieldRoundType roundType;
  final Function(PegConfiguration pegConfig, int faceSize, String? notes) onSave;

  const FieldTargetSetupSheet({
    super.key,
    required this.targetNumber,
    required this.roundType,
    required this.onSave,
  });

  @override
  State<FieldTargetSetupSheet> createState() => _FieldTargetSetupSheetState();
}

class _FieldTargetSetupSheetState extends State<FieldTargetSetupSheet> {
  PegConfiguration? _selectedConfig;
  int? _selectedFaceSize;
  String _notes = '';
  bool _isCustomDistance = false;

  // Custom distance fields
  double _customDistance = 50;
  DistanceUnit _customUnit = DistanceUnit.yards;
  PegType _customPegType = PegType.single;
  List<double> _customDistances = [50];

  // Face-size-first flow - step tracking
  bool get _hasFaceSize => _selectedFaceSize != null;
  bool get _hasConfig => _selectedConfig != null || _isCustomDistance;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Fixed header with save button at top
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.surfaceLight.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Header row with title and save button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target ${widget.targetNumber}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontFamily: AppFonts.pixel,
                            ),
                      ),
                      ElevatedButton(
                        onPressed: _canSave() ? _save : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        child: const Text('Add Target'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // STEP 1: Face size first
                    _buildStepHeader(1, 'Select Face Size', _hasFaceSize),
                    const SizedBox(height: AppSpacing.sm),
                    _buildFaceSizeSection(),

                    const SizedBox(height: AppSpacing.xl),

                    // STEP 2: Peg configuration (only if face size selected)
                    _buildStepHeader(2, 'Select Distance', _hasConfig),
                    const SizedBox(height: AppSpacing.sm),
                    if (!_hasFaceSize)
                      _buildLockedSection('Select face size first')
                    else ...[
                      // Toggle between preset and custom
                      _buildModeToggle(),
                      const SizedBox(height: AppSpacing.lg),

                      // Content based on mode
                      if (_isCustomDistance)
                        _buildCustomDistanceSection()
                      else
                        _buildPresetSection(),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // Notes (optional)
                    Text(
                      'Notes (optional)',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'e.g., uphill, shadows',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                      ),
                      onChanged: (value) => _notes = value,
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepHeader(int step, String title, bool isComplete) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete ? AppColors.gold : AppColors.surfaceLight,
          ),
          alignment: Alignment.center,
          child: isComplete
              ? const Icon(Icons.check, size: 14, color: AppColors.background)
              : Text(
                  '$step',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: AppFonts.pixel,
              ),
        ),
      ],
    );
  }

  Widget _buildLockedSection(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Row(
      children: [
        Expanded(
          child: _ToggleCard(
            title: 'Preset',
            isSelected: !_isCustomDistance,
            onTap: () => setState(() => _isCustomDistance = false),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ToggleCard(
            title: 'Custom',
            isSelected: _isCustomDistance,
            onTap: () => setState(() => _isCustomDistance = true),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetSection() {
    return Consumer<FieldCourseProvider>(
      builder: (context, provider, _) {
        final allPresets = widget.roundType == FieldRoundType.animal
            ? provider.getAvailableAnimalPresets()
            : provider.getAvailableFieldPresets();

        // Filter presets by selected face size
        final presets = _selectedFaceSize != null
            ? allPresets.where((config) {
                final faceSizeForConfig =
                    IFAAFaceSizes.getFaceSize(config.primaryDistance);
                return faceSizeForConfig == _selectedFaceSize;
              }).toList()
            : allPresets;

        if (presets.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.gold,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _selectedFaceSize != null
                      ? 'No presets for ${_selectedFaceSize}cm face'
                      : 'All preset pegs are in use',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => setState(() => _isCustomDistance = true),
                  child: const Text('Use Custom Distance'),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Distances for ${_selectedFaceSize}cm',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: presets.map((config) {
                final isSelected = _selectedConfig?.displayString == config.displayString;
                return ChoiceChip(
                  label: Text(config.displayString),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedConfig = config;
                    });
                  },
                  selectedColor: AppColors.gold,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.background : AppColors.textPrimary,
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomDistanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Peg type selector
        Text(
          'Peg Type',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: const Text('Single'),
              selected: _customPegType == PegType.single,
              onSelected: (_) => setState(() {
                _customPegType = PegType.single;
                _customDistances = [_customDistance];
              }),
              selectedColor: AppColors.gold,
              labelStyle: TextStyle(
                color: _customPegType == PegType.single
                    ? AppColors.background
                    : AppColors.textPrimary,
              ),
            ),
            ChoiceChip(
              label: const Text('Walk-down'),
              selected: _customPegType == PegType.walkDown,
              onSelected: (_) => setState(() {
                _customPegType = PegType.walkDown;
                _customDistances = [_customDistance, _customDistance - 10, _customDistance - 20, _customDistance - 30];
              }),
              selectedColor: AppColors.gold,
              labelStyle: TextStyle(
                color: _customPegType == PegType.walkDown
                    ? AppColors.background
                    : AppColors.textPrimary,
              ),
            ),
            if (widget.roundType == FieldRoundType.animal)
              ChoiceChip(
                label: const Text('Walk-up'),
                selected: _customPegType == PegType.walkUp,
                onSelected: (_) => setState(() {
                  _customPegType = PegType.walkUp;
                  _customDistances = [_customDistance - 20, _customDistance - 10, _customDistance];
                }),
                selectedColor: AppColors.gold,
                labelStyle: TextStyle(
                  color: _customPegType == PegType.walkUp
                      ? AppColors.background
                      : AppColors.textPrimary,
                ),
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // Distance input(s)
        Text(
          _customPegType == PegType.single ? 'Distance' : 'Distances',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),

        if (_customPegType == PegType.single)
          _buildSingleDistanceInput()
        else
          _buildMultiDistanceInput(),

        const SizedBox(height: AppSpacing.md),

        // Unit selector
        Row(
          children: [
            Text(
              'Unit:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: AppSpacing.md),
            SegmentedButton<DistanceUnit>(
              segments: const [
                ButtonSegment(value: DistanceUnit.yards, label: Text('yd')),
                ButtonSegment(value: DistanceUnit.meters, label: Text('m')),
              ],
              selected: {_customUnit},
              onSelectionChanged: (selection) {
                setState(() => _customUnit = selection.first);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleDistanceInput() {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: _customDistance,
            min: 10,
            max: 100,
            divisions: 18,
            label: '${_customDistance.round()}',
            activeColor: AppColors.gold,
            onChanged: (value) {
              setState(() {
                _customDistance = value.roundToDouble();
                _customDistances = [_customDistance];
                _customFaceSize = IFAAFaceSizes.getFaceSize(_customDistance);
              });
            },
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            '${_customDistance.round()}${_customUnit.abbreviation}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.gold,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiDistanceInput() {
    return Column(
      children: List.generate(_customDistances.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Text(
                'Peg ${index + 1}:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Slider(
                  value: _customDistances[index],
                  min: 10,
                  max: 100,
                  divisions: 18,
                  label: '${_customDistances[index].round()}',
                  activeColor: AppColors.gold,
                  onChanged: (value) {
                    setState(() {
                      _customDistances[index] = value.roundToDouble();
                      // Update face size based on primary (first) distance
                      if (_customPegType == PegType.walkDown) {
                        _customFaceSize = IFAAFaceSizes.getFaceSize(_customDistances.first);
                      } else {
                        _customFaceSize = IFAAFaceSizes.getFaceSize(_customDistances.last);
                      }
                    });
                  },
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  '${_customDistances[index].round()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFaceSizeSection() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [20, 35, 50, 65].map((size) {
        final isSelected = _selectedFaceSize == size;
        // Show typical distance range for each face size
        final distanceHint = _getDistanceHintForFace(size);
        return GestureDetector(
          onTap: () => setState(() {
            _selectedFaceSize = size;
            // Clear config when face size changes
            _selectedConfig = null;
          }),
          child: Container(
            width: 80,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.gold.withValues(alpha: 0.2)
                  : AppColors.surfaceLight,
              border: Border.all(
                color: isSelected ? AppColors.gold : AppColors.surfaceLight,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Column(
              children: [
                Text(
                  '${size}cm',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isSelected ? AppColors.gold : AppColors.textPrimary,
                        fontFamily: AppFonts.pixel,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  distanceHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getDistanceHintForFace(int faceSize) {
    switch (faceSize) {
      case 20:
        return '15-30yd';
      case 35:
        return '35-45yd';
      case 50:
        return '50-60yd';
      case 65:
        return '65-80yd';
      default:
        return '';
    }
  }

  int _getSuggestedFaceSize() {
    if (_selectedConfig != null) {
      return IFAAFaceSizes.getFaceSize(_selectedConfig!.primaryDistance);
    }
    return IFAAFaceSizes.getFaceSize(_customDistance);
  }

  bool _canSave() {
    if (_selectedFaceSize == null) return false;
    if (_isCustomDistance) {
      return _customDistances.isNotEmpty;
    }
    return _selectedConfig != null;
  }

  void _save() {
    final config = _isCustomDistance
        ? _buildCustomConfig()
        : _selectedConfig!;

    final faceSize = _selectedFaceSize ?? _getSuggestedFaceSize();

    widget.onSave(config, faceSize, _notes.isNotEmpty ? _notes : null);
  }

  PegConfiguration _buildCustomConfig() {
    switch (_customPegType) {
      case PegType.single:
        return PegConfiguration.single(_customDistances.first, _customUnit);
      case PegType.walkDown:
        return PegConfiguration.walkDown(_customDistances, _customUnit);
      case PegType.walkUp:
        return PegConfiguration.walkUp(_customDistances, _customUnit);
      case PegType.fan:
        return PegConfiguration.fan(_customDistances, _customUnit);
    }
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withOpacity(0.2) : AppColors.surfaceLight,
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.surfaceLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected ? AppColors.gold : AppColors.textPrimary,
              ),
        ),
      ),
    );
  }
}
