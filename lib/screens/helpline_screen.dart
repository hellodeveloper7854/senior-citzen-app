import 'package:flutter/material.dart';
import 'national_helpline_screen.dart';
import 'register_complaint_screen.dart';
import 'hospital_helpline_screen.dart';

class HelplineScreen extends StatelessWidget {
  const HelplineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA), // Light gray background
      body: Stack(
        children: [
          // Circular decorations - responsive
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

          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenHeight * 0.045),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.02,),
                  // Header with back button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            "Helpline Numbers",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.05,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.12), // Balance the back button
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // --- First Card: Ask for help ---
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HospitalHelplineScreen(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.0375),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 10,
                            color: Colors.black12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Row(
                        children: [
                          // Support agent icon with blue background
                          Container(
                            width: screenWidth * 0.125,
                            height: screenWidth * 0.125,
                            decoration: const BoxDecoration(

                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Image.asset("assets/help.png", width: screenWidth * 0.1,),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hospital Contacts",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: screenWidth * 0.04,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  "Hospital contact info",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.0325,
                                    color: Colors.black54,
                                      // color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Support text badge
                          // Container(
                          //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          //   decoration: BoxDecoration(
                          //     color: const Color(0xFF4A90E2),
                          //     borderRadius: BorderRadius.circular(12),
                          //   ),
                          //   child: const Text(
                          //     "SUPPORT",
                          //     style: TextStyle(
                          //       color: Colors.white,
                          //       fontSize: 10,
                          //       fontWeight: FontWeight.w600,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.006),

                  // "Thane Police's Helpline" text
                  Text(
                    "Hospital Contacts Numbers",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.035,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),

                  // --- Second Card: National Helpline ---
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NationalHelplineScreen(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.0375),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 10,
                            color: Colors.black12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Row(
                        children: [
                          // Help icon with red/pink background
                          Container(
                            width: screenWidth * 0.125,
                            height: screenWidth * 0.125,
                            decoration: const BoxDecoration(
                              // color: Color(0xFFE53E3E),
                              shape: BoxShape.circle,
                            ),
                            child:  Center(
                              child:Image.asset("assets/help.png", width: screenWidth * 0.1),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "National Helpline",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: screenWidth * 0.04,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  "Common Helpline Numbers of country are listed here.",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.0325,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.006),
                  // "Common Helpline Numbers" text
                  Text(
                    "Common Helpline Numbers",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.035,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.055,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.01),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Back",
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w500,
                          color: Colors.white
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
