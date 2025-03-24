import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart'; // Import this package
import 'package:mellow/NetworkPage/no_network_page.dart';
import 'package:mellow/auth/auth_page.dart';
import 'package:mellow/auth/forgotpassword/fp_emailsent.dart';
import 'package:mellow/auth/signin/sign_in.dart';
import 'package:mellow/auth/signup/sign_up_email_verification.dart';
import 'package:mellow/auth/signup/sign_up_personal_details.dart';
import 'package:mellow/provider/BannerImageProvider/banner_image_provider.dart';
import 'package:mellow/provider/ProfileImageProvider/profile_image_provider.dart';
import 'package:mellow/screens/DashboardScreen/dashboard_screen.dart';
import 'package:mellow/screens/MessageScreen/message_screen.dart';
import 'package:mellow/screens/NotificationScreen/notification_screen.dart';
import 'package:mellow/screens/Policies/DataPrivacyAct/data_privacy_screen.dart';
import 'package:mellow/screens/ProfileScreen/SearchFriendsScreen/search_friends.dart';
import 'package:mellow/screens/ProfileScreen/profile_page.dart';
import 'package:mellow/screens/SettingsScreen/AccountInformation/UpdateEmail/email_update.dart';
import 'package:mellow/screens/SettingsScreen/ChangePassword/change_password.dart';
import 'package:mellow/screens/Policies/PrivacyPolicy/privacy_policy.dart';
import 'package:mellow/screens/SettingsScreen/ReportBugs/reportbugs_screen.dart';
import 'package:mellow/screens/SettingsScreen/SendFeedbackScreen/sendfeedback_screen.dart';
import 'package:mellow/screens/Policies/TermsOfService/terms_of_service.dart';
import 'package:mellow/screens/SettingsScreen/settings_drawer.dart';
import 'package:mellow/screens/SettingsScreen/settings_page.dart';
import 'package:mellow/screens/TaskCreation/task_creation.dart';
import 'package:mellow/screens/TaskCreation/task_creation_duo.dart';
import 'package:mellow/screens/TaskCreation/task_creation_space.dart';
import 'package:mellow/screens/TaskManagement/TaskHistory/task_history.dart';
import 'package:mellow/screens/TaskManagement/task_management.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Workmanager for periodic task checks
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  // Initialize notifications
  await _initializeNotifications();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileImageProvider()),
        ChangeNotifierProvider(create: (_) => BannerImageProvider()),
      ],
      child: const MellowApp(),
    ),
  );
}

Future<void> _initializeNotifications() async {
  // Android initialization settings
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // Initialization settings for all platforms
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  // Initialize the plugin with the new callback
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
  );
}

// Handle notification tapped logic
void _onDidReceiveNotificationResponse(NotificationResponse response) {
  final String? payload = response.payload;
  if (payload != null) {
    // Navigate to the task details page with the task name as payload
    navigatorKey.currentState?.pushNamed('/task_details', arguments: payload);
  }
}

// Handle notification tapped logic
Future<void> _onSelectNotification(String? payload) async {
  if (payload != null) {
    // Navigate to the task details page with the task name as payload
    // You need to provide a navigation context or use a navigator key
    navigatorKey.currentState?.pushNamed('/task_details', arguments: payload);
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    print("Background task executed: $task");
    return Future.value(true);
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MellowApp extends StatelessWidget {
  const MellowApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Restrict the app to portrait mode only
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      navigatorKey: navigatorKey, // Set the navigator key
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.grey),
        ),
      ),
      home: const NetworkCheckWrapper(),
      routes: {
        '/signin': (context) => const SignInPage(),
        '/emailVerification': (context) => const EmailVerification(),
        '/signup': (context) => const SignUpPersonalDetails(),
        '/dashboard': (context) {
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            return const DashboardScreen();
          } else {
            return const SignInPage();
          }
        },
        '/profile': (context) => const ProfilePage(),
        '/taskCreation': (context) => const TaskCreationScreen(),
        '/createDuoTask': (context) => const TaskCreationDuo(),
        '/createSpaceTask': (context) => const TaskCreationSpace(),
        '/taskManagement': (context) => const TaskManagementScreen(),
        '/emailSent': (context) => const ForgotPasswordEmailSent(),
        '/notification': (context) => const NotificationScreen(),
        '/settings': (context) => const SettingsPage(),
        '/settingsdrawer': (context) => const SettingsDrawer(),
        '/terms': (context) => const TermsOfService(),
        '/privacy': (context) => const PrivacyPolicy(),
        '/dataPrivacy': (context) => const DataPrivacyScreen(),
        '/change_email': (context) => const EmailUpdatePage(),
        '/change_password': (context) => const ChangePassword(),
        '/search_friends': (context) => const SearchFriends(),
        '/messages': (context) => const MessageScreen(),
        '/sendfeedback': (context) => const SendfeedbackScreen(),
        '/reportbugs': (context) => const ReportBugsScreen(),
        '/taskhistory': (context) => const TaskListScreen(),
        '/no_network': (context) => NoNetworkPage(),
      },
    );
  }
}

class NetworkCheckWrapper extends StatefulWidget {
  const NetworkCheckWrapper({super.key});

  @override
  _NetworkCheckWrapperState createState() => _NetworkCheckWrapperState();
}

class _NetworkCheckWrapperState extends State<NetworkCheckWrapper> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      setState(() {
        _isConnected =
            result.isNotEmpty && result.first != ConnectivityResult.none;
      });
      if (!_isConnected) {
        navigatorKey.currentState?.pushReplacementNamed('/no_network');
      }
    });
  }

  Future<void> _checkInitialConnection() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = result != ConnectivityResult.none;
    });
    if (!_isConnected) {
      navigatorKey.currentState?.pushReplacementNamed('/no_network');
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isConnected ? const AuthPage() : NoNetworkPage();
  }
}
