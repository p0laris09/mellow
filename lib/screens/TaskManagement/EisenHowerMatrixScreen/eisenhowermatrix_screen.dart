import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mellow/screens/TaskDetails/task_details.dart';

class EisenhowerMatrixView extends StatefulWidget {
  final PageController pageController;
  final DateTime startOfWeek;
  final DateTime Function(int) getStartOfWeekFromIndex;
  final Stream<QuerySnapshot> tasksStream;
  final String selectedFilter;

  const EisenhowerMatrixView({
    required this.pageController,
    required this.startOfWeek,
    required this.getStartOfWeekFromIndex,
    required this.tasksStream,
    required this.selectedFilter,
    Key? key,
  }) : super(key: key);

  @override
  State<EisenhowerMatrixView> createState() => _EisenhowerMatrixViewState();
}

class _EisenhowerMatrixViewState extends State<EisenhowerMatrixView> {
  late DateTime _currentStartOfWeek;

  @override
  void initState() {
    super.initState();
    _currentStartOfWeek = widget.startOfWeek;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 2),
        Expanded(
          child: _buildEisenhowerMatrix(),
        ),
      ],
    );
  }

  Widget _buildEisenhowerMatrix() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildQuadrant("Urgent & Important", Colors.green),
              _buildQuadrant("Not Urgent & Important", Colors.orange),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              _buildQuadrant("Urgent & Not Important", Colors.blue),
              _buildQuadrant("Not Urgent & Not Important", Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuadrant(String title, Color color) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: widget.tasksStream,
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

                  String uid = FirebaseAuth.instance.currentUser!.uid;
                  final tasks = snapshot.data!.docs.where((taskDoc) {
                    final task = taskDoc.data() as Map<String, dynamic>;

                    // Apply the same filtering logic as in _buildTaskSection
                    if (widget.selectedFilter == 'All') {
                      return (task['taskType'] == 'personal' &&
                              task['userId'] == uid &&
                              task['status'] != 'Finished') ||
                          ((task['taskType'] == 'duo' ||
                                  task['taskType'] == 'space') &&
                              (task['assignedTo']?.contains(uid) ?? false) &&
                              task['status'] != 'Finished');
                    } else if (widget.selectedFilter == 'Personal') {
                      return task['userId'] == uid &&
                          task['taskType'] == 'personal' &&
                          task['status'] != 'Finished';
                    } else if (widget.selectedFilter == 'Shared') {
                      return task['taskType'] == 'duo' &&
                          (task['assignedTo']?.contains(uid) ?? false) &&
                          task['status'] != 'Finished';
                    } else if (widget.selectedFilter == 'Collaboration Space') {
                      return task['taskType'] == 'space' &&
                          (task['assignedTo']?.contains(uid) ?? false) &&
                          task['status'] != 'Finished';
                    }
                    return false;
                  }).where((task) {
                    // Filter tasks based on the quadrant
                    double urgency = (task.data() as Map<String, dynamic>)
                            .containsKey('urgency')
                        ? task['urgency']
                        : 0.0;
                    double priority = (task.data() as Map<String, dynamic>)
                            .containsKey('priority')
                        ? task['priority']
                        : 0.0;

                    switch (title) {
                      case "Urgent & Important": // Quadrant I
                        return (urgency >= 3 &&
                            priority >=
                                3); // Include 3 as part of high urgency and importance

                      case "Not Urgent & Important": // Quadrant II
                        return (urgency <= 2) &&
                            (priority >=
                                3); // Low urgency, but important (priority 3 or 4)

                      case "Urgent & Not Important": // Quadrant III
                        return (urgency >= 3) &&
                            (priority <= 2); // High urgency, low priority

                      case "Not Urgent & Not Important": // Quadrant IV
                        return (urgency <= 2) &&
                            (priority <= 2); // Low urgency and low priority

                      default:
                        return false;
                    }
                  }).toList();

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index].data() as Map<String, dynamic>;
                      return TaskCard(
                          task: task); // Use TaskCard to display tasks
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;

  const TaskCard({required this.task, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(task['taskName'] ?? 'Unnamed Task'),
        onTap: () {
          // Navigate to TaskDetailsScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailsScreen(
                taskId: task['taskId'] ?? '',
                taskName: task['taskName'] ?? 'Unnamed Task',
                startTime: (task['startTime'] is Timestamp)
                    ? (task['startTime'] as Timestamp).toDate().toString()
                    : '',
                dueDate: (task['dueDate'] is Timestamp)
                    ? (task['dueDate'] as Timestamp).toDate().toString()
                    : '',
                startDateTime: (task['startTime'] is Timestamp)
                    ? (task['startTime'] as Timestamp).toDate()
                    : DateTime.now(),
                dueDateTime: (task['dueDate'] is Timestamp)
                    ? (task['dueDate'] as Timestamp).toDate()
                    : DateTime.now(),
                status: task['status'] ?? 'Unknown',
                description: task['description'] ?? 'No description',
                priority: task['priority']?.toString() ?? '0',
                urgency: task['urgency']?.toString() ?? '0',
                complexity: task['complexity']?.toString() ?? '0',
              ),
            ),
          );
        },
      ),
    );
  }
}
