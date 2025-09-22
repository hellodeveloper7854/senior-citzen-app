import 'package:flutter/material.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to auth choice screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          // Status bar with time and battery
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 50,
              color: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  right: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '9:45',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                   
                  ],
                ),
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              // Top section (reduced height so bottom text shows)
              Expanded(
                flex: 4, // 🔹 Reduced from 5 to 4
                child: Stack(
                  children: [
                    // Blue circles
                    Positioned(
                      top: -80,
                      left: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x7D000DFF),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -40,
                      left: 40,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x7D000DFF),
                        ),
                      ),
                    ),
                     // Main illustration
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/Senior Citizen.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                      // const SizedBox(height: 12),
                      // const Text(
                      //   'आधारवड',
                      //   style: TextStyle(
                      //     fontSize: 36,
                      //     fontWeight: FontWeight.w800,
                      //     color: Color(0xFFCC5A0B),
                      //     letterSpacing: 1.0,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
              
                    
                  ],
                ),
              ),
              
             
              // Bottom section with text + button
              Expanded(
                flex: 3,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          'Your Safety, Our Priority',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Our Senior Citizen's safety app empowers you with one-tap SOS alerts, live location tracking, and a volunteer network ready to help in any emergency. Stay connected, stay safe, and get the support you need, whenever you need it.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        const SizedBox(height: 10),
                        SizedBox(
                            height:
                                MediaQuery.of(context).padding.bottom + 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashHeight = 8.0;
    const dashSpace = 6.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
