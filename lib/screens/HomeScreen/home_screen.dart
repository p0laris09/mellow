import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mellow/screens/AnalyticsScreen/analytics_screen.dart';
import 'package:mellow/screens/CollaborationScreen/collaboration_screen.dart';
import 'package:mellow/screens/TaskManagement/task_management.dart';
import 'package:mellow/widgets/appbar/myappbar.dart';
import 'package:mellow/widgets/bottomnav/mybottomnavbar.dart';
import 'package:mellow/widgets/cards/task_card.dart';
import 'package:mellow/widgets/drawer/mydrawer.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Authentication

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    HomeScreenContent(), // Removed UID passing as we will fetch it from FirebaseAuth
    TaskManagementScreen(),
    const CollaborationScreen(),
    const AnalyticsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(),
      drawer: const MyDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: MyBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  List<DocumentSnapshot> _tasks = [];

  DateTime get _startOfWeek {
    DateTime now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1)); // Monday
  }

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<String?> _getFirstName() async {
    final user = FirebaseAuth.instance.currentUser; // Fetch current user
    if (user == null) return null;

    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return userDoc.exists ? userDoc['firstName'] as String? : null;
  }

  void _fetchTasks() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DateTime startOfWeek = _startOfWeek;
      DateTime endOfWeek = startOfWeek.add(Duration(days: 7));

      // Debug prints
      print("Fetching tasks for user: $uid");
      print("Start of week: $startOfWeek");
      print("End of week: $endOfWeek");

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: uid)
          .where('startTime', isGreaterThanOrEqualTo: startOfWeek)
          .where('startTime', isLessThan: endOfWeek)
          .get();

      setState(() {
        _tasks = querySnapshot.docs;
      });
    } catch (e) {
      print("Error fetching tasks: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getFirstName(),
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final String firstName = snapshot.data ?? 'User';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello $firstName!",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  "Have a nice day.",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTaskCards(),
                const SizedBox(height: 32),
                _buildTaskSection(), // Ensures tasks are displayed here
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildTaskCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          TaskCard(
            project: "Project 1",
            title: "Front-End Development",
            date: "30 September 2024",
          ),
          const SizedBox(width: 16),
          TaskCard(
            project: "Project 2",
            title: "Back-End Development",
            date: "20 October 2024",
            opacity: 0.5,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "Tasks",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          // Corrected logic for task display to ensure all tasks are rendered
          _tasks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No tasks available for the current week.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot task = _tasks[index];
                    DateTime startTime =
                        (task['startTime'] as Timestamp?)?.toDate() ??
                            DateTime.now();
                    DateTime dueDate =
                        (task['endTime'] as Timestamp?)?.toDate() ??
                            DateTime.now();
                    String name = task['taskName'] ?? 'Unnamed Task';

                    String formattedStartTime =
                        DateFormat('hh:mm a').format(startTime);
                    String formattedDueDate =
                        DateFormat('yyyy-MM-dd').format(dueDate);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildProgressTask(
                          name, formattedDueDate, formattedStartTime),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildProgressTask(String taskName, String dueDate, String startTime) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.task, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Due: $dueDate | Start: $startTime',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {
              // Handle options button
            },
          ),
        ],
      ),
    );
  }
}
