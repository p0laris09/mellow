import 'package:flutter/material.dart';

class CollaborationScreen extends StatelessWidget {
  const CollaborationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: null, // No app bar if you're relying on the one in HomeScreen
      body: Center(
        child: Text(
          "Collaboration Screen",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
