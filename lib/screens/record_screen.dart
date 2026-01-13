import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_service.dart';
import '../utils/permission_utils.dart';
import 'recording_status_screen.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  RecordScreenState createState() => RecordScreenState();
}

class RecordScreenState extends State<RecordScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ApiService _apiService = ApiService();
  bool _isRecording = false;
  bool _isUploading = false;
  String? _recordingPath;
  String? _currentUserPhone;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final phoneNumber = await _apiService.getCurrentUserPhoneNumber();
      if (phoneNumber != null) {
        setState(() {
          _currentUserPhone = phoneNumber;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }
  Future<void> _startRecording() async {
    try {
      // Check if platform is supported
      if (Platform.isWindows || Platform.isLinux || kIsWeb) {
        _showUnsupportedPlatformDialog();
        return;
      }

      // Request microphone permission if not granted
      final hasPermission = await PermissionUtils.requestMicrophonePermission(context);

      if (hasPermission) {
        // Create temporary directory path - use system temp directly to avoid path_provider issues
        final tempDir = Directory.systemTemp;
        final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _recordingPath = '${tempDir.path}\\$fileName';

        print('Recording path: $_recordingPath');

        // Check if recording is supported
        if (await _audioRecorder.hasPermission()) {
          await _audioRecorder.start(
            RecordConfig(
              encoder: AudioEncoder.aacLc, // Use AAC-LC encoder for better compatibility
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: _recordingPath!,
          );

          setState(() {
            _isRecording = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording started...')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission not granted')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for recording')),
        );
      }
    } catch (e) {
      print('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
    }
  }

  void _showUnsupportedPlatformDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 12),
              Text('Platform Not Supported'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audio recording is only supported on mobile platforms (Android & iOS).',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Please run this app on:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Android device or emulator'),
              Text('• iPhone or iPad'),
              SizedBox(height: 16),
              Text(
                'To run on Android:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '1. Connect an Android device or start an emulator',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              Text(
                '2. Run: flutter run -d android',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });

      if (path != null) {
        // Show confirmation dialog before uploading
        print('DEBUG: About to show upload confirmation dialog');
        final shouldUpload = await _showUploadConfirmationDialog();
        print('DEBUG: User chose to upload: $shouldUpload');

        if (shouldUpload == true && _currentUserPhone != null) {
          print('DEBUG: Starting upload process');
          await _uploadRecording(path);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recording uploaded successfully')),
            );
          }
        } else if (shouldUpload == false) {
          print('DEBUG: User chose not to upload, deleting local file');
          // Delete the local recording file if user chooses not to upload
          try {
            final file = File(path);
            if (await file.exists()) {
              await file.delete();
              print('DEBUG: Local file deleted successfully');
            }
          } catch (e) {
            print('DEBUG: Error deleting local file: $e');
            // Silently handle file deletion error
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recording saved locally')),
            );
          }
        } else {
          print('DEBUG: Dialog was dismissed or returned null');
          // If dialog was dismissed, keep the file locally
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recording saved locally')),
            );
          }
        }
      } else {
        print('DEBUG: Recording path is null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording completed')),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Error in _stopRecording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
        );
      }
    }
  }

  Future<bool> _showUploadConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Upload Recording',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Do you want to upload this recording to the police database? This will allow authorities to review your recording.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Keep Local',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E0FAD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Upload'),
            ),
          ],
        );
      },
    ) ?? false; // Return false if dialog is dismissed
  }

  Future<void> _uploadRecording(String filePath) async {
    if (_currentUserPhone == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(filePath);
      // Upload to backend (which handles Supabase upload and metadata saving)
      final downloadUrl = await _apiService.uploadAudioRecording(file, _currentUserPhone!);

      print('✅ Recording uploaded successfully: $downloadUrl');
    } catch (e) {
      print('❌ Error uploading recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload recording: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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

          // Main content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                SizedBox(height: 20),
                // Custom Header with back button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937), size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Record Complaints',
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Main content area
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title and subtitle
                      const Text(
                        "Record Complaints",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Your safety is our mission.\nRecording is started.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Waveform icon
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.graphic_eq,
                          size: 80,
                          color: _isRecording ? Colors.red : const Color(0xFF3E0FAD),
                        ),
                      ),

                      const SizedBox(height: 50),

                      // Mic Button
                      GestureDetector(
                        onTap: _isUploading ? null : (_isRecording ? _stopRecording : _startRecording),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecording ? Colors.red : (_isUploading ? Colors.grey : Colors.red),
                            boxShadow: [
                              BoxShadow(
                                color: (_isRecording ? Colors.red : Colors.red).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: _isUploading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Icon(
                                  _isRecording ? Icons.stop : Icons.mic,
                                  color: Colors.white,
                                  size: 35,
                                ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Recording Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _isUploading
                              ? 'Uploading recording...'
                              : _isRecording
                                  ? 'Recording... Tap to stop'
                                  : 'Tap to start recording',
                          style: TextStyle(
                            color: _isRecording ? Colors.red : const Color(0xFF6B7280),
                            fontSize: 16,
                            fontWeight: _isRecording ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // Check Recording Status Button
                Container(
                  width: double.infinity,
                  height: 56,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black87),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecordingStatusScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Check Recording Status",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Back Button
                Container(
                  width: double.infinity,
                  height: 56,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Back",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
