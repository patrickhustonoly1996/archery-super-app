import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_conditions.dart';

/// Weather service with caching and graceful fallback
class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  // Cache settings
  static const Duration _cacheDuration = Duration(minutes: 15);
  static WeatherConditions? _cachedWeather;
  static DateTime? _lastFetch;
  static String? _cachedLocation;

  // API key placeholder - should be set via environment or secure storage
  static String? _apiKey;

  /// Set the OpenWeatherMap API key
  static void setApiKey(String key) {
    _apiKey = key;
  }

  /// Check if API key is configured
  static bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Get current weather conditions
  /// Falls back: API -> Cache -> null
  static Future<WeatherConditions?> getCurrentWeather({
    double? latitude,
    double? longitude,
    String? city,
  }) async {
    // Return cached if still valid
    if (_isCacheValid()) {
      return _cachedWeather;
    }

    // Try API if configured
    if (isConfigured) {
      try {
        final weather = await _fetchFromApi(
          latitude: latitude,
          longitude: longitude,
          city: city,
        );
        if (weather != null) {
          _updateCache(weather, city ?? '$latitude,$longitude');
          return weather;
        }
      } catch (e) {
        // Fall through to cache/null
      }
    }

    // Return stale cache if available
    if (_cachedWeather != null) {
      return _cachedWeather;
    }

    return null;
  }

  /// Fetch weather from OpenWeatherMap API
  static Future<WeatherConditions?> _fetchFromApi({
    double? latitude,
    double? longitude,
    String? city,
  }) async {
    if (_apiKey == null) return null;

    String url;
    if (city != null) {
      url = '$_baseUrl?q=$city&appid=$_apiKey&units=metric';
    } else if (latitude != null && longitude != null) {
      url = '$_baseUrl?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric';
    } else {
      return null;
    }

    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 10),
      onTimeout: () => http.Response('', 408),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseWeatherResponse(data);
    }

    return null;
  }

  /// Parse OpenWeatherMap response
  static WeatherConditions _parseWeatherResponse(Map<String, dynamic> data) {
    final main = data['main'] as Map<String, dynamic>?;
    final wind = data['wind'] as Map<String, dynamic>?;
    final weather = (data['weather'] as List?)?.firstOrNull as Map<String, dynamic>?;

    return WeatherConditions(
      temperature: main?['temp']?.toDouble(),
      humidity: main?['humidity']?.toDouble(),
      pressure: main?['pressure']?.toDouble(),
      windSpeed: wind?['speed']?.toDouble(),
      windDirection: wind?['deg']?.toDouble(),
      description: weather?['main'] as String?,
    );
  }

  /// Check if cache is still valid
  static bool _isCacheValid() {
    if (_cachedWeather == null || _lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheDuration;
  }

  /// Update the cache
  static void _updateCache(WeatherConditions weather, String location) {
    _cachedWeather = weather;
    _lastFetch = DateTime.now();
    _cachedLocation = location;
  }

  /// Get cached weather (even if stale)
  static WeatherConditions? get cachedWeather => _cachedWeather;

  /// Get cache age
  static Duration? get cacheAge {
    if (_lastFetch == null) return null;
    return DateTime.now().difference(_lastFetch!);
  }

  /// Clear the cache
  static void clearCache() {
    _cachedWeather = null;
    _lastFetch = null;
    _cachedLocation = null;
  }

  /// Create manual weather conditions
  static WeatherConditions createManual({
    double? temperature,
    double? humidity,
    double? pressure,
    String? description,
  }) {
    return WeatherConditions(
      temperature: temperature,
      humidity: humidity,
      pressure: pressure,
      description: description ?? 'Manual entry',
    );
  }
}

/// Simple location utility
class LocationService {
  /// Check if we have location permissions
  /// For now, returns false - implement with geolocator package if needed
  static Future<bool> hasLocationPermission() async {
    return false;
  }

  /// Get current location
  /// Returns null - implement with geolocator package if needed
  static Future<({double latitude, double longitude})?> getCurrentLocation() async {
    return null;
  }
}
