import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/sight_marks_provider.dart';
import '../providers/connectivity_provider.dart';
import '../models/sight_mark.dart';
import '../models/weather_conditions.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import 'slope_slider.dart';
import 'temperature_slider.dart';
import 'wind_slider.dart';
import 'sun_light_selector.dart';

/// Form for adding or editing a sight mark
class SightMarkEntryForm extends StatefulWidget {
  final String bowId;
  final SightMark? existingMark;
  final DistanceUnit? defaultUnit;
  final double? defaultDistance;
  final VoidCallback? onSaved;

  const SightMarkEntryForm({
    super.key,
    required this.bowId,
    this.existingMark,
    this.defaultUnit,
    this.defaultDistance,
    this.onSaved,
  });

  @override
  State<SightMarkEntryForm> createState() => _SightMarkEntryFormState();
}

class _SightMarkEntryFormState extends State<SightMarkEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController();
  final _sightValueController = TextEditingController();

  late DistanceUnit _unit;
  bool _isSaving = false;
  bool _isFetchingWeather = false;

  // Slope angle (-45 to +45)
  double _slopeAngle = 0;

  // Temperature (null = not set)
  double? _temperature;

  // Wind (Beaufort scale, null = not set)
  int? _windBeaufort;

  // Light conditions
  LightQuality? _lightQuality;
  SunPosition? _sunPosition;

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
      _slopeAngle = widget.existingMark!.slopeAngle ?? 0;

      if (widget.existingMark!.weather != null) {
        final w = widget.existingMark!.weather!;
        _temperature = w.temperature;
        _windBeaufort = w.windBeaufort ?? windStringToBeaufort(w.wind);
        _lightQuality = LightQuality.fromString(w.lightQuality ?? w.sky);
        _sunPosition = SunPosition.fromString(w.sunPosition);
      }
    } else {
      _unit = widget.defaultUnit ?? DistanceUnit.meters;
      if (widget.defaultDistance != null) {
        _distanceController.text = widget.defaultDistance!.toStringAsFixed(0);
      }
      // Try to auto-fetch weather when adding new mark
      _tryAutoFetchWeather();
    }
  }

  Future<void> _tryAutoFetchWeather() async {
    // Check if we have connectivity
    final connectivity = context.read<ConnectivityProvider>();
    if (!connectivity.isOnline) return;

    // Check if weather service is configured
    if (!WeatherService.isConfigured) return;

    setState(() => _isFetchingWeather = true);

    try {
      // Try to get location first
      final location = await LocationService.getCurrentLocation(
        requestIfDenied: false, // Don't prompt on form open
      );

      if (location != null) {
        final weather = await WeatherService.getCurrentWeather(
          latitude: location.latitude,
          longitude: location.longitude,
        );

        if (weather != null && mounted) {
          setState(() {
            _temperature = weather.temperature;
            _windBeaufort = weather.windBeaufort ?? windStringToBeaufort(weather.wind);
            _lightQuality = LightQuality.fromString(weather.lightQuality ?? weather.sky);
            // Sun position can't be determined from API, leave for user
          });
        }
      }
    } catch (e) {
      // Silently fail - manual entry is always available
    } finally {
      if (mounted) {
        setState(() => _isFetchingWeather = false);
      }
    }
  }

  Future<void> _fetchWeather() async {
    setState(() => _isFetchingWeather = true);

    try {
      // Get location (will request permission if needed)
      final location = await LocationService.getCurrentLocation();

      if (location == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not get location. Check permissions.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final weather = await WeatherService.getCurrentWeather(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      if (weather != null && mounted) {
        setState(() {
          _temperature = weather.temperature;
          _windBeaufort = weather.windBeaufort ?? windStringToBeaufort(weather.wind);
          _lightQuality = LightQuality.fromString(weather.lightQuality ?? weather.sky);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_done, color: AppColors.gold, size: 18),
                const SizedBox(width: 8),
                Text('Weather updated: ${weather.temperature?.round()}°C'),
              ],
            ),
            backgroundColor: AppColors.surfaceDark,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not fetch weather. Enter manually.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Weather error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingWeather = false);
      }
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _sightValueController.dispose();
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
        child: SingleChildScrollView(
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

              // Distance and sight value inputs
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
                        fillColor: AppColors.surfaceBright.withValues(alpha: 0.5),
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
                        fillColor: AppColors.surfaceBright.withValues(alpha: 0.5),
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

              const SizedBox(height: AppSpacing.xl),

              // SLOPE SECTION - Visual slider with archer/target
              SlopeSlider(
                value: _slopeAngle,
                onChanged: (value) => setState(() => _slopeAngle = value),
              ),

              const SizedBox(height: AppSpacing.xl),

              // CONDITIONS SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conditions',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        Text(
                          'optional... but highly recommended',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Auto-fetch weather button
                  if (WeatherService.isConfigured)
                    TextButton.icon(
                      onPressed: _isFetchingWeather ? null : _fetchWeather,
                      icon: _isFetchingWeather
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_download, size: 16),
                      label: Text(_isFetchingWeather ? 'Loading...' : 'Auto'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Temperature slider
              TemperatureSlider(
                value: _temperature,
                onChanged: (value) => setState(() => _temperature = value),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Wind Beaufort slider
              WindSlider(
                beaufortScale: _windBeaufort,
                onChanged: (value) => setState(() => _windBeaufort = value),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Sun/Light selector
              SunLightSelector(
                lightQuality: _lightQuality,
                sunPosition: _sunPosition,
                onLightQualityChanged: (value) =>
                    setState(() => _lightQuality = value),
                onSunPositionChanged: (value) =>
                    setState(() => _sunPosition = value),
              ),

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

      // Only include slope if not zero
      final slope = _slopeAngle != 0 ? _slopeAngle : null;

      // Build weather conditions from selections
      final hasConditions = _temperature != null ||
          _windBeaufort != null ||
          _lightQuality != null ||
          _sunPosition != null;

      final weather = hasConditions
          ? WeatherConditions(
              temperature: _temperature,
              lightQuality: _lightQuality?.value,
              sky: _lightQuality?.toSkyString(), // Backwards compatibility
              sunPosition: _sunPosition?.value,
              windBeaufort: _windBeaufort,
              wind: beaufortToWindString(_windBeaufort), // Backwards compatibility
            )
          : null;

      if (widget.existingMark != null) {
        await provider.updateSightMark(
          id: widget.existingMark!.id,
          bowId: widget.bowId,
          distance: distance,
          unit: _unit,
          sightValue: sightValue,
          weather: weather,
          slopeAngle: slope,
        );
      } else {
        await provider.addSightMark(
          bowId: widget.bowId,
          distance: distance,
          unit: _unit,
          sightValue: sightValue,
          weather: weather,
          slopeAngle: slope,
          confidenceScore: 0.7, // Default confidence for manual entry
        );

        // Show reminder to write it down
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.edit_note, color: AppColors.gold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Saved! Now write ${distance.toStringAsFixed(0)}${_unit.abbreviation} -> $sightValue in your notebook.',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.surfaceDark,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
  final VoidCallback? onDismiss;
  final VoidCallback? onSaved;

  const SightMarkQuickPrompt({
    super.key,
    required this.bowId,
    required this.distance,
    required this.unit,
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
        onSaved: () {
          Navigator.pop(ctx);
          onSaved?.call();
        },
      ),
    );
  }
}
