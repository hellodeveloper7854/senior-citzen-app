import 'package:flutter/material.dart';

class TrackMeScreen extends StatelessWidget {
  const TrackMeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Me'),
      ),
      body: const Center(
        child: Text('Track Me Screen'),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Back'),
        ),
      ),
    );
  }
}