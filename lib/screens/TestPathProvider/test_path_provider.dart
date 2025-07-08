import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class TestPathProvider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Path Provider'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              print('Attempting to get temporary directory...');
              final Directory tempDir = await getTemporaryDirectory();
              print('Temporary directory obtained: ${tempDir.path}');
            } catch (e) {
              print('Error getting temporary directory: $e');
            }
          },
          child: const Text('Test getTemporaryDirectory'),
        ),
      ),
    );
  }
}
