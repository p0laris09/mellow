import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mellow/screens/TaskEditScreen/task_edit.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;
  final String taskName;
  final String startTime;
  final String dueDate;
  final DateTime startDateTime;
  final DateTime dueDateTime;
  final String taskStatus;
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
    required this.taskStatus,
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
  late String taskStatus;
  late String description;
  late String priority;
  late String urgency;
  late String importance;
  late String complexity;

  @override
  void initState() {
    super.initState();
    // Simulate reloading or refreshing data by setting new values
    _loadTaskData();
  }

  // Simulate fetching data or refreshing the screen
  void _loadTaskData() {
    // You can replace this with actual data fetching from Firestore or another source
    setState(() {
      taskName = widget.taskName;
      dueDate = widget.dueDate;
      startDateTime = widget.startDateTime;
      dueDateTime = widget.dueDateTime;
      taskStatus = widget.taskStatus;
      description = widget.description;
      priority = widget.priority;
      urgency = widget.urgency;
      importance = widget.importance;
      complexity = widget.complexity;
    });
  }

  // Convert numeric values to string labels
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3C3C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3C3C),
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
        flexibleSpace: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              'Task Details',
              style: const TextStyle(
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
            onPressed: () {
              // Add your logic for the check icon
              print('Check icon pressed');
            },
          ),
          // Pen Icon - Navigate to Task Creation screen with task details
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
                    taskStatus: widget.taskStatus,
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
            // Task Name
            const Text(
              'Name',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              taskName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Due Date
            const Text(
              'Due Date',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dueDate,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Task Status
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: taskStatus == 'Pending'
                    ? Colors.blue
                    : taskStatus == 'Ongoing'
                        ? Colors.green
                        : taskStatus == 'Overdue'
                            ? Colors.red
                            : Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                taskStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Start Time and End Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Start Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start Time',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('hh:mm a').format(startDateTime),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                // End Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'End Time',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('hh:mm a').format(dueDateTime),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Priority Section
            _buildPrioritySection('Priority', _getPriorityLabel(priority)),
            const SizedBox(height: 16),
            _buildPrioritySection('Urgency', _getPriorityLabel(urgency)),
            const SizedBox(height: 16),
            _buildPrioritySection('Importance', _getPriorityLabel(importance)),
            const SizedBox(height: 16),
            _buildPrioritySection('Complexity', _getPriorityLabel(complexity)),
          ],
        ),
      ),
    );
  }

  // Helper method for Priority Section
  Widget _buildPrioritySection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
