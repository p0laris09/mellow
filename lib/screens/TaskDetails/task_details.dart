import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

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
  final String? createdBy; // Add createdBy field
  final List<String>? assignedTo; // Add assignedTo field (list of UIDs)

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
    this.createdBy,
    this.assignedTo,
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
  List<String> assignedToNames = [];
  String? createdByName;
  List<String> uploadedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadTaskData();
    _loadUploadedFiles();
  }

  Future<void> _loadTaskData() async {
    setState(() {
      taskName = widget.taskName;
      dueDate = widget.dueDate;
      startDateTime = widget.startDateTime;
      dueDateTime = widget.dueDateTime;
      status = widget.status;
      description = widget.description;
      priority = double.tryParse(widget.priority) ?? 0;
      urgency = double.tryParse(widget.urgency) ?? 0;
      complexity = double.tryParse(widget.complexity) ?? 0;
    });

    // Fetch createdBy name
    if (widget.createdBy != null) {
      createdByName = await _getUserName(widget.createdBy!);
      print('Created By Name: $createdByName'); // Debug print
    } else {
      print('No createdBy field found.');
    }

    // Fetch assignedTo names
    if (widget.assignedTo != null && widget.assignedTo!.isNotEmpty) {
      List<Future<String>> nameFutures =
          widget.assignedTo!.map((uid) => _getUserName(uid)).toList();
      assignedToNames = await Future.wait(nameFutures);
      print('Assigned To Names: $assignedToNames'); // Debug print
    } else {
      print('No assignedTo field found or it is empty.');
    }

    setState(() {}); // Update UI after fetching names
  }

  Future<void> _loadUploadedFiles() async {
    try {
      DocumentSnapshot taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .get();

      if (!taskDoc.exists || taskDoc.data() == null) {
        print('Task document does not exist or has no data.');
        return;
      }

      Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;

      if (taskData.containsKey('fileUrls')) {
        uploadedFiles = List<String>.from(taskData['fileUrls']);
        print('Files loaded: ${uploadedFiles.length}');
        for (var file in uploadedFiles) {
          print('File URL: $file'); // Debug print for each file URL
        }
      } else {
        print('No files found in the task document.');
      }

      setState(() {});
    } catch (e) {
      print('Error loading files: $e');
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/$fileName');

      final Reference ref = FirebaseStorage.instance.refFromURL(url);
      final DownloadTask downloadTask = ref.writeToFile(file);

      final TaskSnapshot snapshot = await downloadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fileName downloaded successfully!')),
        );
        OpenFile.open(file.path);
      } else {
        throw Exception("Download failed or file not found.");
      }
    } catch (e) {
      print('Error downloading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: ${e.toString()}')),
      );
    }
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

  Future<void> _confirmDeleteTask() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Confirm Delete',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this task? This action cannot be undone.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: const Text(
                'Cancel',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: const Text(
                'Delete',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteTask();
    }
  }

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

  Future<String> _getUserName(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String firstName = userData['firstName'] ?? '';
        String middleName = userData['middleName'] ?? '';
        String lastName = userData['lastName'] ?? '';

        // Format name as "FirstName MiddleInitial LastName"
        String middleInitial =
            middleName.isNotEmpty ? '${middleName[0]}. ' : '';
        String fullName = '$firstName $middleInitial$lastName';
        print('Fetched user name for UID $uid: $fullName'); // Debug print
        return fullName;
      } else {
        print('No user found for UID $uid'); // Debug print
      }
    } catch (e) {
      print('Error fetching user name for UID $uid: $e');
    }
    return 'Unknown User';
  }

  Widget _buildFileSection() {
    if (uploadedFiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 1, height: 20),
        const Text(
          'Files:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...uploadedFiles.map((url) {
          String fileName = Uri.parse(url).pathSegments.last;
          return ListTile(
            leading: url.endsWith('.jpg') ||
                    url.endsWith('.png') ||
                    url.endsWith('.jpeg')
                ? GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: Image.network(url),
                          );
                        },
                      );
                    },
                    child: Image.network(
                      url,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.insert_drive_file, size: 50),
            title: Text(fileName),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadFile(url, fileName),
            ),
          );
        }).toList(),
      ],
    );
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
          // Mark as Finished
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
                        _buildDetailRow(
                          'Due Date',
                          DateFormat('MMMM dd, yyyy hh:mm a')
                              .format(dueDateTime),
                        ),
                        _buildStatusChip(
                            'Status', status, _getStatusColor(status)),
                        _buildDetailRow(
                          'Start Time',
                          DateFormat('MMMM dd, yyyy hh:mm a')
                              .format(startDateTime),
                        ),
                        _buildDetailRow(
                          'End Time',
                          DateFormat('MMMM dd, yyyy hh:mm a')
                              .format(dueDateTime),
                        ),
                        _buildDetailRow('Description', description),

                        // Show Created By
                        if (createdByName != null || assignedToNames.isNotEmpty)
                          const Divider(thickness: 1, height: 20),

                        if (createdByName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Created by: $createdByName',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),

                        // Show Assigned To
                        if (assignedToNames.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Assigned to: ${assignedToNames.join(', ')}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),

                        // Show Priority, Urgency, Complexity
                        _buildDetailRow(
                            'Priority', _getPriorityLabel(priority ?? 0)),
                        _buildDetailRow(
                            'Urgency', _getPriorityLabel(urgency ?? 0)),
                        _buildDetailRow(
                            'Complexity', _getPriorityLabel(complexity ?? 0)),

                        // Add File Section
                        _buildFileSection(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Delete Button at the Bottom
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed:
                    _confirmDeleteTask, // Updated to call _confirmDeleteTask
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
