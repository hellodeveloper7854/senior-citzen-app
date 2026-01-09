import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/supabase_service.dart';

class RecordingStatusScreen extends StatefulWidget {
  const RecordingStatusScreen({super.key});

  @override
  RecordingStatusScreenState createState() => RecordingStatusScreenState();
}

class RecordingStatusScreenState extends State<RecordingStatusScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, dynamic>> _recordings = [];
  bool _isLoading = true;
  String? _userPhone;
  bool _isPlaying = false;
  String? _playingUrl;

  @override
  void initState() {
    super.initState();
    _loadUserRecordings();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadUserRecordings() async {
    try {
      final email = await _supabaseService.getCurrentUserEmail();
      if (email != null) {
        final credentials = await _supabaseService.getUserCredentials(email);
        if (credentials != null) {
          _userPhone = credentials['phone_number'];
          final recordings = await _supabaseService.getUserRecordings(_userPhone!);
          setState(() {
            _recordings = recordings;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load recordings: $e')),
      );
    }
  }

  Future<void> _playRecording(String url) async {
    try {
      if (_isPlaying && _playingUrl == url) {
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
          _playingUrl = null;
        });
      } else {
        await _audioPlayer.stop(); // Stop any current playback
        await _audioPlayer.play(UrlSource(url));
        setState(() {
          _isPlaying = true;
          _playingUrl = url;
        });

        _audioPlayer.onPlayerComplete.listen((event) {
          setState(() {
            _isPlaying = false;
            _playingUrl = null;
          });
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play recording: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.green;
      case 'archived':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'reviewed':
        return 'Reviewed';
      case 'archived':
        return 'Archived';
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
                          "My Recordings",
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
                      : _recordings.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.mic_none,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No recordings uploaded yet",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadUserRecordings,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _recordings.length,
                                itemBuilder: (context, index) {
                                  final recording = _recordings[index];
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
                                                  color: _getStatusColor(recording['status']).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: _getStatusColor(recording['status']).withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Text(
                                                  _getStatusText(recording['status']),
                                                  style: TextStyle(
                                                    color: _getStatusColor(recording['status']),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                _formatDate(recording['recorded_at']),
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          // Recording Info
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF3E0FAD).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.mic,
                                                  color: const Color(0xFF3E0FAD),
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Audio Recording",
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 16,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "Uploaded for police review",
                                                      style: TextStyle(
                                                        color: Colors.grey.shade600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (recording['audio_url'] != null)
                                                IconButton(
                                                  icon: Icon(
                                                    _isPlaying && _playingUrl == recording['audio_url']
                                                        ? Icons.stop
                                                        : Icons.play_arrow,
                                                    color: const Color(0xFF3E0FAD),
                                                    size: 28,
                                                  ),
                                                  onPressed: () => _playRecording(recording['audio_url']),
                                                ),
                                            ],
                                          ),

                                          // Police Station Info
                                          if (recording['police_station'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 12),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.local_police,
                                                      size: 16,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      "Police Station: ${recording['police_station']}",
                                                      style: TextStyle(
                                                        color: Colors.grey.shade700,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                          // Admin Notes (if available)
                                          if (recording['notes'] != null && recording['notes'].toString().trim().isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 12),
                                              child: Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.blue.shade200),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(Icons.admin_panel_settings, color: Colors.blue.shade600, size: 16),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          'Notes',
                                                          style: TextStyle(
                                                            color: Colors.blue.shade800,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      recording['notes'],
                                                      style: TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: 14,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
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
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}