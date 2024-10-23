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
import 'package:mellow/widgets/cards/TaskCards/task_card.dart';
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
    const ProfilePage(),
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
  List<DocumentSnapshot> _recentSpaces = [];
  bool hasAnalytics = false;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _loadUserProfile();
    _fetchRecentSpaces();
    _checkAnalyticsAvailability();
  }

  Future<void> _loadUserProfile() async {
    final profileImageProvider =
        Provider.of<ProfileImageProvider>(context, listen: false);
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        setState(() {
          userName = userDoc.exists ? userDoc['firstName'] ?? 'User' : 'User';
        });

        await profileImageProvider.fetchProfileImage(user);
        setState(() {
          profileImageUrl = profileImageProvider.profileImageUrl ?? '';
        });
      } catch (e) {
        print('Error loading profile: $e');
        setState(() {
          userName = 'User';
          profileImageUrl = '';
        });
      }
    }
  }

  Future<void> _fetchTasks() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print("User is not authenticated");
        return;
      }

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isNotEqualTo: 'Finished')
          .get();

      List<DocumentSnapshot> tasks = querySnapshot.docs;

      tasks.sort((a, b) {
        DateTime dueDateA =
            (a['endTime'] as Timestamp?)?.toDate() ?? DateTime.now();
        DateTime dueDateB =
            (b['endTime'] as Timestamp?)?.toDate() ?? DateTime.now();
        return dueDateA.compareTo(dueDateB);
      });

      if (mounted) {
        setState(() {
          _tasks = tasks;
        });
      }
    } catch (e) {
      print("Error fetching tasks: $e");
    }
  }

  Future<void> _fetchRecentSpaces() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('spaces')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      setState(() {
        _recentSpaces = querySnapshot.docs;
      });
    } catch (e) {
      print("Error fetching recent spaces: $e");
    }
  }

  Future<void> _checkAnalyticsAvailability() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('analytics').get();

      setState(() {
        hasAnalytics = querySnapshot.docs.isNotEmpty;
      });
    } catch (e) {
      print("Error checking analytics availability: $e");
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

  Widget _buildAnalyticsSection() {
    if (!hasAnalytics) {
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
            const Text(
              "No analytics to show.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

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
          // Add analytics content here (if any)
        ],
      ),
    );
  }

  Widget _buildSpaceSection() {
    if (_recentSpaces.isEmpty) {
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
            const Text(
              "No spaces were opened recently.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

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
          _buildRecentSpaceCards(),
        ],
      ),
    );
  }

  Widget _buildRecentSpaceCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _recentSpaces.map((space) {
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: RecentSpaceCard(
              spaceName: space['name'] ?? 'Unnamed Space',
              description: space['description'] ?? 'No description',
              date: DateFormat('dd MMMM yyyy').format(
                (space['createdAt'] as Timestamp).toDate(),
              ),
            ),
          );
        }).toList(),
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
          if (_tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'No tasks available.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
          else
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                DocumentSnapshot task = _tasks[index];

                DateTime startTime =
                    (task['startTime'] as Timestamp?)?.toDate() ??
                        DateTime.now();
                DateTime dueDate =
                    (task['endTime'] as Timestamp?)?.toDate() ?? DateTime.now();
                String name = task['taskName'] ?? 'Unnamed Task';

                String taskId = task.id;
                String taskStatus = task['status'] ?? 'Pending';

                String formattedStartTime =
                    DateFormat('yyyy-MM-dd hh:mm a').format(startTime);
                String formattedDueDate =
                    DateFormat('yyyy-MM-dd hh:mm a').format(dueDate);

                DateTime now = DateTime.now();

                bool isOverdue = now.isAfter(dueDate);
                bool isOngoing =
                    now.isAfter(startTime) && now.isBefore(dueDate);

                if (taskStatus != 'Finished' &&
                    (isOngoing || isOverdue || taskStatus == 'Pending')) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TaskCard(
                      taskId: taskId,
                      taskName: name,
                      startTime: formattedStartTime,
                      dueDate: formattedDueDate,
                      startDateTime: startTime,
                      dueDateTime: dueDate,
                      taskStatus: taskStatus,
                    ),
                  );
                }
                return const SizedBox.shrink(); // Skip tasks that are finished
              },
            ),
        ],
      ),
    );
  }

  Future<String?> _getFirstName() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return snapshot['firstName'];
    }
    return null;
  }
}
