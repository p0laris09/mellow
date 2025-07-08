import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mellow/provider/ProfileImageProvider/profile_image_provider.dart';
import 'package:mellow/screens/ProfileScreen/profile_page.dart';
import 'package:mellow/screens/SpaceScreen/space_screen.dart';
import 'package:mellow/screens/TaskManagement/task_management.dart';
import 'package:mellow/widgets/appbar/myappbar.dart';
import 'package:mellow/widgets/bottomnav/mybottomnavbar.dart';
import 'package:mellow/widgets/cards/AnalyticsCards/task_analytics_card.dart';
import 'package:mellow/widgets/cards/SpaceCards/recently_space_card.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mellow/widgets/cards/TaskCards/task_card.dart';
import 'package:provider/provider.dart'; // For Firebase Authentication
import 'package:connectivity_plus/connectivity_plus.dart'; // For checking network connectivity

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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivityAndLoadData();
  }

  Future<void> _checkConnectivityAndLoadData() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      Navigator.of(context).pushReplacementNamed('/no_network');
    } else {
      await Future.wait([
        _fetchTasks(),
        _loadUserProfile(),
        _fetchRecentSpaces(),
      ]);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserProfile() async {
    final profileImageProvider =
        Provider.of<ProfileImageProvider>(context, listen: false);
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Fetch the profile image using the provider, similar to the MyAppBar approach
        await profileImageProvider.fetchProfileImage(user);

        // Update state only if necessary
        if (mounted) {
          setState(() {
            profileImageUrl =
                profileImageProvider.profileImageUrl?.isNotEmpty ?? false
                    ? profileImageProvider.profileImageUrl!
                    : 'assets/img/default_profile.png';
            userName = user.displayName ?? 'User';
          });
        }
      } catch (e) {
        // Fallback to default values if an error occurs
        print('Error loading profile: $e');
        if (mounted) {
          setState(() {
            profileImageUrl = 'assets/img/default_profile.png';
            userName = 'User';
          });
        }
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
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var task in taskSnapshot.docs) {
        DateTime dueDate = (task['endTime'] as Timestamp).toDate();
        if (dueDate.isBefore(now)) {
          // Update task to overdue if past due date
          batch.update(task.reference, {'status': 'overdue'});
        }
      }
      await batch.commit();
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

      // Update state only if necessary
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
            // If it's a String, parse it using a custom format
            try {
              lastOpenedDate = DateFormat('yyyy-M-d HH:m:s').parse(lastOpened);
            } catch (e) {
              print('Error parsing lastOpened string: $e');
            }
          }
        }

        // Format the date as "Month Name Day, Year"
        final formattedDate = lastOpenedDate != null
            ? DateFormat('MMMM d, yyyy').format(lastOpenedDate)
            : 'Unknown Date';

        // Optionally, you can add the formatted date back to the space data
        space['formattedLastOpened'] = formattedDate;

        return doc; // Returning the original document, you can modify this if needed
      }).toList();

      // Update state only if necessary
      if (mounted) {
        setState(() {
          _recentSpaces = processedSpaces; // Use the processed spaces list
        });
      }
    } catch (e) {
      print("Error fetching recent spaces: $e");
    }
  }

  Future<void> _refreshPage() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      Navigator.of(context).pushReplacementNamed('/no_network');
    } else {
      setState(() {
        isLoading = true;
      });
      await _checkConnectivityAndLoadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshPage,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<String?>(
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
            ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseAuth.instance.currentUser != null
                ? FirebaseFirestore.instance
                    .collection('tasks')
                    .where('userId',
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                    .snapshots()
                : null,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  "Error fetching task data.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text(
                  "You have no tasks.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                );
              }

              var tasks = snapshot.data!.docs;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TaskAnalyticsCard(
                      totalTasks: tasks.length,
                    ),
                  ),
                ],
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
                  height: 150, // Adjust height to fit the cards
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentSpaces.length,
                    itemBuilder: (context, index) {
                      final space = _recentSpaces[index];
                      final spaceName = space['name'] ?? 'Unnamed Space';
                      final description = space['description'] ?? '';
                      final createdAt = space['createdAt'];

                      DateTime? createdAtDate;

                      // Handle Timestamp for createdAt
                      if (createdAt != null && createdAt is Timestamp) {
                        createdAtDate = createdAt.toDate();
                      }

                      // Format the creation date as "March 10, 2025"
                      final date = createdAtDate != null
                          ? DateFormat('MMMM d, yyyy').format(createdAtDate)
                          : 'Unknown Date';

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: RecentSpaceCard(
                          spaceId: space.id, // Pass the space ID here
                          spaceName: spaceName,
                          description: description,
                          date: date, // Pass the formatted creation date
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
          StreamBuilder<List<DocumentSnapshot>>(
            stream: _fetchUserTasks(uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text("Error loading tasks: ${snapshot.error}");
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No tasks available.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                );
              }

              var taskDocs = snapshot.data!;
              DateTime now = DateTime.now();

              // Filter tasks based on the computed statusLabel
              var filteredTasks = taskDocs.where((task) {
                final taskData = task.data() as Map<String, dynamic>;
                DateTime startTime =
                    (taskData['startTime'] as Timestamp?)?.toDate() ??
                        DateTime.now();
                DateTime dueDate =
                    (taskData['endTime'] as Timestamp?)?.toDate() ??
                        DateTime.now();
                String taskStatus = taskData['status'] ?? 'Pending';

                // Compute dynamic status
                bool isOverdue =
                    now.isAfter(dueDate) && taskStatus != 'Finished';
                bool isOngoing =
                    now.isAfter(startTime) && now.isBefore(dueDate);

                String statusLabel;
                if (taskStatus == 'Finished') {
                  statusLabel = 'Finished';
                } else if (isOngoing) {
                  statusLabel = 'Ongoing';
                } else if (isOverdue) {
                  statusLabel = 'Overdue';
                } else {
                  statusLabel = 'Pending';
                }

                // Only include tasks with status Pending, Ongoing, or Overdue
                return statusLabel == 'Pending' ||
                    statusLabel == 'Ongoing' ||
                    statusLabel == 'Overdue';
              }).toList();

              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot task = filteredTasks[index];
                  String taskId = task.id;
                  final taskData = task.data() as Map<String, dynamic>;
                  DateTime startTime =
                      (taskData['startTime'] as Timestamp?)?.toDate() ??
                          DateTime.now();
                  DateTime dueDate =
                      (taskData['endTime'] as Timestamp?)?.toDate() ??
                          DateTime.now();
                  String name = taskData['taskName'] ?? 'Unnamed Task';
                  String taskStatus = taskData['status'] ?? 'Pending';

                  // Compute dynamic status
                  bool isOverdue =
                      now.isAfter(dueDate) && taskStatus != 'Finished';
                  bool isOngoing =
                      now.isAfter(startTime) && now.isBefore(dueDate);

                  String statusLabel;
                  if (taskStatus == 'Finished') {
                    statusLabel = 'Finished';
                  } else if (isOngoing) {
                    statusLabel = 'Ongoing';
                  } else if (isOverdue) {
                    statusLabel = 'Overdue';
                  } else {
                    statusLabel = 'Pending';
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
                      taskStatus: statusLabel, // Pass the computed statusLabel
                      onTaskFinished: () {
                        // Add your logic here for when the task is finished
                      },
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

  Stream<List<DocumentSnapshot>> _fetchUserTasks(String uid) async* {
    try {
      // Query for tasks where the user is assigned (as a string or in an array)
      QuerySnapshot arrayQuery = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', arrayContains: uid)
          .get();

      QuerySnapshot stringQuery = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: uid)
          .get();

      // Combine both query results and remove duplicates
      List<DocumentSnapshot> allTasks = [];
      Set<String> taskIds = {};

      for (var doc in arrayQuery.docs + stringQuery.docs) {
        if (!taskIds.contains(doc.id)) {
          taskIds.add(doc.id);
          allTasks.add(doc);
        }
      }

      yield allTasks;
    } catch (e) {
      print("Error fetching tasks: $e");
      yield [];
    }
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
