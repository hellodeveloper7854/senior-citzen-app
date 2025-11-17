import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import '../utils/permission_utils.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialProfile;
  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _imagePicker = ImagePicker();

  // controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _otherMedicalController = TextEditingController();
  final TextEditingController _emergency1NameController = TextEditingController();
  final TextEditingController _emergency1NumberController = TextEditingController();
  final TextEditingController _emergency2NameController = TextEditingController();
  final TextEditingController _emergency2NumberController = TextEditingController();

  // selections
  String? _selectedMaritalStatus;
  String? _selectedLivingWith;
  String? _selectedPoliceStation;
  String? _selectedLanguage;
  String? _selectedBloodGroup;
  String? _selectedEmergency1Relation;
  String? _selectedEmergency2Relation;
  List<String> _selectedMedicalConditions = [];
  bool _isPhysicallyDisabled = false;
  final TextEditingController _disabilityTypeController = TextEditingController();

  // image
  XFile? _pickedImage;
  String? _currentPhotoUrl;

  bool _saving = false;

  // option lists (mirrored from signup)
  final List<String> _maritalStatuses = ['Married', 'Unmarried', 'Divorced', 'Widowed'];
  final List<String> _livingWithOptions = ['Living Alone', 'Living with Children', 'Living in Old Age Home', 'Living with Relative', 'Living with Spouse'];
  final List<String> _languages = ['English', 'Hindi', 'Marathi'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _medicalConditionsList = ['Low BP', 'High BP', 'Diabetes', 'Depression', 'Heart Disease', 'Alzheimer'];
  final List<String> _relations = ['Caretaker', 'Child', 'Cousin', 'Friend', 'Grandchild', 'Niece/Nephew', 'Sibling', 'Spouse', 'Other'];
  final List<String> _policeStations = [
    'Select Police Station',
    'KALWA POLICE STATION',
    'MUMBRA POLICE STATION',
    'NAUPADA POLICE STATION',
    'RABODI POLICE STATION',
    'SHIL DAIGHAR POLICE STATION',
    'THANENAGAR POLICE STATION',
    'BHIWANDI POLICE STATION',
    'BHOIWADA POLICE STATION',
    'KONGAON POLICE STATION',
    'NARPOLI POLICE STATION',
    'NIZAMPURA POLICE STATION',
    'SHANTINAGAR POLICE STATION',
    'BAZARPETH POLICE STATION',
    'DOMBIWALI POLICE STATION',
    'KHADAKPADA POLICE STATION',
    'KOLSHEWADI POLICE STATION',
    'MAHATMA PHULE CHOUK POLICE STATION',
    'MANPADA POLICE STATION',
    'TILAKNAGAR POLICE STATION',
    'VISHNUNAGAR POLICE STATION',
    'AMBARNATH POLICE STATION',
    'BADALAPUR EAST POLICE STATION',
    'BADALAPUR WEST POLICE STATION',
    'CETRAL POLICE STATION',
    'HILLLINE POLICE STATION',
    'SHIVAJINAGAR POLICE STATION',
    'ULHASNAGAR POLICE STATION',
    'VITTHALWADI POLICE STATION',
    'CHITALSAR POLICE STATION',
    'KAPURBAWADI POLICE STATION',
    'KASARWADAWALI POLICE STATION',
    'KOPARI POLICE STATION',
    'SHRINAGAR POLICE STATION',
    'VARTAKNAGAR POLICE STATION',
    'WAGALE ESTATE POLICE STATION'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nameController.text = p['full_name'] ?? '';
    _addressController.text = p['address'] ?? '';
    _pincodeController.text = p['pincode'] ?? '';
    _selectedMaritalStatus = p['marital_status'];
    if (_selectedMaritalStatus != null && !_maritalStatuses.contains(_selectedMaritalStatus)) {
      _selectedMaritalStatus = null;
    }
    _selectedLivingWith = p['living_with'];
    if (_selectedLivingWith != null && !_livingWithOptions.contains(_selectedLivingWith)) {
      _selectedLivingWith = null;
    }
    _selectedPoliceStation = p['police_station'];
    if (_selectedPoliceStation != null && !_policeStations.contains(_selectedPoliceStation)) {
      _selectedPoliceStation = null;
    }
    _selectedLanguage = p['preferred_language'];
    if (_selectedLanguage != null && !_languages.contains(_selectedLanguage)) {
      _selectedLanguage = null;
    }
    _selectedBloodGroup = p['blood_group'];
    if (_selectedBloodGroup != null && !_bloodGroups.contains(_selectedBloodGroup)) {
      _selectedBloodGroup = null;
    }
    final mc = p['medical_conditions'];
    if (mc is List) {
      _selectedMedicalConditions = mc.map((e) => e.toString()).toList();
    } else if (mc is String && mc.isNotEmpty) {
      _selectedMedicalConditions = mc.split(',').map((e) => e.trim()).toList();
    }
    _otherMedicalController.text = p['other_medical_conditions'] ?? '';
    _currentPhotoUrl = p['profile_photo_url'];
    _emergency1NameController.text = p['emergency_contact_1_name'] ?? '';
    _emergency1NumberController.text = p['emergency_contact_1_number'] ?? '';
    _selectedEmergency1Relation = p['emergency_contact_1_relation'];
    if (_selectedEmergency1Relation != null && !_relations.contains(_selectedEmergency1Relation)) {
      _selectedEmergency1Relation = null;
    }
    _emergency2NameController.text = p['emergency_contact_2_name'] ?? '';
    _emergency2NumberController.text = p['emergency_contact_2_number'] ?? '';
    _selectedEmergency2Relation = p['emergency_contact_2_relation'];
    if (_selectedEmergency2Relation != null && !_relations.contains(_selectedEmergency2Relation)) {
      _selectedEmergency2Relation = null;
    }
    _isPhysicallyDisabled = p['is_physically_disabled'] ?? false;
    _disabilityTypeController.text = p['disability_type'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _otherMedicalController.dispose();
    _emergency1NameController.dispose();
    _emergency1NumberController.dispose();
    _emergency2NameController.dispose();
    _emergency2NumberController.dispose();
    _disabilityTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Request storage permission before accessing gallery
    final hasPermission = await PermissionUtils.requestStoragePermission(context);

    if (!hasPermission) {
      return; // Permission denied, don't show toast
    }

    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty ||
        _selectedMaritalStatus == null ||
        _selectedLivingWith == null ||
        _selectedPoliceStation == null ||
        _addressController.text.isEmpty ||
        _pincodeController.text.isEmpty ||
        _selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete required fields')));
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      String contactNumber = widget.initialProfile['contact_number'];
      String? photoUrl = _currentPhotoUrl;

      if (_pickedImage != null) {
        final file = File(_pickedImage!.path);
        photoUrl = await _supabaseService.uploadProfilePhoto(file, contactNumber);
      }

      final updates = <String, dynamic>{
        'full_name': _nameController.text,
        'marital_status': _selectedMaritalStatus,
        'living_with': _selectedLivingWith,
        'police_station': _selectedPoliceStation,
        'address': _addressController.text,
        'pincode': _pincodeController.text,
        'preferred_language': _selectedLanguage,
        'medical_conditions': _selectedMedicalConditions,
        'other_medical_conditions': _otherMedicalController.text,
        'blood_group': _selectedBloodGroup,
        'emergency_contact_1_name': _emergency1NameController.text,
        'emergency_contact_1_number': _emergency1NumberController.text,
        'emergency_contact_1_relation': _selectedEmergency1Relation,
        'emergency_contact_2_name': _emergency2NameController.text,
        'emergency_contact_2_number': _emergency2NumberController.text,
        'emergency_contact_2_relation': _selectedEmergency2Relation,
        'is_physically_disabled': _isPhysicallyDisabled,
        'disability_type': _isPhysicallyDisabled ? _disabilityTypeController.text : null,
      };

      if (photoUrl != null && photoUrl.isNotEmpty && photoUrl != _currentPhotoUrl) {
        updates['profile_photo_url'] = photoUrl;
      }

      await _supabaseService.updateUserProfile(contactNumber, updates);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: Stack(
        children: [
          // Circular decorations same style as main screen
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

          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                       
                       SizedBox(height: 100),

                      const Text(
                        'Edit Profile',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                      ),
                      SizedBox(height: 60),
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _pickedImage != null
                            ? FileImage(File(_pickedImage!.path))
                            : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                                ? NetworkImage(_currentPhotoUrl!)
                                : const AssetImage('assets/Ellipse.png')) as ImageProvider,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo, color: Color(0xFF3E0FAD)),
                        label: const Text(
                          'Change Photo',
                          style: TextStyle(color: Color(0xFF3E0FAD)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF3E0FAD), width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Full Name *', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF3E0FAD), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Marital Status *', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedMaritalStatus,
                  style: const TextStyle(fontSize: 18, color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF3E0FAD), width: 2),
                    ),
                  ),
                  items: _maritalStatuses.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 18)))).toList(),
                  onChanged: (v) => setState(() => _selectedMaritalStatus = v),
                ),
                const SizedBox(height: 16),

                const Text('Living Situation *', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedLivingWith,
                  style: const TextStyle(fontSize: 18, color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF3E0FAD), width: 2),
                    ),
                  ),
                  items: _livingWithOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 18)))).toList(),
                  onChanged: (v) => setState(() => _selectedLivingWith = v),
                ),
                const SizedBox(height: 16),

                const Text('Police Station *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPoliceStation,
                  isExpanded: true,
                  items: _policeStations.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis, maxLines: 2))).toList(),
                  onChanged: (v) => setState(() => _selectedPoliceStation = v),
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 16),

                const Text('Address *', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF3E0FAD), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Pincode *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 16),

                const Text('Preferred Language *', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  items: _languages.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _selectedLanguage = v),
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 24),

                const Text('Medical Conditions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 8),
                Column(
                  children: _medicalConditionsList.map((cond) {
                    final selected = _selectedMedicalConditions.contains(cond);
                    return CheckboxListTile(
                      title: Text(cond),
                      value: selected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true && !selected) {
                            _selectedMedicalConditions.add(cond);
                          } else if (v == false && selected) {
                            _selectedMedicalConditions.remove(cond);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                const Text('Other Medical Conditions', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _otherMedicalController,
                  maxLines: 2,
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 16),

                const Text('Blood Group', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedBloodGroup,
                  items: _bloodGroups.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _selectedBloodGroup = v),
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 16),

                const Text('Physical Disability', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Are you physically disabled?',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                          ),
                          const Spacer(),
                          Switch(
                            value: _isPhysicallyDisabled,
                            onChanged: (value) => setState(() => _isPhysicallyDisabled = value),
                            activeColor: const Color(0xFF3E0FAD),
                            activeTrackColor: const Color(0xFF3E0FAD).withOpacity(0.3),
                          ),
                        ],
                      ),
                      if (_isPhysicallyDisabled) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Type of Disability',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _disabilityTypeController,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(
                            labelText: 'Describe your disability (e.g., mobility impairment, visual impairment)',
                            labelStyle: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            hintText: 'Please provide details to help us serve you better',
                            hintStyle: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Emergency Contacts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 16),

                const Text('Emergency Contact 1 Name', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emergency1NameController,
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 16),

                const Text('Emergency Contact 1 Number', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emergency1NumberController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  maxLength: 10,
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 16),

                const Text('Emergency Contact 1 Relation', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedEmergency1Relation,
                  items: _relations.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _selectedEmergency1Relation = v),
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 16),

                const Text('Emergency Contact 2 Name', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emergency2NameController,
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 16),

                const Text('Emergency Contact 2 Number', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emergency2NumberController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  maxLength: 10,
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 16),

                const Text('Emergency Contact 2 Relation', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedEmergency2Relation,
                  items: _relations.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _selectedEmergency2Relation = v),
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _saving ? Colors.grey : Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (_saving)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}