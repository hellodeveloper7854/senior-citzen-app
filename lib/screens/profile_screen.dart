import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../utils/crypto_util.dart';
import './edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final email = await _supabaseService.getCurrentUserEmail();
      if (email != null) {
        final credentials = await _supabaseService.getUserCredentials(email);
        if (credentials != null) {
          final profile = await _supabaseService.getUserProfileByPhone(credentials['phone_number']);
          if (profile != null) {
            profile['aadhar_number'] = await CryptoUtil.decryptString(profile['aadhar_number']);
            profile['emergency_contact_1_number'] = await CryptoUtil.decryptString(profile['emergency_contact_1_number']);
            profile['emergency_contact_2_number'] = await CryptoUtil.decryptString(profile['emergency_contact_2_number']);
          }
          setState(() {
            _userProfile = profile;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text('Profile not found'))
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ListView(
                    children: [
                      // Profile Photo
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _userProfile!['profile_photo_url'] != null
                              ? NetworkImage(_userProfile!['profile_photo_url'])
                              : const AssetImage('assets/Ellipse.png') as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Profile Information
                      _buildProfileField('Full Name', _userProfile!['full_name']),
                      _buildProfileField('Gender', _userProfile!['gender']),
                      _buildProfileField('Contact Number', _userProfile!['contact_number']),
                      _buildProfileField('Marital Status', _userProfile!['marital_status']),
                      _buildProfileField('Living with', _userProfile!['living_with']),
                      _buildProfileField('Police Station', _userProfile!['police_station']),
                      _buildProfileField('Address', _userProfile!['address']),
                      _buildProfileField('Pincode', _userProfile!['pincode']),
                      _buildProfileField('Preferred Language', _userProfile!['preferred_language']),

                      // Emergency Contacts
                      const SizedBox(height: 20),
                      const Text('Emergency Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      _buildProfileField('Contact 1', _userProfile!['emergency_contact_1_name'] != null && _userProfile!['emergency_contact_1_relation'] != null ? '${_userProfile!['emergency_contact_1_name']} - ${_userProfile!['emergency_contact_1_relation']}' : ''),
                      _buildProfileField('Contact 1 Number', _userProfile!['emergency_contact_1_number']),
                      _buildProfileField('Contact 2', _userProfile!['emergency_contact_2_name'] != null && _userProfile!['emergency_contact_2_relation'] != null ? '${_userProfile!['emergency_contact_2_name']} - ${_userProfile!['emergency_contact_2_relation']}' : ''),
                      _buildProfileField('Contact 2 Number', _userProfile!['emergency_contact_2_number']),

                      // Medical Information
                      const SizedBox(height: 20),
                      const Text('Medical Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      _buildProfileField('Medical Conditions', (_userProfile!['medical_conditions'] as List?)?.join(', ') ?? 'None'),
                      _buildProfileField('Blood Group', _userProfile!['blood_group']),

                      const SizedBox(height: 30),
                      ElevatedButton(
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
                        child: const Text('Edit Profile'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'Not provided',
            style: const TextStyle(fontSize: 16),
          ),
          const Divider(),
        ],
      ),
    );
  }
}