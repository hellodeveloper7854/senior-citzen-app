import 'package:flutter/material.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  RecordScreenState createState() => RecordScreenState();
}

class RecordScreenState extends State<RecordScreen> {
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Record"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),

            // Title
            const Text(
              "Record",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your safety is our mission.\nRecording is started.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),

            const SizedBox(height: 50),

            // Waveform icon (replace with custom if you have one)
            Icon(
              Icons.graphic_eq,
              size: 120,
              color: Colors.black,
            ),

            const SizedBox(height: 40),

            // Mic Button
            GestureDetector(
              onTap: () {
                setState(() {
                  _isRecording = !_isRecording;
                });
              },
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Colors.red,
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 35,
                ),
              ),
            ),

            const Spacer(),

            // Back Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Back"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
