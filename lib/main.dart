import 'package:flutter/material.dart';
import 'package:mellow/auth/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mellow/auth/forgotpassword/fp_emailsent.dart';
import 'package:mellow/auth/signin/sign_in.dart';
import 'package:mellow/auth/signup/sign_up_personal_details.dart';
import 'package:mellow/provider/BannerImageProvider/banner_image_provider.dart';
import 'package:mellow/provider/ProfileImageProvider/profile_image_provider.dart';
import 'package:mellow/screens/DashboardScreen/dashboard_screen.dart';
import 'package:mellow/screens/NotificationScreen/notification_screen.dart';
import 'package:mellow/screens/ProfileScreen/profile_page.dart';
import 'package:mellow/screens/SettingsScreen/settings_screen.dart';
import 'package:mellow/screens/TaskCreation/task_creation.dart';
import 'package:mellow/screens/TaskManagement/task_management.dart'; // Import the Task Management screen
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Workmanager for periodic task checks
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  runApp(
    MultiProvider(
      // Use MultiProvider to provide multiple providers
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileImageProvider()),
        ChangeNotifierProvider(create: (_) => BannerImageProvider()),
      ],
      child: const MellowApp(),
    ),
  );
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
        scaffoldBackgroundColor:
            const Color(0xFFF4F6F8), // Set the background color for all screens
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
        '/dashboard': (context) {
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            return const DashboardScreen(); // Navigate to HomeScreen if authenticated
          } else {
            return SignInPage(); // Redirect to sign-in if no user is logged in
          }
        },
        '/profile': (context) => const ProfilePage(),
        '/taskCreation': (context) =>
            const TaskCreationScreen(), // Task Creation route
        '/taskManagement': (context) =>
            TaskManagementScreen(), // Task Management route
        '/emailSent': (context) => const ForgotPasswordEmailSent(),
        '/notification': (context) => const NotificationScreen(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
