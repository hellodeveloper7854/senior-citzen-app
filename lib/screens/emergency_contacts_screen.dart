import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart'; // Assuming these services are available
import '../utils/crypto_util.dart'; // Assuming this utility is available
import '../utils/permission_utils.dart'; // Import PermissionUtils

// A simple structure to hold contact data for the UI
class EmergencyContact {
  final String name;
  final String relation;
  final String number;
  final IconData avatarIcon;
  final Color avatarColor;

  EmergencyContact({
    required this.name,
    required this.relation,
    required this.number,
    required this.avatarIcon,
    required this.avatarColor,
  });
}

class SelectEmergencyContactScreen extends StatefulWidget {
  const SelectEmergencyContactScreen({super.key});

  @override
  _SelectEmergencyContactScreenState createState() =>
      _SelectEmergencyContactScreenState();
}

class _SelectEmergencyContactScreenState
    extends State<SelectEmergencyContactScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  List<EmergencyContact> _contacts = [];

  // Placeholder for the message to be sent
  final String _emergencyMessage =
      "I am in an emergency. Please call or check on me immediately.";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // --- Data Loading and Decryption ---
  Future<void> _loadUserProfile() async {
    try {
      final email = await _supabaseService.getCurrentUserEmail();
      if (email != null) {
        final credentials = await _supabaseService.getUserCredentials(email);
        if (credentials != null) {
          final profile = await _supabaseService
              .getUserProfileByPhone(credentials['phone_number']);
          if (profile != null) {
            // Decrypting the contact numbers as done in the original code
            profile['emergency_contact_1_number'] =
            await CryptoUtil.decryptString(
                profile['emergency_contact_1_number']);
            profile['emergency_contact_2_number'] =
            await CryptoUtil.decryptString(
                profile['emergency_contact_2_number']);
          }

          setState(() {
            _userProfile = profile;
            _contacts = _extractContacts(profile);
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // print('Error loading profile: $e'); // For debugging
      setState(() => _isLoading = false);
    }
  }

  // --- Contact Extraction Logic (Adapted for the UI) ---
  List<EmergencyContact> _extractContacts(Map<String, dynamic>? profile) {
    if (profile == null) return [];

    List<EmergencyContact> list = [];

    // Contact 1
    final name1 = profile['emergency_contact_1_name'];
    final relation1 = profile['emergency_contact_1_relation'];
    final number1 = profile['emergency_contact_1_number'];
    if (name1 != null && name1.isNotEmpty && number1 != null) {
      list.add(EmergencyContact(
        name: name1,
        relation: relation1 ?? 'Contact',
        number: number1,
        avatarIcon: Icons.person_4, // Example icon
        avatarColor: const Color(0xFF10B981),
      ));
    }

    // Contact 2
    final name2 = profile['emergency_contact_2_name'];
    final relation2 = profile['emergency_contact_2_relation'];
    final number2 = profile['emergency_contact_2_number'];
    if (name2 != null && name2.isNotEmpty && number2 != null) {
      list.add(EmergencyContact(
        name: name2,
        relation: relation2 ?? 'Contact',
        number: number2,
        avatarIcon: Icons.person_3, // Example icon
        avatarColor: const Color(0xFF3E0FAD),
      ));
    }

    // Use the actual relations from the database, with appropriate icons and colors
    List<EmergencyContact> updatedList = [];
    for (int i = 0; i < list.length; i++) {
      final contact = list[i];
      final IconData icon;
      final Color color;

      // Assign icons and colors based on the actual relation stored in database
      switch (contact.relation.toLowerCase()) {
        case 'caretaker':
          icon = Icons.medical_services;
          color = const Color(0xFF10B981);
          break;
        case 'child':
        case 'son':
          icon = Icons.person_3;
          color = const Color(0xFF3E0FAD);
          break;
        case 'spouse':
        case 'husband':
        case 'wife':
          icon = Icons.person_4;
          color = const Color(0xFF6366F1);
          break;
        case 'sibling':
          icon = Icons.people;
          color = const Color(0xFFF59E0B);
          break;
        case 'friend':
          icon = Icons.person_outline;
          color = Colors.orange.shade400;
          break;
        case 'cousin':
          icon = Icons.family_restroom;
          color = Colors.teal.shade400;
          break;
        case 'niece/nephew':
          icon = Icons.child_care;
          color = Colors.pink.shade400;
          break;
        case 'grandchild':
          icon = Icons.child_friendly;
          color = Colors.purple.shade400;
          break;
        case 'other':
        default:
          icon = Icons.contact_phone;
          color = const Color(0xFF6B7280);
          break;
      }

      updatedList.add(EmergencyContact(
        name: contact.name,
        relation: contact.relation,
        number: contact.number,
        avatarIcon: icon,
        avatarColor: color,
      ));
    }

    return updatedList;
  }

  // --- ROBUST SMS Sending Functionality for Latest Android Devices ---
  Future<void> _sendSms(String phoneNumber) async {
    await PermissionUtils.launchSms(phoneNumber, _emergencyMessage, context);
  }

  // --- UI Widget Builders ---

  // Builds a large, green contact button matching the image
  Widget _buildContactButton(EmergencyContact contact) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Use the icon and color that were already assigned in _extractContacts based on the actual relation
    final IconData avatarIcon = contact.avatarIcon;
    final Color avatarColor = contact.avatarColor;

    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xff2fff00).withOpacity(.25), // Light green background
          borderRadius: BorderRadius.circular(screenWidth * 1.25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: screenWidth * 0.0025,
                offset: Offset(0, screenHeight * 0.004),
                spreadRadius: screenWidth * 0.005,
              ),
            ]
        ),
        child: InkWell(
          onTap: () => _sendSms(contact.number),
          borderRadius: BorderRadius.circular(screenWidth * 1.25),
          child: Container(
            height: screenHeight * 0.06,
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    contact.relation, // Use relation as the main text
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                // Avatar (Customized to mimic the image)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: avatarColor, width: screenWidth * 0.005),
                      ),
                      child: Icon(
                        avatarIcon,
                        color: avatarColor,
                        size: screenWidth * 0.06,
                      ),
                    ),
                    // WhatsApp Icon (Always present as in the image)
                    Positioned(
                      right: -screenWidth * 0.025,
                      bottom: -screenHeight * 0.006,
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.005),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.phone, // Using a standard icon placeholder
                          color: Color(0xFF25D366),
                          size: screenWidth * 0.065,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: screenWidth * 0.025),
              ],
            ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3E0FAD)),
        ),
      )
          : Column(
        children: [
          // Top Header Decoration (Mimics the blue circles) - responsive
          Stack(
            alignment: Alignment.topLeft,
            children: [
              Container(
                height: screenHeight * 0.25,
                width: double.infinity,
                color: Colors.transparent, // Background of the safe area
              ),
              Positioned(
                top: -screenHeight * 0.06,
                left: -screenWidth * 0.03,
                child: Container(
                  width: screenWidth * 0.5,
                  height: screenWidth * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xff000BAA).withOpacity(0.45),
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
                    color: Color(0xff000DFF).withOpacity(0.49),
                  ),
                ),
              ),
              // The 9:45 time and battery/signal icons (cannot be implemented here)
            ],
          ),

          // Main Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.075),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Emergency Contact',
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Your safety is our mission.\nWho do you want to SMS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.0375),

                  // Contact Buttons List
                  if (_contacts.isEmpty)
                    const Center(
                      child: Text('No emergency contacts available.'),
                    )
                  else
                    ..._contacts.map(_buildContactButton).toList(),
                ],
              ),
            ),
          ),

          // Back Button (Bottom)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.0125),
            child: SizedBox(
              height: screenHeight * 0.06,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
                child: Text(
                  '        Back        ',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
