import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mellow/screens/DashboardScreen/dashboard_screen.dart';
import 'package:mellow/auth/onboarding/onboarding.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If the user is logged in
          if (snapshot.hasData) {
            return const DashboardScreen();
          } else {
            // If the user is not logged in
            return OnboardingPage();
          }
        },
      ),
    );
  }
}
