import 'package:flutter/material.dart';
import 'package:mellow/auth/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mellow/auth/signin/sign_in.dart';
import 'package:mellow/auth/signup/sign_up_personal_details.dart';
import 'package:mellow/screens/HomeScreen/home_screen.dart';
import 'package:mellow/screens/ProfileScreen/profile_page.dart';
import 'package:mellow/screens/TaskCreation/task_creation.dart';
import 'package:mellow/screens/TaskManagement/task_management.dart'; // Import the Task Management screen
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Workmanager for periodic task checks
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  runApp(const MellowApp());
}

// Background callback to check tasks
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    print("Background task executed: $task");
    // You can add your task checking code here
    return Future.value(true);
  });
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
      home:
          const AuthPage(), // This page decides where to navigate based on user authentication
      routes: {
        '/signin': (context) => SignInPage(), // SignInPage route
        '/signup': (context) => SignUpPersonalDetails(), // SignUpPage route
        '/home': (context) {
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            return const HomeScreen(); // Navigate to HomeScreen if authenticated
          } else {
            return SignInPage(); // Redirect to sign-in if no user is logged in
          }
        },
        '/profile': (context) => const ProfilePage(),
        '/taskCreation': (context) =>
            const TaskCreationScreen(), // Task Creation route
        '/taskManagement': (context) =>
            TaskManagementScreen(), // Task Management route
      },
    );
  }
}
