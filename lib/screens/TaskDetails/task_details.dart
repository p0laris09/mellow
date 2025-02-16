import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mellow/screens/TaskEditScreen/task_edit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskDetailsScreen extends StatefulWidget {
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
  final String importance;
  final String complexity;

  const TaskDetailsScreen({
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
    required this.importance,
    required this.complexity,
  });

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late String taskName;
  late String dueDate;
  late DateTime startDateTime;
  late DateTime dueDateTime;
  late String status;
  late String description;
  late String priority;
  late String urgency;
  late String importance;
  late String complexity;

  @override
  void initState() {
    super.initState();
    _loadTaskData();
  }

  void _loadTaskData() {
    setState(() {
      taskName = widget.taskName;
      dueDate = widget.dueDate;
      startDateTime = widget.startDateTime;
      dueDateTime = widget.dueDateTime;
      status = widget.status;
      description = widget.description;
      priority = widget.priority;
      urgency = widget.urgency;
      importance = widget.importance;
      complexity = widget.complexity;
    });
  }

  String _getPriorityLabel(String value) {
    switch (value) {
      case '3.0':
        return 'High';
      case '2.0':
        return 'Medium';
      case '1.0':
        return 'Low';
      default:
        return 'Not set';
    }
  }

  // Delete Task Functionality
  Future<void> _deleteTask() async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks') // Replace with your collection name
          .doc(widget.taskId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted successfully!')),
      );

      // Navigate back after deletion
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting task: ${e.toString()}')),
      );
    }
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
        flexibleSpace: const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              'Task Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        actions: [
          // Check Icon
          IconButton(
            icon: const Icon(
              Icons.check,
              color: Colors.white,
            ),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('tasks')
                    .doc(widget.taskId)
                    .update({'status': 'Finished'});

                setState(() {
                  status = 'Finished';
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task marked as Finished!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
          ),
          // Edit Icon
          IconButton(
            icon: const Icon(
              Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskEditScreen(
                    isEditMode: true,
                    taskId: widget.taskId,
                    taskName: widget.taskName,
                    startTime: widget.startTime,
                    dueDate: widget.dueDate,
                    status: widget.status,
                    description: widget.description,
                    priority: double.tryParse(widget.priority) ?? 0.0,
                    urgency: double.tryParse(widget.urgency) ?? 0.0,
                    importance: double.tryParse(widget.importance) ?? 0.0,
                    complexity: double.tryParse(widget.complexity) ?? 0.0,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Name',
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Text(
              taskName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Due Date',
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Text(
              dueDate,
              style: const TextStyle(fontSize: 20, color: Colors.black),
            ),
            const SizedBox(height: 16),
            const Text(
              'Status',
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'Pending'
                    ? Colors.blue
                    : status == 'Ongoing'
                        ? Colors.green
                        : status == 'Overdue'
                            ? Colors.red
                            : Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start Time',
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('hh:mm a').format(startDateTime),
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'End Time',
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('hh:mm a').format(dueDateTime),
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Description',
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 24),
            _buildPrioritySection('Priority', _getPriorityLabel(priority)),
            const SizedBox(height: 16),
            _buildPrioritySection('Urgency', _getPriorityLabel(urgency)),
            const SizedBox(height: 16),
            _buildPrioritySection('Importance', _getPriorityLabel(importance)),
            const SizedBox(height: 16),
            _buildPrioritySection('Complexity', _getPriorityLabel(complexity)),

            // Delete Task Text at the bottom
            const SizedBox(height: 40), // Adding space before delete text
            Center(
              child: GestureDetector(
                onTap: () async {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Task'),
                      content: const Text(
                          'Are you sure you want to delete this task?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _deleteTask();
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'DELETE TASK',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySection(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }
}
