import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'supabase_service.dart';
import 'navigation_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Global service to manage persistent tracking across the entire app
/// This ensures tracking continues even when user navigates away from tracking screen or app goes to background
class TrackingService extends ChangeNotifier {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  // Tracking state
  bool _isTracking = false;
  Position? _currentPosition;
  String? _userPhone;
  String? _userName;
  String _currentLocationDetails = "";
  LatLng? _selectedDestination;
  String _destinationAddress = "";

  // Background tracking
  Timer? _trackingTimer;
  StreamSubscription<Position>? _positionStream;
  final SupabaseService _supabaseService = SupabaseService();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Getters
  bool get isTracking => _isTracking;
  Position? get currentPosition => _currentPosition;
  String? get userPhone => _userPhone;
  LatLng? get selectedDestination => _selectedDestination;
  String get destinationAddress => _destinationAddress;
  String get currentLocationDetails => _currentLocationDetails;

  /// Initialize the tracking service
  Future<void> initialize() async {
    await _initializeNotifications();

    // Load user data and check for existing tracking session
    try {
      final email = await _supabaseService.getCurrentUserEmail();
      if (email != null) {
        final credentials = await _supabaseService.getUserCredentials(email);
        if (credentials != null) {
          _userPhone = credentials['phone_number'];
          final profile = await _supabaseService.getUserProfileByPhone(_userPhone!);
          if (profile != null) {
            _userName = profile['full_name'] ?? 'Unknown User';
          }

          // Check for existing active tracking session
          await _checkExistingTrackingSession();
        }
      }
    } catch (e) {
      print('Error initializing tracking service: $e');
    }
  }

  /// Initialize notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap using NavigationService
        NavigationService().handleNotificationTap(response);
      },
    );
  }

  /// Check for existing active tracking session and restore it
  Future<void> _checkExistingTrackingSession() async {
    if (_userPhone == null) return;

    try {
      final activeSession = await _supabaseService.getActiveTrackingSession(_userPhone!);

      if (activeSession != null) {
        print('TrackingService: Found existing active tracking session');

        // Restore destination if it exists
        if (activeSession['destination_latitude'] != null &&
            activeSession['destination_longitude'] != null) {
          _selectedDestination = LatLng(
            activeSession['destination_latitude'],
            activeSession['destination_longitude'],
          );
          _destinationAddress = activeSession['destination_address'] ?? 'Destination';
        }

        // Set tracking state to active
        _isTracking = true;

        // Start background tracking again
        _startBackgroundLocationTracking();

        // Show persistent notification
        await _showPersistentTrackingNotification();

        // Notify listeners
        notifyListeners();

        print('TrackingService: Previous tracking session resumed');
      }
    } catch (e) {
      print('TrackingService: Error checking existing tracking session: $e');
    }
  }

  /// Start tracking session
  Future<bool> startTracking({
    required Position currentPosition,
    required String locationAddress,
    required LatLng destination,
    required String destinationAddress,
  }) async {
    try {
      if (_userPhone == null) {
        print('TrackingService: Cannot start tracking - user phone not available');
        return false;
      }

      _currentPosition = currentPosition;
      _currentLocationDetails = locationAddress;
      _selectedDestination = destination;
      _destinationAddress = destinationAddress;

      await _supabaseService.startTrackingSession(
        userPhone: _userPhone!,
        userName: _userName ?? 'Unknown User',
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
        locationAddress: locationAddress,
        destinationLatitude: destination.latitude,
        destinationLongitude: destination.longitude,
        destinationAddress: destinationAddress.isNotEmpty ? destinationAddress : null,
      );

      // Start periodic location updates (every 30 seconds)
      _trackingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _updateLocationInDatabase();
      });

      // Start background location tracking for continuous monitoring
      _startBackgroundLocationTracking();

      // Show persistent notification
      await _showPersistentTrackingNotification();

      _isTracking = true;
      notifyListeners();

      print('TrackingService: Tracking started successfully');
      return true;
    } catch (e) {
      print('TrackingService: Error starting tracking: $e');
      return false;
    }
  }

  /// Stop tracking session
  Future<bool> stopTracking() async {
    try {
      _trackingTimer?.cancel();
      _trackingTimer = null;

      // Stop background location tracking
      _positionStream?.cancel();
      _positionStream = null;

      // Cancel persistent notification
      await _cancelPersistentTrackingNotification();

      if (_userPhone != null) {
        await _supabaseService.stopTrackingSession(_userPhone!);
      }

      _isTracking = false;
      _selectedDestination = null;
      _destinationAddress = "";
      notifyListeners();

      print('TrackingService: Tracking stopped successfully');
      return true;
    } catch (e) {
      print('TrackingService: Error stopping tracking: $e');
      return false;
    }
  }

  /// Update location in database
  Future<void> _updateLocationInDatabase() async {
    if (_userPhone == null || _currentPosition == null || !_isTracking) return;

    try {
      await _supabaseService.updateTrackingLocation(
        userPhone: _userPhone!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        locationAddress: _currentLocationDetails.split('\n').first,
      );
    } catch (e) {
      print('TrackingService: Error updating location: $e');
    }
  }

  /// Update current position (called from background tracking)
  void updateCurrentPosition(Position position, {String? locationDetails}) {
    _currentPosition = position;
    if (locationDetails != null) {
      _currentLocationDetails = locationDetails;
    }
    notifyListeners();
  }

  /// Start background location tracking
  void _startBackgroundLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        if (_isTracking && _selectedDestination != null) {
          // Update current position
          _currentPosition = position;

          // Update database
          _updateLocationInDatabase();

          // Check if reached destination
          if (_isNearDestination()) {
            _autoStopTracking();
          }

          // Notify listeners
          notifyListeners();
        }
      },
      onError: (e) {
        print('TrackingService: Error in background location tracking: $e');
      },
    );
  }

  /// Calculate distance between two coordinates in meters
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
    return degrees * (3.14159265359 / 180);
  }

  /// Check if user reached destination
  bool _isNearDestination() {
    if (_currentPosition == null || _selectedDestination == null) {
      return false;
    }

    double distance = _calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _selectedDestination!.latitude,
      _selectedDestination!.longitude,
    );

    return distance <= 50.0; // 50 meters threshold
  }

  /// Auto-stop tracking when destination is reached
  Future<void> _autoStopTracking() async {
    if (!_isTracking) return;

    try {
      await stopTracking();

      await _showNotification(
        title: 'Destination Reached!',
        body: 'Tracking has been automatically stopped as you reached your destination.',
      );

      print('TrackingService: Destination reached - tracking auto-stopped');
    } catch (e) {
      print('TrackingService: Error auto-stopping tracking: $e');
    }
  }

  /// Show persistent tracking notification
  Future<void> _showPersistentTrackingNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'tracking_ongoing_channel',
      'Tracking Ongoing Notifications',
      channelDescription: 'Persistent notification for active location tracking',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true, // Makes notification non-dismissable
      autoCancel: false, // Don't cancel when tapped
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      2, // Notification ID (different from SOS)
      'Location Tracking Active',
      'Your location is being shared. Tap to view.',
      platformChannelSpecifics,
      payload: 'tracking_active',
    );
  }

  /// Cancel persistent tracking notification
  Future<void> _cancelPersistentTrackingNotification() async {
    await _notifications.cancel(2);
  }

  /// Show notification
  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'tracking_channel',
      'Tracking Notifications',
      channelDescription: 'Notifications for tracking status',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  @override
  void dispose() {
    // Don't stop tracking when service is disposed
    // Tracking should only stop when explicitly requested
    _trackingTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }
}
