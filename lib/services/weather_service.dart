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
    final clouds = data['clouds'] as Map<String, dynamic>?;

    // Convert API wind speed (m/s) to Beaufort scale and qualitative description
    final windSpeed = wind?['speed']?.toDouble();
    String? windDesc;
    int? windBeaufort;
    if (windSpeed != null) {
      windBeaufort = _windSpeedToBeaufort(windSpeed);
      if (windSpeed < 1.5) {
        windDesc = 'none';
      } else if (windSpeed < 5.5) {
        windDesc = 'light';
      } else if (windSpeed < 10.8) {
        windDesc = 'moderate';
      } else {
        windDesc = 'strong';
      }
    }

    // Convert API weather description to sky condition and light quality
    final apiDescription = weather?['main'] as String?;
    final cloudCover = clouds?['all'] as int? ?? 0;
    String? sky;
    String? lightQuality;

    if (apiDescription != null) {
      final desc = apiDescription.toLowerCase();
      if (desc.contains('rain') || desc.contains('drizzle') || desc.contains('thunder')) {
        sky = 'rainy';
        lightQuality = 'overcast';
      } else if (desc.contains('clear') || desc.contains('sun')) {
        sky = 'sunny';
        lightQuality = 'direct_sun';
      } else if (desc.contains('overcast') || desc.contains('mist') || desc.contains('fog')) {
        sky = 'overcast';
        lightQuality = 'overcast';
      } else if (desc.contains('cloud')) {
        sky = 'cloudy';
        // Use cloud cover to determine light quality
        if (cloudCover < 50) {
          lightQuality = 'partial_sun';
        } else if (cloudCover < 85) {
          lightQuality = 'bright_cloudy';
        } else {
          lightQuality = 'overcast';
        }
      }
    }

    return WeatherConditions(
      temperature: main?['temp']?.toDouble(),
      sky: sky,
      lightQuality: lightQuality,
      wind: windDesc,
      windBeaufort: windBeaufort,
      // sunPosition can't be determined from API - user sets manually
    );
  }

  /// Convert wind speed (m/s) to Beaufort scale (capped at 6 for archery)
  static int _windSpeedToBeaufort(double speedMs) {
    if (speedMs < 0.3) return 0;
    if (speedMs < 1.6) return 1;
    if (speedMs < 3.4) return 2;
    if (speedMs < 5.5) return 3;
    if (speedMs < 8.0) return 4;
    if (speedMs < 10.8) return 5;
    return 6; // Cap at 6 for archery purposes
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
    String? sky,
    String? sunPosition,
    String? wind,
  }) {
    return WeatherConditions(
      temperature: temperature,
      sky: sky,
      sunPosition: sunPosition,
      wind: wind,
    );
  }
}

// Note: LocationService is now in location_service.dart with full geolocator support
// Import it separately: import 'location_service.dart';
