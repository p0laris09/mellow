import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mellow/screens/TaskDetails/task_detail_space.dart';
import 'package:mellow/screens/TaskDetails/task_details.dart';
import 'package:mellow/screens/TaskDetails/task_details_duo.dart';

class TaskCard extends StatelessWidget {
  final String taskId;
  final String taskName;
  final String dueDate;
  final String startTime;
  final DateTime startDateTime;
  final DateTime dueDateTime;
  final String taskStatus; // Accept task status from Firestore
  final DateTime? completionTime; // Add completion time
  final VoidCallback onTaskFinished; // Callback to notify parent

  const TaskCard({
    super.key,
    required this.taskId,
    required this.taskName,
    required this.dueDate,
    required this.startTime,
    required this.startDateTime,
    required this.dueDateTime,
    required this.taskStatus, // Initialize task status
    this.completionTime, // Initialize completion time
    required this.onTaskFinished, // Initialize callback
  });

  Future<void> _markTaskAsFinished() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DateTime completionTime = DateTime.now();

    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'status': 'Finished',
        'userId': uid,
        'completionTime': completionTime,
      });
      print('Task marked as finished.');
      onTaskFinished(); // Notify parent widget
    } catch (e) {
      print('Error updating task status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compute dynamic status
    bool isOverdue =
        DateTime.now().isAfter(dueDateTime) && taskStatus != 'Finished';
    bool isOngoing = DateTime.now().isAfter(startDateTime) &&
        DateTime.now().isBefore(dueDateTime);

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

    // Determine task status colors based on the computed statusLabel
    Color statusColor;
    if (statusLabel == 'Finished') {
      statusColor = Colors.green; // Finished -> Green
    } else if (statusLabel == 'Ongoing') {
      statusColor = const Color.fromARGB(255, 33, 150, 243); // Ongoing -> Blue
    } else if (statusLabel == 'Overdue') {
      statusColor = Colors.red; // Overdue -> Red
    } else {
      statusColor = Colors.grey; // Pending -> Grey
    }

    // Define the child widget content
    final taskContent = GestureDetector(
      onTap: () async {
        // Fetch additional task details from Firestore
        DocumentSnapshot taskDoc = await FirebaseFirestore.instance
            .collection('tasks')
            .doc(taskId)
            .get();

        if (!taskDoc.exists || taskDoc.data() == null) {
          print('Task document does not exist or has no data.');
          return;
        }

        Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;

        // Extract and convert necessary fields from Firestore
        String description =
            taskData['description'] ?? 'No description available';
        String priority = (taskData['priority'] ?? 'Not set').toString();
        String urgency = (taskData['urgency'] ?? 'Not set').toString();
        String complexity = (taskData['complexity'] ?? 'Not set').toString();

        // Determine the appropriate screen based on task type
        Widget targetScreen;
        if (taskData['taskType'] == 'personal') {
          targetScreen = TaskDetailsScreen(
            taskId: taskId,
            taskName: taskName,
            startTime: startTime,
            dueDate: dueDate,
            startDateTime: startDateTime,
            dueDateTime: dueDateTime,
            status: statusLabel, // Pass the computed statusLabel
            description: description,
            priority: priority,
            urgency: urgency,
            complexity: complexity,
          );
        } else if (taskData['taskType'] == 'duo') {
          targetScreen = TaskDetailsDuoScreen(
            taskId: taskId,
            taskName: taskName,
            startTime: startTime,
            dueDate: dueDate,
            startDateTime: startDateTime,
            dueDateTime: dueDateTime,
            status: statusLabel, // Pass the computed statusLabel
            description: description,
            priority: priority,
            urgency: urgency,
            complexity: complexity, taskType: taskData['taskType'],
          );
        } else if (taskData['taskType'] == 'space') {
          targetScreen = TaskDetailsSpaceScreen(
            taskId: taskId,
            taskName: taskName,
            startTime: startTime,
            dueDate: dueDate,
            startDateTime: startDateTime,
            dueDateTime: dueDateTime,
            status: statusLabel, // Pass the computed statusLabel
            description: description,
            priority: priority,
            urgency: urgency,
            complexity: complexity,
            taskType:
                taskData['taskType'], // Pass taskType to match constructor
          );
        } else {
          throw Exception('Unknown task type: ${taskData['taskType']}');
        }

        // Check if the widget is still mounted before navigating
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => targetScreen,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:
              statusLabel == 'Finished' ? Colors.green.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.task, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    taskName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    'Start: ${DateFormat('yyyy-MM-dd HH:mm').format(startDateTime)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Due: ${DateFormat('yyyy-MM-dd HH:mm').format(dueDateTime)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: $statusLabel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (statusLabel == 'Finished' && completionTime != null)
                    Text(
                      'Completed: ${DateFormat('yyyy-MM-dd HH:mm').format(completionTime!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Return the Dismissible widget only if the task is not finished
    final isDismissible = statusLabel != 'Finished';
    if (isDismissible) {
      return Dismissible(
        key: Key(taskId),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.green,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 32,
          ),
        ),
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            _markTaskAsFinished(); // Mark as finished in Firestore
          }
        },
        child: taskContent,
      );
    } else {
      // If the task is finished, return the content without the Dismissible wrapper
      return taskContent;
    }
  }
}
