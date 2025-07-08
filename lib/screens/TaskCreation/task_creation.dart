import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mellow/models/TaskModel/task_model.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class TaskCreationScreen extends StatefulWidget {
  const TaskCreationScreen({super.key});

  @override
  State<TaskCreationScreen> createState() => _TaskCreationScreenState();
}

class TaskManager {
  List<Task> tasks = [];

  Future<void> loadTasksFromFirestore(
      String userId, Map<String, double> criteriaWeights) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();

      tasks = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Handle the 'assignedTo' field (String or List<dynamic>)
        String assignedTo = '';
        if (data['assignedTo'] is String) {
          assignedTo = data['assignedTo'] as String;
        } else if (data['assignedTo'] is List<dynamic>) {
          assignedTo = (data['assignedTo'] as List<dynamic>).join(', ');
        }

        Task task = Task(
          userId: data['userId'] ?? '', // Ensure userId is not null
          taskName: data['taskName'] ?? 'Untitled', // Default name if missing
          dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          startTime:
              (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          description: data['description'] ?? '', // Default empty description
          priority: (data['priority'] as num?)?.toDouble() ?? 1.0,
          urgency: (data['urgency'] as num?)?.toDouble() ?? 1.0,
          complexity: (data['complexity'] as num?)?.toDouble() ?? 1.0,
          taskType: data['taskType'] ?? 'personal', // Provide default task type
          assignedTo: assignedTo, // Handle mixed data types
        );

        task.updateWeight(criteriaWeights);
        return task;
      }).toList();

      print("Loaded ${tasks.length} tasks for user $userId.");
    } catch (e) {
      print("Error loading tasks: $e");
    }
  }

  Future<int> _getTaskPreference(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('task_preference')
        .doc(userId)
        .get();
    String taskPreferenceString = userDoc['tasksPerHour'] ?? "4";
    return _parseTaskPreference(taskPreferenceString);
  }

  int _parseTaskPreference(String taskPreferenceString) {
    final RegExp regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(taskPreferenceString);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 4; // Default to 4 if no number is found
  }

  Future<List<DateTime>> suggestBestTimes(Task newTask, String userId) async {
    List<DateTime> bestTimes = [];
    Duration taskDuration = newTask.endTime.difference(newTask.startTime);

    const int daysToCheck = 7;
    DateTime now = DateTime.now();
    int taskPreference = await _getTaskPreference(userId);

    for (int i = 0; i < daysToCheck; i++) {
      DateTime checkDate = now.add(Duration(days: i));
      DateTime startOfDay =
          DateTime(checkDate.year, checkDate.month, checkDate.day, 8, 0);
      DateTime endOfDay =
          DateTime(checkDate.year, checkDate.month, checkDate.day, 20, 0);

      for (DateTime time = startOfDay;
          time.isBefore(endOfDay);
          time = time.add(Duration(minutes: 30))) {
        DateTime proposedStart = time;
        DateTime proposedEnd = proposedStart.add(taskDuration);

        // Check for the number of tasks in the proposed time slot
        int taskCount = tasks
            .where((task) =>
                task.startTime.isBefore(proposedEnd) &&
                task.endTime.isAfter(proposedStart))
            .length;

        // Ensure the number of tasks does not exceed the user's preference
        if (taskCount < taskPreference &&
            proposedStart.isAfter(now.subtract(Duration(minutes: 5)))) {
          bestTimes.add(proposedStart);
          print("Valid slot found: ${proposedStart.toIso8601String()}");

          // Stop once we've found 2 best times
          if (bestTimes.length >= 2) break;
        }
      }

      // Stop after finding 2 best times across days
      if (bestTimes.length >= 2) break;
    }

    // Return the best times (up to 2), or an empty list if no valid times are found
    return bestTimes.isNotEmpty ? bestTimes.take(2).toList() : [];
  }

  Future<void> addTaskWithConflictResolution(
    Task newTask,
    BuildContext context,
    String? userId,
    Function(Task) onTaskResolved,
    Map<String, double> criteriaWeights,
  ) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    // Adjust task details based on existing tasks with the same name
    adjustTaskDetails(newTask);

    // Update the task's weight before checking conflicts
    newTask.updateWeight(criteriaWeights);

    // Initialize task count with the new task
    int taskCount = 1;

    // Check for any conflicts and calculate the number of overlapping tasks
    for (var task in tasks) {
      task.updateWeight(
          criteriaWeights); // Ensure each task's weight is updated
      if (newTask.overlapsWith(task)) {
        taskCount++; // Increment task count for each conflicting task
        print(
            "Conflict with task: ${task.taskName}, Task count now: $taskCount");
      }
    }

    print("Total task count after checking for conflicts: $taskCount");

    // Get the user's task preference
    int taskPreference = await _getTaskPreference(userId);

    // Check if task count exceeds the user's preference
    if (taskCount > taskPreference) {
      print(
          "Task count exceeds the user's preference, showing conflict dialog.");
      await showConflictDialog(newTask, context, onTaskResolved, userId);
    } else {
      // No conflict, add the task directly
      print("No conflict detected, adding the task directly.");
      onTaskResolved(newTask); // Immediately resolve the task
    }
  }

  // Automatically adjust task details based on existing tasks with the same name
  void adjustTaskDetails(Task newTask) {
    for (var task in tasks) {
      if (task.userId == newTask.userId && task.taskName == newTask.taskName) {
        // Adjust priority, urgency, and complexity
        newTask.priority = task.priority;
        newTask.urgency = task.urgency;
        newTask.complexity = task.complexity;

        // Adjust due date, start time, and end time based on the day of the week
        DateTime now = DateTime.now();
        DateTime adjustedDueDate = task.dueDate;
        DateTime adjustedStartTime = task.startTime;
        DateTime adjustedEndTime = task.endTime;

        // Ensure the adjusted times are in the future
        if (adjustedDueDate.isBefore(now)) {
          int daysToAdd = (now.weekday - task.dueDate.weekday) % 7;
          if (daysToAdd <= 0) {
            daysToAdd += 7;
          }
          adjustedDueDate = now.add(Duration(days: daysToAdd));
        }

        adjustedStartTime = DateTime(
          adjustedDueDate.year,
          adjustedDueDate.month,
          adjustedDueDate.day,
          task.startTime.hour,
          task.startTime.minute,
        );

        adjustedEndTime = DateTime(
          adjustedDueDate.year,
          adjustedDueDate.month,
          adjustedDueDate.day,
          task.endTime.hour,
          task.endTime.minute,
        );

        // If the adjusted start time is before now, move it to the next day
        if (adjustedStartTime.isBefore(now)) {
          adjustedStartTime = adjustedStartTime.add(Duration(days: 1));
          adjustedEndTime = adjustedEndTime.add(Duration(days: 1));
        }

        newTask.dueDate = adjustedDueDate;
        newTask.startTime = adjustedStartTime;
        newTask.endTime = adjustedEndTime;

        print(
            'Adjusted task details for "${newTask.taskName}" based on existing task.');
        break;
      }
    }
  }

  Future<void> showConflictDialog(
    Task conflictingTask,
    BuildContext context,
    Function(Task) onTaskResolved,
    String userId,
  ) async {
    List<DateTime> bestTimes = await suggestBestTimes(conflictingTask, userId);
    final duration =
        conflictingTask.endTime.difference(conflictingTask.startTime);

    if (bestTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available time slots found.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  'Task Conflict Detected',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2275AA),
                  ),
                ),
                const SizedBox(height: 12),
                // Conflict Message
                Text(
                  'The task "${conflictingTask.taskName}" conflicts with other tasks in your schedule. Please select a new time:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                // Suggested Times
                for (var i = 0; i < bestTimes.length; i++)
                  _buildTimeCard(
                    context: context,
                    startTime: bestTimes[i],
                    endTime: bestTimes[i].add(duration),
                    label: i == 0
                        ? "Suggested Best Time"
                        : "Alternative Time ${i + 1}",
                    onSelect: () {
                      conflictingTask.startTime = bestTimes[i];
                      conflictingTask.endTime = bestTimes[i].add(duration);
                      onTaskResolved(conflictingTask);
                      Navigator.pop(context);
                    },
                  ),
                const SizedBox(height: 16),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2275AA)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2275AA),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2275AA),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Change Manually',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Improved Time Card with Start and End Time
  Widget _buildTimeCard({
    required BuildContext context,
    required DateTime startTime,
    required DateTime endTime,
    required String label,
    required VoidCallback onSelect,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2275AA),
              ),
            ),
            const SizedBox(height: 6),
            // Start Time
            Row(
              children: [
                const SizedBox(width: 8),
                Text(
                  'Start: ${DateFormat('EEEE, MMM d, hh:mm a').format(startTime)}',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // End Time
            Row(
              children: [
                const Icon(Icons.access_time_filled,
                    size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'End: ${DateFormat('EEEE, MMM d, hh:mm a').format(endTime)}',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Choose Time Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onSelect,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF2275AA),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Choose'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCreationScreenState extends State<TaskCreationScreen> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // This will be automatically set as 'personal' for personal tasks
  String taskType = 'personal';

  int _descriptionCharCount = 0;
  double _priority = 1;
  double _urgency = 1;
  double _complexity = 1;

  // State variable for the toggle button
  bool _autoFillEnabled = true;

  List<PlatformFile> _selectedFiles = []; // List to store selected files

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true, // Allow multiple file selection
        type: FileType.custom, // Restrict file types
        allowedExtensions: [
          'txt',
          'pdf',
          'doc',
          'docx',
          'jpeg',
          'jpg',
          'png'
        ], // Allowed file types
      );

      if (result != null) {
        // Check file size limit (150MB)
        List<PlatformFile> validFiles = result.files.where((file) {
          return file.size <= 150 * 1024 * 1024; // 150MB in bytes
        }).toList();

        if (validFiles.length != result.files.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Some files were not added because they exceed the 150MB limit.'),
              backgroundColor: Colors.red,
            ),
          );
        }

        setState(() {
          _selectedFiles.addAll(validFiles); // Add valid files to the list
        });

        // Show an indicator that files have been added
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${validFiles.length} file(s) added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error picking files: $e'); // Log the error to the debug console
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking files: $e')),
      );
    }
  }

  Future<void> _uploadFilesToFirebase(String taskId) async {
    try {
      List<String> fileUrls = []; // List to store file URLs

      for (var file in _selectedFiles) {
        final String filePath = file.path!;
        final File localFile = File(filePath);

        // Generate a unique ID for the file
        String fileId = const Uuid().v4();

        // Upload file to Firebase Storage under 'task/<taskId>/files/<fileId>'
        final firebase_storage.Reference storageRef = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('task/$taskId/files/$fileId');
        final firebase_storage.UploadTask uploadTask =
            storageRef.putFile(localFile);

        // Wait for the upload to complete
        final firebase_storage.TaskSnapshot snapshot = await uploadTask;

        // Get the download URL
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        // Add the file URL to the list
        fileUrls.add(downloadUrl);
      }

      // Update the task document with the file URLs
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'fileUrls':
            FieldValue.arrayUnion(fileUrls), // Append file URLs to the array
        'timestamp':
            FieldValue.serverTimestamp(), // Add a timestamp for the update
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Files uploaded successfully!')),
        );
      }
    } catch (e) {
      print('Error uploading files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading files: $e')),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();

    _descriptionController.addListener(() {
      setState(() {
        _descriptionCharCount = _descriptionController.text.length;
      });
    });
  }

  Future<void> _selectDateTime(
      BuildContext context, TextEditingController controller) async {
    DateTime now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now, // Prevent picking past dates
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor:
                const Color(0xFF2275AA), // Match the page primary color
            hintColor: const Color(0xFF2275AA), // Match the page accent color
            colorScheme: ColorScheme.light(primary: const Color(0xFF2275AA)),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor:
                  const Color(0xFF2275AA), // Match the page primary color
              hintColor: const Color(0xFF2275AA), // Match the page accent color
              colorScheme: const ColorScheme.light(primary: Color(0xFF2275AA)),
              buttonTheme:
                  const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (combinedDateTime.isAfter(now)) {
          // Only allow future times
          String formattedDateTime =
              DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);
          controller.text = formattedDateTime;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a future time.')),
          );
        }
      }
    }
  }

  Future<void> _createTaskInFirestore() async {
    String taskName = _taskNameController.text;
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      _showAlertDialog('User not authenticated');
      return;
    }

    if (taskName.isEmpty) {
      _showAlertDialog('Please enter a task name');
      return;
    }

    TaskManager taskManager = TaskManager();

    Map<String, double> criteriaWeights = {
      'priority': _priority,
      'urgency': _urgency,
      'complexity': _complexity,
    };

    await taskManager.loadTasksFromFirestore(userId, criteriaWeights);

    // Debugging: Check if tasks are actually loaded
    print('Loaded tasks: ${taskManager.tasks.map((t) => t.taskName).toList()}');

    Task? existingTask = taskManager.tasks.firstWhereOrNull(
      (task) => task.taskName == taskName && task.userId == userId,
    );

    if (_autoFillEnabled && existingTask != null) {
      setState(() {
        _descriptionController.text = existingTask.description;
        _priority = existingTask.priority;
        _urgency = existingTask.urgency;
        _complexity = existingTask.complexity;
      });

      // Suggest best times
      List<DateTime> bestTimes =
          await taskManager.suggestBestTimes(existingTask, userId);
      if (bestTimes.isNotEmpty) {
        setState(() {
          _dueDateController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(bestTimes[0]);
          _startTimeController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(bestTimes[0]);
          _endTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(
            bestTimes[0]
                .add(existingTask.endTime.difference(existingTask.startTime)),
          );
        });
        return;
      }
    }

    // Proceed with task creation
    if (_dueDateController.text.isEmpty ||
        _startTimeController.text.isEmpty ||
        _endTimeController.text.isEmpty) {
      _showAlertDialog('Please fill in all fields');
      return;
    }

    DateTime dueDate =
        DateFormat('yyyy-MM-dd HH:mm').parse(_dueDateController.text);
    DateTime startTime =
        DateFormat('yyyy-MM-dd HH:mm').parse(_startTimeController.text);
    DateTime endTime =
        DateFormat('yyyy-MM-dd HH:mm').parse(_endTimeController.text);

    Task newTask = Task(
      userId: userId,
      taskName: taskName,
      dueDate: dueDate,
      startTime: startTime,
      endTime: endTime,
      description: _descriptionController.text,
      priority: _priority,
      urgency: _urgency,
      complexity: _complexity,
      taskType: taskType,
      assignedTo: userId,
    );

    await taskManager.addTaskWithConflictResolution(
      newTask,
      context,
      userId,
      (resolvedTask) async {
        await _addTaskToFirestore(resolvedTask, userId);
        await _uploadFilesToFirebase(resolvedTask.taskName);
      },
      criteriaWeights,
    );
  }

  void _showAlertDialog(String errorMessage) {
    print(errorMessage); // Print the error message to the debug console
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2275AA),
          title:
              const Text("Empty Fields", style: TextStyle(color: Colors.white)),
          content:
              Text(errorMessage, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: const Text("OK", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addTaskToFirestore(Task task, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(task.taskName)
          .set({
        'taskName': task.taskName,
        'dueDate': Timestamp.fromDate(task.dueDate),
        'startTime': Timestamp.fromDate(task.startTime),
        'endTime': Timestamp.fromDate(task.endTime),
        'description': task.description,
        'priority': task.priority,
        'urgency': task.urgency,
        'complexity': task.complexity,
        'weight': task.weight,
        'createdAt': Timestamp.now(),
        'userId': userId,
        'assignedTo': task.assignedTo, // Save the user's UID here
        'status': 'pending',
        'taskType': task.taskType,
        'fileUrls': [], // Initialize an empty fileUrls array
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error creating task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating task: $e')),
      );
    }
  }

  Widget _buildFileUploadNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD), // Light blue background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2275AA), width: 1.5),
        ),
        padding: const EdgeInsets.all(16.0),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Color(0xFF2275AA),
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'You can upload files with the following extensions: txt, pdf, doc, docx, jpeg, jpg, png. Maximum file size is 150MB.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2275AA),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2275AA),
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
        title: const Text(
          'Create a Task',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 35,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 400,
                    child: TextField(
                      controller: _taskNameController,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Task Name",
                        labelStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    width: 300,
                    child: GestureDetector(
                      onTap: () {
                        // Open the date picker when the field is tapped
                        _selectDateTime(context, _dueDateController);
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _dueDateController,
                          readOnly: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Due Date",
                            labelStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            border: const UnderlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today,
                                  color: Colors.white),
                              onPressed: () {
                                _selectDateTime(context, _dueDateController);
                              },
                            ),
                            hintText: 'yyyy-mm-dd hh:mm',
                            hintStyle: const TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 45),
            SizedBox(
              height: 1000,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          child: GestureDetector(
                            onTap: () {
                              // Open the time picker when the field is tapped
                              _selectDateTime(context, _startTimeController);
                            },
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _startTimeController,
                                readOnly: true,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  labelText: "Start Time",
                                  labelStyle: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  border: const UnderlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.access_time,
                                        color: Colors.black),
                                    onPressed: () {
                                      _selectDateTime(
                                          context, _startTimeController);
                                    },
                                  ),
                                  hintText: 'hh:mm',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 25),
                        SizedBox(
                          width: 150,
                          child: GestureDetector(
                            onTap: () {
                              // Open the time picker when the field is tapped
                              _selectDateTime(context, _endTimeController);
                            },
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _endTimeController,
                                readOnly: true,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  labelText: "End Time",
                                  labelStyle: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  border: const UnderlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.access_time,
                                        color: Colors.black),
                                    onPressed: () {
                                      _selectDateTime(
                                          context, _endTimeController);
                                    },
                                  ),
                                  hintText: 'hh:mm',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      width: 325,
                      child: TextField(
                        controller: _descriptionController,
                        style: const TextStyle(color: Colors.black),
                        maxLines: 4,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(250)
                        ],
                        decoration: InputDecoration(
                          labelText: "Description",
                          labelStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: const UnderlineInputBorder(),
                          suffixText: "$_descriptionCharCount/250",
                        ),
                      ),
                    ),
                    const SizedBox(height: 45),
                    _buildSlider("Priority", _priority, (value) {
                      setState(() {
                        _priority = value;
                      });
                    }),
                    const SizedBox(height: 15),
                    _buildSlider("Urgency", _urgency, (value) {
                      setState(() {
                        _urgency = value;
                      });
                    }),
                    const SizedBox(height: 15),
                    _buildSlider("Complexity", _complexity, (value) {
                      setState(() {
                        _complexity = value;
                      });
                    }),
                    const SizedBox(height: 25),
                    _buildFileUploadNote(),
                    ElevatedButton(
                      onPressed: _pickFiles,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 20,
                        ),
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF2275AA),
                      ),
                      child: const Text('Attach Files'),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _selectedFiles.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_selectedFiles[index].name),
                            subtitle: Text(
                                '${(_selectedFiles[index].size / (1024 * 1024)).toStringAsFixed(2)} MB'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeFile(index),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _createTaskInFirestore,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 20,
                            ),
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF2275AA),
                          ),
                          child: const Text('Create Task'),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: Icon(
                            _autoFillEnabled
                                ? Icons.auto_awesome
                                : Icons.auto_awesome_outlined,
                            color: _autoFillEnabled ? Colors.green : Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              _autoFillEnabled = !_autoFillEnabled;
                            });
                          },
                          tooltip: 'Toggle Auto-Fill',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
      String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black), // Set header text color to black
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Very Low',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black)), // Set text color to black
            Text('Low',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black)), // Set text color to black
            Text('Medium',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black)), // Set text color to black
            Text('High',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black)), // Set text color to black
            Text('Very High',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black)), // Set text color to black
          ],
        ),
        Slider(
          value: value,
          min: 1, // Start at 1
          max: 5, // End at 5
          divisions: 4, // Allow only whole numbers
          onChanged: onChanged,
          activeColor: const Color(0xFF2275AA), // Set active color to blue
          inactiveColor:
              const Color(0xFFB0C4DE), // Set inactive color to light blue
        ),
      ],
    );
  }
}
