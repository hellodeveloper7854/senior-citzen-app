import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ComplaintStatusScreen extends StatefulWidget {
  const ComplaintStatusScreen({super.key});

  @override
  ComplaintStatusScreenState createState() => ComplaintStatusScreenState();
}

class ComplaintStatusScreenState extends State<ComplaintStatusScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  String? _userPhone;

  @override
  void initState() {
    super.initState();
    _loadUserComplaints();
  }

  Future<void> _loadUserComplaints() async {
    try {
      final phoneNumber = await _apiService.getCurrentUserPhoneNumber();
      print('📱 Loading complaints for phone: $phoneNumber');

      if (phoneNumber != null) {
        _userPhone = phoneNumber;
        final complaints = await _apiService.getUserComplaints(_userPhone!);

        print('✅ Retrieved ${complaints.length} complaints');
        for (var complaint in complaints) {
          print('  - Complaint: ${complaint['title']}, user_phone: ${complaint['user_phone']}, status: ${complaint['status']}');
        }

        setState(() {
          _complaints = complaints;
          _isLoading = false;
        });
        print('✅ State updated with ${complaints.length} complaints');
      } else {
        print('❌ Phone number is null');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading complaints: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load complaints: $e')),
      );
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'under_review':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    if (status == null) return 'Unknown';
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'under_review':
        return 'Under Review';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: Stack(
        children: [
          // Circular decorations same style as main screen
          Positioned(
            top: -50,
            left: -10,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff000BAA).withOpacity(0.45),
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
                color: Color(0xff000DFF).withOpacity(0.49),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          "My Complaints",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _complaints.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No complaints submitted yet",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadUserComplaints,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _complaints.length,
                                itemBuilder: (context, index) {
                                  final complaint = _complaints[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Status and Date
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(complaint['status']).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: _getStatusColor(complaint['status']).withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Text(
                                                  _getStatusText(complaint['status']),
                                                  style: TextStyle(
                                                    color: _getStatusColor(complaint['status']),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                _formatDate(complaint['submitted_at']),
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          // Title
                                          Text(
                                            complaint['title'] ?? 'No Title',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          // Description
                                          Text(
                                            complaint['description'] ?? 'No Description',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          // Location and Time (if available)
                                          if (complaint['location'] != null ||
                                              complaint['incident_date'] != null ||
                                              complaint['incident_time'] != null)
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 12),
                                                const Divider(),
                                                const SizedBox(height: 8),
                                                if (complaint['incident_date'] != null ||
                                                    complaint['incident_time'] != null)
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.event,
                                                        size: 16,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _formatIncidentDateTime(
                                                          complaint['incident_date'],
                                                          complaint['incident_time'],
                                                        ),
                                                        style: TextStyle(
                                                          color: Colors.grey.shade600,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                if (complaint['location'] != null)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.location_on,
                                                          size: 16,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            complaint['location'],
                                                            style: TextStyle(
                                                              color: Colors.grey.shade600,
                                                              fontSize: 12,
                                                            ),
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),

                                          // Admin Notes (if available)
                                          if (complaint['admin_notes'] != null &&
                                              complaint['admin_notes'].toString().trim().isNotEmpty)
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 12),
                                                const Divider(),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: Colors.blue.shade200,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.admin_panel_settings,
                                                            size: 16,
                                                            color: Colors.blue.shade700,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'Admin Notes',
                                                            style: TextStyle(
                                                              color: Colors.blue.shade700,
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        complaint['admin_notes'],
                                                        style: TextStyle(
                                                          color: Colors.blue.shade800,
                                                          fontSize: 13,
                                                          height: 1.3,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
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

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatIncidentDateTime(String? date, String? time) {
    String result = '';
    if (date != null) {
      result += _formatDate(date);
    }
    if (time != null) {
      if (result.isNotEmpty) result += ' ';
      result += time;
    }
    return result.isEmpty ? 'No date/time specified' : result;
  }
}