import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported locales for the app
class SupportedLocales {
  static const List<Locale> all = [
    Locale('en'), // English
    Locale('fr'), // French
    Locale('de'), // German
    Locale('es'), // Spanish
    Locale('it'), // Italian
    Locale('ko'), // Korean
    Locale('ja'), // Japanese
  ];

  static const Locale fallback = Locale('en');

  /// Check if a locale is supported (by language code)
  static bool isSupported(Locale locale) {
    return all.any((l) => l.languageCode == locale.languageCode);
  }

  /// Get a supported locale matching the given locale, or fallback
  static Locale getSupported(Locale locale) {
    return all.firstWhere(
      (l) => l.languageCode == locale.languageCode,
      orElse: () => fallback,
    );
  }
}

/// Provider for managing the app's locale/language setting.
///
/// On first launch, automatically detects the device's language.
/// If the device language is supported, uses it; otherwise falls back to English.
/// User can override this in settings, and the preference is persisted.
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  Locale _locale = SupportedLocales.fallback;
  bool _isLoaded = false;

  Locale get locale => _locale;
  bool get isLoaded => _isLoaded;

  /// Initialize the provider - call this early in app startup
  Future<void> initialize() async {
    if (_isLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);

    if (savedLocale != null) {
      // User has a saved preference
      _locale = SupportedLocales.getSupported(Locale(savedLocale));
    } else {
      // First launch - detect system locale
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      _locale = SupportedLocales.getSupported(systemLocale);

      // Save the detected locale so we remember it
      await prefs.setString(_localeKey, _locale.languageCode);
    }

    _isLoaded = true;
    notifyListeners();
  }

  /// Set a new locale and persist it
  Future<void> setLocale(Locale newLocale) async {
    if (!SupportedLocales.isSupported(newLocale)) {
      debugPrint('Locale ${newLocale.languageCode} not supported, ignoring');
      return;
    }

    if (_locale.languageCode == newLocale.languageCode) {
      return; // No change
    }

    _locale = newLocale;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);

    notifyListeners();
  }

  /// Get the display name for a locale (in the current language)
  /// Returns both the translated name and native name
  static LocaleDisplayInfo getDisplayInfo(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return const LocaleDisplayInfo('English', 'English', 'en');
      case 'fr':
        return const LocaleDisplayInfo('French', 'Francais', 'fr');
      case 'de':
        return const LocaleDisplayInfo('German', 'Deutsch', 'de');
      case 'es':
        return const LocaleDisplayInfo('Spanish', 'Espanol', 'es');
      case 'it':
        return const LocaleDisplayInfo('Italian', 'Italiano', 'it');
      case 'ko':
        return const LocaleDisplayInfo('Korean', 'Korean', 'ko');
      case 'ja':
        return const LocaleDisplayInfo('Japanese', 'Japanese', 'ja');
      default:
        return LocaleDisplayInfo(locale.languageCode, locale.languageCode, locale.languageCode);
    }
  }
}

/// Display information for a locale
class LocaleDisplayInfo {
  final String translatedName; // Name in current app language
  final String nativeName;     // Name in the locale's own language
  final String code;           // Language code

  const LocaleDisplayInfo(this.translatedName, this.nativeName, this.code);
}
