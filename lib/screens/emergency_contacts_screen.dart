import 'package:flutter/material.dart';
// Removed: import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top circle decoration
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 150,
                  color: Colors.white,
                ),
                Positioned(
                  top: -60,
                  left: -60,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B5998), // Deep blue color similar to image
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title and subtitle
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Column(
                children: [
                  Text(
                    'Emergency Contact',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your safety is our mission.\nWho do you want to SMS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Contact buttons list (Husband, Son, Daughter, Friend)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    _ContactButton(
                      label: 'Husband',
                      icon: Icons.person,
                      iconColor: Colors.blue,
                      onPressed: () {
                        // Handle SMS via WhatsApp or other
                      },
                    ),
                    const SizedBox(height: 15),
                    _ContactButton(
                      label: 'Son',
                      icon: Icons.child_care,
                      iconColor: Colors.red,
                      onPressed: () {},
                    ),
                    const SizedBox(height: 15),
                    _ContactButton(
                      label: 'Daughter',
                      icon: Icons.face_retouching_natural,
                      iconColor: Colors.orange,
                      onPressed: () {},
                    ),
                    const SizedBox(height: 15),
                    _ContactButton(
                      label: 'Friend',
                      icon: Icons.people,
                      iconColor: Colors.purple,
                      onPressed: () {},
                    ),
                    const Spacer(),

                    // Back button
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
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

class _ContactButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  const _ContactButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFBDF3AE), // Light green background
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side with label and person icon in circle
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              children: [
                // Circle avatar with icon
                CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white,
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // WhatsApp icon button in circle with green background
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GestureDetector(
              onTap: onPressed,
              child: Container(
                width: 35,
                height: 35,
                decoration: const BoxDecoration(
                  color: Color(0xFF12B54C), // WhatsApp green color
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.contact_emergency,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}