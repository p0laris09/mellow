import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mellow/screens/TaskDetails/task_details.dart';

class TaskCard extends StatelessWidget {
  final String taskId;
  final String taskName;
  final String dueDate;
  final String startTime;
  final DateTime startDateTime;
  final DateTime dueDateTime;
  final String taskStatus; // Accept task status from Firestore

  const TaskCard({
    super.key,
    required this.taskId,
    required this.taskName,
    required this.dueDate,
    required this.startTime,
    required this.startDateTime,
    required this.dueDateTime,
    required this.taskStatus, // Initialize task status
  });

  Future<void> _markTaskAsFinished() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({'status': 'Finished', 'userId': uid});
      print('Task marked as finished.');
    } catch (e) {
      print('Error updating task status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the task is overdue based on the due date
    bool isOverdue =
        DateTime.now().isAfter(dueDateTime) && taskStatus != 'Finished';

    // Determine task status colors based on Firestore status
    Color statusColor;
    if (taskStatus == 'Finished') {
      statusColor = Colors.green; // Finished -> Green
    } else if (taskStatus == 'ongoing') {
      statusColor = const Color.fromARGB(255, 33, 150, 243); // Ongoing -> Blue
    } else if (isOverdue) {
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

        Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;

        // Extract and convert necessary fields from Firestore
        String description =
            taskData['description'] ?? 'No description available';

        // Ensure proper type conversion to String
        String priority = (taskData['priority'] ?? 'Not set').toString();
        String urgency = (taskData['urgency'] ?? 'Not set').toString();
        String importance = (taskData['importance'] ?? 'Not set').toString();
        String complexity = (taskData['complexity'] ?? 'Not set').toString();

        // Ensure that these values are treated as strings, even if they are numbers or other types

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsScreen(
              taskId: taskId, // taskId to uniquely identify the task
              taskName: taskName, // task name
              startTime: startTime, // start time
              dueDate: dueDate, // due date
              startDateTime:
                  startDateTime, // start date time (if different from startTime)
              dueDateTime:
                  dueDateTime, // due date time (if different from dueDate)
              status: taskStatus,
              description: description, // task description
              priority: priority, // priority level
              urgency: urgency, // urgency level
              importance: importance, // importance level
              complexity: complexity, // complexity level
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:
              taskStatus == 'Finished' ? Colors.green.shade100 : Colors.white,
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
                    'Status: $taskStatus',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
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
    final isDismissible = taskStatus != 'Finished';
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
