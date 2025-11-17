
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
    // Future.delayed(const Duration(seconds: 3), () {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (context) => const LoginScreen()),
    //   );
    // });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: Color(0xfff6f6f6),
      body: Container(
        child: SizedBox(
          child: Column(
            children: [
              // Top section with logo and decorative elements

              Stack(
                children: [
                  // Decorative circles - responsive sizing
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
                  // Main content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: screenHeight * 0.25,
                        ),
                        // Logo - responsive height
                        Image.asset(
                          'assets/Senior Citizen.png',
                          fit: BoxFit.cover,
                          height: screenHeight * 0.2,
                        ),

                        // App name

                        SizedBox(height: screenHeight * 0.04),
                        Text(
                          'Your Safety, Our Priority',
                          style: TextStyle(
                            fontSize: screenWidth * 0.055,
                            color: Colors.black.withOpacity(0.74),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.035),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.2),
                          child: Text(
                            "Our Senior Citizen's safety app empowers you with one-tap SOS alerts, live location tracking, and a volunteer network ready to help in any emergency. Stay connected, stay safe, and get the support you need, whenever you need it.",
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.black.withOpacity(0.74),
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.035),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                          child: SizedBox(
                            width: screenWidth,
                            height: screenHeight * 0.06,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const LoginScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(1),
                                ),
                                elevation: 4,
                                shadowColor:
                                    const Color(0xFF3E0FAD).withOpacity(0.3),
                              ),
                              child: Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),

              // Bottom section with text and button
              // Expanded(
              //   flex: 2,
              //   child: Container(
              //     padding: const EdgeInsets.symmetric(horizontal: 32),
              //     child: Column(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         const Text(
              //           'Your Safety, Our Priority',
              //           style: TextStyle(
              //             fontSize: 28,
              //             fontWeight: FontWeight.bold,
              //             color: Color(0xFF1F2937),
              //           ),
              //           textAlign: TextAlign.center,
              //         ),
              //         const SizedBox(height: 16),
              //         Text(
              //           "Empowering senior citizens with instant SOS alerts, live location tracking, and a trusted volunteer network for emergency support.",
              //           style: TextStyle(
              //             fontSize: 16,
              //             color: Color(0xFF6B7280),
              //             height: 1.6,
              //           ),
              //           textAlign: TextAlign.center,
              //         ),
              //         const SizedBox(height: 40),
              //         // Get Started Button
              //         SizedBox(
              //           width: double.infinity,
              //           height: 56,
              //           child: ,
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
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
