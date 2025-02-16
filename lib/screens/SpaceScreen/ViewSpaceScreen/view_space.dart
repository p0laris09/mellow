import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mellow/screens/SpaceScreen/SpaceActivity/space_activity_feed.dart';
import 'package:mellow/screens/TaskCreation/task_creation_space.dart';
import 'package:mellow/screens/SpaceScreen/SpaceTasks/space_tasks_screen.dart';

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
    } catch (e) {}
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
              // Handle settings icon press
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SpaceTasksScreen(spaceId: widget.spaceId)),
                  );
                },
                child: const Text('Go to Space Tasks'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SpaceActivityFeedScreen(spaceId: widget.spaceId)),
                  );
                },
                child: const Text('Go to Activity Feed'),
              ),
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
              child: buildAnalyticsCard(
                title: "Tasks",
                count: tasksCount,
                color: const Color(0xFF2275AA),
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
      stream: tasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No tasks available"));
        }

        final tasks = snapshot.data!.docs.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2275AA),
              ),
            ),
            const SizedBox(height: 8),
            ...tasks.map((taskDoc) {
              final task = taskDoc.data() as Map<String, dynamic>;
              return TaskItem(
                title: task['taskName'] ?? 'Unnamed Task',
                assignedTo: task['assignedTo']?.join(", ") ?? "Unassigned",
                dateCreated:
                    (task['createdAt'] as Timestamp?)?.toDate().toString() ??
                        "Unknown",
              );
            }).toList(),
            const SizedBox(height: 8),
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
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No activities available"));
        }

        final activities = snapshot.data!.docs.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2275AA),
              ),
            ),
            const SizedBox(height: 8),
            ...activities.map((activityDoc) {
              final activity = activityDoc.data() as Map<String, dynamic>;
              return ActivityItem(
                description: activity['description'] ?? 'No Description',
                timestamp: (activity['timestamp'] as Timestamp?)
                        ?.toDate()
                        .toString() ??
                    "Unknown",
              );
            }).toList(),
            const SizedBox(height: 8),
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
        );
      },
    );
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
  final String description;
  final String timestamp;

  const ActivityItem({
    super.key,
    required this.description,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.event, color: Color(0xFF2275AA)),
        title: Text(description,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Timestamp: $timestamp"),
      ),
    );
  }
}
