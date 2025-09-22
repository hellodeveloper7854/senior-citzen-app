import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'under_verification_screen.dart';

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

  final SupabaseService _supabaseService = SupabaseService();

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
        _emergency2NameController.text.isEmpty ||
        _selectedEmergency2Relation == null ||
        _emergency2NumberController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    try {
      // Insert user credentials
      await _supabaseService.insertUserCredentials(
        _emailController.text,
        _passwordController.text,
        _contactNumberController.text,
      );

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
      appBar: AppBar(
        title: const Text('Signup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personal Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(labelText: 'Date of Birth *'),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: 'Gender *'),
                items: _genders.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _aadharController,
                decoration: const InputDecoration(labelText: 'Aadhar Number *'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _contactNumberController,
                decoration: const InputDecoration(labelText: 'Contact Number *'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              const Text('Additional Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedMaritalStatus,
                decoration: const InputDecoration(labelText: 'Marital Status *'),
                items: _maritalStatuses.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
                onChanged: (value) => setState(() => _selectedMaritalStatus = value),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedLivingWith,
                decoration: const InputDecoration(labelText: 'Living with *'),
                items: _livingWithOptions.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                onChanged: (value) => setState(() => _selectedLivingWith = value),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedPoliceStation,
                decoration: const InputDecoration(labelText: 'Police Station *'),
                items: _policeStations.map((station) => DropdownMenuItem(value: station, child: Text(station))).toList(),
                onChanged: (value) => setState(() => _selectedPoliceStation = value),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address *'),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _pincodeController,
                decoration: const InputDecoration(labelText: 'Pincode *'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: const InputDecoration(labelText: 'Preferred Language *'),
                items: _languages.map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
                onChanged: (value) => setState(() => _selectedLanguage = value),
              ),
              const SizedBox(height: 20),
              const Text('Emergency Contacts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Emergency Contact 1'),
              TextField(
                controller: _emergency1NameController,
                decoration: const InputDecoration(labelText: 'Name *'),
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: _selectedEmergency1Relation,
                decoration: const InputDecoration(labelText: 'Relation *'),
                items: _relations.map((rel) => DropdownMenuItem(value: rel, child: Text(rel))).toList(),
                onChanged: (value) => setState(() => _selectedEmergency1Relation = value),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: _emergency1NumberController,
                decoration: const InputDecoration(labelText: 'Contact Number *'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              const Text('Emergency Contact 2'),
              TextField(
                controller: _emergency2NameController,
                decoration: const InputDecoration(labelText: 'Name *'),
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: _selectedEmergency2Relation,
                decoration: const InputDecoration(labelText: 'Relation *'),
                items: _relations.map((rel) => DropdownMenuItem(value: rel, child: Text(rel))).toList(),
                onChanged: (value) => setState(() => _selectedEmergency2Relation = value),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: _emergency2NumberController,
                decoration: const InputDecoration(labelText: 'Contact Number *'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              const Text('Medical Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Medical Conditions'),
              ..._medicalConditionsList.map((condition) => CheckboxListTile(
                title: Text(condition),
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
              )),
              const SizedBox(height: 10),
              TextField(
                controller: _otherMedicalController,
                decoration: const InputDecoration(labelText: 'Other Medical Conditions'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedBloodGroup,
                decoration: const InputDecoration(labelText: 'Blood Group'),
                items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
                onChanged: (value) => setState(() => _selectedBloodGroup = value),
              ),
              const SizedBox(height: 20),
              const Text('Account Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password *'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Signup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}