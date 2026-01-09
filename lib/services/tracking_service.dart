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
  int? _trackingDurationMinutes; // Duration in minutes (null = indefinite/destination-based)
  DateTime? _sessionEndTime; // When the tracking should auto-stop
  DateTime? _sessionStartTime; // When the tracking session started

  // Background tracking
  Timer? _trackingTimer;
  Timer? _durationTimer; // Timer to check duration expiry
  Timer? _continuationCheckTimer; // Timer to check if user wants to continue
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
  int? get trackingDurationMinutes => _trackingDurationMinutes;
  DateTime? get sessionEndTime => _sessionEndTime;
  DateTime? get sessionStartTime => _sessionStartTime;

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
    LatLng? destination, // Now optional - can track without destination
    String? destinationAddress,
    int? durationMinutes, // Duration in minutes (15, 30, 60, 120) or null for indefinite
  }) async {
    try {
      print('=== TrackingService.startTracking ===');
      print('User phone: $_userPhone');
      print('User name: $_userName');
      print('Destination: ${destination ?? "None"}');
      print('Duration: $durationMinutes minutes');

      if (_userPhone == null) {
        print('TrackingService: ✗ Cannot start tracking - user phone not available');
        return false;
      }

      _currentPosition = currentPosition;
      _currentLocationDetails = locationAddress;
      _selectedDestination = destination;
      _destinationAddress = destinationAddress ?? "";
      _trackingDurationMinutes = durationMinutes;
      _sessionStartTime = DateTime.now(); // Record session start time

      // Calculate session end time if duration is provided
      if (durationMinutes != null && durationMinutes > 0) {
        _sessionEndTime = DateTime.now().add(Duration(minutes: durationMinutes));
        // Start timer to check for duration expiry
        _startDurationTimer();
      } else {
        _sessionEndTime = null;
      }

      print('Calling SupabaseService.startTrackingSession...');
      await _supabaseService.startTrackingSession(
        userPhone: _userPhone!,
        userName: _userName ?? 'Unknown User',
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
        locationAddress: locationAddress,
        destinationLatitude: destination?.latitude,
        destinationLongitude: destination?.longitude,
        destinationAddress: destinationAddress?.isNotEmpty == true ? destinationAddress : null,
        durationMinutes: durationMinutes,
      );

      // Start periodic location updates (every 30 seconds)
      _trackingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _updateLocationInDatabase();
      });

      // Start background location tracking for continuous monitoring
      _startBackgroundLocationTracking();

      // Start continuation check timer for indefinite tracking without destination
      if (destination == null && durationMinutes == null) {
        _startContinuationCheckTimer();
      }

      // Show persistent notification
      await _showPersistentTrackingNotification();

      _isTracking = true;
      notifyListeners();

      print('✓ TrackingService: Tracking started successfully${durationMinutes != null ? ' for $durationMinutes minutes' : ''}');
      return true;
    } catch (e, stackTrace) {
      print('✗ TrackingService: Error starting tracking');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Stop tracking session
  Future<bool> stopTracking() async {
    try {
      _trackingTimer?.cancel();
      _trackingTimer = null;

      // Cancel duration timer
      _durationTimer?.cancel();
      _durationTimer = null;

      // Cancel continuation check timer
      _continuationCheckTimer?.cancel();
      _continuationCheckTimer = null;

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
      _trackingDurationMinutes = null;
      _sessionEndTime = null;
      _sessionStartTime = null;
      notifyListeners();

      print('TrackingService: Tracking stopped successfully');
      return true;
    } catch (e) {
      print('TrackingService: Error stopping tracking: $e');
      return false;
    }
  }

  /// Update destination during active tracking
  Future<bool> updateDestination({
    required LatLng newDestination,
    required String newDestinationAddress,
  }) async {
    try {
      if (!_isTracking || _userPhone == null) {
        print('TrackingService: Cannot update destination - not tracking');
        return false;
      }

      print('=== TrackingService.updateDestination ===');
      print('New destination: ${newDestination.latitude}, ${newDestination.longitude}');
      print('New address: $newDestinationAddress');

      // Update local state
      _selectedDestination = newDestination;
      _destinationAddress = newDestinationAddress;

      // Update in database
      await _supabaseService.updateTrackingDestination(
        userPhone: _userPhone!,
        destinationLatitude: newDestination.latitude,
        destinationLongitude: newDestination.longitude,
        destinationAddress: newDestinationAddress,
      );

      // Update persistent notification
      await _showPersistentTrackingNotification();

      // Notify listeners
      notifyListeners();

      print('✓ TrackingService: Destination updated successfully');
      return true;
    } catch (e, stackTrace) {
      print('✗ TrackingService: Error updating destination');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Start timer to check for duration expiry
  void _startDurationTimer() {
    // Check every minute if duration has expired
    _durationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_sessionEndTime != null && DateTime.now().isAfter(_sessionEndTime!)) {
        print('TrackingService: Duration expired, stopping tracking');
        _autoStopTracking(reason: 'duration');
      }
    });
  }

  /// Start timer to check if user wants to continue tracking (for indefinite tracking without destination)
  void _startContinuationCheckTimer() {
    // Check every 15 minutes (after initial 15 minutes)
    _continuationCheckTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      if (_sessionStartTime != null) {
        final duration = DateTime.now().difference(_sessionStartTime!);
        print('TrackingService: Checking continuation - tracking for ${duration.inMinutes} minutes');

        // Show continuation notification
        _showContinuationNotification();
      }
    });
  }

  /// Show notification asking if user wants to continue tracking
  Future<void> _showContinuationNotification() async {
    final duration = DateTime.now().difference(_sessionStartTime!);
    final minutes = duration.inMinutes;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'tracking_continuation_channel',
      'Tracking Continuation',
      channelDescription: 'Notifications for tracking continuation checks',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notifications.show(
      3, // Different notification ID
      'Still Sharing Location?',
      'You have been sharing your location for $minutes minutes. Tap to manage.',
      platformChannelSpecifics,
      payload: 'tracking_continuation',
    );
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

  /// Auto-stop tracking when destination is reached or duration expires
  Future<void> _autoStopTracking({String reason = 'destination'}) async {
    if (!_isTracking) return;

    try {
      await stopTracking();

      String title;
      String body;

      if (reason == 'duration') {
        title = 'Time Expired!';
        body = 'Your location sharing session has ended.';
      } else {
        title = 'Destination Reached!';
        body = 'Tracking has been automatically stopped as you reached your destination.';
      }

      await _showNotification(
        title: title,
        body: body,
      );

      print('TrackingService: Tracking auto-stopped - reason: $reason');
    } catch (e) {
      print('TrackingService: Error auto-stopping tracking: $e');
    }
  }

  /// Show persistent tracking notification
  Future<void> _showPersistentTrackingNotification() async {
    // Build notification text based on tracking type
    String notificationText;
    if (_trackingDurationMinutes != null) {
      notificationText = 'Sharing location for $_trackingDurationMinutes minutes. Tap to view.';
    } else if (_selectedDestination != null) {
      notificationText = 'Sharing location to destination. Tap to view.';
    } else {
      notificationText = 'Sharing location indefinitely. Tap to view.';
    }

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
      notificationText,
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
