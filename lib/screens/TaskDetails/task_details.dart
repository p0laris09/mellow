import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskDetailsScreen extends StatelessWidget {
  final String taskName;
  final String startTime;
  final String dueDate;
  final DateTime startDateTime;
  final DateTime dueDateTime;
  final String taskStatus;

  const TaskDetailsScreen({
    super.key,
    required this.taskName,
    required this.startTime,
    required this.dueDate,
    required this.startDateTime,
    required this.dueDateTime,
    required this.taskStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Details'),
        backgroundColor: const Color(0xFF2C3C3C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              taskName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start Time: $startTime',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Due Date: $dueDate',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Task Status: $taskStatus',
              style: TextStyle(
                fontSize: 18,
                color: taskStatus == 'Overdue'
                    ? Colors.red
                    : taskStatus == 'Ongoing'
                        ? Colors.green
                        : Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Task started on: ${DateFormat('yyyy-MM-dd hh:mm a').format(startDateTime)}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              'Task due on: ${DateFormat('yyyy-MM-dd hh:mm a').format(dueDateTime)}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
