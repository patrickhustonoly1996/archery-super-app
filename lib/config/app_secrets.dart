/// API keys and secrets loaded from compile-time environment variables.
///
/// Pass secrets at build time via --dart-define:
/// ```
/// flutter run --dart-define=WEATHER_API_KEY=your_key_here
/// flutter build ios --dart-define=WEATHER_API_KEY=your_key_here
/// ```
///
/// For development, you can create a .env file (git-ignored) and use a
/// build script, or pass the key directly via --dart-define.
library;

/// External API configuration
class AppSecrets {
  AppSecrets._();

  /// OpenWeatherMap API key for weather conditions on sight marks.
  /// Pass via: --dart-define=WEATHER_API_KEY=your_key
  static const String weatherApiKey = String.fromEnvironment(
    'WEATHER_API_KEY',
    defaultValue: '',
  );

  /// Check if weather API is configured
  static bool get hasWeatherKey => weatherApiKey.isNotEmpty;
}
