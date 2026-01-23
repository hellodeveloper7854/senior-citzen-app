import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:math';
import '../services/supabase_service.dart';
import '../services/navigation_service.dart';
import '../services/tracking_service.dart';
import '../services/route_service.dart';

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
  List<Map<String, dynamic>> _placePredictions = []; // For place predictions
  bool _showPredictions = false;

  // Tracking related variables
  final SupabaseService _supabaseService = SupabaseService();
  final TrackingService _trackingService = TrackingService();
  final RouteService _routeService = RouteService();
  String? _userPhone;
  String? _userName;
  String _emergencyPhoneNumber = '9326520525'; // Default fallback number
  static const String _emergencyServiceName = 'Police'; // Service name to fetch from database

  // Time-based tracking
  int? _selectedDurationMinutes; // null = indefinite tracking

  // Route information
  RouteResult? _routeResult;
  bool _isCalculatingRoute = false;

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
    _initializeNotificationListeners();
    _loadEmergencyPhoneNumber(_emergencyServiceName);
    _loadUserData();
    _getCurrentLocation();

    // Listen to global tracking service state changes
    _trackingService.addListener(_onTrackingServiceChanged);

    // Initialize with current tracking state
    _isTracking = _trackingService.isTracking;
    if (_trackingService.selectedDestination != null) {
      _selectedDestination = _trackingService.selectedDestination;
      _destinationAddress = _trackingService.destinationAddress;
      _selectedAddress = 'Tracking in progress...';
      _updateMarkers();

      // Calculate route if tracking is being restored
      if (_trackingService.isTracking) {
        // Delay route calculation until we have current position
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_currentPosition != null && _selectedDestination != null) {
            _calculateRouteAndDraw();
          }
        });
      }

      _drawRoute();
    }
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

        // If tracking was restored with destination, calculate route now that we have position
        if (_isTracking && _selectedDestination != null && _routeResult == null) {
          _calculateRouteAndDraw();
        }

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

    // Add current location marker with custom icon for tracking
    if (_currentPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: InfoWindow(
            title: _isTracking ? 'Your Location (Moving)' : 'Your Location',
            snippet: _currentLocationDetails.split('\n').first,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _isTracking ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueGreen,
          ),
          rotation: _isTracking ? 45.0 : 0.0, // Rotate marker when tracking to show movement
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
      if (_routeResult != null) {
        // Use calculated route
        final polyline = _routeService.createPolyline(
          id: 'route',
          points: _routeResult!.routePoints,
          color: Colors.blue,
          width: 5,
        );

        setState(() {
          _polylines = {polyline};
        });
      } else {
        // Fallback to straight line
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
      }
    } else {
      setState(() {
        _polylines = {};
      });
    }
  }

  // Handle map tap to select destination
  void _onMapTap(LatLng position) async {
    if (_isTracking) {
      // If tracking is active, update destination
      final success = await _updateDestinationDuringTracking(position);
      if (success) {
        _showMessage('Destination updated successfully', Colors.green);
      } else {
        _showMessage('Failed to update destination', Colors.red);
      }
      return;
    }

    setState(() {
      _selectedDestination = position;
      _selectedAddress = "Destination selected";
      _isCalculatingRoute = true;
    });

    _getLocationDetails(position.latitude, position.longitude);
    _updateMarkers();

    // Calculate route and ETA
    await _calculateRouteAndDraw();

    setState(() {
      _isCalculatingRoute = false;
    });

    // Auto-start tracking when destination is selected
    if (!_isTracking) {
      // Show confirmation dialog before starting
      _showStartTrackingDialog();
    }
  }

  // Update destination during active tracking
  Future<bool> _updateDestinationDuringTracking(LatLng newDestination) async {
    if (_currentPosition == null) return false;

    try {
      // Get location details for new destination
      await _getLocationDetails(newDestination.latitude, newDestination.longitude);

      // Update via tracking service
      final success = await _trackingService.updateDestination(
        newDestination: newDestination,
        newDestinationAddress: _destinationAddress.isNotEmpty ? _destinationAddress : 'Updated destination',
      );

      if (success) {
        // Recalculate route
        await _calculateRouteAndDraw();

        // Update UI
        setState(() {
          _selectedAddress = 'Destination updated';
        });

        // Show notification
        _showNotification(
          title: 'Destination Updated',
          body: 'Your tracking destination has been updated to ${_destinationAddress.isNotEmpty ? _destinationAddress : 'new location'}.',
        );
      }

      return success;
    } catch (e) {
      print('Error updating destination during tracking: $e');
      return false;
    }
  }

  // Calculate route and draw it on the map
  Future<void> _calculateRouteAndDraw() async {
    if (_currentPosition == null || _selectedDestination == null) return;

    try {
      final routeResult = await _routeService.calculateRoute(
        origin: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        destination: _selectedDestination!,
        travelMode: TravelMode.driving,
      );

      setState(() {
        _routeResult = routeResult;
      });

      // Draw route on map
      _drawRoute();
    } catch (e) {
      print('Error calculating route: $e');
    }
  }

  // Show dialog to start tracking after selecting destination
  void _showStartTrackingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Destination Selected',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 50,
              ),
              const SizedBox(height: 16),
              Text(
                'Start sharing your location to this destination?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startTracking();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Start Sharing',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
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
    if (_isTracking) {
      // If tracking is active, just show a message - destination can be changed but not fully cleared
      _showMessage('Tap on map to change destination while tracking', Colors.blue);
      return;
    }

    setState(() {
      _selectedDestination = null;
      _destinationAddress = "";
      _selectedAddress = "Tap map or search to select destination";
      _polylines = {};
      _routeResult = null;
    });
    _updateMarkers();
  }

  // Callback when tracking service state changes
  void _onTrackingServiceChanged() {
    if (mounted) {
      setState(() {
        _isTracking = _trackingService.isTracking;
        _selectedDestination = _trackingService.selectedDestination;
        _destinationAddress = _trackingService.destinationAddress;
        _currentPosition = _trackingService.currentPosition;

        if (_isTracking && _selectedDestination != null) {
          _selectedAddress = 'Tracking in progress...';
          // Recalculate route with new position
          _recalculateRoute();
        } else if (!_isTracking) {
          _selectedAddress = "Tap map or search to select destination";
        }

        // Update markers and route
        _updateMarkers();
      });

      // Draw route after setState to ensure we have all the data
      if (_isTracking && _selectedDestination != null) {
        _drawRoute();
      }
    }
  }

  // Recalculate route when position changes
  Future<void> _recalculateRoute() async {
    if (_currentPosition == null || _selectedDestination == null) return;

    try {
      final routeResult = await _routeService.calculateRoute(
        origin: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        destination: _selectedDestination!,
        travelMode: TravelMode.driving,
      );

      if (mounted) {
        setState(() {
          _routeResult = routeResult;
        });
      }
    } catch (e) {
      print('Error recalculating route: $e');
    }
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

          // Initialize TrackingService with user data
          await _trackingService.initialize();
          print('TrackMeScreen: User data loaded and TrackingService initialized');
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

    // If destination is selected, auto-start tracking
    if (_selectedDestination != null) {
      await _startTrackingWithDuration();
    } else {
      // If no destination, show duration selection dialog
      _showDurationSelectionDialog();
    }
  }

  // Show duration selection dialog
  void _showDurationSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Share Location For',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select how long you want to share your location',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              // Duration options
              ...[
                {'label': '15 minutes', 'minutes': 15},
                {'label': '30 minutes', 'minutes': 30},
                {'label': '1 hour', 'minutes': 60},
                {'label': '2 hours', 'minutes': 120},
                {'label': 'Indefinitely', 'minutes': null},
              ].map((option) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _selectedDurationMinutes = option['minutes'] as int?;
                          _startTrackingWithDuration();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          option['label'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Start tracking with selected duration
  Future<void> _startTrackingWithDuration() async {
    print('=== _startTrackingWithContext ===');
    print('Current position: $_currentPosition');
    print('Selected destination: $_selectedDestination');
    print('Selected duration: $_selectedDurationMinutes');

    // Ensure TrackingService is initialized with user data
    if (_trackingService.userPhone == null) {
      print('TrackingService not initialized, initializing now...');
      await _trackingService.initialize();
      if (_trackingService.userPhone == null) {
        _showMessage('Failed to initialize tracking service. Please try again.', Colors.red);
        return;
      }
    }

    // Request background location permission first
    await _requestBackgroundLocationPermission();

    try {
      print('Starting tracking service...');
      final success = await _trackingService.startTracking(
        currentPosition: _currentPosition!,
        locationAddress: _currentLocationDetails.split('\n').first,
        destination: _selectedDestination, // Now optional
        destinationAddress: _destinationAddress.isNotEmpty ? _destinationAddress : null,
        durationMinutes: _selectedDurationMinutes,
      );

      print('Tracking service result: $success');

      if (success) {
        String durationText = _selectedDurationMinutes != null
            ? 'for ${_getDurationText(_selectedDurationMinutes!)}'
            : _selectedDestination != null ? 'to your destination' : 'indefinitely';

        _showNotification(
          title: 'Tracking Started',
          body: 'Your location is being shared $durationText.',
        );

        _showMessage('Tracking started successfully', Colors.green);
        print('✓ Tracking started successfully with background monitoring');
      } else {
        _showMessage('Failed to start tracking', Colors.red);
        print('✗ Tracking service returned false');
      }
    } catch (e, stackTrace) {
      print('✗ Error starting tracking: $e');
      print('Stack trace: $stackTrace');
      _showMessage('Failed to start tracking: ${e.toString()}', Colors.red);
    }
  }

  // Get duration text for display
  String _getDurationText(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else {
      final hours = minutes / 60;
      return '${hours.toInt()} hour${hours > 1 ? "s" : ""}';
    }
  }

  // Format time for display
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Search for location predictions using geocoding
  Future<void> _searchPlacePredictions(String query) async {
    if (query.isEmpty) return;

    try {
      setState(() {
        _isSearching = true;
      });

      // Use geocoding to search for places
      List<Location> locations = await locationFromAddress(query);

      // Create predictions from locations
      List<Map<String, dynamic>> predictions = [];
      for (var location in locations) {
        // Get placemarks to get formatted address
        List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          String description = _formatAddress(place);
          predictions.add({
            'description': description,
            'latitude': location.latitude,
            'longitude': location.longitude,
            'place': place,
          });
        }
      }

      if (mounted) {
        setState(() {
          _placePredictions = predictions.take(5).toList(); // Limit to 5 results
          _showPredictions = predictions.isNotEmpty;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Error searching places: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _showPredictions = false;
        });
      }
    }
  }

  // Select place from prediction list
  Future<void> _selectPlaceFromPrediction(Map<String, dynamic> prediction) async {
    try {
      final latitude = prediction['latitude'] as double;
      final longitude = prediction['longitude'] as double;
      final position = LatLng(latitude, longitude);

      // Clear search
      _searchController.clear();
      setState(() {
        _showPredictions = false;
        _placePredictions = [];
      });

      // If tracking is active, update destination
      if (_isTracking) {
        await _updateDestinationDuringTracking(position);
      } else {
        // Set as new destination
        setState(() {
          _selectedDestination = position;
          _selectedAddress = "Destination selected";
          _isCalculatingRoute = true;
        });

        _getLocationDetails(latitude, longitude);
        _updateMarkers();

        // Calculate route
        await _calculateRouteAndDraw();

        setState(() {
          _isCalculatingRoute = false;
        });

        // Show confirmation dialog
        _showStartTrackingDialog();
      }
    } catch (e) {
      print('Error selecting place: $e');
      _showMessage('Failed to select location', Colors.red);
    }
  }

  // Format address from placemark
  String _formatAddress(Placemark place) {
    List<String> parts = [];
    if (place.name?.isNotEmpty == true) parts.add(place.name!);
    if (place.street?.isNotEmpty == true) parts.add(place.street!);
    if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
    if (place.administrativeArea?.isNotEmpty == true) parts.add(place.administrativeArea!);
    if (place.country?.isNotEmpty == true) parts.add(place.country!);

    return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
  }

  // Stop tracking session
  Future<void> _stopTracking() async {
    try {
      final success = await _trackingService.stopTracking();

      if (success) {
        print('Tracking stopped successfully');
      } else {
        _showMessage('Error stopping tracking', Colors.red);
      }
    } catch (e) {
      print('Error stopping tracking: $e');
      _showMessage('Error stopping tracking', Colors.red);
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

  // Initialize notification listeners
  Future<void> _initializeNotificationListeners() async {
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
            // Header with back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
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
              Stack(
                children: [
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
                        // Search bar for destination
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Icon(Icons.search, color: Colors.grey[600], size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: _isTracking
                                        ? 'Search new destination to update'
                                        : 'Search destination or tap on map',
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      _searchPlacePredictions(value);
                                    } else {
                                      setState(() {
                                        _showPredictions = false;
                                        _placePredictions = [];
                                      });
                                    }
                                  },
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _showPredictions = false;
                                      _placePredictions = [];
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Selected destination display (simplified)
                        if (_selectedDestination != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.red[600], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isTracking ? 'Tracking to:' : 'Selected:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (_destinationAddress.isNotEmpty)
                                        Text(
                                          _destinationAddress,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.red[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                if (!_isTracking)
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(Icons.clear, color: Colors.red[600], size: 18),
                                    onPressed: _clearDestination,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Place predictions dropdown - positioned as overlay
                  if (_showPredictions && _placePredictions.isNotEmpty)
                    Positioned(
                      top: 130, // Adjust based on search bar position
                      left: 16,
                      right: 16,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _placePredictions.length,
                          itemBuilder: (context, index) {
                            final prediction = _placePredictions[index];
                            return ListTile(
                              leading: Icon(Icons.location_on, color: Colors.red[600], size: 20),
                              title: Text(
                                prediction['description'] ?? 'Unknown place',
                                style: const TextStyle(fontSize: 14),
                              ),
                              onTap: () {
                                _selectPlaceFromPrediction(prediction);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                ],
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
                    // Floating route information card - positioned at bottom right
                    if (_routeResult != null && _selectedDestination != null)
                      Positioned(
                        bottom: 16, // Position from bottom
                        right: 16, // Position from right
                        left: null, // Remove left constraint
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min, // Only take needed width
                            children: [
                              // Distance
                              Row(
                                children: [
                                  Icon(Icons.straighten, color: Colors.blue[700], size: 20),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _routeResult!.distanceText,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                      Text(
                                        'Distance',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Vertical divider
                              Container(
                                height: 30,
                                width: 1,
                                color: Colors.grey[300],
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              // Estimated time
                              Row(
                                children: [
                                  Icon(Icons.access_time, color: Colors.blue[700], size: 20),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _routeResult!.durationText,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                      Text(
                                        'Est. Time',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Loading indicator
                              if (_isCalculatingRoute)
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Updating...',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
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
                child: Column(
                  children: [
                    // Start/Stop tracking button
                    ElevatedButton(
                      onPressed: _toggleTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTracking ? Colors.red[600] : Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isTracking ? Icons.stop : Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isTracking
                                ? 'Stop Tracking'
                                : 'Start Sharing Location',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Display current tracking status
                    if (_isTracking) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _trackingService.trackingDurationMinutes != null
                                        ? 'Sharing for ${_getDurationText(_trackingService.trackingDurationMinutes!)}'
                                        : _trackingService.selectedDestination != null
                                            ? 'Sharing to destination'
                                            : 'Sharing indefinitely',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            // Show remaining time if duration-based
                            if (_trackingService.sessionEndTime != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Ends at ${_formatTime(_trackingService.sessionEndTime!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
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

    // Remove listener from tracking service
    _trackingService.removeListener(_onTrackingServiceChanged);

    // NOTE: We DO NOT stop tracking here anymore
    // Tracking continues in the background managed by TrackingService
    // Tracking will only stop when:
    // 1. User explicitly stops it
    // 2. Police stops it remotely
    // 3. Destination is reached

    super.dispose();
  }
}
