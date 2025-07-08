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
// import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Add this function to handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Ensure Firebase is initialized
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // Change this in production
    appleProvider: AppleProvider.appAttest, // Use DeviceCheck if needed
  );

  // Initialize Workmanager for periodic task checks
  // Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  // Initialize notifications
  await _initializeNotifications();

  // Initialize Firebase Messaging
  await _initializeFirebaseMessaging();

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

// Initialize Firebase Messaging
Future<void> _initializeFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request notification permissions for iOS
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }

  // Get the FCM token for the device
  try {
    String? token = await messaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token'); // Use debugPrint for logging
    } else {
      debugPrint('Failed to retrieve FCM Token');
    }
  } catch (e) {
    debugPrint('Error retrieving FCM Token: $e');
  }

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received a foreground message: ${message.notification?.title}');
    _showForegroundNotification(message);
  });

  // Handle background messages
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Notification opened: ${message.notification?.title}');
    _handleNotificationTap(message);
  });

  // Handle terminated state messages
  RemoteMessage? initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    _handleNotificationTap(initialMessage);
  }
}

// Show a notification when the app is in the foreground
Future<void> _showForegroundNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'channel_id',
    'channel_name',
    channelDescription: 'channel_description',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    message.notification.hashCode,
    message.notification?.title,
    message.notification?.body,
    platformDetails,
    payload: message.data['payload'], // Pass any custom payload
  );
}

// Handle notification tap
void _handleNotificationTap(RemoteMessage message) {
  final String? payload = message.data['payload'];
  if (payload != null) {
    navigatorKey.currentState?.pushNamed('/task_details', arguments: payload);
  }
}

// Handle notification tapped logic
void _onDidReceiveNotificationResponse(NotificationResponse response) {
  final String? payload = response.payload;
  if (payload != null) {
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

// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) {
//     print("Background task executed: $task");
//     return Future.value(true);
//   });
// }

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
