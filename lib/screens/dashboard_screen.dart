import 'dart:convert';
import 'package:aadharwad/screens/register_complaint_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// Import the screens that are used in the dashboard
import 'sos_screen.dart';
import 'sos_alerts_screen.dart';
import 'emergency_contacts_screen.dart';
import 'helpline_screen.dart';
import 'record_screen.dart';
import 'track_me_screen2.dart' as track_screen;
import 'profile_screen.dart';
import '../services/api_service.dart';
import '../utils/image_util.dart';

// Assuming you have a separate screen for support, let's include it
// import 'support_screen.dart';

// NOTE: Since the prompt is about the dashboard, I'll use placeholders for
// the unprovided screen imports (SOS, Helpline, Record, TrackMe, Support).

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  String _fullName = 'User'; // Default name
  String? _profilePhotoUrl;

  // Back press detection for exit confirmation
  bool _isShowingExitDialog = false;

  // SOS Alert status
  bool _hasActiveSOS = false;
  bool _isLoadingSOSStatus = true;

  // Active Tracking status
  bool _hasActiveTracking = false;
  bool _isLoadingTrackingStatus = true;

  // Notification counts
  int _unreadNotificationCount = 0;
  bool _isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadFullName();
    _checkActiveSOS();
    _checkActiveTracking();
    _loadUnreadNotifications();
  }

  // --- Data Loading Logic ---
  Future<void> _loadFullName() async {
    try {
      final phoneNumber = await _apiService.getCurrentUserPhoneNumber();
      if (phoneNumber != null) {
        final profile = await _apiService.getUserProfileByPhone(phoneNumber);
        if (mounted) {
          setState(() {
            // Extract and capitalize the full name for the welcome message
            final name = (profile?['full_name'] as String?)?.trim();
            if (name != null && name.isNotEmpty) {
              // Simple capitalization (assumes two words for the look in the image)
              _fullName = name.split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ');
            }

            final url = profile?['profile_img'] as String?;
            _profilePhotoUrl = (url != null && url.trim().isNotEmpty) ? url.trim() : null;
          });
        }
      }
    } catch (_) {
      // Silently ignore fetch errors
    }
  }

  // --- Pull to Refresh Functionality ---
  Future<void> _onRefresh() async {
    await _loadFullName();
    await _checkActiveSOS();
    await _checkActiveTracking();
    await _loadUnreadNotifications();
    // Add a small delay to show the refresh indicator
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // --- Check for Active SOS Alert ---
  Future<void> _checkActiveSOS() async {
    try {
      final phoneNumber = await _apiService.getCurrentUserPhoneNumber();
      if (phoneNumber != null) {
        final alerts = await _apiService.getUserSOSAlerts(phoneNumber);

        // Check if there's any active SOS alert within 15 minutes
        final now = DateTime.now();
        const duration = Duration(minutes: 15);
        bool hasActiveAlert = false;

        for (var alert in alerts) {
          if (alert['status'] == 'active' && alert['alert_timestamp'] != null) {
            try {
              final alertTime = DateTime.parse(alert['alert_timestamp']);
              final timeDifference = now.difference(alertTime);

              // If alert is within 15 minutes, consider it active
              if (timeDifference <= duration) {
                hasActiveAlert = true;
                break;
              } else {
                // Alert is older than 15 minutes, auto-expire it
                await _apiService.updateSOSAlertStatus(
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

        if (mounted) {
          setState(() {
            _hasActiveSOS = hasActiveAlert;
            _isLoadingSOSStatus = false;
          });
        }
      }
    } catch (e) {
      // Silently ignore errors, just mark as not loading
      if (mounted) {
        setState(() {
          _isLoadingSOSStatus = false;
        });
      }
    }
  }

  // --- Check for Active Tracking Session ---
  Future<void> _checkActiveTracking() async {
    try {
      final phoneNumber = await _apiService.getCurrentUserPhoneNumber();
      if (phoneNumber != null) {
        final activeSession = await _apiService.getActiveTrackingSession(phoneNumber);

        if (mounted) {
          setState(() {
            _hasActiveTracking = activeSession != null;
            _isLoadingTrackingStatus = false;
          });
        }
      }
    } catch (e) {
      // Silently ignore errors, just mark as not loading
      if (mounted) {
        setState(() {
          _isLoadingTrackingStatus = false;
        });
      }
    }
  }

  // --- Load Unread Notifications Count ---
  Future<void> _loadUnreadNotifications() async {
    try {
      final phoneNumber = await _apiService.getCurrentUserPhoneNumber();
      if (phoneNumber == null) return;

      int unreadCount = 0;

      // 1. Count complaints with status updates (not 'pending')
      final complaints = await _apiService.getUserComplaints(phoneNumber);
      for (var complaint in complaints) {
        // Count complaints that have been viewed or have status updates
        if (complaint['status'] != null &&
            complaint['status'] != 'pending' &&
            (complaint['is_viewed'] == null || complaint['is_viewed'] == false)) {
          unreadCount++;
        }
      }

      // 2. Count SOS alerts with responses (resolved or with notes)
      final sosAlerts = await _apiService.getUserSOSAlerts(phoneNumber);
      for (var alert in sosAlerts) {
        // Count alerts that have been resolved or have notes
        if ((alert['status'] == 'resolved' || alert['status'] == 'Request terminate' ||
             alert['status'] == 'expired') &&
            (alert['is_viewed'] == null || alert['is_viewed'] == false)) {
          unreadCount++;
        }
      }

      // 3. Count recordings with responses (if there's a recordings table)
      // For now, we'll focus on complaints and SOS alerts

      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadCount;
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    }
  }

  // --- SOS Functionality (Mimics the original code's _makeEmergencyCall) ---
  Future<void> _makeEmergencyCall() async {
    // Always navigate to SOS screen
    // If there's an active SOS, it will show "Request sent to Police" message
    // If there's no active SOS, it will create a new SOS alert
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SosScreen()),
    ).then((_) {
      // Refresh SOS status when returning from SOS screen
      _checkActiveSOS();
    });

    // If you prefer the original code's instant call action, use this instead:
    /*
    final Uri phoneUri = Uri(scheme: 'tel', path: '02225445353'); // Example number
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer')),
      );
    }
    */
  }

  // --- Show Notifications Bottom Sheet ---
  Future<void> _showNotificationsBottomSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF340298),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Notifications List
              Expanded(
                child: FutureBuilder(
                  future: _fetchNotifications(),
                  builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No notifications',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final notifications = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationItem(notification);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      // Refresh notification count when closing bottom sheet
      _loadUnreadNotifications();
    });
  }

  // Fetch notifications from database
  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    try {
      final phoneNumber = await _apiService.getCurrentUserPhoneNumber();
      if (phoneNumber == null) return [];

      List<Map<String, dynamic>> allNotifications = [];

      // Get complaints with status updates
      final complaints = await _apiService.getUserComplaints(phoneNumber);
      for (var complaint in complaints) {
        if (complaint['status'] != null && complaint['status'] != 'pending') {
          allNotifications.add({
            'type': 'complaint',
            'id': complaint['id'],
            'title': 'Complaint Update',
            'message': 'Your complaint status is: ${complaint['status']}',
            'timestamp': complaint['submitted_at'],
            'status': complaint['status'],
            'is_viewed': complaint['is_viewed'] ?? false,
          });
        }
      }

      // Get SOS alerts with responses
      final sosAlerts = await _apiService.getUserSOSAlerts(phoneNumber);
      for (var alert in sosAlerts) {
        if (alert['status'] != 'active') {
          allNotifications.add({
            'type': 'sos',
            'id': alert['id'],
            'title': 'SOS Alert ${alert['status']?.toString().toUpperCase() ?? ''}',
            'message': alert['notes'] ?? 'Your SOS alert has been ${alert['status']}',
            'timestamp': alert['alert_timestamp'],
            'status': alert['status'],
            'is_viewed': alert['is_viewed'] ?? false,
          });
        }
      }

      // Sort by timestamp descending
      allNotifications.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp']);
        final bTime = DateTime.parse(b['timestamp']);
        return bTime.compareTo(aTime);
      });

      return allNotifications;
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Build notification item widget
  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    IconData icon;
    Color iconColor;

    switch (notification['type']) {
      case 'complaint':
        icon = Icons.report_problem;
        iconColor = Colors.orange;
        break;
      case 'sos':
        icon = Icons.emergency;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification['is_viewed'] ? Colors.grey.shade100 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification['is_viewed'] ? Colors.grey.shade300 : Colors.blue.shade200,
          width: notification['is_viewed'] ? 1 : 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: notification['is_viewed'] ? Colors.grey.shade700 : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification['message'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(notification['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (!notification['is_viewed'])
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  // Format timestamp
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  // --- UI Widget Builder for Grid Items ---
  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required String image,
    String? subtitle,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    // Enhanced card with better shadows and animations
    return Card(
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        splashColor: iconColor.withOpacity(0.2),
        highlightColor: iconColor.withOpacity(0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.all(screenWidth * 0.025),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(screenWidth * 0.1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon/Image with animation
              AnimatedScale(
                scale: 1.0,
                duration: const Duration(milliseconds: 200),
                child: Image.asset(
                  image,
                  width: screenWidth * 0.2,
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              // Title with better styling
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              // Subtitle (for Track Me)
              if (subtitle != null)
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Determine the user's name to display
    final String welcomeName = _fullName.split(' ').length > 1
        ? _fullName.split(' ').sublist(0, 2).join(' ') // Use first two words
        : _fullName;

    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFF3E0FAD),
          backgroundColor: Colors.white,
          child: Column(
          children: [
            // 1. Purple Header Section (Compact size)
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 8,
              ),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF340298), // Dominant purple color
              ),
              child: Column(
                children: [
                  // Top bar with Profile Icon and Notification Bell
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo placeholder
                        Image.asset(
                          'assets/Senior Citizen.png',
                          width: screenWidth * 0.15,
                          height: screenWidth * 0.15,
                          fit: BoxFit.contain,
                        ),

                        // Right side icons
                        Row(
                          children: [
                            // Notification Bell with Badge - COMMENTED OUT
                            // Stack(
                            //   children: [
                            //     IconButton(
                            //       icon: Icon(
                            //         Icons.notifications,
                            //         color: Colors.white,
                            //         size: screenWidth * 0.06,
                            //       ),
                            //       onPressed: () {
                            //         // Navigate to notifications screen
                            //         _showNotificationsBottomSheet();
                            //       },
                            //     ),
                            //     // Badge for unread count
                            //     if (_unreadNotificationCount > 0)
                            //       Positioned(
                            //         right: 0,
                            //         top: 0,
                            //         child: Container(
                            //           padding: const EdgeInsets.all(4),
                            //           decoration: BoxDecoration(
                            //             color: Colors.red,
                            //             shape: BoxShape.circle,
                            //             border: Border.all(
                            //               color: const Color(0xFF340298),
                            //               width: 2,
                            //             ),
                            //           ),
                            //           constraints: const BoxConstraints(
                            //             minWidth: 18,
                            //             minHeight: 18,
                            //           ),
                            //           child: Text(
                            //             _unreadNotificationCount > 99
                            //                 ? '99+'
                            //                 : '$_unreadNotificationCount',
                            //             style: const TextStyle(
                            //               color: Colors.white,
                            //               fontSize: 10,
                            //               fontWeight: FontWeight.bold,
                            //             ),
                            //             textAlign: TextAlign.center,
                            //           ),
                            //         ),
                            //       ),
                            //   ],
                            // ),

                            // const SizedBox(width: 8),

                            // Profile Icon (Tappable)
                            IconButton(
                              icon: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: screenWidth * 0.06,
                              ),
                              onPressed: () {
                                // Navigate to Profile/Settings
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Profile Picture (Circular) - Smaller
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: screenWidth * 0.08,
                      backgroundImage: ImageUtil.imageProviderFromString(_profilePhotoUrl) ??
                          const AssetImage('assets/elderly_woman.png'),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Welcome Text - Compact
                  Text(
                    'Welcome,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    welcomeName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // SOS Active Alert Banner (if there's an active SOS)
            if (_hasActiveSOS)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade400.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.emergency,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SOS Alert Active',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Help is on the way',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Pulsing indicator
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Active Tracking Alert Banner (if there's an active tracking session)
            if (_hasActiveTracking)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade400.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tracking Active',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Your location is being tracked',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Pulsing indicator
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 2. Main Content Grid (Matches the image)
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: screenWidth * 0.04,
                    mainAxisSpacing: screenWidth * 0.04,
                    padding: EdgeInsets.zero, // Remove default grid padding
                    children: [
                      // 1. SOS (Red Background) - Enhanced with better shadows and animations
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFEF4444), // Red
                              Color(0xFFDC2626), // Darker red
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.6),
                              blurRadius: screenWidth * 0.03,
                              offset: const Offset(0, 6),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: screenWidth * 0.02,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _makeEmergencyCall,
                            borderRadius: BorderRadius.circular(screenWidth * 0.05),
                            splashColor: Colors.white.withOpacity(0.3),
                            highlightColor: Colors.white.withOpacity(0.1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Animated SOS icon
                                  AnimatedScale(
                                    scale: 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Image.asset(
                                      "assets/sos.png",
                                      width: screenWidth * 0.35,
                                    ),
                                  ),
                                  Text(
                                    "SOS",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: const Offset(1, 1),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 2. Emergency Contacts
                      _buildActionCard(
                        title: 'Emergency\nContacts',
                        icon: Icons.contact_phone, // Icon approximation
                        iconColor: const Color(0xFF3E0FAD), // Purple/blue
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SelectEmergencyContactScreen()),
                          );
                        },
                        image: 'assets/ambulance.png',
                      ),
                      // 3. Helpline
                      _buildActionCard(
                        title: 'Helpline',
                        icon: Icons.headset_mic, // Icon approximation
                        iconColor: const Color(0xFF3E0FAD),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HelplineScreen()),
                          );
                        },
                        image: "assets/helpline.png"
                      ),

                      // 4. Record
                      _buildActionCard(
                        title: 'Record',
                        icon: Icons.mic, // Icon approximation
                        iconColor: const Color(0xFF3E0FAD),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RecordScreen()),
                          );
                        },
                        image: "assets/microphone.png"
                      ),

                      // 5. Track Me (Advanced)
                      _buildActionCard(
                        title: 'Track Me',
                        subtitle: '(Advanced)',
                        icon: Icons.location_on, // Icon approximation
                        iconColor: const Color(0xFF3E0FAD),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const track_screen.TrackMeScreen()),
                          ).then((_) {
                            // Refresh tracking status when returning from track me screen
                            _checkActiveTracking();
                          });
                        },
                        image: "assets/location.png"
                      ),

                      // 6. Support
                      _buildActionCard(
                        title: 'Support',
                        icon: Icons.support_agent, // Icon approximation
                        iconColor: const Color(0xFF3E0FAD),
                        onTap: () {
                          // Assuming a support screen exists
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterComplaintScreen()),
                          );
                        },
                        image: "assets/contact_service.png"
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  // Handle back button press with confirmation dialog
  Future<bool> _handleWillPop() async {
    // Prevent multiple dialogs
    if (_isShowingExitDialog) {
      return false;
    }

    _isShowingExitDialog = true;

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.exit_to_app,
                color: Colors.red[600],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Exit App',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to exit the app?',
            style: TextStyle(fontSize: 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _isShowingExitDialog = false;
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _isShowingExitDialog = false;
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
                'Exit',
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

    return shouldExit ?? false;
  }
}
