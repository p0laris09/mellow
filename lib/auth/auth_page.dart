import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mellow/screens/HomeScreen/home_screen.dart';
import 'package:mellow/auth/onboarding/onboarding.dart';

class AuthPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If the user is logged in
          if (snapshot.hasData) {
            User? user = snapshot.data;
            return HomeScreen(uid: user!.uid); // Ensure the correct named parameter
          } else {
            // If the user is not logged in
            return OnboardingPage();
          }
        },
      ),
    );
  }
}
