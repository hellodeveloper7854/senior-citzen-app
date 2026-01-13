import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../services/api_service.dart';

class UnderVerificationScreen extends StatefulWidget {
  final bool showProfileIcon;
  const UnderVerificationScreen({super.key, this.showProfileIcon = true});

  @override
  State<UnderVerificationScreen> createState() => _UnderVerificationScreenState();
}

class _UnderVerificationScreenState extends State<UnderVerificationScreen> {
  final ApiService _apiService = ApiService();
  String? _policeStationNumber;
  String? _policeStationName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPoliceStationNumber();
  }

  Future<void> _loadPoliceStationNumber() async {
    try {
      // Get current user's phone number directly
      final phoneNumber = await _apiService.getCurrentUserPhoneNumber();
      if (phoneNumber != null) {
        // Get user profile to find police station
        final profile = await _apiService.getUserProfileByPhone(phoneNumber);
        if (profile != null) {
          final policeStation = profile['police_station'];

          if (policeStation != null && policeStation.toString().isNotEmpty) {
            setState(() {
              _policeStationName = policeStation.toString();
            });

            // Get police station contact number with SOS fallback
            final contactNumber = await _apiService.getPoliceStationNumberWithSOSFallback(policeStation);

            setState(() {
              _policeStationNumber = contactNumber;
              _isLoading = false;
            });
          } else {
            // No police station assigned, just show SOS number
            final sosNumber = await _apiService.getPoliceEmergencyNumber();
            setState(() {
              _policeStationNumber = sosNumber ?? '9326520525';
              _policeStationName = 'Police Emergency';
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading police station number: $e');
      // Fallback to SOS number on error
      final sosNumber = await _apiService.getPoliceEmergencyNumber();
      setState(() {
        _policeStationNumber = sosNumber ?? '9326520525';
        _policeStationName = 'Police Emergency';
        _isLoading = false;
      });
    }
  }

  Future<void> _callPoliceStation() async {
    if (_policeStationNumber == null) return;

    final Uri phoneUri = Uri(scheme: 'tel', path: _policeStationNumber!.replaceAll('-', ''));

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch dialer. Please dial $_policeStationNumber manually.'),
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
            content: Text('Error opening dialer. Please dial $_policeStationNumber manually.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: Stack(
        children: [
          // Circular decorations same style as other screens
          Positioned(
            top: -50,
            left: -10,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff000BAA).withOpacity(0.45),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff000DFF).withOpacity(0.49),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      const SizedBox(width: 48), // Balance the actions
                      const Expanded(
                        child: Text(
                          "Under Verification",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (widget.showProfileIcon)
                        IconButton(
                          icon: const Icon(Icons.account_circle, color: Colors.black),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileScreen()),
                            );
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.black),
                        onPressed: () async {
                          await _apiService.clearCurrentUser();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, size: 100, color: Colors.green),
                          const SizedBox(height: 20),
                          const Text(
                            'Thank you for enrolling!',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'You will get access to the application once it is approved by the admin.',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          // Police station contact information
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else if (_policeStationNumber != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.phone, color: Colors.blue[700], size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Contact ${_policeStationName ?? "Police"}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _policeStationNumber!,
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: _callPoliceStation,
                                        icon: const Icon(Icons.call, size: 18),
                                        label: const Text('Call'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[600],
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_policeStationName != 'Police Emergency')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'For any queries regarding your enrollment',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
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