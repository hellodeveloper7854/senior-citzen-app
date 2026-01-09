import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';

/// Service for calculating routes and estimated time to destination
class RouteService {
  static const double _averageWalkingSpeedKmH = 5.0; // 5 km/h average walking speed
  static const double _averageDrivingSpeedKmH = 30.0; // 30 km/h average city driving speed

  /// Calculate route between two points
  /// Note: This is a simplified implementation using straight-line distance
  /// For actual road routes, you would integrate Google Directions API
  Future<RouteResult> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    TravelMode travelMode = TravelMode.driving,
  }) async {
    try {
      // Calculate straight-line distance
      final distanceInMeters = _calculateDistance(
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
      );

      // Calculate estimated time based on travel mode
      final speedKmH = travelMode == TravelMode.driving
          ? _averageDrivingSpeedKmH
          : _averageWalkingSpeedKmH;

      final distanceInKm = distanceInMeters / 1000;
      final timeInMinutes = (distanceInKm / speedKmH * 60).round();

      // Create route points (simplified - straight line)
      final routePoints = [
        origin,
        destination,
      ];

      return RouteResult(
        distanceInMeters: distanceInMeters,
        distanceText: _formatDistance(distanceInMeters),
        durationInSeconds: timeInMinutes * 60,
        durationText: _formatDuration(timeInMinutes),
        routePoints: routePoints,
      );
    } catch (e) {
      print('RouteService: Error calculating route: $e');
      rethrow;
    }
  }

  /// Calculate distance between two coordinates in meters using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Format distance for display
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  /// Format duration for display
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours hr';
      } else {
        return '$hours hr $mins min';
      }
    }
  }

  /// Create polyline from route points
  Polyline createPolyline({
    required String id,
    required List<LatLng> points,
    Color color = const Color(0xFF2196F3),
    int width = 5,
  }) {
    return Polyline(
      polylineId: PolylineId(id),
      color: color,
      width: width.toInt(),
      points: points,
      endCap: Cap.roundCap,
      startCap: Cap.roundCap,
      jointType: JointType.round,
    );
  }
}

/// Result of route calculation
class RouteResult {
  final double distanceInMeters;
  final String distanceText;
  final int durationInSeconds;
  final String durationText;
  final List<LatLng> routePoints;

  RouteResult({
    required this.distanceInMeters,
    required this.distanceText,
    required this.durationInSeconds,
    required this.durationText,
    required this.routePoints,
  });
}

/// Travel mode enum
enum TravelMode {
  driving,
  walking,
  bicycling,
  transit,
}
