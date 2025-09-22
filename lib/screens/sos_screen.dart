import 'package:flutter/material.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850], // Dark background color similar to image
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Overlapping CircleAvatars for Police and User
            Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const CircleAvatar(
        radius: 40,
        backgroundImage: NetworkImage(
          'https://via.placeholder.com/100x100?text=Police',
        ),
      ),
    ),
    // Replace SizedBox with a Transform to shift the second avatar left, creating an overlap
    Transform.translate(
      offset: const Offset(-15, 0), // Move left by 15 pixels
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const CircleAvatar(
          radius: 40,
          backgroundImage: NetworkImage(
            'https://via.placeholder.com/100x100?text=User',
          ),
        ),
      ),
    ),
  ],
),
            const SizedBox(height: 10),
            // Text "Calling....Police"
            const Text(
              'Calling....Police',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            // Map image placeholder (use NetworkImage of the map shown or replace with your map widget)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    'https://i.imgur.com/FakeMapImage.png', // Replace with actual map image URL or your map widget
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Red circular close button
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.all(20),
                  elevation: 5,
                ),
                child: const Icon(
                  Icons.close,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}