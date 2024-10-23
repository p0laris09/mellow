import 'package:flutter/material.dart';
import 'package:mellow/auth/signin/sign_in.dart'; // Make sure this is imported

class ForgotPasswordEmailSent extends StatelessWidget {
  const ForgotPasswordEmailSent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center the content
          children: [
            // Email sent icon (Material Icons has an email icon)
            const Icon(
              Icons.email_outlined,
              size: 100,
              color: Colors.black54, // Light black color
            ),
            const SizedBox(height: 30), // Space between icon and text

            // Message to the user
            const Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 32.0), // Padding to center the text properly
              child: Text(
                "Please check your inbox for the\npassword reset link.",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40), // Space between text and button

            // Button to go back to Sign In Page
            SizedBox(
              width: 315,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the SignInPage
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => SignInPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF2C3C3C), // Matches theme
                ),
                child: const Text(
                  "Back to Sign In",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
