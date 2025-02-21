import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mellow/screens/SpaceScreen/SpaceActivity/space_activity_feed.dart';
import 'package:mellow/screens/TaskCreation/task_creation_space.dart';
import 'package:mellow/screens/SpaceScreen/SpaceTasks/space_tasks_screen.dart';
import 'package:mellow/screens/SpaceScreen/SpaceSettings/space_setting_screen.dart';
import 'package:mellow/widgets/cards/TaskCards/task_card.dart';

class ViewSpace extends StatefulWidget {
  final String spaceId;
  final String spaceName;
  final String description;
  final String date;

  const ViewSpace({
    super.key,
    required this.spaceId,
    required this.spaceName,
    required this.description,
    required this.date,
  });

  @override
  State<ViewSpace> createState() => _ViewSpaceState();
}

class _ViewSpaceState extends State<ViewSpace> {
  late Stream<QuerySnapshot> tasksStream;
  late Stream<QuerySnapshot> activitiesStream;
  late Stream<DocumentSnapshot> spaceDetailsStream;

  @override
  void initState() {
    super.initState();
    tasksStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('spaceId', isEqualTo: widget.spaceId)
        .orderBy('createdAt', descending: false)
        .snapshots();

    activitiesStream = FirebaseFirestore.instance
        .collection('activities')
        .where('spaceId', isEqualTo: widget.spaceId)
        .orderBy('timestamp', descending: true)
        .snapshots();

    spaceDetailsStream = FirebaseFirestore.instance
        .collection('spaces')
        .doc(widget.spaceId)
        .snapshots();
  }

  Future<String> getUserFullName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return "${userData['firstName']} ${userData['lastName']}";
      }
    } catch (e) {
      print("Error getting user full name: $e");
    }
    return "Unknown User";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
        title:
            Text(widget.spaceName, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message, color: Colors.white),
            onPressed: () {
              // Handle message icon press
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SpaceSettingScreen(spaceId: widget.spaceId),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSpaceDetailsCard(),
              const SizedBox(height: 16),
              buildTaskList(),
              const SizedBox(height: 16),
              buildActivityFeed(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskCreationSpace()),
          );
        },
        backgroundColor: const Color(0xFF2275AA),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Task', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget buildSpaceDetailsCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: spaceDetailsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text("No space details found.");
        }

        final spaceData = snapshot.data!.data() as Map<String, dynamic>;
        final members = spaceData['members'] as List<dynamic>? ?? [];
        final tasksCount = spaceData['tasksCount'] ?? 0;

        return Row(
          children: [
            Expanded(
              child: buildAnalyticsCard(
                title: "Members",
                count: members.length,
                color: const Color(0xFF2275AA),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: tasksStream,
                builder: (context, taskSnapshot) {
                  if (taskSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (taskSnapshot.hasError) {
                    return Center(child: Text("Error: ${taskSnapshot.error}"));
                  }
                  if (!taskSnapshot.hasData ||
                      taskSnapshot.data!.docs.isEmpty) {
                    return buildAnalyticsCard(
                      title: "Tasks",
                      count: 0,
                      color: const Color(0xFF2275AA),
                    );
                  }

                  final tasksCount = taskSnapshot.data!.docs.length;

                  return buildAnalyticsCard(
                    title: "Tasks",
                    count: tasksCount,
                    color: const Color(0xFF2275AA),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildAnalyticsCard(
      {required String title, required int count, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTaskList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('spaceId', isEqualTo: widget.spaceId)
          .orderBy('createdAt', descending: false)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print("Error fetching tasks: ${snapshot.error}");
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print("No tasks available");
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tasks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SpaceTasksScreen(spaceId: widget.spaceId)),
                      );
                    },
                    child: const Text(
                      'See More',
                      style: TextStyle(
                        color: Color(0xFF2275AA),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  "No tasks available",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ],
          );
        }

        final tasks = snapshot.data!.docs.toList();
        print("Fetched ${tasks.length} tasks");

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SpaceTasksScreen(spaceId: widget.spaceId)),
                    );
                  },
                  child: const Text(
                    'See More',
                    style: TextStyle(
                      color: Color(0xFF2275AA),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...tasks.map((taskDoc) {
              final task = taskDoc.data() as Map<String, dynamic>;
              print(
                  "Task: ${task['taskName']}, Assigned to: ${task['assignedTo']}, Created at: ${task['createdAt']}");
              return TaskCard(
                taskId: taskDoc.id,
                taskName: task['taskName'] ?? 'Unnamed Task',
                dueDate: (task['dueDate'] as Timestamp).toDate().toString(),
                startTime: (task['startTime'] as Timestamp).toDate().toString(),
                startDateTime: (task['startTime'] as Timestamp).toDate(),
                dueDateTime: (task['dueDate'] as Timestamp).toDate(),
                taskStatus: task['status'] ?? 'Pending',
              );
            }).toList(),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget buildActivityFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: activitiesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print("Error fetching activities: ${snapshot.error}");
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print("No activities available");
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Activities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SpaceActivityFeedScreen(
                                spaceId: widget.spaceId)),
                      );
                    },
                    child: const Text(
                      'See More',
                      style: TextStyle(
                        color: Color(0xFF2275AA),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  "No activities available",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ],
          );
        }

        final activities = snapshot.data!.docs.take(3).toList();
        print("Fetched ${activities.length} activities");

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SpaceActivityFeedScreen(spaceId: widget.spaceId)),
                    );
                  },
                  child: const Text(
                    'See More',
                    style: TextStyle(
                      color: Color(0xFF2275AA),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...activities.map((activityDoc) {
              final activity = activityDoc.data() as Map<String, dynamic>;
              final createdBy = activity['createdBy'] as String;
              final taskName = activity['taskName'] as String;
              final assignedToUids = activity['assignedTo'] as List<dynamic>;
              final timestamp = (activity['timestamp'] as Timestamp).toDate();
              final timeAgo = timeAgoSinceDate(timestamp);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(createdBy)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final userName =
                      "${userData['firstName']} ${userData['lastName']}";

                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .where(FieldPath.documentId, whereIn: assignedToUids)
                        .get(),
                    builder: (context, assignedToSnapshot) {
                      if (!assignedToSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final assignedToNames =
                          assignedToSnapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return "${data['firstName']} ${data['lastName']}";
                      }).join(", ");

                      return ActivityItem(
                        userName: userName,
                        description:
                            "$userName created task $taskName and assigned it to $assignedToNames",
                        timestamp: timeAgo,
                      );
                    },
                  );
                },
              );
            }).toList(),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  String timeAgoSinceDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 8) {
      return DateFormat('yyyy-MM-dd').format(date);
    } else if ((difference.inDays / 7).floor() >= 1) {
      return '1 week ago';
    } else if (difference.inDays >= 2) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays >= 1) {
      return '1 day ago';
    } else if (difference.inHours >= 2) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours >= 1) {
      return '1 hour ago';
    } else if (difference.inMinutes >= 2) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inMinutes >= 1) {
      return '1 minute ago';
    } else if (difference.inSeconds >= 3) {
      return '${difference.inSeconds} seconds ago';
    } else {
      return 'just now';
    }
  }
}

class TaskItem extends StatelessWidget {
  final String title;
  final String assignedTo;
  final String dateCreated;

  const TaskItem({
    super.key,
    required this.title,
    required this.assignedTo,
    required this.dateCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2275AA),
          child: Text(title[0], style: const TextStyle(color: Colors.white)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Assigned to: $assignedTo\nDate Created: $dateCreated"),
      ),
    );
  }
}

class ActivityItem extends StatelessWidget {
  final String userName;
  final String description;
  final String timestamp;

  const ActivityItem({
    super.key,
    required this.userName,
    required this.description,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.event_note, color: Color(0xFF2275AA)),
        title: Text(description,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Created $timestamp"),
      ),
    );
  }
}
