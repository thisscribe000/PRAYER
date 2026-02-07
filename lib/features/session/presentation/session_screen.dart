import 'package:flutter/material.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Session'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(child: Text('This screen is not used. Use PrayNowScreen instead.')),
    );
  }
}