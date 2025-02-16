import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          // Top section with the image
          Expanded(
            child: Container(
              color: const Color(
                  0xFF2275AA), // Background color for the image area
              child: Center(
                child: Image.asset(
                  'assets/img/onboarding.png', // Replace with your image asset path
                  height: 400, // Adjust height as needed
                ),
              ),
            ),
          ),
          // Bottom section with title, description, and buttons
          Container(
            padding: const EdgeInsets.all(20),
            color:
                const Color(0xFF2275AA), // Background color for bottom section
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Title
                const Text(
                  "Mellow",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                // Subtitle
                const Text(
                  "The new Task Manager App that will help students handle their tasks and manage their time better where they can collaborate with friends and peers.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),
                // SIGN IN Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signin');
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFF2275AA),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 80,
                    ),
                  ),
                  child: const Text(
                    "SIGN IN",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // SIGN UP Button
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 80,
                    ),
                  ),
                  child: const Text(
                    "SIGN UP",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
