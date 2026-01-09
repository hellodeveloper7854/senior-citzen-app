import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/sos_screen.dart';
import '../screens/track_me_screen.dart' as track_screen;
import 'tracking_service.dart';

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
    } else if (payload == 'tracking_continuation') {
      _navigateToTrackingWithContinuationDialog();
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

  void _navigateToTrackingWithContinuationDialog() {
    final currentContext = navigatorKey.currentContext;
    if (currentContext != null) {
      // Navigate to Track Me screen and then show continuation dialog
      Navigator.push(
        currentContext,
        MaterialPageRoute(builder: (context) => const track_screen.TrackMeScreen()),
      ).then((_) {
        // After navigation, check if tracking is still active and show dialog
        Future.delayed(const Duration(milliseconds: 500), () {
          final trackingService = TrackingService();
          if (trackingService.isTracking &&
              trackingService.sessionStartTime != null) {
            final duration = DateTime.now().difference(trackingService.sessionStartTime!);
            if (duration.inMinutes >= 15) {
              _showContinuationDialog(currentContext);
            }
          }
        });
      });
    }
  }

  void _showContinuationDialog(BuildContext context) {
    final trackingService = TrackingService();
    final duration = trackingService.sessionStartTime != null
        ? DateTime.now().difference(trackingService.sessionStartTime!)
        : const Duration(minutes: 0);

    showDialog(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Still Sharing Location?',
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
                'You have been sharing your location for ${duration.inMinutes} minutes.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Do you want to continue sharing?',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Stop tracking
                trackingService.stopTracking();
              },
              child: const Text(
                'Stop Sharing',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Continue tracking - timer will check again in 15 minutes
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
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
