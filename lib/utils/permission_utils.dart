import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class PermissionUtils {
  // Request microphone permission for audio recording
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.microphone.request();
      if (result.isGranted) {
        return true;
      } else if (result.isPermanentlyDenied) {
        await _showPermissionDialog(
          context,
          'Microphone Permission Required',
          'This app needs microphone permission to record audio for emergency situations. Please enable it in app settings.',
          Permission.microphone,
        );
        return false;
      }
    } else if (status.isPermanentlyDenied) {
      await _showPermissionDialog(
        context,
        'Microphone Permission Required',
        'This app needs microphone permission to record audio for emergency situations. Please enable it in app settings.',
        Permission.microphone,
      );
      return false;
    }

    return false;
  }

  // Request location permission for GPS tracking
  static Future<bool> requestLocationPermission(BuildContext context) async {
    final status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.location.request();
      if (result.isGranted) {
        return true;
      } else if (result.isPermanentlyDenied) {
        await _showPermissionDialog(
          context,
          'Location Permission Required',
          'This app needs location permission to send your location to emergency contacts during SOS alerts. Please enable it in app settings.',
          Permission.location,
        );
        return false;
      }
    } else if (status.isPermanentlyDenied) {
      await _showPermissionDialog(
        context,
        'Location Permission Required',
        'This app needs location permission to send your location to emergency contacts during SOS alerts. Please enable it in app settings.',
        Permission.location,
      );
      return false;
    }

    return false;
  }

  // Request phone call permission for emergency calls
  static Future<bool> requestPhonePermission(BuildContext context) async {
    // For Android 13+, we need to request CALL_PHONE permission specifically
    final phoneStatus = await Permission.phone.status;
    final callPhoneStatus = await Permission.phone.request();

    if (callPhoneStatus.isGranted || phoneStatus.isGranted) {
      return true;
    }

    if (callPhoneStatus.isDenied || callPhoneStatus.isPermanentlyDenied) {
      await _showPermissionDialog(
        context,
        'Phone Permission Required',
        'This app needs phone permission to make emergency calls to police. Please enable it in app settings.',
        Permission.phone,
      );
      return false;
    }

    return false;
  }

  // Request SMS permission for emergency SMS
  static Future<bool> requestSmsPermission(BuildContext context) async {
    final smsStatus = await Permission.sms.status;
    final smsRequest = await Permission.sms.request();

    if (smsStatus.isGranted || smsRequest.isGranted) {
      return true;
    }

    if (smsRequest.isDenied || smsRequest.isPermanentlyDenied) {
      await _showPermissionDialog(
        context,
        'SMS Permission Required',
        'This app needs SMS permission to send emergency alerts to your contacts. Please enable it in app settings.',
        Permission.sms,
      );
      return false;
    }

    return false;
  }

  // Request notification permission (required on Android 13+)
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.notification.request();
      if (result.isGranted) {
        return true;
      } else if (result.isPermanentlyDenied) {
        await _showPermissionDialog(
          context,
          'Notification Permission Required',
          'This app needs notification permission to send alerts and updates. Please enable it in app settings.',
          Permission.notification,
        );
        return false;
      }
    } else if (status.isPermanentlyDenied) {
      await _showPermissionDialog(
        context,
        'Notification Permission Required',
        'This app needs notification permission to send alerts and updates. Please enable it in app settings.',
        Permission.notification,
      );
      return false;
    }

    return false;
  }

  // Request camera permission for profile photos
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        return true;
      } else if (result.isPermanentlyDenied) {
        await _showPermissionDialog(
          context,
          'Camera Permission Required',
          'This app needs camera permission to take profile photos. Please enable it in app settings.',
          Permission.camera,
        );
        return false;
      }
    } else if (status.isPermanentlyDenied) {
      await _showPermissionDialog(
        context,
        'Camera Permission Required',
        'This app needs camera permission to take profile photos. Please enable it in app settings.',
        Permission.camera,
      );
      return false;
    }

    return false;
  }

  // Request storage permission for gallery access
  static Future<bool> requestStoragePermission(BuildContext context) async {
    final status = await Permission.storage.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.storage.request();
      if (result.isGranted) {
        return true;
      } else if (result.isPermanentlyDenied) {
        await _showPermissionDialog(
          context,
          'Storage Permission Required',
          'This app needs storage permission to access gallery photos. Please enable it in app settings.',
          Permission.storage,
        );
        return false;
      }
    } else if (status.isPermanentlyDenied) {
      await _showPermissionDialog(
        context,
        'Storage Permission Required',
        'This app needs storage permission to access gallery photos. Please enable it in app settings.',
        Permission.storage,
      );
      return false;
    }

    return false;
  }

  // Show permission dialog for permanently denied permissions
  static Future<void> _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
    Permission permission,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Request all critical permissions at once (for app initialization)
  static Future<Map<Permission, PermissionStatus>> requestAllCriticalPermissions() async {
    final permissions = [
      Permission.location,
      Permission.microphone,
      Permission.phone,
      Permission.sms,
      Permission.camera,
      Permission.storage,
      Permission.notification,
    ];

    final statuses = await permissions.request();
    return statuses;
  }

  // Request permissions on app startup (call this in main.dart)
  static Future<void> requestPermissionsOnStartup(BuildContext? context) async {
    try {
      // Request critical permissions that are needed for the app to function
      final statuses = await requestAllCriticalPermissions();

      // Log permission statuses for debugging (you can remove this in production)
      statuses.forEach((permission, status) {
        print('Permission $permission: $status');
      });

      // If context is provided, show a dialog for any denied permissions
      if (context != null) {
        final deniedPermissions = statuses.entries
            .where((entry) => entry.value.isDenied || entry.value.isPermanentlyDenied)
            .map((entry) => entry.key)
            .toList();

        if (deniedPermissions.isNotEmpty) {
          await _showStartupPermissionDialog(context, deniedPermissions);
        }
      }
    } catch (e) {
      print('Error requesting permissions on startup: $e');
    }
  }

  // Show dialog for permissions denied on startup
  static Future<void> _showStartupPermissionDialog(BuildContext context, List<Permission> deniedPermissions) async {
    final permissionNames = deniedPermissions.map((p) {
      switch (p) {
        case Permission.location:
          return 'Location';
        case Permission.microphone:
          return 'Microphone';
        case Permission.phone:
          return 'Phone';
        case Permission.sms:
          return 'SMS';
        case Permission.camera:
          return 'Camera';
        case Permission.storage:
          return 'Storage';
        case Permission.notification:
          return 'Notifications';
        default:
          return p.toString();
      }
    }).join(', ');

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: Text(
            'The following permissions are needed for the app to work properly: $permissionNames. '
            'You can grant them now or enable them later in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // --- SMS and Phone Call Launching Utilities for Latest Android Devices ---

  // Launch SMS with message - more robust for latest Android versions
  static Future<bool> launchSms(String phoneNumber, String message, BuildContext context) async {
    try {
      // First try the standard SMS URI
      final Uri smsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        return true;
      }

      // Fallback: Try without body parameter
      final Uri fallbackUri = Uri.parse('sms:$phoneNumber');
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        return true;
      }

      // If both fail, show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open SMS app. Please check your device settings.')),
        );
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening SMS app: ${e.toString()}')),
        );
      }
      return false;
    }
  }

  // Launch phone call - more robust for latest Android versions
  static Future<bool> launchPhoneCall(String phoneNumber, BuildContext context) async {
    try {
      // Clean the phone number
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Try the standard tel URI
      final Uri telUri = Uri.parse('tel:$cleanNumber');

      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
        return true;
      }

      // Fallback: Try without launch mode specification
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
        return true;
      }

      // If both fail, show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to make phone call. Please check your device settings.')),
        );
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error making phone call: ${e.toString()}')),
        );
      }
      return false;
    }
  }

  // Send emergency SMS to multiple contacts
  static Future<void> sendEmergencySmsToContacts(List<String> phoneNumbers, String message, BuildContext context) async {
    int successCount = 0;
    int failCount = 0;

    for (final phoneNumber in phoneNumbers) {
      final success = await launchSms(phoneNumber, message, context);
      if (success) {
        successCount++;
      } else {
        failCount++;
      }

      // Small delay between SMS attempts to avoid overwhelming the system
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (context.mounted) {
      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Emergency SMS sent to $successCount contact${successCount > 1 ? 's' : ''}')),
        );
      }

      if (failCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send SMS to $failCount contact${failCount > 1 ? 's' : ''}')),
        );
      }
    }
  }
}