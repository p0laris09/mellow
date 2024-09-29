import 'package:flutter/material.dart';
import 'package:mellow/auth/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:mellow/auth/signin/sign_in.dart';
import 'package:mellow/auth/signup/sign_up_personal_details.dart';
import 'package:mellow/screens/HomeScreen/home_screen.dart';
import 'package:mellow/screens/ProfileScreen/profile_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MellowApp());
}

class MellowApp extends StatelessWidget {
  const MellowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.grey),
        ),
      ),
      home: AuthPage(), // This page decides where to navigate based on user authentication
      routes: {
        '/signin': (context) => SignInPage(), // SignInPage route
        '/signup': (context) => SignUpPersonalDetails(), // SignUpPage route
        // Home route only navigates when user is not null
        '/home': (context) {
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            return HomeScreen(uid: user.uid); // Pass the user's uid correctly
          } else {
            return SignInPage(); // Redirect to sign-in if no user is logged in
          }
        },
        '/profile': (context) => const ProfilePage(), 
      },
    );
  }
}
