import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  bool _notificationsEnabled = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _checkNotificationPermission(); // Check permission status
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/logo');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
  }

  // Check notification permission status
  Future<void> _checkNotificationPermission() async {
    PermissionStatus status = await Permission.notification.status;
    setState(() {
      _notificationsEnabled = status.isGranted;
    });
  }

  void _toggleNotifications(bool? value) async {
    if (_isRequestingPermission) {
      return; // Prevent multiple permission requests
    }

    print(
        'Toggle switch clicked. Value: $value'); // Print the toggle switch value

    if (value ?? false) {
      // Enable notifications
      print('Requesting notification permission...');
      _isRequestingPermission = true;
      PermissionStatus status = await Permission.notification.request();
      _isRequestingPermission = false;

      if (status.isGranted) {
        setState(() => _notificationsEnabled = true);
        print('Notifications enabled.');
        // Schedule notifications here or on specific tasks/events
        _scheduleNotifications(
            taskName: 'Sample Task'); // Schedule notifications when enabled
      } else {
        setState(() => _notificationsEnabled = false);
        print('Notification permission denied. Opening app settings...');
        openAppSettings(); // Opens the device settings to grant permissions
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please enable notification permission")),
        );
      }
    } else {
      // Disable notifications
      print('Disabling notifications...');
      setState(() => _notificationsEnabled = false);

      await _cancelAllNotifications(); // Cancel all notifications
      print('All notifications canceled.');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Notifications disabled. You will not receive any notifications.")),
      );
    }
  }

  Future<void> _scheduleNotifications({required String taskName}) async {
    DateTime taskStartTime = DateTime.now().add(const Duration(minutes: 10));

    await _scheduleNotification(
      id: 0,
      title: 'Task Reminder: $taskName',
      body: 'The task "$taskName" is about to start in 5 minutes.',
      scheduledTime: taskStartTime.subtract(const Duration(minutes: 5)),
      payload: taskName,
    );

    await _scheduleNotification(
      id: 1,
      title: 'Task Started: $taskName',
      body: 'The task "$taskName" has just started.',
      scheduledTime: taskStartTime,
      payload: taskName,
    );

    await _scheduleNotification(
      id: 2,
      title: 'Task Overdue: $taskName',
      body: 'The task "$taskName" is now overdue.',
      scheduledTime: taskStartTime.add(const Duration(minutes: 10)),
      payload: taskName,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'task_channel',
      'Task Notifications',
      channelDescription: 'Notifications for tasks',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> _cancelAllNotifications() async {
    print('Canceling all notifications...');
    await flutterLocalNotificationsPlugin.cancelAll();
    print('All notifications canceled.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            ListTile(
              title: const Text(
                'Change Email',
                style: TextStyle(fontSize: 16),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, '/change_email');
              },
            ),
            ListTile(
              title: const Text(
                'Change Password',
                style: TextStyle(fontSize: 16),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, '/change_password');
              },
            ),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Enable Notifications',
                  style: TextStyle(fontSize: 16),
                ),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeColor: Colors.blue,
                ),
              ],
            ),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const ListTile(
              title: Text(
                'App Version',
                style: TextStyle(fontSize: 16),
              ),
              subtitle: Text('v1.0.0'),
            ),
            ListTile(
              title: const Text(
                'Terms of Service',
                style: TextStyle(fontSize: 16),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, '/terms');
              },
            ),
            ListTile(
              title: const Text(
                'Privacy Policy',
                style: TextStyle(fontSize: 16),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, '/privacy');
              },
            ),
          ],
        ),
      ),
    );
  }
}
