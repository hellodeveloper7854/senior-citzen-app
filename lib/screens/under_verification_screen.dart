import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import '../services/supabase_service.dart';

class UnderVerificationScreen extends StatelessWidget {
  const UnderVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Under Verification'),
        actions: [
  TextButton(
    onPressed: () async {
      final supabaseService = SupabaseService();
      await supabaseService.clearCurrentUser();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    },
    child: const Text(
      'Logout',
      style: TextStyle(color: Colors.white),
    ),
  ),
],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty, size: 100, color: Colors.orange),
              SizedBox(height: 20),
              Text(
                'Your account is under verification.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Please wait for the admin to verify your details. You will be notified once verified.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}