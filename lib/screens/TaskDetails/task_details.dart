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
          Padding(
            padding: const EdgeInsets.only(right: 2.0),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.check,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.edit,
                color: Colors.white,
              ),
            ),
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
            const Text(
              'Lorem ipsum dolor sit amet, er adipiscing elit, sed dianummy nibh euismod dolor sit amet, er adipiscing elit, sed dianummy nibh euismod.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Priority Section
            _buildPrioritySection('Priority', 'Low'),
            const SizedBox(height: 16),
            _buildPrioritySection('Urgency', 'Medium'),
            const SizedBox(height: 16),
            _buildPrioritySection('Importance', 'Low'),
            const SizedBox(height: 16),
            _buildPrioritySection('Complexity', 'High'),
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
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
