import 'package:flutter/material.dart';

class SpaceSettingScreen extends StatefulWidget {
  final String spaceId;

  const SpaceSettingScreen({super.key, required this.spaceId});

  @override
  State<SpaceSettingScreen> createState() => _SpaceSettingScreenState();
}

class _SpaceSettingScreenState extends State<SpaceSettingScreen> {
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
