import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../models/sight_mark.dart';
import '../providers/equipment_provider.dart';
import '../providers/sight_marks_provider.dart';
import '../utils/angle_sight_mark_calculator.dart';
import '../widgets/angle_table.dart';
import '../widgets/slope_slider.dart';

/// Full-featured angle calculator screen.
///
/// Provides:
/// - Arrow speed input (slider or auto-estimate from bow)
/// - Distance input with common presets
/// - Angle table display (degrees or percentage view)
/// - Custom angle input field
/// - Learning stats (once learning is implemented)
class AngleCalculatorScreen extends StatefulWidget {
  /// Optional bow ID to auto-load equipment data
  final String? bowId;

  /// Optional default flat sight mark
  final double? defaultSightMark;

  /// Optional default distance
  final double? defaultDistance;

  /// Optional default distance unit
  final DistanceUnit? defaultUnit;

  const AngleCalculatorScreen({
    super.key,
    this.bowId,
    this.defaultSightMark,
    this.defaultDistance,
    this.defaultUnit,
  });

  @override
  State<AngleCalculatorScreen> createState() => _AngleCalculatorScreenState();
}

class _AngleCalculatorScreenState extends State<AngleCalculatorScreen> {
  // Speed input
  double _arrowSpeed = 220.0;
  bool _speedFromEquipment = false;

  // Distance input
  double _distance = 50.0;
  DistanceUnit _distanceUnit = DistanceUnit.meters;

  // Flat sight mark
  double _flatSightMark = 4.15;

  // Custom angle
  double _customAngle = 0.0;

  // Display mode
  AngleTableDisplayMode _displayMode = AngleTableDisplayMode.degrees;

  // Loading
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Apply defaults if provided
    if (widget.defaultDistance != null) {
      _distance = widget.defaultDistance!;
    }
    if (widget.defaultUnit != null) {
      _distanceUnit = widget.defaultUnit!;
    }
    if (widget.defaultSightMark != null) {
      _flatSightMark = widget.defaultSightMark!;
    }

    // Try to load equipment data if bow ID provided
    if (widget.bowId != null) {
      final equipProvider = context.read<EquipmentProvider>();
      final bow = equipProvider.bows.where((b) => b.id == widget.bowId).firstOrNull;

      if (bow != null && bow.poundage != null) {
        _arrowSpeed = AngleSightMarkCalculator.estimateArrowSpeed(
          bowType: BowType.fromString(bow.bowType),
          poundage: bow.poundage!,
          drawLength: bow.drawLength,
        );
        _speedFromEquipment = true;
      }

      // Try to load a sight mark for the default distance
      final sightProvider = context.read<SightMarksProvider>();
      await sightProvider.loadMarksForBow(widget.bowId!);
      final marks = sightProvider.getMarksForBow(widget.bowId!);

      // Find mark closest to default distance
      if (marks.isNotEmpty) {
        final matchingMark = marks.where((m) {
          final dist = m.unit == _distanceUnit
              ? m.distance
              : m.unit.convert(m.distance);
          return (dist - _distance).abs() < 1;
        }).firstOrNull;

        if (matchingMark != null) {
          _flatSightMark = matchingMark.numericValue;
        } else {
          // Use first available mark and its distance
          final firstMark = marks.first;
          _distance = firstMark.distance;
          _distanceUnit = firstMark.unit;
          _flatSightMark = firstMark.numericValue;
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Angle Calculator'),
        actions: [
          // Display mode toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _displayMode = _displayMode == AngleTableDisplayMode.degrees
                    ? AngleTableDisplayMode.percentage
                    : AngleTableDisplayMode.degrees;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.md),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceBright,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _displayMode == AngleTableDisplayMode.degrees
                        ? Icons.straighten
                        : Icons.percent,
                    size: 16,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _displayMode == AngleTableDisplayMode.degrees ? 'MARKS' : '%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Arrow speed section
                  _buildSpeedSection(context),
                  const SizedBox(height: AppSpacing.lg),

                  // Distance and sight mark inputs
                  _buildInputSection(context),
                  const SizedBox(height: AppSpacing.lg),

                  // Angle table
                  AngleTable(
                    flatSightMark: _flatSightMark,
                    arrowSpeedFps: _arrowSpeed,
                    distance: _distance,
                    distanceUnit: _distanceUnit.abbreviation,
                    displayMode: _displayMode,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Custom angle calculator
                  _buildCustomAngleSection(context),
                  const SizedBox(height: AppSpacing.lg),

                  // Info section
                  _buildInfoSection(context),
                ],
              ),
            ),
    );
  }

  Widget _buildSpeedSection(BuildContext context) {
    final speedDesc = AngleSightMarkCalculator.getSpeedDescription(_arrowSpeed);
    final typicalSetup = AngleSightMarkCalculator.getTypicalSetupForSpeed(_arrowSpeed);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, size: 16, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Arrow Speed',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              if (_speedFromEquipment) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FROM BOW',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accentCyan,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Speed value display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_arrowSpeed.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 4),
              Text(
                'fps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '$speedDesc - $typicalSetup',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Speed slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.gold,
              inactiveTrackColor: AppColors.surfaceBright,
              thumbColor: AppColors.gold,
              overlayColor: AppColors.gold.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _arrowSpeed,
              min: 140,
              max: 320,
              divisions: 36,
              onChanged: (value) {
                setState(() {
                  _arrowSpeed = value;
                  _speedFromEquipment = false;
                });
              },
            ),
          ),

          // Speed range labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Slow (140)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                ),
                Text(
                  'Fast (320)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),

          // Preset buttons
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildSpeedPreset(context, 'Longbow', 160),
              _buildSpeedPreset(context, 'Barebow', 185),
              _buildSpeedPreset(context, 'Recurve', 210),
              _buildSpeedPreset(context, 'Compound', 280),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedPreset(BuildContext context, String label, double speed) {
    final isSelected = (_arrowSpeed - speed).abs() < 10;

    return GestureDetector(
      onTap: () {
        setState(() {
          _arrowSpeed = speed;
          _speedFromEquipment = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.2)
              : AppColors.surfaceBright,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? Border.all(color: AppColors.gold) : null,
        ),
        child: Text(
          '$label (~${speed.toStringAsFixed(0)})',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? AppColors.gold : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ),
    );
  }

  Widget _buildInputSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distance & Flat Sight Mark',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              // Distance input
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distance',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: AppColors.surfaceBright,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                            controller: TextEditingController(
                              text: _distance.toStringAsFixed(0),
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value);
                              if (parsed != null && parsed > 0) {
                                setState(() => _distance = parsed);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Unit toggle
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _distanceUnit = _distanceUnit == DistanceUnit.meters
                                  ? DistanceUnit.yards
                                  : DistanceUnit.meters;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _distanceUnit.abbreviation.toUpperCase(),
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Flat sight mark input
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flat Mark',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surfaceBright,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.gold,
                          ),
                      controller: TextEditingController(
                        text: _flatSightMark.toStringAsFixed(2),
                      ),
                      onChanged: (value) {
                        final parsed = double.tryParse(value);
                        if (parsed != null && parsed > 0) {
                          setState(() => _flatSightMark = parsed);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Common distances
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _distanceUnit.commonDistances.map((dist) {
              final isSelected = (_distance - dist).abs() < 1;
              return GestureDetector(
                onTap: () => setState(() => _distance = dist),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.gold.withValues(alpha: 0.2)
                        : AppColors.surfaceBright,
                    borderRadius: BorderRadius.circular(4),
                    border: isSelected ? Border.all(color: AppColors.gold) : null,
                  ),
                  child: Text(
                    '${dist.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected ? AppColors.gold : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAngleSection(BuildContext context) {
    final sightMark = AngleSightMarkCalculator.getSightMarkForAngle(
      flatSightMark: _flatSightMark,
      angleDegrees: _customAngle,
      arrowSpeedFps: _arrowSpeed,
    );
    final percentage = AngleSightMarkCalculator.getSightMarkAsPercentage(
      flatSightMark: _flatSightMark,
      angleDegrees: _customAngle,
      arrowSpeedFps: _arrowSpeed,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Angle',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Slope slider
          SlopeSlider(
            value: _customAngle,
            onChanged: (value) => setState(() => _customAngle = value),
          ),
          const SizedBox(height: AppSpacing.md),

          // Result display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  '${_distance.toStringAsFixed(0)}${_distanceUnit.abbreviation} at ${_customAngle >= 0 ? '+' : ''}${_customAngle.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      sightMark.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '(${percentage.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final factors = AngleSightMarkCalculator.getFactorsForSpeed(_arrowSpeed);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'How it works',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Arrow speed determines how much adjustment is needed for angled shots. '
            'Faster arrows need less correction, and uphill/downhill corrections are nearly equal. '
            'Slower arrows need more correction, and downhill shots need more adjustment than uphill.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Current factors (at ${_arrowSpeed.toStringAsFixed(0)} fps):',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Uphill: ${factors.uphill.toStringAsFixed(4)} per degree\n'
            'Downhill: ${factors.downhill.toStringAsFixed(4)} per degree\n'
            'Ratio (down/up): ${factors.ratio.toStringAsFixed(2)}x',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontFamily: AppFonts.mono,
                ),
          ),
        ],
      ),
    );
  }
}
