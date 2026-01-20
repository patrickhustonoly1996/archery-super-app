import 'package:geolocator/geolocator.dart';

/// Location service for venue detection and weather auto-fill
class LocationService {
  /// Check if location services are enabled on the device
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      return false;
    }
  }

  /// Check current location permission status
  static Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      return LocationPermission.denied;
    }
  }

  /// Request location permission from the user
  static Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      return LocationPermission.denied;
    }
  }

  /// Check if we have adequate permissions
  static Future<bool> hasLocationPermission() async {
    final permission = await checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Get current location with permission handling
  /// Returns null if permissions denied or location unavailable
  static Future<({double latitude, double longitude})?> getCurrentLocation({
    bool requestIfDenied = true,
  }) async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permission
      var permission = await checkPermission();

      if (permission == LocationPermission.denied && requestIfDenied) {
        permission = await requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get position with reasonable timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return (latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      return null;
    }
  }

  /// Get last known location (faster, may be stale)
  static Future<({double latitude, double longitude})?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;

      return (latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      return null;
    }
  }

  /// Calculate distance between two points in meters
  static double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Check if a location is within a certain distance of another
  static bool isWithinDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
    double maxDistanceMeters,
  ) {
    final distance = distanceBetween(lat1, lng1, lat2, lng2);
    return distance <= maxDistanceMeters;
  }
}
