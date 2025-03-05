import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NoNetworkPage extends StatelessWidget {
  NoNetworkPage({super.key});

  bool _navigated = false;

  Future<void> _checkConnectivity(BuildContext context) async {
    final result = await Connectivity().checkConnectivity();
    if (result != ConnectivityResult.none || _navigated) {
      // If there is connectivity or already navigated, navigate back to the home page
      _navigated = true;
      Navigator.pushReplacementNamed(context, '/');
    } else {
      // If there is still no connectivity, show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No network connection. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'No Network',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2275AA),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off,
                size: 100,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 20),
              const Text(
                'No Network Connection',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please connect to the internet and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black38,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _checkConnectivity(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2275AA),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
