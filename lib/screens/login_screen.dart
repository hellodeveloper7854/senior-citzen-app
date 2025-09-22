import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'dashboard_screen.dart';
import 'under_verification_screen.dart';
import 'rejected_screen.dart';
import '../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email and password')));
      return;
    }

    try {
      var credentials = await _supabaseService.getUserCredentials(email);
      if (credentials == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User doesn\'t exist')));
        return;
      }

      if (credentials['password'] != password) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please use correct password')));
        return;
      }

      // Get profile
      var profile = await _supabaseService.getUserProfileByPhone(credentials['phone_number']);
      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile not found')));
        return;
      }

      // Store current user email
      await _supabaseService.setCurrentUserEmail(email);

      if (profile['status'] == 'verified') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else if (profile['status'] == 'rejected') {
        // Navigate to rejected screen with rejection reason
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RejectedScreen(
              rejectionReason: profile['rejection_reason'] ?? 'No reason provided',
            ),
          ),
        );
      } else {
        // Navigate to under verification screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UnderVerificationScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Light background color similar to image
      body: SafeArea(
        child: Stack(
          children: [
            // Top circles decoration
            Positioned(
              top: -60,
              left: -60,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: -30,
              left: 70,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 120),
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                // Placeholder Image with dashed border
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      style: BorderStyle.solid, // Dashed border needs custom painter (simplified here)
                      width: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    'assets/undraw_my_notifications_rjej.png', // Replace with your image asset path
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 30),
                // Email input field
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                // Password input field
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                // Forgot Password Text Button
                Container(
                  margin: const EdgeInsets.only(right: 30, top: 5),
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Forgot password action
                    },
                    child: const Text(
                      'Forgot Password',
                      style: TextStyle(
                        color: Colors.indigo,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                // Sign In Button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: _login,
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                // Sign Up text with navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(color: Colors.indigo),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

