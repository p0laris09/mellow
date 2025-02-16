import 'package:flutter/material.dart';
import 'package:mellow/auth/signin/sign_in.dart'; // Adjust the import path if necessary

class EmailVerification extends StatefulWidget {
  const EmailVerification({super.key});

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
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
                "An email verification link has been sent \nto your email. Click it to verify before \nsigning in.",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40), // Space between text and button

            // Button to go back to Dashboard Page
            SizedBox(
              width: 315,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the DashboardPage
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF2275AA), // Matches theme
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
