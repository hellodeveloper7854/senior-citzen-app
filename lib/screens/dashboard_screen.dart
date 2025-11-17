import 'package:aadharwad/screens/register_complaint_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// Import the screens that are used in the dashboard
import 'sos_screen.dart';
import 'emergency_contacts_screen.dart';
import 'helpline_screen.dart';
import 'record_screen.dart';
import 'track_me_screen.dart';
import 'profile_screen.dart';
import '../services/supabase_service.dart';

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
  final SupabaseService _supabaseService = SupabaseService();
  String _fullName = 'User'; // Default name
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadFullName();
  }

  // --- Data Loading Logic ---
  Future<void> _loadFullName() async {
    try {
      final email = await _supabaseService.getCurrentUserEmail();
      if (email != null) {
        final credentials = await _supabaseService.getUserCredentials(email);
        if (credentials != null) {
          final profile = await _supabaseService.getUserProfileByPhone(credentials['phone_number']);
          if (mounted) {
            setState(() {
              // Extract and capitalize the full name for the welcome message
              final name = (profile?['full_name'] as String?)?.trim();
              if (name != null && name.isNotEmpty) {
                // Simple capitalization (assumes two words for the look in the image)
                _fullName = name.split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ');
              }

              final url = profile?['profile_photo_url'] as String?;
              _profilePhotoUrl = (url != null && url.trim().isNotEmpty) ? url.trim() : null;
            });
          }
        }
      }
    } catch (_) {
      // Silently ignore fetch errors
    }
  }

  // --- Pull to Refresh Functionality ---
  Future<void> _onRefresh() async {
    await _loadFullName();
    // Add a small delay to show the refresh indicator
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // --- SOS Functionality (Mimics the original code's _makeEmergencyCall) ---
  Future<void> _makeEmergencyCall() async {
    // This is the action for the large red SOS button on the dashboard
    // It should navigate to a dedicated SOS screen or perform an instant action (like a distress message or call)
    // Based on the image, the SOS button is a grid item, which usually navigates.

    // For the "SOS" button functionality, let's navigate to the SOS screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SosScreen()),
    );

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF3E0FAD),
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // 1. Purple Header Section (Matches the image)
            Container(
              padding: EdgeInsets.only(top: screenHeight * 0, bottom: screenHeight * 0),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF340298), // Dominant purple color
              ),
              child: Column(
                children: [
                  // Top bar: Time, Logo/Title, Settings Icon
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Placeholder for the custom logo/title from the image
                        Container(
                          width: screenWidth * 0.5,
                          height: screenHeight * 0.25,
                          child : Stack(
                          children:[
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

                          ]
                        )

                                              ),

                        // Profile Icon (Tappable)
                        IconButton(
                          icon: Icon(Icons.person, color: Colors.white, size: screenWidth * 0.07),
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
                  ),

                  // SizedBox(height: screenHeight * 0.02),

                  // Profile Picture (Circular)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: screenWidth * 0.01,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: screenWidth * 0.1,
                      // Note: Since we don't have the exact image, we'll use a placeholder
                      backgroundImage: _profilePhotoUrl != null
                          ? NetworkImage(_profilePhotoUrl!)
                          : const AssetImage('assets/elderly_woman.png') as ImageProvider, // Placeholder asset
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  // Welcome Text
                  Text(
                    'Welcome,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    welcomeName, // Display the loaded name
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
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
                            MaterialPageRoute(builder: (context) => const TrackMeScreen()),
                          );
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
    );
  }
}
