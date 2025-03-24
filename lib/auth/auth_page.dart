import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mellow/auth/introduction/introduction.dart';
import 'package:mellow/screens/DashboardScreen/dashboard_screen.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If the snapshot has no data (still loading or error)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator()); // Show a loading indicator
          }

          // If the user is logged in
          if (snapshot.hasData) {
            return const DashboardScreen();
          } else {
            // If the user is not logged in
            return const IntroductionScreen();
          }
        },
      ),
    );
  }
}
