import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/supabase_service.dart';
import '../services/navigation_service.dart';
import '../utils/crypto_util.dart';
import '../utils/permission_utils.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  _SosScreenState createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  String _currentLocation = 'Getting location...';
  String _locationAddress = '';
  bool _locationLoaded = false;
  List<Map<String, dynamic>> _emergencyContacts = [];
  String? _profilePhotoUrl;
  bool _isProcessing = true; // Show loading state
  String _statusMessage = 'Initializing emergency response...';
  String _emergencyPhoneNumber = '9326520525'; // Default fallback number
  static const String _emergencyServiceName = 'Police'; // Service name to fetch from database
  
  // Animation for the "Calling...." dots
  late AnimationController _dotController;
  late Animation<int> _dotAnimation;

  // Map related variables
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  final LatLng _defaultLocation = const LatLng(19.0760, 72.8777); // Mumbai coordinates as default
  
  final String _defaultUserAvatarPath = 'assets/Ellipse.png';
  final String _logoAssetPath = 'assets/Senior Citizen.png';
  
  // Flag to prevent duplicate SOS alerts
  bool _sosAlertSent = false;

  // Store the alert ID for updating status
  int? _currentAlertId;

  // Store alert timestamp for time remaining calculation
  DateTime? _alertTimestamp;

  // Timer for updating time remaining
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Reset the SOS alert flag to ensure fresh state each time
    _sosAlertSent = false;
    _currentAlertId = null;

    // Start timer to update time remaining display
    _startTimer();

    // Check for existing active SOS first
    _checkExistingActiveSOS().then((hasActive) {
      if (!hasActive) {
        // Only create new SOS if no active one exists
        _initializeSOSWorkflow();
      } else {
        // If active SOS exists, just show the screen with existing alert info
        _updateStatus('SOS Alert Already Active');
        _loadEmergencyContactsAndProfile();
        _getCurrentLocation();
        // Mark the SOS alert as viewed since user opened the screen
        _markSOSAlertAsViewed();
      }
    });
  }

  // Start timer to update time remaining
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _sosAlertSent && !_isProcessing && _alertTimestamp != null) {
        setState(() {}); // Trigger rebuild to update time remaining
      }
    });
  }

  // Check if user already has an active SOS alert
  Future<bool> _checkExistingActiveSOS() async {
    try {
      final email = await _supabaseService.getCurrentUserEmail();
      if (email == null) return false;

      final credentials = await _supabaseService.getUserCredentials(email);
      if (credentials == null) return false;

      final userPhone = credentials['phone_number'];
      final alerts = await _supabaseService.getUserSOSAlerts(userPhone);

      // Check if there's any active SOS alert within 15 minutes
      final now = DateTime.now();
      const duration = Duration(minutes: 15);

      for (var alert in alerts) {
        if (alert['status'] == 'active' && alert['alert_timestamp'] != null) {
          try {
            final alertTime = DateTime.parse(alert['alert_timestamp']);
            final timeDifference = now.difference(alertTime);

            // If alert is within 15 minutes, consider it active
            if (timeDifference <= duration) {
              if (mounted) {
                setState(() {
                  _currentAlertId = alert['id'] as int?;
                  _sosAlertSent = true;
                  _isProcessing = false;
                  _statusMessage = 'SOS Alert Active - Help is on the way';
                  _alertTimestamp = alertTime;
                });
              }
              return true;
            } else {
              // Alert is older than 15 minutes, auto-expire it
              await _supabaseService.updateSOSAlertStatus(
                alert['id'],
                'expired',
                notes: 'Auto-expired after 15 minutes',
              );
            }
          } catch (e) {
            print('Error parsing alert timestamp: $e');
          }
        }
      }

      return false;
    } catch (e) {
      print('Error checking existing SOS: $e');
      return false;
    }
  }

  // Initialize the SOS workflow (create new alert)
  void _initializeSOSWorkflow() {
    // Start with immediate actions first
    _updateStatus('Connecting to emergency services...');
    _loadEmergencyPhoneNumber(_emergencyServiceName).then((_) {
      _makePhoneCall(); // Call after getting phone number
    });
    _startCallingAnimation(); // UI feedback
    _initializeNotifications(); // Background

    // Load data in parallel but non-blocking
    _loadEmergencyContactsAndProfile();
    _getCurrentLocation();
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
        _isProcessing = true;
      });
    }
  }
  
  // --- Initialization and Cleanup ---
  void _startCallingAnimation() {
    _dotController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    _dotAnimation = IntTween(begin: 0, end: 3).animate(_dotController);
  }

  @override
  void dispose() {
    _dotController.dispose();
    _mapController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // --- Utility/Service Functions (Retained) ---

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap using NavigationService
        NavigationService().handleNotificationTap(response);
      },
    );
  }

  // Show persistent notification for SOS
  Future<void> _showPersistentSOSNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'sos_ongoing_channel',
      'SOS Ongoing Notifications',
      channelDescription: 'Persistent notification for active SOS alerts',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true, // Makes notification non-dismissable
      autoCancel: false, // Don't cancel when tapped
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      1, // Notification ID (can be used to update/cancel)
      'SOS Alert Active',
      'Your location is being shared with police. Tap to view.',
      platformChannelSpecifics,
      payload: 'sos_active',
    );
  }

  // Cancel persistent SOS notification
  Future<void> _cancelPersistentSOSNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(1);
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location services first (fast operation)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _currentLocation = 'Location services disabled - please enable GPS');
        _showLocationSettingsDialog();
        return;
      }

      // Request permission (fast if already granted)
      final hasPermission = await PermissionUtils.requestLocationPermission(context);
      if (!hasPermission) {
        if (mounted) setState(() => _currentLocation = 'Location permission denied - tap to retry');
        return;
      }

      // Try to get last known position first (much faster)
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        await _handleLocationSuccess(lastPosition);
        // Continue getting fresh position in background
        _getFreshLocation();
        return;
      }

      // Get fresh position with shorter timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Changed from high to medium for speed
        timeLimit: const Duration(seconds: 8), // Reduced from 15 to 8 seconds
      );

      await _handleLocationSuccess(position);
    } catch (e) {
      if (mounted) setState(() => _currentLocation = 'Unable to get location: ${e.toString().split(':').first}');
      _updateMapWithDefaultLocation();
    }
  }

  // Separate method for getting fresh location in background
  Future<void> _getFreshLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      // Update with fresh location if we got it
      await _handleLocationSuccess(position);
    } catch (e) {
      // Silently fail - we already have a location
    }
  }

  void _showLocationSettingsDialog() {
     // ... (Dialog implementation) ...
     showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enable Location Services'),
          content: const Text('Location services are disabled. Please enable GPS/location services to use emergency features.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDialog() {
     // ... (Dialog implementation) ...
     showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text('This app needs location permission to send your location to emergency contacts during SOS alerts.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.requestPermission();
                _getCurrentLocation();
              },
              child: const Text('Grant Permission'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionSettingsDialog() {
     // ... (Dialog implementation) ...
     showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text('Location permission is permanently denied. Please enable it in app settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLocationSuccess(Position position) async {
    _locationAddress = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
    if (mounted) {
      setState(() {
        _currentLocation = 'Location acquired';
        _locationLoaded = true;
        _currentPosition = position;
        _statusMessage = 'Emergency alert sent! Help is on the way.';
        _isProcessing = false;
      });
    }
    _updateMapLocation(position);

    // Send admin alert in background - don't await
    // Only send once using the flag to prevent duplicates
    if (!_sosAlertSent) {
      _sosAlertSent = true;
      _sendLocationToContacts(position);
      _sendSOSAlertToAdmin(position);

      // Show persistent notification only for new SOS
      await _showPersistentSOSNotification();
    }
    // Note: For existing SOS alerts, don't show the notification again
    // The notification should already be active from when it was first created
  }

  void _updateMapWithDefaultLocation() {
    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('default_location'),
            position: _defaultLocation,
            infoWindow: const InfoWindow(
              title: 'Default Location',
              snippet: 'Unable to get current location',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          ),
        );
      });
    }
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_defaultLocation, 12),
    );
  }

  Future<void> _sendSOSAlertToAdmin(Position position) async {
    try {
      final email = await _supabaseService.getCurrentUserEmail();
      if (email == null) return;
      final credentials = await _supabaseService.getUserCredentials(email);
      if (credentials == null) return;
      final profile = await _supabaseService.getUserProfileByPhone(credentials['phone_number']);
      if (profile == null) return;
      List<String> emergencyContacts = _emergencyContacts.map((contact) => contact['number'] as String).toList();
      final alertId = await _supabaseService.createSOSAlert(
        userId: credentials['phone_number'],
        userName: profile['full_name'] ?? 'Unknown User',
        latitude: position.latitude,
        longitude: position.longitude,
        locationAddress: _locationAddress,
        emergencyContacts: emergencyContacts,
      );

      // Store the alert ID for later update
      if (alertId != null && mounted) {
        setState(() {
          _currentAlertId = alertId;
        });
      }
    } catch (e) {
      // Silently fail - admin alert is secondary to immediate emergency response
    }
  }

  Future<void> _loadEmergencyContactsAndProfile() async {
    try {
      final email = await _supabaseService.getCurrentUserEmail();
      if (email == null) return;

      final credentials = await _supabaseService.getUserCredentials(email);
      if (credentials == null) return;

      final profile = await _supabaseService.getUserProfileByPhone(credentials['phone_number']);
      if (profile == null || !mounted) return;

      // Decrypt contact numbers in parallel for speed
      final decrypt1 = CryptoUtil.decryptString(profile['emergency_contact_1_number']);
      final decrypt2 = CryptoUtil.decryptString(profile['emergency_contact_2_number']);

      final results = await Future.wait([decrypt1, decrypt2]);

      if (!mounted) return;

      setState(() {
        _emergencyContacts = [
          if (profile['emergency_contact_1_name'] != null && results[0] != null)
            {
              'name': profile['emergency_contact_1_name'],
              'number': results[0],
              'relation': profile['emergency_contact_1_relation'] ?? 'Contact'
            },
          if (profile['emergency_contact_2_name'] != null && results[1] != null)
            {
              'name': profile['emergency_contact_2_name'],
              'number': results[1],
              'relation': profile['emergency_contact_2_relation'] ?? 'Contact'
            },
        ];
        final url = profile['profile_img'] as String?;
        _profilePhotoUrl = (url != null && url.trim().isNotEmpty) ? url.trim() : null;
      });
    } catch (e) {
      // Handle error silently - emergency contacts are not critical for initial SOS
    }
  }

  Future<void> _sendLocationToContacts(Position position) async {
    if (_emergencyContacts.isEmpty) return;

    // Get user's name from cached profile data (already loaded)
    String userName = 'Unknown User';
    try {
      final email = await _supabaseService.getCurrentUserEmail();
      if (email != null) {
        final credentials = await _supabaseService.getUserCredentials(email);
        if (credentials != null) {
          final profile = await _supabaseService.getUserProfileByPhone(credentials['phone_number']);
          if (profile != null && profile['full_name'] != null) {
            userName = profile['full_name'];
          }
        }
      }
    } catch (e) {
      // Keep default name if unable to fetch
    }

    final locationMessage = 'This is an SOS alert from $userName, I need assistance! My location is https://www.google.com/maps?q=${position.latitude},${position.longitude}. Please respond. - आधारवड ठाणे पोलीस';

    // Extract phone numbers from emergency contacts
    final phoneNumbers = _emergencyContacts.map((contact) => contact['number'] as String).toList();

    // Send SMS using Supabase Edge Function
    _sendSMSToContacts(phoneNumbers, locationMessage).then((_) {
      if (mounted) {
        _showLocalNotification('Emergency Alert Sent', 'Location shared with emergency contacts');
      }
    });
  }

  // New method to send SMS using Supabase Edge Function
  Future<void> _sendSMSToContacts(List<String> phoneNumbers, String message) async {
    for (final phoneNumber in phoneNumbers) {
      await _supabaseService.sendSMS(phoneNumber, message);
    }
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Alerts',
      channelDescription: 'Emergency notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      _updateMapLocation(_currentPosition!);
    } else {
      _updateMapWithDefaultLocation();
    }
  }

  void _updateMapLocation(Position position) {
    final LatLng currentLatLng = LatLng(position.latitude, position.longitude);
    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: currentLatLng,
            infoWindow: const InfoWindow(
              title: 'Your Location',
              snippet: 'Emergency location',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      });
    }
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(currentLatLng, 15),
    );
  }

  // Update SOS alert status to "Request terminate"
  Future<void> _updateSOSStatusToTerminated() async {
    if (_currentAlertId == null) return;

    try {
      await _supabaseService.updateSOSAlertStatus(
        _currentAlertId!,
        'Request terminate',
        notes: 'User terminated the SOS alert from the app',
      );

      // Cancel persistent notification
      await _cancelPersistentSOSNotification();

      // Show notification that alert has been terminated
      await _showLocalNotification(
        'SOS Alert Terminated',
        'Your SOS alert has been marked as terminated',
      );
    } catch (e) {
      print('Error updating SOS status: $e');
    }
  }

  // Calculate time remaining for SOS alert
  String _getTimeRemaining() {
    if (_alertTimestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(_alertTimestamp!);
    const totalDuration = Duration(minutes: 15);
    final remaining = totalDuration - difference;

    if (remaining.isNegative) return 'Expired';

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Mark SOS alert as viewed when user opens the screen
  Future<void> _markSOSAlertAsViewed() async {
    if (_currentAlertId == null) return;

    try {
      await _supabaseService.markSOSAlertAsViewed(_currentAlertId!);
      print('SOS alert marked as viewed');
    } catch (e) {
      print('Error marking SOS alert as viewed: $e');
    }
  }

  // --- ROBUST PHONE CALL FUNCTIONALITY FOR LATEST ANDROID DEVICES ---
  Future<void> _makePhoneCall() async {
    // Request phone permission before making the call
    final hasPermission = await PermissionUtils.requestPhonePermission(context);

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone permission is required to make emergency calls')),
        );
      }
      return;
    }

    // Use emergency phone number from database
    await PermissionUtils.launchPhoneCall(_emergencyPhoneNumber.replaceAll('-', ''), context);
  }

  // Load emergency phone number from database based on service name
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

  // --- UI Components ---
  Widget _buildAnimatedDots() {
    return AnimatedBuilder(
      animation: _dotAnimation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Opacity(
                opacity: _dotAnimation.value > index ? 1.0 : 0.2,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.black, // Changed to black for contrast over the white header area
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildStackedAvatars() {
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarRadius = screenWidth * 0.075;

    return SizedBox(
      width: screenWidth * 0.3,
      height: screenWidth * 0.15,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // User Avatar (Right) - Elderly Woman
          Positioned(
            right: 0,
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: avatarRadius * 0.93,
                backgroundImage: _profilePhotoUrl != null
                    ? MemoryImage(base64Decode(_profilePhotoUrl!))
                    : AssetImage(_defaultUserAvatarPath) as ImageProvider,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          ),
          // Police Avatar (Left) - Male Officer
          Positioned(
            left: 0,
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: avatarRadius * 0.93,
                backgroundImage: const AssetImage('assets/police_avatar.png'), // Placeholder asset
                backgroundColor: const Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Map Widget ---
  Widget _buildMapWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5, // Explicitly sized to take middle space
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : _defaultLocation,
              zoom: _currentPosition != null ? 15 : 12,
            ),
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            mapType: MapType.normal,
          ),
        ),
      ),
    );
  }

  // --- Main Build Method (New Layout) ---
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      // Set background color to match the header's outer color for consistency
      backgroundColor: Color(0xff8e8e8e),
      body: Stack(
        children: [
          // 1. Decorative Circles (Background) - responsive
           Positioned(
                    top: -screenHeight * 0.06,
                    left: -screenWidth * 0.03,
                    child: Container(
                      width: screenWidth * 0.5,
                      height: screenWidth * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.49),
                      ),
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.01,
                    left: -screenWidth * 0.2,
                    child: Container(
                      width: screenWidth * 0.5,
                      height: screenWidth * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.49),
                      ),
                    ),
                  ),

          // 2. Main Content Column
          SafeArea(
            child: Column(
              children: [
                // 2.1 Header Area (Logo, Avatars, Calling Text)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(top: screenHeight * 0.01, bottom: screenHeight * 0.015),
                  // Background will be the white circle at the top
                  child: Column(
                    children: [
                      // Header with back button and logo on same row
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: 4),
                        child: Row(
                          children: [
                            // Back button
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.black87),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            // Logo
                            Image.asset(
                              _logoAssetPath,
                              width: screenWidth * 0.15,
                              height: screenWidth * 0.15,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Stacked Avatars
                      _buildStackedAvatars(),

                      SizedBox(height: screenHeight * 0.025),

                      // Request sent text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Request sent to',
                            style: TextStyle(
                              color: Colors.black, // Dark text over light area
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' Police',
                            style: TextStyle(
                              color: Colors.black, // Dark text over light area
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      // Status message
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        _sosAlertSent && !_isProcessing
                            ? 'SOS Alert Active - Help is on the way'
                            : _statusMessage,
                        style: TextStyle(
                          color: _isProcessing ? Colors.orange : Colors.green,
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Time remaining (only when alert is active)
                      if (_sosAlertSent && !_isProcessing && _getTimeRemaining().isNotEmpty)
                        Column(
                          children: [
                            SizedBox(height: screenHeight * 0.01),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.orange.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 18,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Expires in: ${_getTimeRemaining()}',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: screenWidth * 0.032,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                      // Displaying the emergency phone number from database
                      SizedBox(height: screenHeight * 0.005),
                       Text(
                        _emergencyPhoneNumber,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 2.2 Map Widget (The requested mid-section)
                const SizedBox(height: 20),
                Expanded(
                  child: _buildMapWidget(context),
                ),
                const SizedBox(height: 20),
                
                // 2.3 Footer Area (Cancel Button)
                Padding(
                  padding: EdgeInsets.only(bottom: screenHeight * 0.025),
                  child: SizedBox(
                    width: screenWidth * 0.2,
                    height: screenWidth * 0.2,
                    child: FloatingActionButton(
                      onPressed: () async {
                        // Show confirmation dialog before closing
                        final shouldTerminate = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange[600],
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Cancel SOS Alert',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              content: const Text(
                                'Are you sure you want to cancel this SOS alert?\n\nThis will mark the alert as "Request terminate".',
                                style: TextStyle(fontSize: 16),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop(false);
                                  },
                                  child: Text(
                                    'Keep Active',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop(true);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Terminate',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        // If user confirmed, update status and close
                        if (shouldTerminate == true) {
                          await _updateSOSStatusToTerminated();
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      backgroundColor: const Color(0xFFEF4444), // Red color
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 10,
                      child: Icon(
                        Icons.close, // 'X' icon
                        size: screenWidth * 0.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}