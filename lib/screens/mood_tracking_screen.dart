import 'package:flutter/material.dart';

class MoodTrackingScreen extends StatelessWidget {
  const MoodTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Tracking')),
      body: const Center(child: Text('How are you feeling today?')),
    );
  }
}
