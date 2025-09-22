import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import 'under_verification_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  // Controllers for all fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  String? _selectedGender;
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  String? _selectedMaritalStatus;
  String? _selectedLivingWith;
  String? _selectedPoliceStation;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  String? _selectedLanguage;
  final TextEditingController _emergency1NameController = TextEditingController();
  String? _selectedEmergency1Relation;
  final TextEditingController _emergency1NumberController = TextEditingController();
  final TextEditingController _emergency2NameController = TextEditingController();
  String? _selectedEmergency2Relation;
  final TextEditingController _emergency2NumberController = TextEditingController();
  List<String> _selectedMedicalConditions = [];
  final TextEditingController _otherMedicalController = TextEditingController();
  String? _selectedBloodGroup;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final SupabaseService _supabaseService = SupabaseService();

  // Optional profile image
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _pickedImage;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _maritalStatuses = ['Married', 'Unmarried', 'Divorced', 'Widowed'];
  final List<String> _livingWithOptions = ['Living Alone', 'Living with Children', 'Living in Old Age Home', 'Living with Relative', 'Living with Spouse'];
  final List<String> _languages = ['English', 'Hindi', 'Marathi'];
  final List<String> _relations = ['Caretaker', 'Child', 'Cousin', 'Friend', 'Grandchild', 'Niece/Nephew', 'Sibling', 'Spouse', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _medicalConditionsList = ['Low BP', 'High BP', 'Diabetes', 'Depression', 'Heart Disease', 'Alzheimer'];
  final List<String> _policeStations = [
    'Select Police Station',
    'KALWA POLICE STATION',
    'test police station',
    'MUMBRA POLICE STATION',
    'NAUPADA POLICE STATION',
    'RABODI POLICE STATION',
    'SHILDOIGHAR POLICE STATION',
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
  int _currentStep = 0;

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _nextStep() {
    String? error;
    switch (_currentStep) {
      case 0: // Personal
        if (_fullNameController.text.isEmpty ||
            _dateOfBirthController.text.isEmpty ||
            _selectedGender == null ||
            _aadharController.text.isEmpty ||
            _contactNumberController.text.isEmpty) {
          error = 'Please complete personal information';
        }
        break;
      case 1: // Emergency
        if (_emergency1NameController.text.isEmpty ||
            _selectedEmergency1Relation == null ||
            _emergency1NumberController.text.isEmpty) {
          error = 'Please provide at least one emergency contact';
        }
        break;
      case 2: // Medical - no required fields
        break;
      case 3: // Additional
        if (_selectedMaritalStatus == null ||
            _selectedLivingWith == null ||
            _selectedPoliceStation == null ||
            _addressController.text.isEmpty ||
            _pincodeController.text.isEmpty ||
            _selectedLanguage == null) {
          error = 'Please complete additional information';
        }
        break;
      default:
        break;
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal Information',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 20),
            
            const Text('Full Name *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: _fullNameController,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Enter your full name',
                labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text('Date of Birth *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: _dateOfBirthController,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                labelText: 'YYYY-MM-DD',
                labelStyle: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                helperText: 'Example: 1955-12-25',
                helperStyle: const TextStyle(fontSize: 16, color: Color(0xFF059669)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: const Icon(Icons.calendar_today, size: 28),
                    onPressed: () => _selectDate(context),
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [_DobInputFormatter()],
              readOnly: false,
            ),
            const SizedBox(height: 20),
            
            const Text('Gender *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              style: const TextStyle(fontSize: 18, color: Color(0xFF111827)),
              decoration: const InputDecoration(
                labelText: 'Select your gender',
                labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              items: _genders.map((gender) => DropdownMenuItem(
                value: gender,
                child: Text(gender, style: const TextStyle(fontSize: 18))
              )).toList(),
              onChanged: (value) => setState(() => _selectedGender = value),
            ),
            const SizedBox(height: 20),
            
            const Text('Aadhar Number *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: _aadharController,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Enter 12-digit Aadhar number',
                labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            
            const Text('Contact Number *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: _contactNumberController,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Enter 10-digit mobile number',
                labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),

            const Text('Profile Photo (optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),

            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: _pickedImage != null
                      ? FileImage(File(_pickedImage!.path))
                      : const AssetImage('assets/Ellipse.png') as ImageProvider,
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo),
                  label: const Text('Choose from Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3E0FAD),
                    side: const BorderSide(color: Color(0xFF3E0FAD), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Emergency Contacts',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0EA5E9), width: 1),
              ),
              child: const Text(
                'Please provide at least one emergency contact. This person will be notified in case of emergency.',
                style: TextStyle(fontSize: 16, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(20),
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
                  const Text('Emergency Contact 1 (Required)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  const SizedBox(height: 16),
                  
                  const Text('Full Name *',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emergency1NameController,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'Enter contact\'s full name',
                      labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Relationship *',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedEmergency1Relation,
                    style: const TextStyle(fontSize: 18, color: Color(0xFF111827)),
                    decoration: const InputDecoration(
                      labelText: 'Select relationship',
                      labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                    items: _relations.map((rel) => DropdownMenuItem(
                      value: rel,
                      child: Text(rel, style: const TextStyle(fontSize: 18))
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedEmergency1Relation = value),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Phone Number *',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emergency1NumberController,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'Enter 10-digit mobile number',
                      labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(20),
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
                  const Text('Emergency Contact 2 (Optional)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
                  const SizedBox(height: 16),
                  
                  const Text('Full Name',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emergency2NameController,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'Enter contact\'s full name (optional)',
                      labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Relationship',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedEmergency2Relation,
                    style: const TextStyle(fontSize: 18, color: Color(0xFF111827)),
                    decoration: const InputDecoration(
                      labelText: 'Select relationship (optional)',
                      labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                    items: _relations.map((rel) => DropdownMenuItem(
                      value: rel,
                      child: Text(rel, style: const TextStyle(fontSize: 18))
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedEmergency2Relation = value),
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Phone Number',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emergency2NumberController,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'Enter 10-digit mobile number (optional)',
                      labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Medical Information',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981), width: 1),
              ),
              child: const Text(
                'This information helps us provide better care in case of emergency. All fields are optional.',
                style: TextStyle(fontSize: 16, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text('Medical Conditions (Select if applicable)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
            const SizedBox(height: 12),
            
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
                children: _medicalConditionsList.map((condition) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    title: Text(condition, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    value: _selectedMedicalConditions.contains(condition),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedMedicalConditions.add(condition);
                        } else {
                          _selectedMedicalConditions.remove(condition);
                        }
                      });
                    },
                    activeColor: const Color(0xFF10B981),
                    checkColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text('Other Medical Conditions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: _otherMedicalController,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Specify any other conditions (optional)',
                labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            
            const Text('Blood Group',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedBloodGroup,
              style: const TextStyle(fontSize: 18, color: Color(0xFF111827)),
              decoration: const InputDecoration(
                labelText: 'Select your blood group (optional)',
                labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              items: _bloodGroups.map((bg) => DropdownMenuItem(
                value: bg,
                child: Text(bg, style: const TextStyle(fontSize: 18))
              )).toList(),
              onChanged: (value) => setState(() => _selectedBloodGroup = value),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Additional Information',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 20),
            
            const Text('Marital Status *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedMaritalStatus,
              style: const TextStyle(fontSize: 18, color: Color(0xFF111827)),
              decoration: const InputDecoration(
                labelText: 'Select your marital status',
                labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              items: _maritalStatuses.map((status) => DropdownMenuItem(
                value: status,
                child: Text(status, style: const TextStyle(fontSize: 18))
              )).toList(),
              onChanged: (value) => setState(() => _selectedMaritalStatus = value),
            ),
            const SizedBox(height: 20),
            
            const Text('Living Situation *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLivingWith,
              style: const TextStyle(fontSize: 18, color: Color(0xFF111827)),
              decoration: const InputDecoration(
                labelText: 'Select your living situation',
                labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              items: _livingWithOptions.map((option) => DropdownMenuItem(
                value: option,
                child: Text(option, style: const TextStyle(fontSize: 18))
              )).toList(),
              onChanged: (value) => setState(() => _selectedLivingWith = value),
            ),
            const SizedBox(height: 20),
            
            const Text('Police Station *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPoliceStation,
              isExpanded: true,
              style: const TextStyle(fontSize: 18, color: Color(0xFF111827)),
              decoration: const InputDecoration(
                labelText: 'Select nearest police station',
                labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              items: _policeStations.map((station) => DropdownMenuItem(
                value: station,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: double.infinity),
                  child: Text(
                    station,
                    style: const TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              )).toList(),
              onChanged: (value) => setState(() => _selectedPoliceStation = value),
            ),
            const SizedBox(height: 20),
            
            const Text('Full Address *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Enter your complete address',
                labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            
            const Text('Pincode *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: _pincodeController,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Enter 6-digit pincode',
                labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            
            const Text('Preferred Language *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              style: const TextStyle(fontSize: 18, color: Color(0xFF111827)),
              decoration: const InputDecoration(
                labelText: 'Select your preferred language',
                labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              items: _languages.map((lang) => DropdownMenuItem(
                value: lang,
                child: Text(lang, style: const TextStyle(fontSize: 18))
              )).toList(),
              onChanged: (value) => setState(() => _selectedLanguage = value),
            ),
          ],
        );
      case 4:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Information',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0EA5E9), width: 1),
              ),
              child: const Text(
                'Create your login credentials. Make sure to remember your email and password.',
                style: TextStyle(fontSize: 16, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text('Email Address *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Enter your email address',
                labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                helperText: 'Example: yourname@email.com',
                helperStyle: TextStyle(fontSize: 16, color: Color(0xFF059669)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            
            const Text('Password *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Create a strong password',
                labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                helperText: 'At least 6 characters',
                helperStyle: TextStyle(fontSize: 16, color: Color(0xFF059669)),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            
            const Text('Confirm Password *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Enter password again',
                labelStyle: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                helperText: 'Must match the password above',
                helperStyle: TextStyle(fontSize: 16, color: Color(0xFF059669)),
              ),
              obscureText: true,
            ),
          ],
        );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime minDate = DateTime(now.year - 65, now.month, now.day); // Must be at least 65 years old

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: DateTime(1900),
      lastDate: minDate, // Cannot select future dates, max is 65 years ago
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<bool> _showConsentDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            bool agreed = false;
            return StatefulBuilder(
              builder: (context, setSBState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text(
                    'Consent Agreement',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF0EA5E9), width: 1),
                        ),
                        child: const Text(
                          'I confirm that all information provided is genuine and accurate. I understand this information will be used for safety purposes and agree to be part of the SnehaBand community.',
                          style: TextStyle(fontSize: 16, color: Color(0xFF0F172A), height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: CheckboxListTile(
                          value: agreed,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onChanged: (v) => setSBState(() => agreed = v ?? false),
                          title: const Text(
                            'I agree to the terms above',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: const Color(0xFF3E0FAD),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFF6B7280), width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: agreed ? () => Navigator.of(context).pop(true) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: agreed ? const Color(0xFF3E0FAD) : const Color(0xFFD1D5DB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: agreed ? 3 : 0,
                      ),
                      child: const Text(
                        'I Agree',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;
  }

  Future<void> _submitForm() async {
    // Validate required fields
    if (_fullNameController.text.isEmpty ||
        _dateOfBirthController.text.isEmpty ||
        _selectedGender == null ||
        _aadharController.text.isEmpty ||
        _contactNumberController.text.isEmpty ||
        _selectedMaritalStatus == null ||
        _selectedLivingWith == null ||
        _selectedPoliceStation == null ||
        _addressController.text.isEmpty ||
        _pincodeController.text.isEmpty ||
        _selectedLanguage == null ||
        _emergency1NameController.text.isEmpty ||
        _selectedEmergency1Relation == null ||
        _emergency1NumberController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    // Ask for user consent before proceeding
    final consent = await _showConsentDialog();
    if (consent != true) {
      // User did not consent; abort submission
      return;
    }

    try {
      // Insert user credentials
      await _supabaseService.insertUserCredentials(
        _emailController.text,
        _passwordController.text,
        _contactNumberController.text,
      );

      // Optional: upload profile photo if user selected one
      String? profilePhotoUrl;
      if (_pickedImage != null) {
        try {
          final file = File(_pickedImage!.path);
          profilePhotoUrl = await _supabaseService.uploadProfilePhoto(
            file,
            _contactNumberController.text,
          );
        } catch (_) {
          // Silent failure - keep it optional
        }
      }

      // Prepare profile data
      Map<String, dynamic> profileData = {
        'full_name': _fullNameController.text,
        'date_of_birth': _dateOfBirthController.text,
        'gender': _selectedGender,
        'aadhar_number': _aadharController.text,
        'contact_number': _contactNumberController.text,
        'marital_status': _selectedMaritalStatus,
        'living_with': _selectedLivingWith,
        'police_station': _selectedPoliceStation,
        'address': _addressController.text,
        'pincode': _pincodeController.text,
        'preferred_language': _selectedLanguage,
        'emergency_contact_1_name': _emergency1NameController.text,
        'emergency_contact_1_relation': _selectedEmergency1Relation,
        'emergency_contact_1_number': _emergency1NumberController.text,
        'emergency_contact_2_name': _emergency2NameController.text,
        'emergency_contact_2_relation': _selectedEmergency2Relation,
        'emergency_contact_2_number': _emergency2NumberController.text,
        'medical_conditions': _selectedMedicalConditions,
        'other_medical_conditions': _otherMedicalController.text,
        'blood_group': _selectedBloodGroup,
        'profile_photo_url': profilePhotoUrl,
      };

      await _supabaseService.insertUserProfile(profileData);

      // Navigate to under verification screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UnderVerificationScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF3E0FAD), width: 3),
              ),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3E0FAD), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 45,
                          backgroundImage: AssetImage('assets/Senior Citizen.png'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Welcome Onboard',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 28,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your safety is our mission.\nTogether, let\'s create a safer world for every Senior Citizen.',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Color(0xFFE0E7FF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Multi-step form
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Step indicators
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            final active = i == _currentStep;
                            final completed = i < _currentStep;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Container(
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: active ? 24 : completed ? 20 : 16,
                                      height: active ? 24 : completed ? 20 : 16,
                                      decoration: BoxDecoration(
                                        color: active || completed ? const Color(0xFF3E0FAD) : const Color(0xFFD1D5DB),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: active ? const Color(0xFF3E0FAD) : Colors.transparent,
                                          width: active ? 2 : 0,
                                        ),
                                      ),
                                      child: completed && !active
                                        ? const Icon(Icons.check, color: Colors.white, size: 12)
                                        : null,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: active || completed ? const Color(0xFF3E0FAD) : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Step content
                      _buildStepContent(),
                      const SizedBox(height: 32),

                      // Navigation buttons
                      Row(
                        children: [
                          if (_currentStep > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _prevStep,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF3E0FAD),
                                  side: const BorderSide(color: Color(0xFF3E0FAD), width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                ),
                                child: const Text(
                                  'Back',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          if (_currentStep > 0) const SizedBox(width: 16),
                          Expanded(
                            flex: _currentStep > 0 ? 2 : 1,
                            child: ElevatedButton(
                              onPressed: _currentStep < 4 ? _nextStep : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3E0FAD),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                elevation: 3,
                              ),
                              child: Text(
                                _currentStep < 4 ? 'Continue' : 'Create Account',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Sign-in prompt
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Already have an account?",
                              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text(
                                'Sign In Here',
                                style: TextStyle(
                                  color: Color(0xFF3E0FAD),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}

class _DobInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Keep only digits and limit to 8 characters (YYYYMMDD)
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digitsOnly.length > 8 ? digitsOnly.substring(0, 8) : digitsOnly;

    // Insert hyphens to produce YYYY-MM-DD as the user types
    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i == 4 || i == 6) buffer.write('-');
      buffer.write(limited[i]);
    }
    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}