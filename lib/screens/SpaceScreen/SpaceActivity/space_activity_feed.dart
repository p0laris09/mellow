import 'package:flutter/material.dart';

class SpaceActivityFeedScreen extends StatefulWidget {
  final String spaceId;

  const SpaceActivityFeedScreen({super.key, required this.spaceId});

  @override
  State<SpaceActivityFeedScreen> createState() =>
      _SpaceActivityFeedScreenState();
}

class _SpaceActivityFeedScreenState extends State<SpaceActivityFeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Space Activities'),
        backgroundColor: const Color(0xFF2275AA),
      ),
      body: Center(
        child: Text('Activities for space: ${widget.spaceId}'),
      ),
    );
  }
}
