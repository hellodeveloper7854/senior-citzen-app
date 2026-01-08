import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:math';
import '../services/supabase_service.dart';

class TrackMeScreen extends StatefulWidget {
  const TrackMeScreen({super.key});

  @override
  State<TrackMeScreen> createState() => _TrackMeScreenState();
}

class _TrackMeScreenState extends State<TrackMeScreen> {
  GoogleMapController? _mapController;
  bool _isTracking = false; // Initially OFF
  Position? _currentPosition;
  String _currentAddress = "Getting your location...";
  String _currentLocationDetails = "";
  String _selectedAddress = "Tap map or search to select destination";
  bool _isLoadingLocation = true;
  bool _isLoadingAddress = false;

  // Destination related variables
  LatLng? _selectedDestination;
  String _destinationAddress = "";
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Search related variables
  final TextEditingController _searchController = TextEditingController();
  List<Location> _searchResults = [];
  bool _isSearching = false;
  bool _isFullscreen = false;

  // Tracking related variables
  final SupabaseService _supabaseService = SupabaseService();
  Timer? _trackingTimer;
  String? _userPhone;
  String? _userName;
  String _emergencyPhoneNumber = '9326520525'; // Default fallback number
  static const String _emergencyServiceName = 'Police'; // Service name to fetch from database

  // Background tracking and notification
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const double _destinationProximityMeters = 50.0; // Auto-stop when within 50 meters
  StreamSubscription<Position>? _positionStream;

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(19.2183, 72.9781), // Thane coordinates
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadEmergencyPhoneNumber(_emergencyServiceName);
    _loadUserData();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
        _currentAddress = "Getting your location...";
      });

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = "Location services disabled";
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        setState(() {
          _currentPosition = position;
          _currentAddress = "Your current location";
          _isLoadingLocation = false;
        });

        // Get detailed address for current location
        _getLocationDetails(position.latitude, position.longitude);

        // Update markers with current location
        _updateMarkers();

        // Move map camera to current location once it's obtained
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 16.0,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _currentAddress = "Location permission denied";
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        _currentAddress = "Unable to get location";
        _isLoadingLocation = false;
      });
    }
  }

  // Get detailed address using reverse geocoding
  Future<void> _getLocationDetails(double lat, double lng) async {
    try {
      setState(() {
        _isLoadingAddress = true;
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.street ?? ""}, ${place.subLocality ?? ""}, ${place.locality ?? ""}, ${place.postalCode ?? ""}";
        address = address.replaceAll(RegExp(r',\s*,+'), ',').trim();
        if (address.startsWith(',')) address = address.substring(1).trim();
        if (address.endsWith(',')) address = address.substring(0, address.length - 1).trim();

        String coordinates = "Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}";

        setState(() {
          if (lat == _currentPosition?.latitude && lng == _currentPosition?.longitude) {
            _currentLocationDetails = "$address\n$coordinates";
          } else {
            _destinationAddress = address;
          }
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingAddress = false;
        if (lat == _currentPosition?.latitude && lng == _currentPosition?.longitude) {
          _currentLocationDetails = "Address not available\nLat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}";
        } else {
          _destinationAddress = "Address not available";
        }
      });
    }
  }

  // Update markers on the map
  void _updateMarkers() {
    Set<Marker> newMarkers = {};

    // Add current location marker
    if (_currentPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: _currentLocationDetails.split('\n').first,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    // Add destination marker
    if (_selectedDestination != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _selectedDestination!,
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: _destinationAddress.isNotEmpty ? _destinationAddress : 'Selected destination',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  // Draw route between current location and destination
  void _drawRoute() {
    if (_currentPosition != null && _selectedDestination != null) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 4,
            points: [
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              _selectedDestination!,
            ],
          ),
        };
      });
    } else {
      setState(() {
        _polylines = {};
      });
    }
  }

  // Handle map tap to select destination
  void _onMapTap(LatLng position) {
    setState(() {
      _selectedDestination = position;
      _selectedAddress = "Destination selected";
    });

    _getLocationDetails(position.latitude, position.longitude);
    _updateMarkers();
    _drawRoute();
  }

  // Search for locations
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      setState(() {
        _searchResults = locations;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  // Select destination from search results
  void _selectDestinationFromSearch(Location location) {
    LatLng destination = LatLng(location.latitude, location.longitude);
    setState(() {
      _selectedDestination = destination;
      _selectedAddress = "Destination selected";
      _searchController.clear();
      _searchResults = [];
    });

    _getLocationDetails(location.latitude, location.longitude);
    _updateMarkers();
    _drawRoute();

    // Move camera to selected destination
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: destination,
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  // Clear selected destination
  void _clearDestination() {
    setState(() {
      _selectedDestination = null;
      _destinationAddress = "";
      _selectedAddress = "Tap map or search to select destination";
      _polylines = {};
    });
    _updateMarkers();
  }

  // Load user data
  Future<void> _loadUserData() async {
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
      print('Error loading user data: $e');
    }
  }

  // Load emergency phone number from database based on service name (same as SOS screen)
  Future<void> _loadEmergencyPhoneNumber(String serviceName) async {
    try {
      final phoneNumber = await _supabaseService.getEmergencyPhoneNumber(serviceName);
      if (phoneNumber != null && mounted) {
        setState(() {
          _emergencyPhoneNumber = phoneNumber;
        });
      }
    } catch (e) {
      // Keep default number if there's an error
      print('Error loading emergency phone number for $serviceName: $e');
    }
  }

  // Start tracking session
  Future<void> _startTracking() async {
    if (_currentPosition == null) {
      _showMessage('Please wait for location to be determined', Colors.orange);
      return;
    }

    if (_selectedDestination == null) {
      _showMessage('Please select a destination first by tapping on the map or searching', Colors.orange);
      return;
    }

    // Request background location permission first
    await _requestBackgroundLocationPermission();

    try {
      setState(() {
        _isTracking = true; // Update UI immediately for better UX
      });

      await _supabaseService.startTrackingSession(
        userPhone: _userPhone ?? 'unknown',
        userName: _userName ?? 'Unknown User',
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        locationAddress: _currentLocationDetails.split('\n').first,
        destinationLatitude: _selectedDestination!.latitude,
        destinationLongitude: _selectedDestination!.longitude,
        destinationAddress: _destinationAddress.isNotEmpty ? _destinationAddress : null,
      );

      // Start periodic location updates (every 30 seconds)
      _trackingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _updateLocationInDatabase();
      });

      // Start background location tracking for continuous monitoring
      _startBackgroundLocationTracking();

      // Show persistent notification
      await _showPersistentTrackingNotification();

      _showNotification(
        title: 'Tracking Started',
        body: 'Your journey to ${_destinationAddress.isNotEmpty ? _destinationAddress : 'your destination'} has begun.',
      );

      _showMessage('Tracking started successfully to your destination', Colors.green);
      print('Tracking started successfully with background monitoring');
    } catch (e) {
      print('Error starting tracking: $e');
      setState(() {
        _isTracking = false;
      });
      _showMessage('Failed to start tracking', Colors.red);
    }
  }

  // Stop tracking session
  Future<void> _stopTracking() async {
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

      setState(() {
        _isTracking = false;
      });

      print('Tracking stopped successfully');
    } catch (e) {
      print('Error stopping tracking: $e');
      _showMessage('Error stopping tracking', Colors.red);
    }
  }

  // Update location in database
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
      print('Error updating location: $e');
    }
  }

  // Call police function (same as SOS screen logic)
  Future<void> _callOfficer() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: _emergencyPhoneNumber.replaceAll('-', ''));

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        // Show error message if can't launch dialer
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch dialer. Please dial $_emergencyPhoneNumber manually.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error launching dialer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening dialer. Please dial $_emergencyPhoneNumber manually.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show message to user
  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Initialize notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Show persistent tracking notification
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

  // Cancel persistent tracking notification
  Future<void> _cancelPersistentTrackingNotification() async {
    await _notifications.cancel(2);
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
    print('Notification tapped: ${response.payload}');
  }

  // Show notification
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

  // Calculate distance between two coordinates in meters
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

  // Check if user reached destination
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

    return distance <= _destinationProximityMeters;
  }

  // Request background location permission
  Future<void> _requestBackgroundLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse) {
        // Request background location
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage('Background location permission denied permanently', Colors.red);
      }
    } catch (e) {
      print('Error requesting background location permission: $e');
    }
  }

  // Start background location tracking
  void _startBackgroundLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        if (_isTracking && _selectedDestination != null) {
          // Update current position
          setState(() {
            _currentPosition = position;
          });

          // Get location details
          _getLocationDetails(position.latitude, position.longitude);

          // Update database
          _updateLocationInDatabase();

          // Check if reached destination
          if (_isNearDestination()) {
            _autoStopTracking();
          }
        }
      },
      onError: (e) {
        print('Error in background location tracking: $e');
      },
    );
  }

  // Auto-stop tracking when destination is reached
  Future<void> _autoStopTracking() async {
    if (!_isTracking) return;

    try {
      await _stopTracking();

      _showNotification(
        title: 'Destination Reached!',
        body: 'Tracking has been automatically stopped as you reached your destination.',
      );

      _showMessage('Destination reached! Tracking has been stopped.', Colors.green);

      // Show completion dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('🎉 Destination Reached!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 50,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You have successfully reached your destination.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Destination: ${_destinationAddress}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error auto-stopping tracking: $e');
    }
  }

  // Check for existing active tracking session and restore it
  Future<void> _checkExistingTrackingSession() async {
    if (_userPhone == null) return;

    try {
      final activeSession = await _supabaseService.getActiveTrackingSession(_userPhone!);

      if (activeSession != null) {
        print('Found existing active tracking session');

        // Restore destination if it exists
        if (activeSession['destination_latitude'] != null &&
            activeSession['destination_longitude'] != null) {
          setState(() {
            _selectedDestination = LatLng(
              activeSession['destination_latitude'],
              activeSession['destination_longitude'],
            );
            _destinationAddress = activeSession['destination_address'] ?? 'Destination';
            _selectedAddress = 'Tracking in progress...';
          });
        }

        // Set tracking state to active
        setState(() {
          _isTracking = true;
        });

        // Update markers to show restored destination
        _updateMarkers();

        // Start background tracking again
        _startBackgroundLocationTracking();

        // Show notification that tracking has been restored
        _showNotification(
          title: 'Tracking Restored',
          body: 'Your previous tracking session has been resumed.',
        );

        _showMessage('Previous tracking session resumed', Colors.blue);
      }
    } catch (e) {
      print('Error checking existing tracking session: $e');
    }
  }

// Toggle tracking state
  Future<void> _toggleTracking() async {
    if (_isTracking) {
      await _stopTracking();
    } else {
      await _startTracking();
    }
  }

  // Toggle fullscreen map
  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20), // Added padding on top
            // Search bar - commented out for now
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   child: Column(
            //     children: [
            //       Container(
            //         decoration: BoxDecoration(
            //           color: Colors.white,
            //           borderRadius: BorderRadius.circular(25),
            //           border: Border.all(color: Colors.grey[300]!),
            //           boxShadow: [
            //             BoxShadow(
            //               color: Colors.black.withOpacity(0.1),
            //               blurRadius: 4,
            //               offset: const Offset(0, 2),
            //             ),
            //           ],
            //         ),
            //         child: TextField(
            //           controller: _searchController,
            //           onChanged: (query) {
            //             _searchLocation(query);
            //           },
            //           decoration: InputDecoration(
            //             hintText: 'Search for a destination...',
            //             prefixIcon: Icon(Icons.search, color: Colors.red[600]),
            //             suffixIcon: _searchController.text.isNotEmpty
            //                 ? IconButton(
            //                     icon: Icon(Icons.clear, color: Colors.grey[600]),
            //                     onPressed: () {
            //                       _searchController.clear();
            //                       setState(() {
            //                         _searchResults = [];
            //                       });
            //                     },
            //                   )
            //                 : null,
            //             border: InputBorder.none,
            //             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            //           ),
            //         ),
            //       ),
            //
            //       // Search results
            //       if (_searchResults.isNotEmpty)
            //         Container(
            //           margin: const EdgeInsets.only(top: 8),
            //           decoration: BoxDecoration(
            //             color: Colors.white,
            //             borderRadius: BorderRadius.circular(12),
            //             border: Border.all(color: Colors.grey[300]!),
            //             boxShadow: [
            //               BoxShadow(
            //                 color: Colors.black.withOpacity(0.1),
            //                 blurRadius: 4,
            //                 offset: const Offset(0, 2),
            //               ),
            //             ],
            //           ),
            //           child: ListView.builder(
            //             shrinkWrap: true,
            //             itemCount: _searchResults.length,
            //             itemBuilder: (context, index) {
            //               Location location = _searchResults[index];
            //               return ListTile(
            //                 leading: Icon(Icons.place, color: Colors.red[600]),
            //                 title: Text('Location ${index + 1}'),
            //                 subtitle: Text('${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}'),
            //                 onTap: () => _selectDestinationFromSearch(location),
            //               );
            //             },
            //           ),
            //         ),
            //     ],
            //   ),
            // ),

            // Location inputs section - hide in fullscreen
            if (!_isFullscreen)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    // Current location input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.my_location, color: Colors.green[600], size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _currentAddress,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _isLoadingLocation ? Colors.grey[400] : Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (_isLoadingLocation)
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                                  ),
                                )
                              else if (_currentPosition == null && !_isLoadingLocation)
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(Icons.refresh, color: Colors.green[600], size: 20),
                                  onPressed: _getCurrentLocation,
                                ),
                            ],
                          ),
                          if (_currentLocationDetails.isNotEmpty && !_isLoadingLocation)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 36),
                              child: Text(
                                _currentLocationDetails,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Selected destination input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.red[600], size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedAddress,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (_selectedDestination != null)
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(Icons.clear, color: Colors.red[600], size: 20),
                                  onPressed: _clearDestination,
                                ),
                            ],
                          ),
                          if (_destinationAddress.isNotEmpty && _selectedDestination != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 36),
                              child: Text(
                                _destinationAddress,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Map section
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: _currentPosition != null
                          ? CameraPosition(
                              target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              zoom: 16.0,
                            )
                          : _initialPosition,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                        // If we already have a location, move the camera to it
                        if (_currentPosition != null) {
                          controller.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                zoom: 16.0,
                              ),
                            ),
                          );
                        }

                        // If there's a destination and we're tracking, show both points
                        if (_isTracking && _selectedDestination != null) {
                          // Show both current position and destination in view
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (_currentPosition != null && _selectedDestination != null) {
                              controller.animateCamera(
                                CameraUpdate.newLatLngBounds(
                                  LatLngBounds(
                                    southwest: LatLng(
                                      _currentPosition!.latitude < _selectedDestination!.latitude
                                          ? _currentPosition!.latitude
                                          : _selectedDestination!.latitude,
                                      _currentPosition!.longitude < _selectedDestination!.longitude
                                          ? _currentPosition!.longitude
                                          : _selectedDestination!.longitude,
                                    ),
                                    northeast: LatLng(
                                      _currentPosition!.latitude > _selectedDestination!.latitude
                                          ? _currentPosition!.latitude
                                          : _selectedDestination!.latitude,
                                      _currentPosition!.longitude > _selectedDestination!.longitude
                                          ? _currentPosition!.longitude
                                          : _selectedDestination!.longitude,
                                    ),
                                  ),
                                  100.0, // padding in points
                                ),
                              );
                            }
                          });
                        }
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      markers: _markers,
                      polylines: _polylines,
                      onTap: _onMapTap,
                    ),
                    // Fullscreen button (top right)
                    Positioned(
                      top: 10,
                      right: 60,
                      child: GestureDetector(
                        onTap: _toggleFullscreen,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                            size: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    // Compass/settings button (top right)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.settings, size: 20),
                      ),
                    ),
                    // Back to location button (bottom left)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: GestureDetector(
                        onTap: () {
                          if (_mapController != null && _currentPosition != null) {
                            _mapController!.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                  zoom: 16.0,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.my_location, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // UI elements - hide in fullscreen
            if (!_isFullscreen) ...[
              // Live indicator
              Container(
                margin: const EdgeInsets.only(top: 16, left: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red[400]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Tracking button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ElevatedButton(
                  onPressed: _toggleTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking
                        ? Colors.red[600]
                        : (_selectedDestination != null ? Colors.green[600] : Colors.grey[400]),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isTracking
                            ? Icons.stop
                            : (_selectedDestination != null ? Icons.play_arrow : Icons.location_searching),
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isTracking
                            ? 'Tracking: ON'
                            : (_selectedDestination != null ? 'Start Tracking' : 'Select Destination First'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Destination status indicator - commented out
              // if (_selectedDestination == null && !_isTracking)
              //   Container(
              //     width: double.infinity,
              //     margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              //     padding: const EdgeInsets.all(12),
              //     decoration: BoxDecoration(
              //       color: Colors.orange[50],
              //       borderRadius: BorderRadius.circular(8),
              //       border: Border.all(color: Colors.orange[200]!),
              //     ),
              //     child: Row(
              //       children: [
              //         Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
              //         const SizedBox(width: 8),
              //         Expanded(
              //           child: Text(
              //             'Please select a destination on the map or search to start tracking',
              //             style: TextStyle(
              //               fontSize: 14,
              //               color: Colors.orange[700],
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),

              // Call Officer button (always shown)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ElevatedButton(
                  onPressed: _callOfficer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.call,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Call Police',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Back button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _trackingTimer?.cancel();
    _positionStream?.cancel();

    // Stop tracking if active
    if (_isTracking && _userPhone != null) {
      _supabaseService.stopTrackingSession(_userPhone!);
    }
    super.dispose();
  }
}
