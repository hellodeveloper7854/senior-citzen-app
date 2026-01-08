import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/sos_screen.dart';
import '../screens/track_me_screen.dart' as track_screen;

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Handle notification tap and navigate to appropriate screen
  void handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    print('Notification tapped with payload: $payload');

    if (payload == 'sos_active') {
      _navigateToSOS();
    } else if (payload == 'tracking_active') {
      _navigateToTracking();
    }
  }

  void _navigateToSOS() {
    final currentContext = navigatorKey.currentContext;
    if (currentContext != null) {
      // Navigate to SOS screen
      Navigator.push(
        currentContext,
        MaterialPageRoute(builder: (context) => const SosScreen()),
      );
    }
  }

  void _navigateToTracking() {
    final currentContext = navigatorKey.currentContext;
    if (currentContext != null) {
      // Navigate to Track Me screen
      Navigator.push(
        currentContext,
        MaterialPageRoute(builder: (context) => const track_screen.TrackMeScreen()),
      );
    }
  }
}
