import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  double? priority;
  double? urgency;
  double? complexity;

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

      // ✅ Convert string values to double, fallback to 0 if null
      priority = double.tryParse(widget.priority) ?? 0;
      urgency = double.tryParse(widget.urgency) ?? 0;
      complexity = double.tryParse(widget.complexity) ?? 0;
    });
  }

  // ✅ Get Label for Priority, Urgency, Complexity
  String _getPriorityLabel(double value) {
    switch (value.toInt()) {
      case 5:
        return 'Very High';
      case 4:
        return 'High';
      case 3:
        return 'Medium';
      case 2:
        return 'Low';
      case 1:
        return 'Very Low';
      default:
        return 'Not set';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.grey;
      case 'ongoing':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      case 'finished':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ✅ Delete Task
  Future<void> _deleteTask() async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted successfully!')),
      );
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Task Details',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          // ✅ Mark as Finished
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('tasks')
                    .doc(widget.taskId)
                    .update({
                  'status': 'Finished',
                  'completionTime': FieldValue.serverTimestamp(),
                });

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
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Card(
                  elevation: 4,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Task Name', taskName),
                        _buildDetailRow('Due Date', dueDate),
                        _buildStatusChip(
                            'Status', status, _getStatusColor(status)),
                        _buildDetailRow('Start Time',
                            DateFormat('hh:mm a').format(startDateTime)),
                        _buildDetailRow('End Time',
                            DateFormat('hh:mm a').format(dueDateTime)),
                        _buildDetailRow('Description', description),

                        // ✅ Show Priority, Urgency, Complexity Correctly
                        _buildDetailRow(
                            'Priority', _getPriorityLabel(priority ?? 0)),
                        _buildDetailRow(
                            'Urgency', _getPriorityLabel(urgency ?? 0)),
                        _buildDetailRow(
                            'Complexity', _getPriorityLabel(complexity ?? 0)),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ✅ Delete Button at the Bottom
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _deleteTask,
                child: const Text('DELETE TASK',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value,
              style: const TextStyle(color: Colors.black, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String title, String value, Color color) {
    return Chip(
      label: Text(value, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}
