import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../providers/locale_provider.dart';
import '../providers/accessibility_provider.dart';
import '../db/database.dart';
import 'import_screen.dart';

/// Preference key for default arrow tracking setting
const String kArrowTrackingDefaultPref = 'arrow_tracking_default';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.settingsTitle,
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 20,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Accessibility settings
          _SettingsSection(
            title: 'Accessibility',
            description: 'Text size, color options, and motion settings',
            child: const _AccessibilitySettings(),
          ),

          const SizedBox(height: 24),

          // Language setting
          _SettingsSection(
            title: l10n.settingsLanguage,
            description: l10n.settingsLanguageDescription,
            child: const _LanguagePicker(),
          ),

          const SizedBox(height: 24),

          // Plotting settings
          _SettingsSection(
            title: 'Plotting',
            description: 'Arrow tracking and session defaults',
            child: const _PlottingSettings(),
          ),

          const SizedBox(height: 24),

          // Import data
          _SettingsSection(
            title: l10n.settingsImport,
            description: l10n.settingsImportDescription,
            child: _SettingsButton(
              label: l10n.settingsImport,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ImportScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _SettingsSection({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppFonts.pixel,
            fontSize: 14,
            color: AppColors.gold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SupportedLocales.all.map((locale) {
            final isSelected =
                localeProvider.locale.languageCode == locale.languageCode;
            final info = LocaleProvider.getDisplayInfo(locale);

            return GestureDetector(
              onTap: () => localeProvider.setLocale(locale),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.gold.withValues(alpha: 0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.gold : AppColors.surfaceLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      info.nativeName,
                      style: TextStyle(
                        fontFamily: AppFonts.pixel,
                        fontSize: 14,
                        color:
                            isSelected ? AppColors.gold : AppColors.textPrimary,
                      ),
                    ),
                    if (info.nativeName != info.translatedName) ...[
                      const SizedBox(height: 2),
                      Text(
                        info.translatedName,
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SettingsButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '>',
              style: TextStyle(
                fontFamily: AppFonts.pixel,
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessibilitySettings extends StatelessWidget {
  const _AccessibilitySettings();

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, accessibility, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Size
            Text(
              'Text Size',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TextScaleOption.values.map((option) {
                final isSelected = accessibility.textScale == option;
                return GestureDetector(
                  onTap: () => accessibility.setTextScale(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold.withValues(alpha: 0.2)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppColors.gold : AppColors.surfaceLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      option.displayName,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13,
                        color: isSelected ? AppColors.gold : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Colorblind Mode
            Text(
              'Color Vision',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ColorblindMode.none,
                ColorblindMode.deuteranopia,
                ColorblindMode.protanopia,
                ColorblindMode.tritanopia,
                ColorblindMode.highContrast,
              ].map((mode) {
                final isSelected = accessibility.colorblindMode == mode;
                return GestureDetector(
                  onTap: () => accessibility.setColorblindMode(mode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold.withValues(alpha: 0.2)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppColors.gold : AppColors.surfaceLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      mode.displayName,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 12,
                        color: isSelected ? AppColors.gold : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Temperature Unit
            Text(
              'Temperature Unit',
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TemperatureUnit.values.map((unit) {
                final isSelected = accessibility.temperatureUnit == unit;
                return GestureDetector(
                  onTap: () => accessibility.setTemperatureUnit(unit),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold.withValues(alpha: 0.2)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppColors.gold : AppColors.surfaceLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      unit.displayName,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 13,
                        color: isSelected ? AppColors.gold : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Toggle options
            _ToggleOption(
              label: 'Bold Text',
              value: accessibility.boldText,
              onChanged: accessibility.setBoldText,
            ),
            const SizedBox(height: 8),
            _ToggleOption(
              label: 'Reduce Motion',
              value: accessibility.reduceMotion,
              onChanged: accessibility.setReduceMotion,
            ),
            const SizedBox(height: 8),
            _ToggleOption(
              label: 'Show Ring Labels',
              value: accessibility.showRingLabels,
              onChanged: accessibility.setShowRingLabels,
            ),
          ],
        );
      },
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool) onChanged;

  const _ToggleOption({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              color: value ? AppColors.gold : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Plotting-related settings
class _PlottingSettings extends StatefulWidget {
  const _PlottingSettings();

  @override
  State<_PlottingSettings> createState() => _PlottingSettingsState();
}

class _PlottingSettingsState extends State<_PlottingSettings> {
  bool _arrowTrackingDefault = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = context.read<AppDatabase>();
    final arrowTracking = await db.getBoolPreference(kArrowTrackingDefaultPref, defaultValue: false);
    if (mounted) {
      setState(() {
        _arrowTrackingDefault = arrowTracking;
        _isLoading = false;
      });
    }
  }

  Future<void> _setArrowTrackingDefault(bool value) async {
    final db = context.read<AppDatabase>();
    await db.setBoolPreference(kArrowTrackingDefaultPref, value);
    setState(() => _arrowTrackingDefault = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Arrow Tracking',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        _ToggleOption(
          label: 'Enable by default',
          value: _arrowTrackingDefault,
          onChanged: _setArrowTrackingDefault,
        ),
        const SizedBox(height: 4),
        Text(
          'When enabled, shaft tagging is on by default for new sessions with a quiver selected.',
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
