import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskDetailsSpaceScreen extends StatefulWidget {
  const TaskDetailsSpaceScreen({
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
  State<TaskDetailsSpaceScreen> createState() => _TaskDetailsSpaceScreenState();
}

class _TaskDetailsSpaceScreenState extends State<TaskDetailsSpaceScreen> {
  List<String> assignedToNames = [];
  String? createdByName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTaskDetails();
  }

  Future<void> fetchTaskDetails() async {
    try {
      DocumentSnapshot taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .get();

      Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;

      // Fetch createdBy name
      if (taskData['createdBy'] != null) {
        createdByName = await _getUserName(taskData['createdBy']);
      }

      // Fetch assignedTo names
      if (taskData['assignedTo'] != null) {
        List<Future<String>> nameFutures =
            (taskData['assignedTo'] as List<dynamic>)
                .map((uid) => _getUserName(uid))
                .toList();
        assignedToNames = await Future.wait(nameFutures);
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching task details: $e');
    }
  }

  Future<String> _getUserName(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return "${userData['firstName']} ${userData['lastName']}";
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
    return 'Unknown User';
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
                  Text('Assigned To: ${assignedToNames.join(', ')}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Created By: $createdByName',
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
    );
  }
}
