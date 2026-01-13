import 'dart:convert';
import 'package:aadharwad/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/crypto_util.dart';
import '../utils/image_util.dart';
import './edit_profile_screen.dart';
import './complaint_status_screen.dart';
import './recording_status_screen.dart';
import './sos_alerts_screen.dart';
import './my_feedbacks_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
   final ApiService _apiService = ApiService();
   Map<String, dynamic>? _userProfile;
   bool _isLoading = true;
   int _rating = 0;
   final TextEditingController _feedbackController = TextEditingController();
   bool _isSubmittingFeedback = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      print('🔄 Loading user profile...');

      // Get the phone number directly from login session
      final phoneNumber = await _apiService.getCurrentUserPhoneNumber();
      print('📱 Current user phone: $phoneNumber');

      if (phoneNumber == null) {
        print('❌ Phone number is null - user not logged in');
        setState(() => _isLoading = false);
        return;
      }

      // Fetch profile directly using phone number
      final profile = await _apiService.getUserProfileByPhone(phoneNumber);
      print('📋 Profile data received: ${profile != null}');

      if (profile != null) {
        print('👤 Profile keys: ${profile.keys.toList()}');
        print('📛 Profile full_name: ${profile['full_name']}');

        // Try decryption but don't let failures prevent profile display
        try {
          if (profile['aadhar_number'] != null) {
            profile['aadhar_number'] = await CryptoUtil.decryptString(profile['aadhar_number']);
            print('✅ Aadhar decrypted successfully');
          }
        } catch (e) {
          print('⚠️ Error decrypting aadhar: $e');
          // Keep raw value if decryption fails
        }
        try {
          if (profile['emergency_contact_1_number'] != null) {
            profile['emergency_contact_1_number'] = await CryptoUtil.decryptString(profile['emergency_contact_1_number']);
            print('✅ Emergency contact 1 decrypted successfully');
          }
        } catch (e) {
          print('⚠️ Error decrypting emergency_contact_1: $e');
          // Keep raw value if decryption fails
        }
        try {
          if (profile['emergency_contact_2_number'] != null) {
            profile['emergency_contact_2_number'] = await CryptoUtil.decryptString(profile['emergency_contact_2_number']);
            print('✅ Emergency contact 2 decrypted successfully');
          }
        } catch (e) {
          print('⚠️ Error decrypting emergency_contact_2: $e');
          // Keep raw value if decryption fails
        }

        print('✅ Setting profile state...');
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
        print('✅ Profile state set successfully');
      } else {
        print('❌ Profile is null');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final profileImageValue = (_userProfile?['profile_img'] as String?) ?? (_userProfile?['profile_photo_url'] as String?);
    final profileImageProvider = ImageUtil.imageProviderFromString(profileImageValue);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: Stack(
        children: [
          // Circular decorations same style as main screen - responsive
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

          _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3E0FAD)),
              ),
            )
          : _userProfile == null
              ? const Center(
                  child: Text(
                    'Profile not found',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Custom Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: Color(0xFF1F2937), size: screenWidth * 0.07),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Text(
                              'My Profile',
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                if (_userProfile == null) return;
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(
                                      initialProfile: Map<String, dynamic>.from(_userProfile!),
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  await _loadUserProfile();
                                }
                              },
                              child: Text(
                                'Edit',
                                style: TextStyle(
                                  color: Color(0xFF3E0FAD),
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.025),

                        // Profile Header
                        Container(
                        padding: EdgeInsets.all(screenWidth * 0.06),
                        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(screenWidth * 0.04),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: screenWidth * 0.025,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Profile Photo
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: screenWidth * 0.125,
                                  backgroundImage: (profileImageProvider ?? const AssetImage('assets/Ellipse.png')) as ImageProvider,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(screenWidth * 0.02),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF3E0FAD),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: screenWidth * 0.04,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: screenHeight * 0.02),

                            // Name and basic info
                            Text(
                              _userProfile!['full_name'] ?? 'User',
                              style: TextStyle(
                                fontSize: screenWidth * 0.06,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.01),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: screenWidth * 0.04,
                                  color: Color(0xFF6B7280),
                                ),
                                SizedBox(width: screenWidth * 0.01),
                                Text(
                                  _userProfile!['contact_number'] ?? '',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Personal Information Section
                      _buildSectionCard(
                        title: 'Personal Information',
                        icon: Icons.person,
                        children: [
                          _buildInfoRow('Gender', _userProfile!['gender']),
                          _buildInfoRow('Marital Status', _userProfile!['marital_status']),
                          _buildInfoRow('Living Situation', _userProfile!['living_with']),
                          _buildInfoRow('Preferred Language', _userProfile!['preferred_language']),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Location Information Section
                      _buildSectionCard(
                        title: 'Location & Address',
                        icon: Icons.location_on,
                        children: [
                          _buildInfoRow('Police Station', _userProfile!['police_station']),
                          _buildInfoRow('Address', _userProfile!['address']),
                          _buildInfoRow('Pincode', _userProfile!['pincode']),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Emergency Contacts Section
                      _buildSectionCard(
                        title: 'Emergency Contacts',
                        icon: Icons.emergency,
                        children: [
                          if (_userProfile!['emergency_contact_1_name'] != null)
                            _buildContactRow(
                              name: _userProfile!['emergency_contact_1_name'],
                              relation: _userProfile!['emergency_contact_1_relation'],
                              phone: _userProfile!['emergency_contact_1_number'],
                            ),
                          if (_userProfile!['emergency_contact_2_name'] != null)
                            _buildContactRow(
                              name: _userProfile!['emergency_contact_2_name'],
                              relation: _userProfile!['emergency_contact_2_relation'],
                              phone: _userProfile!['emergency_contact_2_number'],
                            ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Medical Information Section
                      _buildSectionCard(
                        title: 'Medical Information',
                        icon: Icons.medical_services,
                        children: [
                          _buildInfoRow('Medical Conditions', (_userProfile!['medical_conditions'] as List?)?.join(', ') ?? 'None specified'),
                          _buildInfoRow('Blood Group', _userProfile!['blood_group']),
                          _buildInfoRow('Physical Disability', _userProfile!['is_physically_disabled'] == true ? 'Yes' : 'No'),
                          if (_userProfile!['is_physically_disabled'] == true && _userProfile!['disability_type'] != null)
                            _buildInfoRow('Disability Type', _userProfile!['disability_type']),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Account Management Section
                      _buildSectionCard(
                        title: 'Account Management',
                        icon: Icons.manage_accounts,
                        children: [
                          _buildActionRow(
                            'Change Password',
                            Icons.lock,
                            const Color(0xFF3E0FAD),
                            _showChangePasswordDialog,
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Feedback Section
                      _buildFeedbackSection(),

                      SizedBox(height: screenHeight * 0.02),

                      // My Activity Section
                      _buildSectionCard(
                        title: 'My Activity',
                        icon: Icons.history,
                        children: [
                          _buildActionRow(
                            'My SOS Alerts',
                            Icons.emergency,
                            const Color(0xFFEF4444),
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SOSAlertsScreen()),
                            ),
                          ),
                          _buildActionRow(
                            'My Complaints',
                            Icons.description,
                            const Color(0xFF3E0FAD),
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ComplaintStatusScreen()),
                            ),
                          ),
                          _buildActionRow(
                            'My Recordings',
                            Icons.mic,
                            const Color(0xFF10B981),
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RecordingStatusScreen()),
                            ),
                          ),
                          _buildActionRow(
                            'My Feedbacks',
                            Icons.feedback,
                            const Color(0xFFF59E0B),
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MyFeedbacksScreen()),
                            ),
                          ),
                        ],
                      ),

                     SizedBox(height: screenHeight * 0.04),

                     // Logout Button
                     Container(
                       width: double.infinity,
                       padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                       child: ElevatedButton.icon(
                         onPressed: _showLogoutDialog,
                         icon: Icon(Icons.logout, color: Colors.white, size: screenWidth * 0.05),
                         label: Text('Logout', style: TextStyle(fontSize: screenWidth * 0.04)),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFFEF4444),
                           foregroundColor: Colors.white,
                           padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(screenWidth * 0.03),
                           ),
                           elevation: 2,
                         ),
                       ),
                     ),

                     SizedBox(height: screenHeight * 0.04),
                   ],
                 ),
               ),
              ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: screenWidth * 0.025,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E0FAD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF3E0FAD),
                    size: screenWidth * 0.05,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),

          // Section content
          ...children,

          // Divider if not the last item
          if (children.isNotEmpty)
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenWidth * 0.03),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'Not provided',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required String? name,
    required String? relation,
    required String? phone,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenWidth * 0.03),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'Not provided',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: screenHeight * 0.003),
                Text(
                  relation ?? '',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: screenHeight * 0.003),
                Text(
                  phone ?? '',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => phone != null ? _makePhoneCall(phone) : null,
            icon: Icon(
              Icons.phone,
              color: Color(0xFF10B981),
              size: screenWidth * 0.06,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(String title, IconData icon, Color iconColor, VoidCallback onTap) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenWidth * 0.025),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03, horizontal: screenWidth * 0.02),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF6B7280),
                size: screenWidth * 0.04,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Change Password',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (newPasswordController.text != confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('New passwords do not match')),
                      );
                      return;
                    }

                    if (newPasswordController.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password must be at least 6 characters')),
                      );
                      return;
                    }

                    setState(() => isLoading = true);

                    try {
                      final email = await _apiService.getCurrentUserEmail();
                      if (email != null) {
                        await _apiService.updatePassword(email, newPasswordController.text);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password updated successfully')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update password: $e')),
                      );
                    } finally {
                      setState(() => isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E0FAD),
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Clear user session
                await _apiService.clearCurrentUser();

                // Navigate to welcome screen and clear navigation stack
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) =>  WelcomeScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: screenWidth * 0.025,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E0FAD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Icon(
                    Icons.feedback,
                    color: const Color(0xFF3E0FAD),
                    size: screenWidth * 0.05,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Text(
                  'Feedback & Rating',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),

          // Rating section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rate your experience',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Color(0xFFFFD700),
                        size: screenWidth * 0.08,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    );
                  }),
                ),
                SizedBox(height: screenHeight * 0.02),

                // Feedback text field
                Text(
                  'Share your feedback',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Tell us about your experience...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    contentPadding: EdgeInsets.all(screenWidth * 0.03),
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmittingFeedback ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E0FAD),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmittingFeedback
                        ? SizedBox(
                            height: screenHeight * 0.025,
                            width: screenHeight * 0.025,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Submit Feedback',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
        ],
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    setState(() {
      _isSubmittingFeedback = true;
    });

    try {
      final phoneNumber = _userProfile!['contact_number'];
      await _apiService.submitFeedback(
        userPhone: phoneNumber,
        rating: _rating,
        feedback: _feedbackController.text.trim(),
      );

      // Reset form
      setState(() {
        _rating = 0;
        _feedbackController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit feedback: $e')),
      );
    } finally {
      setState(() {
        _isSubmittingFeedback = false;
      });
    }
  }
}
