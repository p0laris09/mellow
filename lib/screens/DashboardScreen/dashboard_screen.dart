import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mellow/provider/ProfileImageProvider/profile_image_provider.dart';
import 'package:mellow/screens/AnalyticsScreen/analytics_screen.dart';
import 'package:mellow/screens/ProfileScreen/profile_page.dart';
import 'package:mellow/screens/SpaceScreen/space_screen.dart';
import 'package:mellow/screens/TaskManagement/task_management.dart';
import 'package:mellow/widgets/appbar/myappbar.dart';
import 'package:mellow/widgets/bottomnav/mybottomnavbar.dart';
import 'package:mellow/widgets/cards/AnalyticsCards/task_analytics_card.dart';
import 'package:mellow/widgets/cards/AnalyticsCards/weight_analytics_card.dart';
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
      // Fetch tasks where user is either the creator (userId) or assigned to (assignedTo)
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('status', whereIn: ['pending', 'ongoing', 'overdue'])
          .where('userId',
              isEqualTo: currentUser.uid) // Tasks created by the user
          .get();

      // Fetch tasks where the user is assigned to them
      QuerySnapshot assignedTasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo',
              arrayContains: currentUser.uid) // Tasks assigned to the user
          .where('status', whereIn: ['pending', 'ongoing', 'overdue']).get();

      // Combine the results
      List<QueryDocumentSnapshot> allTasks = []
        ..addAll(querySnapshot.docs)
        ..addAll(assignedTasksSnapshot.docs);

      // Remove duplicates by taskId (if any)
      Set<String> taskIds = Set();
      List<QueryDocumentSnapshot> uniqueTasks = [];
      for (var doc in allTasks) {
        String taskId = doc.id;
        if (!taskIds.contains(taskId)) {
          taskIds.add(taskId);
          uniqueTasks.add(doc);
        }
      }

      if (mounted) {
        setState(() {
          _tasks = uniqueTasks;
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

      // Fetch spaces where the user is a member or admin
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('spaces')
          .where('members',
              arrayContains: user.uid) // User is a member of the space
          .orderBy('lastOpened',
              descending: true) // Sort by lastOpened in descending order
          .limit(2) // Limit to the 2 most recent spaces
          .get();

      // If no spaces found, fetch spaces where the user is an admin
      if (querySnapshot.docs.isEmpty) {
        querySnapshot = await FirebaseFirestore.instance
            .collection('spaces')
            .where('admin',
                isEqualTo: user.uid) // User is the admin of the space
            .orderBy('lastOpened',
                descending: true) // Sort by lastOpened in descending order
            .limit(2) // Limit to the 2 most recent spaces
            .get();
      }

      print(
          "Fetched spaces: ${querySnapshot.docs.length} spaces found."); // Debugging line

      // Convert lastOpened field to DateTime
      List<DocumentSnapshot> processedSpaces = querySnapshot.docs.map((doc) {
        var space = doc.data() as Map<String, dynamic>;
        final lastOpened = space['lastOpened'];
        DateTime? lastOpenedDate;

        if (lastOpened != null) {
          if (lastOpened is Timestamp) {
            // If it's already a Timestamp, convert it to DateTime
            lastOpenedDate = lastOpened.toDate();
          } else if (lastOpened is String) {
            // If it's a String, try to parse it to DateTime
            try {
              lastOpenedDate = DateTime.parse(lastOpened);
            } catch (e) {
              print('Error parsing lastOpened string: $e');
            }
          }
        }

        // Optionally, you can add the converted DateTime back to the space data or use it for further processing
        if (lastOpenedDate != null) {
          space['lastOpenedDate'] =
              lastOpenedDate; // Adding the converted DateTime back to the space map
        }

        return doc; // Returning the original document, you can modify this if needed
      }).toList();

      if (mounted) {
        setState(() {
          _recentSpaces = processedSpaces; // Use the processed spaces list
        });
      }
    } catch (e) {
      print("Error fetching recent spaces: $e");
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "Analytics",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          StreamBuilder<DocumentSnapshot>(
            // Stream to get totalWeight from Firestore
            stream: FirebaseFirestore.instance
                .collection('users') // Assuming you store user data here
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  "Error fetching analytics data.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Text(
                  "No analytics to show.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                );
              }

              var userData = snapshot.data!.data() as Map<String, dynamic>;
              double totalWeight = userData['totalWeight'] ?? 0.0;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .where('userId',
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      "Error fetching task data.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text(
                      "No tasks available for analytics.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    );
                  }

                  var tasks = snapshot.data!.docs;

                  // Recalculate the total weight if it's not found in Firestore
                  double calculatedWeight = tasks.fold<double>(
                    0.0,
                    (sum, task) => sum + (task['weight'] ?? 0.0),
                  );

                  // If Firestore doesn't have the weight, we use the calculated weight
                  totalWeight =
                      totalWeight != 0.0 ? totalWeight : calculatedWeight;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TaskAnalyticsCard(
                          totalTasks: tasks.length,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: WeightAnalyticsCard(
                          totalWeight: totalWeight,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
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
                      final lastOpened = space['lastOpened'];

                      DateTime? lastOpenedDate;

                      // Handle both Timestamp and String cases
                      if (lastOpened != null) {
                        if (lastOpened is Timestamp) {
                          lastOpenedDate = lastOpened.toDate();
                        } else if (lastOpened is String) {
                          try {
                            lastOpenedDate = DateTime.parse(lastOpened);
                          } catch (e) {
                            print('Error parsing lastOpened string: $e');
                          }
                        }
                      }

                      final date = lastOpenedDate != null
                          ? DateFormat('MMM d, yyyy').format(lastOpenedDate)
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
