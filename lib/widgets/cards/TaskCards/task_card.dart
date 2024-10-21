import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final String taskName;
  final String dueDate;
  final String startTime;
  final DateTime startDateTime;
  final DateTime dueDateTime;

  TaskCard({
    required this.taskName,
    required this.dueDate,
    required this.startTime,
    required this.startDateTime,
    required this.dueDateTime,
  });

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    bool isOverdue = dueDateTime.isBefore(now);
    bool isOngoing = now.isAfter(startDateTime) && now.isBefore(dueDateTime);
    String taskStatus = isOverdue
        ? "Overdue"
        : isOngoing
            ? "Ongoing"
            : "Pending";
    Color statusColor = isOverdue
        ? Colors.red
        : isOngoing
            ? Colors.green
            : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  'Start: $startTime',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Due: $dueDate',
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
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {
              // Handle task options
            },
          ),
        ],
      ),
    );
  }
}
