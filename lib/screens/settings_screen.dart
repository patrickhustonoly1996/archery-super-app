import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../providers/locale_provider.dart';
import 'import_screen.dart';

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
          // Language setting
          _SettingsSection(
            title: l10n.settingsLanguage,
            description: l10n.settingsLanguageDescription,
            child: const _LanguagePicker(),
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
