import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mellow/widgets/cards/TaskCards/task_card.dart';

class TaskHistory extends StatefulWidget {
  const TaskHistory({Key? key}) : super(key: key);

  @override
  State<TaskHistory> createState() => _TaskHistoryState();
}

class _TaskHistoryState extends State<TaskHistory> {
  List<Map<String, dynamic>> filteredTasks = [];
  List<Map<String, dynamic>> allTasks = [];
  bool isAscending = true;

  @override
  void initState() {
    super.initState();
    _getTaskStream();
  }

  Stream<List<Map<String, dynamic>>> _getTaskStream() {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception("User is not authenticated");
    }

    return FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final status = calculateTaskStatus(data, now);

        return {
          'taskId': doc.id,
          'taskName': data['taskName'] ?? 'Unnamed Task',
          'dueDate': (data['dueDate'] as Timestamp).toDate(),
          'startTime': (data['startTime'] as Timestamp?)?.toDate(),
          'endTime': (data['endTime'] as Timestamp?)?.toDate(),
          'description': data['description'] ?? '',
          'taskStatus': status,
          'createdAt': (data['createdAt'] as Timestamp).toDate(),
        };
      }).toList();
    });
  }

  String calculateTaskStatus(Map<String, dynamic> task, DateTime now) {
    DateTime startTime = (task['startTime'] as Timestamp).toDate();
    DateTime endTime = (task['endTime'] as Timestamp).toDate();
    String status = task['status'] ?? 'Pending';

    if (status == 'Finished') {
      return 'Finished';
    } else if (now.isAfter(startTime) && now.isBefore(endTime)) {
      return 'Overdue';
    } else if (now.isAtSameMomentAs(startTime)) {
      return 'Ongoing';
    } else if (now.isBefore(startTime)) {
      return 'Pending';
    } else {
      return 'Pending'; // Fallback
    }
  }

  void _applyFilter(String status) {
    setState(() {
      filteredTasks =
          allTasks.where((task) => task['taskStatus'] == status).toList();
    });
  }

  void _filterTasks(String query) {
    setState(() {
      filteredTasks = allTasks
          .where((task) => task['taskName']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _sortTasks() {
    setState(() {
      isAscending = !isAscending;
      filteredTasks.sort((a, b) {
        final createdAtA = a['createdAt'] as DateTime;
        final createdAtB = b['createdAt'] as DateTime;
        return isAscending
            ? createdAtA.compareTo(createdAtB)
            : createdAtB.compareTo(createdAtA);
      });
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Filter Tasks"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("All Tasks"),
                onTap: () {
                  setState(() {
                    filteredTasks = allTasks; // Reset to all tasks
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Finished"),
                onTap: () {
                  _applyFilter("Finished");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Ongoing"),
                onTap: () {
                  _applyFilter("Ongoing");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Pending"),
                onTap: () {
                  _applyFilter("Pending");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Overdue"),
                onTap: () {
                  _applyFilter("Overdue");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: "Filter tasks",
          ),
          IconButton(
            icon: Icon(
              isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: Colors.white,
            ),
            onPressed: _sortTasks,
            tooltip: "Sort tasks",
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black)),
            child: TextField(
              onChanged: _filterTasks,
              style: const TextStyle(color: Colors.black),
              cursorColor: Colors.black,
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                hintText: 'Search tasks',
                hintStyle: TextStyle(color: Colors.black),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.black),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getTaskStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error fetching tasks'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No tasks found'));
                }

                allTasks = snapshot.data!;
                if (filteredTasks.isEmpty) {
                  filteredTasks = allTasks; // Initialize filteredTasks
                }

                return ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];

                    final dueDate = task['dueDate'];
                    final formattedDueDate =
                        DateFormat('yyyy-MM-dd HH:mm').format(dueDate);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: TaskCard(
                        taskId: task['taskId'],
                        taskName: task['taskName'],
                        dueDate: formattedDueDate,
                        startTime: task['startTime'] != null
                            ? DateFormat('yyyy-MM-dd HH:mm')
                                .format(task['startTime'])
                            : 'Not specified',
                        startDateTime: task['startTime'] ?? task['dueDate'],
                        dueDateTime: dueDate,
                        taskStatus: task['taskStatus'],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
