import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mellow/widgets/cards/TaskCards/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<DocumentSnapshot> tasks = [];
  List<DocumentSnapshot> filteredTasks = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();

    setState(() {
      tasks = querySnapshot.docs;
      filteredTasks = tasks;
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      filteredTasks = tasks.where((task) {
        final taskName = task['taskName'].toString().toLowerCase();
        final searchQuery = _searchQuery.toLowerCase();
        return taskName.contains(searchQuery);
      }).toList();
    });
  }

  void _onTaskFinished(String taskId) {
    setState(() {
      tasks.removeWhere((task) => task.id == taskId);
      filteredTasks.removeWhere((task) => task.id == taskId);
    });
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
          'Task History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                DocumentSnapshot task = filteredTasks[index];
                return TaskCard(
                  taskId: task.id,
                  taskName: task['taskName'],
                  dueDate: (task['dueDate'] as Timestamp).toDate().toString(),
                  startTime:
                      (task['startTime'] as Timestamp).toDate().toString(),
                  startDateTime: (task.data() as Map<String, dynamic>)
                              .containsKey('startDateTime') ==
                          true
                      ? (task['startDateTime'] as Timestamp).toDate()
                      : DateTime.now(),
                  dueDateTime: (task.data() as Map<String, dynamic>)
                              .containsKey('dueDateTime') ==
                          true
                      ? (task['dueDateTime'] as Timestamp).toDate()
                      : DateTime.now(),
                  taskStatus: task['status'],
                  completionTime: (task.data() as Map<String, dynamic>)
                              .containsKey('completionTime') ==
                          true
                      ? (task['completionTime'] as Timestamp).toDate()
                      : null,
                  onTaskFinished: () =>
                      _onTaskFinished(task.id), // Pass the callback
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

extension MapExtensions on Map<String, dynamic> {
  bool containsKey(String key) {
    return this != null && this.containsKey(key);
  }
}
