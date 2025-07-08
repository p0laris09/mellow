import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskDetailsDuoScreen extends StatefulWidget {
  const TaskDetailsDuoScreen({
    super.key,
    required this.taskId,
    required this.taskName,
    required this.startTime,
    required this.dueDate,
    required this.startDateTime,
    required this.dueDateTime,
    required this.status,
    required this.description,
    required this.priority,
    required this.urgency,
    required this.complexity,
    required this.taskType,
  });

  final String taskId;
  final String taskName;
  final String startTime;
  final String dueDate;
  final DateTime startDateTime;
  final DateTime dueDateTime;
  final String status;
  final String description;
  final String priority;
  final String urgency;
  final String complexity;
  final String taskType;

  @override
  State<TaskDetailsDuoScreen> createState() => _TaskDetailsDuoScreenState();
}

class _TaskDetailsDuoScreenState extends State<TaskDetailsDuoScreen> {
  String? assignedTo;
  String? createdBy;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTaskDetails();
  }

  Future<void> fetchTaskDetails() async {
    try {
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .get();

      if (taskDoc.exists) {
        final data = taskDoc.data();
        setState(() {
          assignedTo = data?['assignedTo'] ?? 'Unknown';
          createdBy = data?['createdBy'] ?? 'Unknown';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        // Handle task not found
        print('Task not found');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle errors
      print('Error fetching task details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Task ID: ${widget.taskId}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Task Name: ${widget.taskName}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Start Time: ${widget.startTime}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Due Date: ${widget.dueDate}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Status: ${widget.status}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Description: ${widget.description}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Priority: ${widget.priority}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Urgency: ${widget.urgency}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Complexity: ${widget.complexity}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Task Type: ${widget.taskType}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Assigned To: $assignedTo',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Created By: $createdBy',
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
    );
  }
}
