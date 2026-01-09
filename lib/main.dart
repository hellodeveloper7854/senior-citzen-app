import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/under_verification_screen.dart';
import 'screens/rejected_screen.dart';
import 'services/supabase_service.dart';
import 'services/navigation_service.dart';
import 'services/tracking_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/permission_utils.dart';

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

//   VITE_SUPABASE_PROJECT_ID="tbxihxtvocurqsygfknk"
// VITE_SUPABASE_PUBLISHABLE_KEY=""
// VITE_SUPABASE_URL="https://tbxihxtvocurqsygfknk.supabase.co"

  // Request permissions on app startup (for Android 13+ compatibility)
  // Handle Android 14 compatibility by wrapping in try-catch
  try {
    await PermissionUtils.requestPermissionsOnStartup(null);
  } catch (e) {
    print('Error requesting permissions on startup: $e');
    // Continue app startup even if permission request fails
  }

  // Initialize global TrackingService
  await TrackingService().initialize();

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
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigationService().navigatorKey,
        title: 'आधारवड ठाणे पोलीस',
        theme: ThemeData(
        colorScheme: const ColorScheme(
          primary: Color(0xFF3E0FAD),
          primaryContainer: Color(0xFF6366F1),
          secondary: Color(0xFF10B981),
          secondaryContainer: Color(0xFF059669),
          surface: Colors.white,
          background: Color(0xFFF8FAFC),
          error: Color(0xFFEF4444),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF1F2937),
          onBackground: Color(0xFF1F2937),
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        useMaterial3: false,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          headlineLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF1F2937),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF374151),
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: Color(0xFF6B7280),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shadowColor: const Color(0xFF3E0FAD).withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3E0FAD), width: 2),
          ),
          labelStyle: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 16,
          ),
        ),
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
      ),
    );
  }
}
