import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class MyFeedbacksScreen extends StatefulWidget {
  const MyFeedbacksScreen({super.key});

  @override
  _MyFeedbacksScreenState createState() => _MyFeedbacksScreenState();
}

class _MyFeedbacksScreenState extends State<MyFeedbacksScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _feedbacks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    try {
      final email = await _supabaseService.getCurrentUserEmail();
      if (email != null) {
        final credentials = await _supabaseService.getUserCredentials(email);
        if (credentials != null) {
          final userPhone = credentials['phone_number'];
          final feedbacks = await _supabaseService.getUserFeedback(userPhone);
          setState(() {
            _feedbacks = feedbacks;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // Handle error silently for production
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown date';

    DateTime parsedDate;
    if (date is String) {
      try {
        parsedDate = DateTime.parse(date);
      } catch (e) {
        return 'Invalid date';
      }
    } else if (date is DateTime) {
      parsedDate = date;
    } else {
      return 'Unknown date';
    }

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final day = parsedDate.day.toString().padLeft(2, '0');
    final month = months[parsedDate.month - 1];
    final year = parsedDate.year;
    final hour = parsedDate.hour.toString().padLeft(2, '0');
    final minute = parsedDate.minute.toString().padLeft(2, '0');
    final period = parsedDate.hour >= 12 ? 'PM' : 'AM';

    return '$day $month $year, $hour:$minute $period';
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rating = feedback['rating'] as int? ?? 0;
    final hasReply = feedback['reply'] != null && feedback['reply'].toString().isNotEmpty;
    final replyDate = feedback['reply_date'];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: hasReply
            ? Border.all(color: Colors.green.shade300, width: 1.5)
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with rating and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Your Rating',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: index < rating ? Colors.amber : Colors.grey[300],
                          size: screenWidth * 0.05,
                        );
                      }),
                    ),
                  ],
                ),
                Text(
                  _formatDate(feedback['submitted_at']),
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),

            SizedBox(height: screenWidth * 0.03),

            // User feedback
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.035),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: Colors.blue.shade600, size: screenWidth * 0.05),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Your Feedback',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Text(
                    feedback['feedback'] as String? ?? 'No feedback text',
                    style: TextStyle(
                      fontSize: screenWidth * 0.038,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Admin reply section (if exists)
            if (hasReply) ...[
              SizedBox(height: screenWidth * 0.03),

              // Reply header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.01),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    child: Text(
                      'REPLY RECEIVED',
                      style: TextStyle(
                        fontSize: screenWidth * 0.025,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (replyDate != null)
                    Text(
                      _formatDate(replyDate),
                      style: TextStyle(
                        fontSize: screenWidth * 0.025,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),

              SizedBox(height: screenWidth * 0.02),

              // Reply content
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth * 0.035),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: Colors.green.shade600, size: screenWidth * 0.05),
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          'Admin Response',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Text(
                      feedback['reply'] as String? ?? 'No reply text',
                      style: TextStyle(
                        fontSize: screenWidth * 0.038,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(height: screenWidth * 0.03),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth * 0.025),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.orange.shade600, size: screenWidth * 0.04),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      'Pending reply from admin',
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        color: Colors.orange.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -screenSize.height * 0.06,
            left: -screenWidth * 0.03,
            child: Container(
              width: screenWidth * 0.5,
              height: screenWidth * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff000BAA).withOpacity(0.45),
              ),
            ),
          ),
          Positioned(
            top: screenSize.height * 0.01,
            left: -screenWidth * 0.2,
            child: Container(
              width: screenWidth * 0.5,
              height: screenWidth * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff000DFF).withOpacity(0.49),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: const Color(0xFF1F2937), size: screenWidth * 0.07),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'My Feedbacks',
                          style: TextStyle(
                            color: const Color(0xFF1F2937),
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.12), // Balance the header
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3E0FAD)),
                          ),
                        )
                      : _feedbacks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.feedback_outlined,
                                    size: screenWidth * 0.2,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: screenWidth * 0.05),
                                  Text(
                                    'No feedbacks yet',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.05,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: screenWidth * 0.02),
                                  Text(
                                    'Share your experience and help us improve',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadFeedbacks,
                              color: const Color(0xFF3E0FAD),
                              child: ListView.builder(
                                padding: EdgeInsets.only(bottom: screenWidth * 0.04),
                                itemCount: _feedbacks.length,
                                itemBuilder: (context, index) {
                                  return _buildFeedbackCard(_feedbacks[index]);
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}