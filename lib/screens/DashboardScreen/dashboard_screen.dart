import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mellow/provider/ProfileImageProvider/profile_image_provider.dart';
import 'package:mellow/screens/AnalyticsScreen/analytics_screen.dart';
import 'package:mellow/screens/ProfileScreen/profile_page.dart';
import 'package:mellow/screens/SpaceScreen/space_screen.dart';
import 'package:mellow/screens/TaskManagement/task_management.dart';
import 'package:mellow/widgets/appbar/myappbar.dart';
import 'package:mellow/widgets/bottomnav/mybottomnavbar.dart';
import 'package:mellow/widgets/cards/SpaceCards/recently_space_card.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // For Firebase Authentication

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreenContent(),
    TaskManagementScreen(),
    const SpaceScreen(),
    const AnalyticsScreen(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: MyAppBar(selectedIndex: _selectedIndex),
      body: _pages[_selectedIndex],
      bottomNavigationBar: MyBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class DashboardScreenContent extends StatefulWidget {
  const DashboardScreenContent({super.key});

  @override
  State<DashboardScreenContent> createState() => _DashboardScreenContentState();
}

class _DashboardScreenContentState extends State<DashboardScreenContent> {
  String profileImageUrl = '';
  String userName = '';
  List<DocumentSnapshot> _tasks = [];

  DateTime get _startOfWeek {
    DateTime now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1)); // Start from Monday
  }

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    // Access the ProfileImageProvider
    final profileImageProvider =
        Provider.of<ProfileImageProvider>(context, listen: false);
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Load user name
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        setState(() {
          userName = userDoc.exists ? userDoc['firstName'] ?? 'User' : 'User';
        });

        // Ensure the profile image URL is fetched from the provider
        await profileImageProvider.fetchProfileImage(user);

        // Get the image URL from the provider
        setState(() {
          profileImageUrl = profileImageProvider.profileImageUrl ?? '';
        });
      } catch (e) {
        print('Error loading profile: $e');
        // Load default profile if error occurs
        setState(() {
          userName = 'User';
          profileImageUrl = ''; // Or set to default image URL if needed
        });
      }
    }
  }

  Future<void> _fetchTasks() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DateTime startOfWeek = _startOfWeek;
      DateTime endOfWeek = startOfWeek.add(Duration(days: 7));

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
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl.isEmpty
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
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
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAnalyticsSection(),
                const SizedBox(height: 32),
                _buildSpaceSection(),
                const SizedBox(height: 32),
                _buildTaskSection(),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildRecentSpaceCards() {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          RecentSpaceCard(
            spaceName: "Design Discussion",
            description: "Discussing UI/UX improvements for the app.",
            date: "30 September 2024",
          ),
          SizedBox(width: 16),
          RecentSpaceCard(
            spaceName: "Backend API Development",
            description: "Collaborating on the API integration.",
            date: "20 October 2024",
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "Task Analytics",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "Recent Spaces",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          _buildRecentSpaceCards(), // Display space tasks here
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
                        DateFormat('yyyy-MM-dd hh:mm a').format(startTime);
                    String formattedDueDate =
                        DateFormat('yyyy-MM-dd hh:mm a').format(dueDate);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildProgressTask(
                          name,
                          formattedDueDate,
                          formattedStartTime,
                          startTime, // Pass start time
                          dueDate // Pass due date
                          ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildProgressTask(String taskName, String dueDate, String startTime,
      DateTime taskStartTime, DateTime taskDueDate) {
    DateTime now = DateTime.now();
    String taskStatus;
    Color iconColor;

    // Determine the status and icon color based on the time comparison
    if (now.isAfter(taskDueDate)) {
      taskStatus = "Overdue";
      iconColor = Colors.red;
    } else if (now.isAfter(taskStartTime) && now.isBefore(taskDueDate)) {
      taskStatus = "Ongoing";
      iconColor = Colors.green;
    } else {
      taskStatus = "Pending";
      iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(
          vertical: 8), // Adding margin to increase space between task cards
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.task,
            color: iconColor,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Start: $startTime",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Due: $dueDate",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              taskStatus == "Overdue"
                  ? Icons.warning
                  : taskStatus == "Ongoing"
                      ? Icons.hourglass_bottom
                      : Icons.schedule,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _getFirstName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data()!['firstName'] ?? user?.email;
      }
      return user?.email; // Fallback to email
    } catch (e) {
      print('Error fetching user name: $e');
      return 'User';
    }
  }
}
