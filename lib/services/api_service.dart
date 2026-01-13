import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/crypto_util.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // API Configuration
  static String get baseUrl {
    // Try to get from environment variable first
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    // Fallback to compile-time constant or default
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000/api',
    );
  }

  // Store current user email
  Future<void> setCurrentUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_email', email);
  }

  // Get current user email
  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_email');
  }

  // Store current user phone number
  Future<void> setCurrentUserPhoneNumber(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_phone', phoneNumber);
    print('✅ Saved current user phone: $phoneNumber');
  }

  // Get current user phone number
  Future<String?> getCurrentUserPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('current_user_phone');
    print('📱 Retrieved current user phone: $phone');
    return phone;
  }

  // Clear current user
  Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_email');
    await prefs.remove('current_user_phone');
    print('🗑️ Cleared current user data');
  }

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return password;
  }

  // Helper method to make HTTP GET requests
  Future<dynamic> _get(String endpoint) async {
    print('📡 API GET Request: $baseUrl$endpoint');
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );

    print('📡 API Response Status: ${response.statusCode} for $endpoint');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        print('✅ API Response: Empty body');
        return null;
      }
      final decoded = jsonDecode(response.body);
      print('✅ API Response Data: ${decoded is List ? '${(decoded as List).length} items' : decoded}');
      return decoded;
    } else {
      print('❌ API Error: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  // Helper method to make HTTP POST requests
  Future<dynamic> _post(String endpoint, Map<String, dynamic> data) async {
    print('📤 API POST Request: $baseUrl$endpoint');
    print('Request Data: $data');
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    print('📡 API Response Status: ${response.statusCode} for $endpoint');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        print('✅ API POST Response: Empty body');
        return null;
      }
      final decoded = jsonDecode(response.body);
      print('✅ API POST Response Data: $decoded');
      return decoded;
    } else {
      print('❌ API POST Error: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to create data: ${response.statusCode}');
    }
  }

  // Helper method to make HTTP PUT requests
  Future<dynamic> _put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update data: ${response.statusCode}');
    }
  }

  // Helper method to make HTTP PATCH requests
  Future<dynamic> _patch(String endpoint, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to patch data: ${response.statusCode}');
    }
  }

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  // Login with email and password
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response != null && response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Register user credentials
  Future<void> registerCredentials(String email, String password, String phoneNumber) async {
    try {
      await _post('/auth/register', {
        'email': email,
        'password': password,
        'phone_number': phoneNumber,
      });
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // ============================================================================
  // USER CREDENTIALS
  // ============================================================================

  // Note: Since backend doesn't have user_credentials endpoints yet,
  // we'll use a workaround by storing credentials locally or extending the backend

  // For now, we'll use SharedPreferences for user credentials
  Future<void> insertUserCredentials(String email, String password, String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final credentialsKey = 'user_credentials_$email';

    await prefs.setString(credentialsKey, jsonEncode({
      'email': email,
      'password': _hashPassword(password),
      'phone_number': phoneNumber,
    }));
  }

  Future<Map<String, dynamic>?> getUserCredentials(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final credentialsKey = 'user_credentials_$email';
    final data = prefs.getString(credentialsKey);

    if (data == null) return null;
    return jsonDecode(data);
  }

  Future<Map<String, dynamic>?> getUserCredentialsByPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('user_credentials_'));

    for (final key in keys) {
      final data = prefs.getString(key);
      if (data != null) {
        final credentials = jsonDecode(data);
        if (credentials['phone_number'] == phone) {
          return credentials;
        }
      }
    }
    return null;
  }

  Future<void> updatePassword(String identifier, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('user_credentials_'));

    for (final key in keys) {
      final data = prefs.getString(key);
      if (data != null) {
        final credentials = jsonDecode(data);
        if (credentials['email'] == identifier || credentials['phone_number'] == identifier) {
          credentials['password'] = _hashPassword(newPassword);
          await prefs.setString(key, jsonEncode(credentials));
          return;
        }
      }
    }
    throw Exception('User not found');
  }

  // ============================================================================
  // USER PROFILE
  // ============================================================================

  Future<void> insertUserProfile(Map<String, dynamic> profileData) async {
    final data = Map<String, dynamic>.from(profileData);

    // Encrypt Aadhaar and emergency contact numbers
    data['aadhar_number'] = await CryptoUtil.encryptString(profileData['aadhar_number']);
    data['emergency_contact_1_number'] = await CryptoUtil.encryptString(profileData['emergency_contact_1_number']);
    data['emergency_contact_2_number'] = await CryptoUtil.encryptString(profileData['emergency_contact_2_number']);

    await _post('/users', data);
  }

  Future<Map<String, dynamic>?> getUserProfile(String email) async {
    final response = await _get('/users/$email');
    if (response == null) return null;
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getUserProfileByPhone(String phone) async {
    try {
      print('Fetching profile for phone: $phone');
      final response = await _get('/users/$phone');
      if (response == null) {
        print('No response from backend for phone: $phone');
        return null;
      }

      final profile = response as Map<String, dynamic>;
      print('Raw profile data received: ${profile.keys.toList()}');

      // Compatibility: backend may return profile image as `profile_photo_url`
      // while the app historically uses `profile_img`.
      final String? profileImg = (profile['profile_img'] as String?)?.trim();
      final String? profilePhotoUrl = (profile['profile_photo_url'] as String?)?.trim();
      if ((profileImg == null || profileImg.isEmpty) && profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) {
        profile['profile_img'] = profilePhotoUrl;
      }

      // Decrypt sensitive fields
      try {
        if (profile['aadhar_number'] != null) {
          profile['aadhar_number'] = await CryptoUtil.decryptString(profile['aadhar_number']);
        }
      } catch (e) {
        print('Error decrypting aadhar: $e');
        // Keep raw value if decryption fails
      }
      try {
        if (profile['emergency_contact_1_number'] != null) {
          profile['emergency_contact_1_number'] = await CryptoUtil.decryptString(profile['emergency_contact_1_number']);
        }
      } catch (e) {
        print('Error decrypting emergency_contact_1: $e');
        // Keep raw value if decryption fails
      }
      try {
        if (profile['emergency_contact_2_number'] != null) {
          profile['emergency_contact_2_number'] = await CryptoUtil.decryptString(profile['emergency_contact_2_number']);
        }
      } catch (e) {
        print('Error decrypting emergency_contact_2: $e');
        // Keep raw value if decryption fails
      }

      print('Profile fetched successfully');
      return profile;
    } catch (e) {
      print('Error in getUserProfileByPhone: $e');
      return null;
    }
  }

  Future<String> uploadProfilePhoto(File file, String phoneNumber) async {
    final bytes = await file.readAsBytes();
    final base64String = base64Encode(bytes);
    return base64String;
  }

  Future<void> updateProfilePhotoUrl(String phoneNumber, String publicUrl) async {
    await _put('/users/$phoneNumber', {'profile_img': publicUrl});
  }

  Future<void> updateUserProfile(String phoneNumber, Map<String, dynamic> updates) async {
    final data = Map<String, dynamic>.from(updates);

    // Encrypt sensitive fields if present
    if (data.containsKey('aadhar_number')) {
      data['aadhar_number'] = await CryptoUtil.encryptString(data['aadhar_number']);
    }
    if (data.containsKey('emergency_contact_1_number')) {
      data['emergency_contact_1_number'] = await CryptoUtil.encryptString(data['emergency_contact_1_number']);
    }
    if (data.containsKey('emergency_contact_2_number')) {
      data['emergency_contact_2_number'] = await CryptoUtil.encryptString(data['emergency_contact_2_number']);
    }

    await _put('/users/$phoneNumber', data);
  }

  // ============================================================================
  // AUDIO RECORDINGS
  // ============================================================================

  // Note: For file upload, we need to add an endpoint to backend or use cloud storage
  // For now, returning a placeholder URL
  Future<String> uploadAudioRecording(File file, String phoneNumber) async {
    // TODO: Implement actual file upload to cloud storage or add upload endpoint to backend
    final String fileExt = 'm4a';
    final String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    // This is a placeholder - implement actual storage
    return 'https://example.com/recordings/$phoneNumber/$fileName';
  }

  Future<void> saveRecordingMetadata(String phoneNumber, String audioUrl, String timestamp) async {
    // Get user's police station from profile
    final userProfile = await getUserProfileByPhone(phoneNumber);
    final policeStation = userProfile?['police_station'] ?? 'Unknown';

    await _post('/recordings', {
      'user_phone': phoneNumber,
      'audio_url': audioUrl,
      'recorded_at': timestamp,
      'police_station': policeStation,
      'status': 'pending',
    });
  }

  Future<List<Map<String, dynamic>>> getAllRecordings() async {
    final response = await _get('/recordings');
    if (response == null) return [];
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getUserRecordings(String userPhone) async {
    final response = await _get('/recordings');
    if (response == null) return [];

    final allRecordings = List<Map<String, dynamic>>.from(response);
    return allRecordings.where((rec) => rec['user_phone'] == userPhone).toList();
  }

  Future<void> updateRecordingStatus(int recordingId, String status, {String? adminNotes}) async {
    final data = {'status': status};
    if (adminNotes != null) {
      data['notes'] = adminNotes;
    }
    await _patch('/recordings/$recordingId/status', data);
  }

  // ============================================================================
  // COMPLAINTS
  // ============================================================================

  Future<void> submitComplaint({
    required String userPhone,
    required String title,
    required String description,
    String? incidentDate,
    String? incidentTime,
    String? location,
  }) async {
    // Get user's police station from profile
    final userProfile = await getUserProfileByPhone(userPhone);
    final policeStation = userProfile?['police_station'] ?? 'Unknown';

    await _post('/complaints', {
      'user_phone': userPhone,
      'title': title,
      'description': description,
      'incident_date': incidentDate,
      'incident_time': incidentTime,
      'location': location,
      'police_station': policeStation,
    });
  }

  Future<List<Map<String, dynamic>>> getAllComplaints() async {
    final response = await _get('/complaints');
    if (response == null) return [];
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateComplaintStatus(int complaintId, String status, {String? adminNotes}) async {
    await _patch('/complaints/$complaintId/status', {
      'status': status,
      if (adminNotes != null) 'admin_notes': adminNotes,
    });
  }

  Future<List<Map<String, dynamic>>> getUserComplaints(String userPhone) async {
    print('🔍 Fetching complaints for user_phone: $userPhone');
    final response = await _get('/complaints');
    if (response == null) return [];

    final allComplaints = List<Map<String, dynamic>>.from(response);
    print('📋 Total complaints from API: ${allComplaints.length}');

    // Print each complaint's user_phone for debugging
    for (var comp in allComplaints) {
      print('  Complaint ID: ${comp['id']}, user_phone: "${comp['user_phone']}" (type: ${comp['user_phone'].runtimeType})');
      print('  Comparing with: "$userPhone" (type: ${userPhone.runtimeType})');
      print('  Match: ${comp['user_phone'] == userPhone}');
    }

    final filtered = allComplaints.where((comp) => comp['user_phone'] == userPhone).toList();
    print('✅ Filtered complaints: ${filtered.length}');

    return filtered;
  }

  // ============================================================================
  // SOS ALERTS
  // ============================================================================

  Future<int?> createSOSAlert({
    required String userId,
    required String userName,
    required double latitude,
    required double longitude,
    required String locationAddress,
    required List<String> emergencyContacts,
  }) async {
    // Get user's police station from profile
    final userProfile = await getUserProfileByPhone(userId);
    final policeStation = userProfile?['police_station'] ?? 'Unknown';

    final response = await _post('/sos-alerts', {
      'user_id': userId,
      'user_name': userName,
      'police_station': policeStation,
      'latitude': latitude,
      'longitude': longitude,
      'location_address': locationAddress,
      'emergency_contacts': emergencyContacts,
    });

    if (response != null && response is Map<String, dynamic>) {
      return response['id'] as int?;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getSOSAlerts({String? status}) async {
    final response = await _get('/sos-alerts');
    if (response == null) return [];

    final allAlerts = List<Map<String, dynamic>>.from(response);
    if (status != null) {
      return allAlerts.where((alert) => alert['status'] == status).toList();
    }
    return allAlerts;
  }

  Future<List<Map<String, dynamic>>> getUserSOSAlerts(String userPhone) async {
    final response = await _get('/sos-alerts');
    if (response == null) return [];

    final allAlerts = List<Map<String, dynamic>>.from(response);
    return allAlerts.where((alert) => alert['user_id'] == userPhone).toList();
  }

  Future<void> updateSOSAlertStatus(int alertId, String status, {String? resolvedBy, String? notes}) async {
    await _patch('/sos-alerts/$alertId/status', {
      'status': status,
      'resolved_by': resolvedBy,
      'notes': notes,
    });
  }

  // ============================================================================
  // USER FEEDBACK
  // ============================================================================

  Future<void> submitFeedback({
    required String userPhone,
    required int rating,
    required String feedback,
  }) async {
    try {
      print('📝 Submitting feedback for user: $userPhone');
      print('⭐ Rating: $rating, Feedback: $feedback');

      await _post('/feedback', {
        'user_phone': userPhone,
        'rating': rating,
        'feedback': feedback,
      });

      print('✅ Feedback submitted successfully');
    } catch (e) {
      print('❌ Error submitting feedback: $e');
      throw Exception('Failed to submit feedback: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllFeedback() async {
    try {
      print('📝 Fetching all feedback...');
      final response = await _get('/feedback');
      if (response == null) return [];

      final feedbackList = List<Map<String, dynamic>>.from(response);
      print('✅ Retrieved ${feedbackList.length} feedback entries');
      return feedbackList;
    } catch (e) {
      print('❌ Error fetching all feedback: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserFeedback(String userPhone) async {
    try {
      print('📝 Fetching feedback for user: $userPhone');
      final response = await _get('/feedback/$userPhone');
      if (response == null) return [];

      final feedbackList = List<Map<String, dynamic>>.from(response);
      print('✅ Retrieved ${feedbackList.length} feedback entries for user');
      return feedbackList;
    } catch (e) {
      print('❌ Error fetching user feedback: $e');
      return [];
    }
  }

  // ============================================================================
  // EMERGENCY PHONE NUMBERS
  // ============================================================================

  // Note: These endpoints are not yet in backend
  // Returns default values for now
  Future<List<Map<String, dynamic>>> getEmergencyPhoneNumbers() async {
    return [];
  }

  Future<String?> getEmergencyPhoneNumber(String serviceName) async {
    if (serviceName == 'Police') {
      return '9326520525';
    }
    return null;
  }

  Future<String?> getPoliceEmergencyNumber() async {
    return '9326520525';
  }

  Future<String?> getPoliceStationContactNumber(String policeStation) async {
    // TODO: Add police station contacts endpoint to backend
    return null;
  }

  Future<String> getPoliceStationNumberWithSOSFallback(String policeStation) async {
    final stationNumber = await getPoliceStationContactNumber(policeStation);
    if (stationNumber != null && stationNumber.isNotEmpty) {
      return stationNumber;
    }
    return await getPoliceEmergencyNumber() ?? '9326520525';
  }

  // ============================================================================
  // SMS SENDING
  // ============================================================================

  Future<void> sendSMS(String phoneNumber, String message) async {
    // TODO: Add SMS endpoint to backend
    print('SMS sending not yet implemented in backend');
  }

  // ============================================================================
  // TRACKING SESSIONS
  // ============================================================================

  // Note: Backend doesn't have tracking endpoints yet
  // These are placeholders - add endpoints to backend if needed
  Future<void> startTrackingSession({
    required String userPhone,
    required String userName,
    required double latitude,
    required double longitude,
    required String locationAddress,
    double? destinationLatitude,
    double? destinationLongitude,
    String? destinationAddress,
    int? durationMinutes,
  }) async {
    // TODO: Add tracking session endpoint to backend
    print('Tracking sessions not yet implemented in backend');
  }

  Future<void> updateTrackingLocation({
    required String userPhone,
    required double latitude,
    required double longitude,
    required String locationAddress,
  }) async {
    // TODO: Add tracking location update endpoint to backend
  }

  Future<void> updateTrackingDestination({
    required String userPhone,
    required double destinationLatitude,
    required double destinationLongitude,
    required String destinationAddress,
  }) async {
    // TODO: Add tracking destination update endpoint to backend
  }

  Future<void> stopTrackingSession(String userPhone) async {
    // TODO: Add tracking stop endpoint to backend
  }

  Future<List<Map<String, dynamic>>> getActiveTrackingSessions() async {
    // TODO: Add tracking sessions endpoint to backend
    return [];
  }

  Future<List<Map<String, dynamic>>> getUserTrackingHistory(String userPhone) async {
    // TODO: Add tracking history endpoint to backend
    return [];
  }

  Future<bool> hasActiveTrackingSession(String userPhone) async {
    // TODO: Add active tracking check endpoint to backend
    return false;
  }

  Future<Map<String, dynamic>?> getActiveTrackingSession(String userPhone) async {
    // TODO: Add active tracking session endpoint to backend
    return null;
  }

  // ============================================================================
  // HELPLINE METHODS
  // ============================================================================

  Future<List<Map<String, dynamic>>> getNationalHelplines() async {
    try {
      print('📞 Fetching national helplines...');
      final response = await _get('/national-helplines');
      if (response == null) {
        print('⚠️ No national helplines data received');
        return [];
      }
      final helplines = List<Map<String, dynamic>>.from(response);
      print('✅ Retrieved ${helplines.length} national helplines');
      return helplines;
    } catch (e) {
      print('❌ Error fetching national helplines: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getHospitalContacts() async {
    try {
      print('🏥 Fetching hospital contacts...');
      final response = await _get('/hospital-contacts');
      if (response == null) {
        print('⚠️ No hospital contacts data received');
        return [];
      }
      final hospitals = List<Map<String, dynamic>>.from(response);
      print('✅ Retrieved ${hospitals.length} hospital contacts');
      return hospitals;
    } catch (e) {
      print('❌ Error fetching hospital contacts: $e');
      return [];
    }
  }
}
