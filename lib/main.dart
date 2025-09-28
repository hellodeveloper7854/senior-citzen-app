import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/under_verification_screen.dart';
import 'screens/rejected_screen.dart';
import 'services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await Supabase.initialize(
  //   url: 'https://tbxihxtvocurqsygfknk.supabase.co',
  //   anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRieGloeHR2b2N1cnFzeWdma25rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzNjE5OTMsImV4cCI6MjA3MzkzNzk5M30.cLBscTAW3UaixNphFs-MYnvoRTKg0hMPtN6gbHoezt4',
  // );

  await Supabase.initialize(
    url: 'https://alcqejmotzojjbasrjol.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFsY3Flam1vdHpvampiYXNyam9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkwMzg3MDYsImV4cCI6MjA3NDYxNDcwNn0.9h22kaBiPksRsyGTwhPjzT5VAxYaSQ-z52r8KOJlAuY',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SupabaseService _supabaseService = SupabaseService();

  Future<Widget> _getInitialScreen() async {
    try {
      final email = await _supabaseService.getCurrentUserEmail();
      if (email == null) {
        return const WelcomeScreen();
      }

      final credentials = await _supabaseService.getUserCredentials(email);
      if (credentials == null) {
        return const WelcomeScreen();
      }

      final profile = await _supabaseService.getUserProfileByPhone(credentials['phone_number']);
      if (profile == null) {
        return const WelcomeScreen();
      }

      if (profile['status'] == 'verified') {
        return const DashboardScreen();
      } else if (profile['status'] == 'rejected') {
        return RejectedScreen(rejectionReason: profile['rejection_reason'] ?? 'No reason provided');
      } else {
        return const UnderVerificationScreen();
      }
    } catch (e) {
      return const WelcomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'आधारवड',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return const WelcomeScreen();
          } else {
            return snapshot.data ?? const WelcomeScreen();
          }
        },
      ),
    );
  }
}
