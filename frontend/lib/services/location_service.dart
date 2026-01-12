import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' show cos, sqrt, asin;

class LocationService {
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check and request location permission
  Future<bool> checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current position
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check/request permission
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }

      // Get position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  // Calculate distance between two points using Haversine formula
  // Returns distance in meters
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // meters

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }

  double sin(double radians) {
    // Using Taylor series approximation for sine
    double result = radians;
    double term = radians;
    for (int n = 1; n <= 10; n++) {
      term *= -radians * radians / ((2 * n) * (2 * n + 1));
      result += term;
    }
    return result;
  }

  // Check if current location is within unlock radius
  Future<bool> isWithinUnlockRadius({
    required GeoPoint targetLocation,
    required double radiusInMeters,
  }) async {
    final currentPosition = await getCurrentLocation();
    if (currentPosition == null) return false;

    final distance = calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      targetLocation.latitude,
      targetLocation.longitude,
    );

    print('📍 Current distance from target: ${distance.toStringAsFixed(2)}m');
    print('📍 Required radius: ${radiusInMeters}m');

    return distance <= radiusInMeters;
  }

  // Get distance to target location
  Future<double?> getDistanceToTarget(GeoPoint targetLocation) async {
    final currentPosition = await getCurrentLocation();
    if (currentPosition == null) return null;

    return calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      targetLocation.latitude,
      targetLocation.longitude,
    );
  }

  // Stream of position updates (for real-time tracking)
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }
}
