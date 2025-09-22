import 'dart:ui' as ui show PathMetric;

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
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _forgotIdentifierController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    String identifier = _identifierController.text.trim();
    String password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email/phone and password')));
      return;
    }

    try {
      bool isEmail = identifier.contains('@');
      var credentials = isEmail
          ? await _supabaseService.getUserCredentials(identifier)
          : await _supabaseService.getUserCredentialsByPhone(identifier);
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
      await _supabaseService.setCurrentUserEmail(credentials['email']);

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

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _forgotIdentifierController,
                decoration: const InputDecoration(hintText: 'Enter email or phone'),
              ),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'New password'),
              ),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Confirm password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String identifier = _forgotIdentifierController.text.trim();
                String newPass = _newPasswordController.text;
                String confirmPass = _confirmPasswordController.text;

                if (identifier.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                  return;
                }

                if (newPass != confirmPass) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                  return;
                }

                try {
                  await _supabaseService.updatePassword(identifier, newPass);
                  _forgotIdentifierController.clear();
                  _newPasswordController.clear();
                  _confirmPasswordController.clear();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
                } catch (e) {
                  if (e.toString().contains('User not found')) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found. Please create an account.')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 90),
                const Text(
                  'Welcome!',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 20),
                // App logo inside dashed border
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: DashedBorder(
                    color: Color(0xFFD1D5DB),
                    strokeWidth: 1,
                    dashWidth: 6,
                    dashGap: 4,
                    radius: 12,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        'assets/Senior Citizen.png',
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Email/Phone input field
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                  child: TextField(
                    controller: _identifierController,
                    decoration: InputDecoration(
                      hintText: 'Enter your email or phone number',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.text,
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
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text(
                        'Forgot Password',
                        style: TextStyle(
                          color: Colors.indigo,
                          fontSize: 14,
                        ),
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
                        borderRadius: BorderRadius.circular(8),
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
                    const Text("Don't have an account ? "),
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
                        'Start Enrollment',
                        style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}



// Dashed border widget and painter for the login logo box


class DashedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double radius;

  const DashedBorder({
    super.key,
    required this.child,
    this.color = const Color(0xFFD1D5DB),
    this.strokeWidth = 1,
    this.dashWidth = 6,
    this.dashGap = 4,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedRectPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        dashGap: dashGap,
        radius: radius,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double radius;

  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()..addRRect(rrect);
    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double next = (distance + dashWidth).clamp(0, metric.length);
        final segment = metric.extractPath(distance, next);
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap ||
        oldDelegate.radius != radius;
  }
}
