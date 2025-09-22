import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decorative circles at top-left
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF4B56D2), // blue color opaque
              ),
            ),
          ),
          Positioned(
            top: -40,
            left: 40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4B56D2).withOpacity(0.5),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  const Center(
                    child: Text(
                      'Welcome Onboard!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Your safety is our mission.\nTogether, let\'s create a safer world for every Senior Citizen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form fields
                  _buildTextField('Enter your full name', TextInputType.name),
                  const SizedBox(height: 16),
                  _buildTextField('Enter Birth Date', TextInputType.datetime),
                  const SizedBox(height: 16),
                  _buildTextField('Enter Mobile No.', TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField('Enter your email', TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildTextField('Enter password', TextInputType.text, obscureText: true),
                  const SizedBox(height: 16),
                  _buildTextField('Confirm Password', TextInputType.text, obscureText: true),
                  const SizedBox(height: 32),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      ),
                      onPressed: () {
                        // Add register logic here
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFFFFFFFF),

                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Already have an account? Sign In
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign In',
                            style: const TextStyle(
                              color: Color(0xFF4B56D2),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, TextInputType keyboardType, {bool obscureText = false}) {
    return TextField(
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
      ),
    );
  }
}