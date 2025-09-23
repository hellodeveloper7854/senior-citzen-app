import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import '../utils/crypto_util.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  _EmergencyContactsScreenState createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _addNewContact() async {
    final nameController = TextEditingController();
    String? selectedRelation;
    final phoneController = TextEditingController();
    final relations = ['Caretaker', 'Child', 'Cousin', 'Friend', 'Grandchild', 'Niece/Nephew', 'Sibling', 'Spouse', 'Other'];

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            DropdownButtonFormField<String>(
              value: selectedRelation,
              items: relations.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => selectedRelation = v,
              decoration: const InputDecoration(labelText: 'Relation'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && selectedRelation != null && phoneController.text.isNotEmpty) {
                final updates = {
                  'emergency_contact_2_name': nameController.text,
                  'emergency_contact_2_relation': selectedRelation,
                  'emergency_contact_2_number': phoneController.text,
                };
                try {
                  await _supabaseService.updateUserProfile(_userProfile!['contact_number'], updates);
                  await _loadUserProfile();
                  Navigator.of(ctx).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top circle decoration
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 150,
                            color: Colors.white,
                          ),
                          Positioned(
                            top: -60,
                            left: -60,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3B5998), // Deep blue color similar to image
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Title and subtitle
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                        child: Column(
                          children: [
                            Text(
                              'Emergency Contact',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your safety is our mission.\nWho do you want to SMS.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Contact buttons list/content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                children: [
                                  if (_userProfile != null) ...[
                                    if (_userProfile!['emergency_contact_1_name'] != null && _userProfile!['emergency_contact_1_name'].isNotEmpty) ...[
                                      _EmergencyContactButton(
                                        name: _userProfile!['emergency_contact_1_name'] ?? '',
                                        relation: _userProfile!['emergency_contact_1_relation'] ?? '',
                                        phoneNumber: _userProfile!['emergency_contact_1_number'] ?? '',
                                        onCallPressed: () => _makePhoneCall(_userProfile!['emergency_contact_1_number'] ?? ''),
                                      ),
                                      const SizedBox(height: 15),
                                    ],
                                    if (_userProfile!['emergency_contact_2_name'] != null && _userProfile!['emergency_contact_2_name'].isNotEmpty) ...[
                                      _EmergencyContactButton(
                                        name: _userProfile!['emergency_contact_2_name'] ?? '',
                                        relation: _userProfile!['emergency_contact_2_relation'] ?? '',
                                        phoneNumber: _userProfile!['emergency_contact_2_number'] ?? '',
                                        onCallPressed: () => _makePhoneCall(_userProfile!['emergency_contact_2_number'] ?? ''),
                                      ),
                                      const SizedBox(height: 15),
                                    ] else ...[
                                      // Add new contact button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: _addNewContact,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF12B54C),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: const Text(
                                            'Add New Contact',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                    ],
                                  ] else ...[
                                    const Center(
                                      child: Text(
                                        'No emergency contacts found.\nPlease complete your profile.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 16, color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),

                      const Spacer(),

                      // Back button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            child: const Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmergencyContactButton extends StatelessWidget {
  final String name;
  final String relation;
  final String phoneNumber;
  final VoidCallback onCallPressed;

  const _EmergencyContactButton({
    required this.name,
    required this.relation,
    required this.phoneNumber,
    required this.onCallPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCallPressed,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFFBDF3AE), // Light green background
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // Contact info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      relation,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Phone icon
              Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  color: Color(0xFF12B54C), // Green color
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}