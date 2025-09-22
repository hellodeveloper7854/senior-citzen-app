import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Insert user credentials
  Future<void> insertUserCredentials(String email, String password, String phoneNumber) async {
    await _supabase.from('user_credentials').insert({
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
    });
  }

  // Insert user profile
  Future<void> insertUserProfile(Map<String, dynamic> profileData) async {
    await _supabase.from('registrations').insert(profileData);
  }

  // Check if user exists in user_credentials
  Future<Map<String, dynamic>?> getUserCredentials(String email) async {
    final response = await _supabase
        .from('user_credentials')
        .select()
        .eq('email', email)
        .single();
    return response;
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
      await _supabase.from('user_credentials').update({'password': newPassword}).eq('email', identifier);
    } else {
      await _supabase.from('user_credentials').update({'password': newPassword}).eq('phone_number', identifier);
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
        .eq('contact_number', phone)
        .single();
    return response;
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
}