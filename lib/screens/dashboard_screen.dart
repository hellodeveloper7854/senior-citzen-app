import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sos_screen.dart';
import 'emergency_contacts_screen.dart';
import 'helpline_screen.dart';
import 'record_screen.dart';
import 'track_me_screen.dart';
import 'settings_screen.dart';
import 'welcome_screen.dart';
import 'profile_screen.dart';
import '../services/supabase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService();


  Future<void> _makeEmergencyCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '02225445353');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // overall background white
      body: Column(
        children: [
          // Header with purple background and circles
          Container(
            color: const Color(0xFF3E0FAD), // purple background
            height: 240,
            width: double.infinity,
            child: Stack(
              children: [
                // Large circle bottom left
                Positioned(
                  left: -60,
                  bottom: -40,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Smaller circle top left
                Positioned(
                  left: 20,
                  top: 20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Logout button top right
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      final supabaseService = SupabaseService();
                      await supabaseService.clearCurrentUser();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ),
               // Profile avatar with welcome text
Center(
 child: Column(
   mainAxisAlignment: MainAxisAlignment.center, // vertical center inside Center
   crossAxisAlignment: CrossAxisAlignment.center, // horizontal center
   children: [
     const SizedBox(height: 40),
     InkWell(
       onTap: () {
         Navigator.push(
           context,
           MaterialPageRoute(builder: (context) => const ProfileScreen()),
         );
       },
       child: Stack(
         children: [
           const CircleAvatar(
             radius: 45,
             backgroundImage: AssetImage('assets/Ellipse.png'),
           ),
           Positioned(
             bottom: 5,
             right: 5,
             child: Container(
               padding: const EdgeInsets.all(4),
               decoration: const BoxDecoration(
                 color: Color(0xFF3E0FAD),
                 shape: BoxShape.circle,
               ),
               child: const Icon(
                 Icons.edit,
                 size: 16,
                 color: Colors.white,
               ),
             ),
           ),
         ],
       ),
     ),
     const SizedBox(height: 20),
     const Text(
       'Welcome,User !',
       textAlign: TextAlign.center,
       style: TextStyle(
         color: Colors.white,
         fontSize: 20,
         fontWeight: FontWeight.bold,
       ),
     ),
   ],
 ),
)

              ],
            ),
          ),

          // Grid with white cards, shadow, rounded corners and icons with text below
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildCustomCard(
                    'SOS',
                    'assets/sos.png',
                    _makeEmergencyCall,
                  ),
                  _buildCustomCard(
                    'Emergency\nContacts',
                    'assets/ambulance.png',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
                      );
                    },
                  ),
                  // _buildCustomCard(
                  //   'Helpline',
                  //   'assets/helpline.png',
                  //   () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (context) => const HelplineScreen()),
                  //     );
                  //   },
                  // ),
                  // _buildCustomCard(
                  //   'Record',
                  //   'assets/microphone.png',
                  //   () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (context) => const RecordScreen()),
                  //     );
                  //   },
                  // ),
                  // _buildCustomCard(
                  //   'Track Me\n(Advanced)',
                  //   'assets/location.png',
                  //   () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (context) => const TrackMeScreen()),
                  //     );
                  //   },
                  // ),
                  // _buildCustomCard(
                  //   'Support',
                  //   'assets/contact_service.png',
                  //   () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

Widget _buildCustomCard(String title, String assetPath, VoidCallback onTap) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 6,
    shadowColor: Colors.grey.withOpacity(0.3),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              assetPath, // shows original image without tint
              width: 55,
              height: 55,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}