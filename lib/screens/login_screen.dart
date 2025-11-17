import 'dart:ui' as ui show PathMetric;

import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
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

  // Hash password using SHA-256 (same method as in SupabaseService)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    // return digest.toString();
    return password;
  }

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

      if (credentials['password'] != _hashPassword(password)) {
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
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: Color(0xfff6f6f6),
      body: SingleChildScrollView(
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
          width: double.infinity,
          height: screenHeight * 0.25,
          child: Stack(
          children: [
          // Decorative circles - responsive
          Positioned(
          top: -screenHeight * 0.06,
            left: -screenWidth * 0.03,
            child: Container(
              width: screenWidth * 0.5,
              height: screenWidth * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff000BAA).withOpacity(0.45),
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.01,
            left: -screenWidth * 0.2,
            child: Container(
              width: screenWidth * 0.5,
              height: screenWidth * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff000DFF).withOpacity(0.49),
              ),
            ),
          ),
                  ]),
        ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              'Welcome!',
              style: TextStyle(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            // Header with logo and title
            Container(
              padding: EdgeInsets.all(screenWidth * 0.06),
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo - responsive
                  Center(
                    child: Image.asset(
                      'assets/Senior Citizen.png',
                      fit: BoxFit.cover,
                      height: screenHeight * 0.2,
                    ),
                  ),


                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            // Login Form
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email/Phone input field
                  SizedBox(height: screenHeight * 0.01),
                  TextField(
                    controller: _identifierController,
                    style: TextStyle(fontSize: screenWidth * 0.04),
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: screenWidth * 0.04),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.025, horizontal: screenWidth * 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.125),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.125),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.125),
                        borderSide: const BorderSide(color: Color(0xFF3E0FAD), width: 2),
                      ),

                    ),
                    keyboardType: TextInputType.text,
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  // Password input field
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: TextStyle(fontSize: screenWidth * 0.04),
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: screenWidth * 0.04),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.025, horizontal: screenWidth * 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.125),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.125),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.125),
                        borderSide: const BorderSide(color: Color(0xFF3E0FAD), width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Color(0xFF9CA3AF),
                          size: screenWidth * 0.06,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  // Forgot Password
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF3E0FAD),
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // Sign In Button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.06,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(1),
                          ),
                          elevation: 2,
                          shadowColor: const Color(0xFF3E0FAD).withOpacity(0.3),
                        ),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.03),

            // Sign Up section
            Container(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "Don’t have an account? ",
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Color(0xFF64748B),
                  ),
                  children: [
                    TextSpan(
                      text: "Start Enrollment",
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E0FAD),
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                    ),
                  ],
                ),
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
