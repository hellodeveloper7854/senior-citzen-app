import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tbxihxtvocurqsygfknk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRieGloeHR2b2N1cnFzeWdma25rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzNjE5OTMsImV4cCI6MjA3MzkzNzk5M30.cLBscTAW3UaixNphFs-MYnvoRTKg0hMPtN6gbHoezt4',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'स्नेहबंध',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
