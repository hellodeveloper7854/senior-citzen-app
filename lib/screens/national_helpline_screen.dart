import 'package:flutter/material.dart';

class NationalHelplineScreen extends StatelessWidget {
  const NationalHelplineScreen({super.key});

  final List<Map<String, String>> helplines = const [
    {"title": "Police", "number": "112"},
    {"title": "Ambulance", "number": "108"},
    {"title": "Women Helpline", "number": "1091"},
    {"title": "Senior Citizen", "number": "1090"},
    {"title": "Fire", "number": "101"},
    {"title": "National Helpline", "number": "14567"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: Stack(
        children: [
          // Circle Decorations
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -30,
            left: 60,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(99, 102, 241, 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "National Helpline",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your safety is our mission.\nWho do you want to SMS.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Helpline Buttons List
                  Expanded(
                    child: ListView.separated(
                      itemCount: helplines.length,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = helplines[index];
                        return Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 184, 238, 161),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left side text
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item["title"]!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      item["number"]!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // WhatsApp icon container
                              Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366), // WhatsApp green
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Icon(
                                  Icons.contact_emergency,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Back", style: TextStyle(fontSize: 16,color: Colors.white)),
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