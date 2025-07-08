import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mellow/widgets/cards/TaskCards/task_card.dart';

class SpaceTasksScreen extends StatefulWidget {
  final String spaceId;

  const SpaceTasksScreen({super.key, required this.spaceId});

  @override
  State<SpaceTasksScreen> createState() => _SpaceTasksScreenState();
}

class _SpaceTasksScreenState extends State<SpaceTasksScreen> {
  late Stream<QuerySnapshot> tasksStream;
  late Stream<DocumentSnapshot> spaceDetailsStream;
  String spaceName = '';
  String searchQuery = ''; // Holds the current search query

  @override
  void initState() {
    super.initState();

    // Fetch tasks for the current space
    tasksStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('spaceId', isEqualTo: widget.spaceId) // Filter by spaceId
        .orderBy('createdAt', descending: false)
        .snapshots();

    // Fetch space details
    spaceDetailsStream = FirebaseFirestore.instance
        .collection('spaces')
        .doc(widget.spaceId)
        .snapshots();

    // Fetch space name
    spaceDetailsStream.listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          spaceName =
              (snapshot.data() as Map<String, dynamic>?)?['name'] ?? 'Space';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          spaceName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2275AA),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase(); // Update the search query
                });
              },
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Task List
          Expanded(
            child: _buildTaskListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: tasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error fetching tasks"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No tasks available"));
        }

        final tasks = snapshot.data!.docs.where((doc) {
          final taskName = (doc.data() as Map<String, dynamic>)['taskName']
              ?.toString()
              .toLowerCase();
          return taskName != null && taskName.contains(searchQuery);
        }).toList();

        if (tasks.isEmpty) {
          return const Center(child: Text("No tasks match your search"));
        }

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index].data() as Map<String, dynamic>;
            return TaskCard(
              taskId: tasks[index].id,
              taskName: task['taskName'] ?? 'Unnamed Task',
              dueDate: (task['dueDate'] as Timestamp).toDate().toString(),
              startTime: (task['startTime'] as Timestamp).toDate().toString(),
              startDateTime: (task['startTime'] as Timestamp).toDate(),
              dueDateTime: (task['dueDate'] as Timestamp).toDate(),
              taskStatus: task['status'] ?? 'Pending',
              onTaskFinished: () {},
            );
          },
        );
      },
    );
  }
}
