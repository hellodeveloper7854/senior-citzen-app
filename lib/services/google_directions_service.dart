import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'route_service.dart'; // Import RouteResult and TravelMode from existing service

/// Service for fetching real routes from Google Directions API
class GoogleDirectionsService {
  // Using the API key from AndroidManifest.xml
  static const String _apiKey = 'AIzaSyBikKyiS4qA2b1uzLpw_i1coG0K8lV-BnQ';

  /// Get directions from Google Directions API
  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    TravelMode travelMode = TravelMode.driving,
  }) async {
    try {
      final originStr = '${origin.latitude},${origin.longitude}';
      final destStr = '${destination.latitude},${destination.longitude}';

      final travelModeStr = _getTravelModeString(travelMode);

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=$originStr&destination=$destStr&mode=$travelModeStr&key=$_apiKey'
      );

      print('🌐 GoogleDirectionsService: Fetching directions...');
      print('   From: $originStr');
      print('   To: $destStr');
      print('   Mode: $travelModeStr');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      print('   Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('   API status: ${data['status']}');

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Decode the polyline points
          final encodedPolyline = route['overview_polyline']['points'];
          print('   Encoded polyline length: ${encodedPolyline.length} chars');

          final points = _decodePolyline(encodedPolyline);

          print('✅ GoogleDirectionsService: Route fetched successfully');
          print('   Distance: ${leg['distance']['text']} (${leg['distance']['value']}m)');
          print('   Duration: ${leg['duration']['text']} (${leg['duration']['value']}s)');
          print('   Route points: ${points.length}');
          print('   Start: ${leg['start_address']}');
          print('   End: ${leg['end_address']}');

          return DirectionsResult(
            distanceInMeters: leg['distance']['value'] as int,
            distanceText: leg['distance']['text'] as String,
            durationInSeconds: leg['duration']['value'] as int,
            durationText: leg['duration']['text'] as String,
            routePoints: points,
            startAddress: leg['start_address'] as String,
            endAddress: leg['end_address'] as String,
            polylinePoints: encodedPolyline,
          );
        } else {
          print('❌ GoogleDirectionsService: No route found');
          print('   Status: ${data['status']}');
          if (data['error_message'] != null) {
            print('   Error: ${data['error_message']}');
          }
          if (data['geocoded_waypoints'] != null) {
            print('   Geocoded waypoints: ${data['geocoded_waypoints']}');
          }
          return null;
        }
      } else {
        print('❌ GoogleDirectionsService: HTTP error ${response.statusCode}');
        print('   Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ GoogleDirectionsService: Exception - $e');
      return null;
    }
  }

  /// Convert TravelMode enum to API string
  String _getTravelModeString(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'driving';
      case TravelMode.walking:
        return 'walking';
      case TravelMode.bicycling:
        return 'bicycling';
      case TravelMode.transit:
        return 'transit';
    }
  }

  /// Decode Google's encoded polyline
  /// Format: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    print('📍 Decoding polyline with ${len} characters');

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        if (index >= len) break;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        if (index >= len) break;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    print('✓ Decoded ${points.length} points from polyline');
    return points;
  }
}

/// Result of directions API call
class DirectionsResult {
  final int distanceInMeters;
  final String distanceText;
  final int durationInSeconds;
  final String durationText;
  final List<LatLng> routePoints;
  final String startAddress;
  final String endAddress;
  final String polylinePoints;

  DirectionsResult({
    required this.distanceInMeters,
    required this.distanceText,
    required this.durationInSeconds,
    required this.durationText,
    required this.routePoints,
    required this.startAddress,
    required this.endAddress,
    required this.polylinePoints,
  });

  /// Convert to RouteResult for compatibility
  RouteResult toRouteResult() {
    return RouteResult(
      distanceInMeters: distanceInMeters.toDouble(),
      distanceText: distanceText,
      durationInSeconds: durationInSeconds,
      durationText: durationText,
      routePoints: routePoints,
    );
  }
}
