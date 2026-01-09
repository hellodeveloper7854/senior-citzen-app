import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import '../services/supabase_service.dart';

class NationalHelplineScreen extends StatefulWidget {
  const NationalHelplineScreen({super.key});

  @override
  State<NationalHelplineScreen> createState() => _NationalHelplineScreenState();
}

class _NationalHelplineScreenState extends State<NationalHelplineScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _helplines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHelplines();
  }

  Future<void> _loadHelplines() async {
    final helplines = await _supabaseService.getNationalHelplines();
    if (mounted) {
      setState(() {
        _helplines = helplines;
        _isLoading = false;
      });
    }
  }

  // Function to initiate a phone call
  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      // Show an error message if the dialer can't be opened
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open dialer for $phoneNumber')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: Stack(
        children: [
          // Circle Decorations
          Positioned(
            top: -50,
            left: -10,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Using a non-hex color literal here, replacing with a standard Flutter color expression
                color: const Color(0xff000BAA).withOpacity(0.45),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Using a non-hex color literal here, replacing with a standard Flutter color expression
                color: const Color(0xff000DFF).withOpacity(0.49),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Header with back button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            "National Helpline",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Correcting the subtitle to reflect the call functionality, not SMS
                  const Text(
                    "Tap any contact to initiate a call directly.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Show loading indicator or helpline list
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _helplines.isEmpty
                          ? const Center(
                              child: Text(
                                'No helpline numbers available',
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          : Expanded(
                              child: ListView.separated(
                                itemCount: _helplines.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final item = _helplines[index];

                        // Wrap the container in InkWell to make it tappable and show ripple effect
                        return InkWell(
                          onTap: () => _makePhoneCall(context, item['phone_number'] ?? ''),
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              // Using a standard Flutter color expression instead of non-hex literal
                              color: const Color(0xff24ff00).withOpacity(.25),
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
                                        item['title'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        item['phone_number'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Phone/Call icon container (Changed from WhatsApp to Phone/Emergency for helplines)
                                Container(
                                  width: 44,
                                  height: 44,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3E0FAD), // Using a distinct color for call
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: const Icon(
                                    Icons.call, // Changed icon to represent call/dialer
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
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
