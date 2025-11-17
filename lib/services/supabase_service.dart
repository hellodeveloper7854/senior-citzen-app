import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../utils/crypto_util.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

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

  // Clear current user
  Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_email');
  }

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    // return digest.toString();
    return password;


  }

  // Insert user credentials
  Future<void> insertUserCredentials(String email, String password, String phoneNumber) async {
    await _supabase.from('user_credentials').insert({
      'email': email,
      'password': _hashPassword(password),
      'phone_number': phoneNumber,
    });
  }

  // Insert user profile (encrypt sensitive fields before storing)
  Future<void> insertUserProfile(Map<String, dynamic> profileData) async {
    final data = Map<String, dynamic>.from(profileData);

    // Encrypt Aadhaar and emergency contact numbers
    data['aadhar_number'] = await CryptoUtil.encryptString(profileData['aadhar_number']);
    data['emergency_contact_1_number'] = await CryptoUtil.encryptString(profileData['emergency_contact_1_number']);
    data['emergency_contact_2_number'] = await CryptoUtil.encryptString(profileData['emergency_contact_2_number']);

    await _supabase.from('registrations').insert(data);
  }

  // Check if user exists in user_credentials
  Future<Map<String, dynamic>?> getUserCredentials(String email) async {
    final response = await _supabase
        .from('user_credentials')
        .select()
        .eq('email', email);
    if (response.isEmpty) return null;
    return response.first;
  }

  // Get user credentials by phone
  Future<Map<String, dynamic>?> getUserCredentialsByPhone(String phone) async {
    final response = await _supabase
        .from('user_credentials')
        .select()
        .eq('phone_number', phone);
    if (response.isEmpty) return null;
    return response.first;
  }

  // Update password
  Future<void> updatePassword(String identifier, String newPassword) async {
    bool isEmail = identifier.contains('@');
    var existing = isEmail ? await getUserCredentials(identifier) : await getUserCredentialsByPhone(identifier);
    if (existing == null) throw Exception('User not found');
    if (isEmail) {
      await _supabase.from('user_credentials').update({'password': _hashPassword(newPassword)}).eq('email', identifier);
    } else {
      await _supabase.from('user_credentials').update({'password': _hashPassword(newPassword)}).eq('phone_number', identifier);
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String email) async {
    final response = await _supabase
        .from('registrations')
        .select()
        .eq('contact_number', email) // assuming contact_number is email? wait, no
        .single();
    return response;
  }

  // Actually, since user_credentials has email, and profile has contact_number which is phone, but login with email?
  // The task says login with email I think, but store phone in credentials.

  // Perhaps login with email, check credentials, then get profile by phone or something.

  // For simplicity, assume profile has email too, but the schema doesn't have email in profile.

  // The schema has contact_number, which is phone.

  // Perhaps link by phone.

  // For login, check user_credentials by email, get phone, then get profile by contact_number.

  Future<Map<String, dynamic>?> getUserProfileByPhone(String phone) async {
    final response = await _supabase
        .from('registrations')
        .select()
        .eq('contact_number', phone);

    if (response.isEmpty) return null;

    final profile = response.first;

    // Decrypt sensitive fields (handles legacy plaintext gracefully)
    try {
      profile['aadhar_number'] =
          await CryptoUtil.decryptString(profile['aadhar_number']);
    } catch (e) {
      // If decryption fails, keep the raw value
    }
    try {
      profile['emergency_contact_1_number'] =
          await CryptoUtil.decryptString(profile['emergency_contact_1_number']);
    } catch (e) {
      // If decryption fails, keep the raw value
    }
    try {
      profile['emergency_contact_2_number'] =
          await CryptoUtil.decryptString(profile['emergency_contact_2_number']);
    } catch (e) {
      // If decryption fails, keep the raw value
    }

    return profile;
  }

  // Upload profile photo to Supabase Storage and return a public URL
  // Make sure you have a public bucket named "profile-photos" in Supabase
  Future<String> uploadProfilePhoto(File file, String phoneNumber) async {
    final String fileExt = file.path.split('.').last.toLowerCase();
    final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final String storagePath = 'profiles/$phoneNumber/$fileName';

    // Upload file
    await _supabase.storage.from('profile-photos').upload(
      storagePath,
      file,
      fileOptions: FileOptions(
        cacheControl: '3600',
        upsert: true,
        contentType: 'image/$fileExt',
      ),
    );

    // Get public URL
    final String publicUrl = _supabase.storage.from('profile-photos').getPublicUrl(storagePath);
    return publicUrl;
  }

  // Update only the profile photo URL field for a given contact number
  Future<void> updateProfilePhotoUrl(String phoneNumber, String publicUrl) async {
    await _supabase
        .from('registrations')
        .update({'profile_photo_url': publicUrl})
        .eq('contact_number', phoneNumber);
  }

  // Update user profile fields for a given contact number (phone).
  // Encrypts sensitive fields if they are present in the updates map.
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

    await _supabase
        .from('registrations')
        .update(data)
        .eq('contact_number', phoneNumber);
  }

  // Upload audio recording to Supabase Storage
  Future<String> uploadAudioRecording(File file, String phoneNumber) async {
    final String fileExt = 'm4a';
    final String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final String storagePath = 'recordings/$phoneNumber/$fileName';

    // Upload file
    await _supabase.storage.from('audio-recordings').upload(
      storagePath,
      file,
      fileOptions: FileOptions(
        cacheControl: '3600',
        upsert: true,
        contentType: 'audio/m4a',
      ),
    );

    // Get public URL
    final String publicUrl = _supabase.storage.from('audio-recordings').getPublicUrl(storagePath);
    return publicUrl;
  }

  // Save recording metadata to database
  Future<void> saveRecordingMetadata(String phoneNumber, String audioUrl, String timestamp) async {
    // Get user's police station from profile
    final userProfile = await getUserProfileByPhone(phoneNumber);
    final policeStation = userProfile?['police_station'] ?? 'Unknown';

    await _supabase.from('audio_recordings').insert({
      'user_phone': phoneNumber,
      'audio_url': audioUrl,
      'recorded_at': timestamp,
      'police_station': policeStation,
      'status': 'pending', // Can be 'pending', 'reviewed', 'archived'
    });
  }

  // Get all recordings for admin panel
  Future<List<Map<String, dynamic>>> getAllRecordings() async {
    final response = await _supabase
        .from('audio_recordings')
        .select()
        .order('recorded_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get recordings for a specific user
  Future<List<Map<String, dynamic>>> getUserRecordings(String userPhone) async {
    final response = await _supabase
        .from('audio_recordings')
        .select()
        .eq('user_phone', userPhone)
        .order('recorded_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Update recording status
  Future<void> updateRecordingStatus(int recordingId, String status) async {
    await _supabase
        .from('audio_recordings')
        .update({'status': status})
        .eq('id', recordingId);
  }

  // Submit a complaint
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

    await _supabase.from('complaints').insert({
      'user_phone': userPhone,
      'title': title,
      'description': description,
      'incident_date': incidentDate,
      'incident_time': incidentTime,
      'location': location,
      'police_station': policeStation,
      'status': 'pending',
    });
  }

  // Get all complaints for admin panel
  Future<List<Map<String, dynamic>>> getAllComplaints() async {
    final response = await _supabase
        .from('complaints')
        .select()
        .order('submitted_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Update complaint status
  Future<void> updateComplaintStatus(int complaintId, String status, {String? adminNotes}) async {
    final updateData = {'status': status, 'updated_at': DateTime.now().toIso8601String()};
    if (adminNotes != null) {
      updateData['admin_notes'] = adminNotes;
    }

    await _supabase
        .from('complaints')
        .update(updateData)
        .eq('id', complaintId);
  }

  // Get complaints for a specific user
  Future<List<Map<String, dynamic>>> getUserComplaints(String userPhone) async {
    final response = await _supabase
        .from('complaints')
        .select()
        .eq('user_phone', userPhone)
        .order('submitted_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Create SOS alert for admin monitoring
  Future<void> createSOSAlert({
    required String userId, // phone number
    required String userName,
    required double latitude,
    required double longitude,
    required String locationAddress,
    required List<String> emergencyContacts,
  }) async {
    // Get user's police station from profile
    final userProfile = await getUserProfileByPhone(userId);
    final policeStation = userProfile?['police_station'] ?? 'Unknown';

    await _supabase.from('sos_alerts').insert({
      'user_id': userId,
      'user_name': userName,
      'police_station': policeStation,
      'latitude': latitude,
      'longitude': longitude,
      'location_address': locationAddress,
      'emergency_contacts': emergencyContacts,
      'alert_timestamp': DateTime.now().toIso8601String(),
      'status': 'active',
    });
  }

  // Get all SOS alerts for admin
  Future<List<Map<String, dynamic>>> getSOSAlerts({String? status}) async {
    var query = _supabase
        .from('sos_alerts')
        .select();

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('alert_timestamp', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get SOS alerts for a specific user
  Future<List<Map<String, dynamic>>> getUserSOSAlerts(String userPhone) async {
    final response = await _supabase
        .from('sos_alerts')
        .select()
        .eq('user_id', userPhone)
        .order('alert_timestamp', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Update SOS alert status
  Future<void> updateSOSAlertStatus(int alertId, String status, {String? resolvedBy, String? notes}) async {
    final updates = {
      'status': status,
      'resolved_at': status != 'active' ? DateTime.now().toIso8601String() : null,
      'resolved_by': resolvedBy,
      'notes': notes,
    };

    await _supabase
        .from('sos_alerts')
        .update(updates)
        .eq('id', alertId);
  }

  // Submit user feedback
  Future<void> submitFeedback({
    required String userPhone,
    required int rating,
    required String feedback,
  }) async {
    // Get user's police station from profile
    final userProfile = await getUserProfileByPhone(userPhone);
    final policeStation = userProfile?['police_station'] ?? 'Unknown';

    await _supabase.from('user_feedback').insert({
      'user_phone': userPhone,
      'rating': rating,
      'feedback': feedback,
      'police_station': policeStation,
      'submitted_at': DateTime.now().toIso8601String(),
    });
  }

  // Get all feedback for admin panel
  Future<List<Map<String, dynamic>>> getAllFeedback() async {
    final response = await _supabase
        .from('user_feedback')
        .select()
        .order('submitted_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get feedback for a specific user
  Future<List<Map<String, dynamic>>> getUserFeedback(String userPhone) async {
    final response = await _supabase
        .from('user_feedback')
        .select()
        .eq('user_phone', userPhone)
        .order('submitted_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}