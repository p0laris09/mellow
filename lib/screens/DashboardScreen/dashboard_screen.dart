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
        // Fetch the profile image using the provider, similar to the MyAppBar approach
        await profileImageProvider.fetchProfileImage(user);

        // Set the default values if the profile image URL is null or empty
        setState(() {
          profileImageUrl =
              profileImageProvider.profileImageUrl?.isNotEmpty ?? false
                  ? profileImageProvider.profileImageUrl!
                  : 'assets/img/default_profile.png';
          userName = user.displayName ?? 'User';
        });
      } catch (e) {
        // Fallback to default values if an error occurs
        print('Error loading profile: $e');
        setState(() {
          profileImageUrl = 'assets/img/default_profile.png';
          userName = 'User';
        });
      }
    }
  }

  Future<void> _updateOverdueTasks() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Check and update overdue tasks
      QuerySnapshot taskSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: currentUser.uid)
          .where('status',
              isEqualTo:
                  'ongoing') // Only check ongoing tasks for overdue status
          .get();

      DateTime now = DateTime.now();
      for (var task in taskSnapshot.docs) {
        DateTime dueDate = (task['endTime'] as Timestamp).toDate();
        if (dueDate.isBefore(now)) {
          // Update task to overdue if past due date
          await FirebaseFirestore.instance
              .collection('tasks')
              .doc(task.id)
              .update({'status': 'overdue'});
        }
      }
    } catch (e) {
      print("Error updating overdue tasks: $e");
    }
  }

  Future<void> _fetchTasks() async {
    await _updateOverdueTasks(); // First update overdue tasks

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Fetch tasks including those marked as overdue
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', whereIn: ['pending', 'ongoing', 'overdue'])
          .orderBy('endTime')
          .get();

      if (mounted) {
        setState(() {
          _tasks = querySnapshot.docs;
        });
      }
    } catch (e) {
      print("Error fetching tasks: $e");
    }
  }

  Future<void> _fetchRecentSpaces() async {
    try {
      // Get the current user's UID
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Fetch spaces where the user is either a member or an admin
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('spaces')
          .where('members',
              arrayContains: user.uid) // User is a member of the space
          .where('admin', isEqualTo: user.uid) // User is the admin of the space
          .orderBy('lastOpened',
              descending: true) // Sort by lastOpened in descending order
          .limit(2) // Limit to the 2 most recent spaces
          .get();

      if (mounted) {
        setState(() {
          _recentSpaces = querySnapshot.docs;
        });
      }
    } catch (e) {
      print("Error fetching recent spaces: $e");
    }
  }

  Future<void> _checkAnalyticsAvailability() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('analytics').get();

      if (mounted) {
        setState(() {
          hasAnalytics = querySnapshot.docs.isNotEmpty;
        });
      }
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
          _recentSpaces.isEmpty
              ? const Text(
                  "No spaces were opened recently.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                )
              : SizedBox(
                  height: 120, // Adjust height to fit the cards
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentSpaces.length,
                    itemBuilder: (context, index) {
                      final space = _recentSpaces[index];
                      final spaceName = space['name'] ?? 'Unnamed Space';
                      final description = space['description'] ?? '';
                      final lastOpened = space['lastOpened'] != null
                          ? (space['lastOpened'] as Timestamp).toDate()
                          : null;
                      final date = lastOpened != null
                          ? DateFormat('MMM d, yyyy').format(lastOpened)
                          : 'Unknown Date';

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: RecentSpaceCard(
                          spaceId: space.id, // Pass the space ID here
                          spaceName: spaceName,
                          description: description,
                          date: date,
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTaskSection() {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tasks')
                .where('userId', isEqualTo: uid)
                .where('status', whereIn: ['pending', 'ongoing', 'overdue'])
                .orderBy('endTime', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text("Error loading tasks: ${snapshot.error}");
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No tasks available.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                );
              }

              var taskDocs = snapshot.data!.docs;
              DateTime now = DateTime.now();

              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: taskDocs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot task = taskDocs[index];
                  String taskId = task.id;
                  DateTime startTime =
                      (task['startTime'] as Timestamp).toDate();
                  DateTime dueDate = (task['endTime'] as Timestamp).toDate();
                  String name = task['taskName'] ?? 'Unnamed Task';
                  String taskStatus = task['status'] ?? 'pending';

                  // Dynamically set status to overdue if due date is past and status is not 'finished'
                  if (dueDate.isBefore(now) && taskStatus != 'Finished') {
                    taskStatus = 'overdue';
                  }

                  String formattedStartTime =
                      DateFormat('yyyy-MM-dd hh:mm a').format(startTime);
                  String formattedDueDate =
                      DateFormat('yyyy-MM-dd hh:mm a').format(dueDate);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TaskCard(
                      taskId: taskId,
                      taskName: name,
                      dueDate: formattedDueDate,
                      startTime: formattedStartTime,
                      startDateTime: startTime,
                      dueDateTime: dueDate,
                      taskStatus: taskStatus,
                    ),
                  );
                },
              );
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
