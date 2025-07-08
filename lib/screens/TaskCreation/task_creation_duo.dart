import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mellow/models/TaskModel/task_model_duo.dart';

class TaskCreationDuo extends StatefulWidget {
  const TaskCreationDuo({super.key});

  @override
  State<TaskCreationDuo> createState() => _TaskCreationDuoState();
}

class TaskManager {
  List<TaskDuo> tasks = [];

  Future<void> loadTasksFromFirestore(
      String assignedTo, Map<String, double> criteriaWeights) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: assignedTo)
          .get();

      tasks = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Safely handle missing fields with default values
        TaskDuo task = TaskDuo(
          userId: data['userId'] ?? '', // Default to an empty string
          taskName:
              data['taskName'] ?? 'Unnamed Task', // Default to 'Unnamed Task'
          dueDate: (data['dueDate'] as Timestamp?)?.toDate() ??
              DateTime.now(), // Default to now
          startTime: (data['startTime'] as Timestamp?)?.toDate() ??
              DateTime.now(), // Default to now
          endTime: (data['endTime'] as Timestamp?)?.toDate() ??
              DateTime.now()
                  .add(const Duration(hours: 1)), // Default to 1 hour from now
          description: data['description'] ?? '', // Default to an empty string
          priority:
              (data['priority'] as num?)?.toDouble() ?? 1.0, // Default to 1.0
          urgency:
              (data['urgency'] as num?)?.toDouble() ?? 1.0, // Default to 1.0
          complexity:
              (data['complexity'] as num?)?.toDouble() ?? 1.0, // Default to 1.0
          taskType: data['taskType'] ?? 'duo', // Default to 'general'
          assignedTo: data['assignedTo'] ?? '', // Default to an empty string
          createdBy: data['createdBy'] ?? '', // Default to an empty string
        );

        task.updateWeight(criteriaWeights); // Pass criteriaWeights
        return task;
      }).toList();

      print("Loaded ${tasks.length} tasks for user $assignedTo.");
    } catch (e) {
      print("Error loading tasks: $e");
    }
  }

  Future<int> _getTaskPreference(String assignedTo) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('task_preference')
        .doc(assignedTo)
        .get();
    if (userDoc.exists) {
      String taskPreferenceString = userDoc['tasksPerHour'] ?? "4";
      return _parseTaskPreference(taskPreferenceString);
    } else {
      return 4; // Default to 4 if the document does not exist
    }
  }

  int _parseTaskPreference(String taskPreferenceString) {
    final RegExp regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(taskPreferenceString);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 4; // Default to 4 if no number is found
  }

  Future<List<DateTime>> suggestBestTimes(
      TaskDuo newTask, String assignedTo) async {
    List<DateTime> bestTimes = [];
    Duration taskDuration = newTask.endTime.difference(newTask.startTime);

    const int daysToCheck = 7;
    DateTime now = DateTime.now();
    int taskPreference = await _getTaskPreference(assignedTo);

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
    TaskDuo newTask,
    BuildContext context,
    String? assignedTo,
    Function(TaskDuo) onTaskResolved,
    Map<String, double> criteriaWeights,
  ) async {
    if (assignedTo == null) {
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
    int taskPreference = await _getTaskPreference(assignedTo);

    // Check if task count exceeds the user's preference
    if (taskCount > taskPreference) {
      print(
          "Task count exceeds the user's preference, showing conflict dialog.");
      await showConflictDialog(newTask, context, onTaskResolved, assignedTo);
    } else {
      // No conflict, add the task directly
      print("No conflict detected, adding the task directly.");
      onTaskResolved(newTask); // Immediately resolve the task
    }
  }

  // Automatically adjust task details based on existing tasks with the same name
  void adjustTaskDetails(TaskDuo newTask) {
    for (var task in tasks) {
      if (task.assignedTo == newTask.assignedTo &&
          task.taskName == newTask.taskName) {
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
    TaskDuo conflictingTask,
    BuildContext context,
    Function(TaskDuo) onTaskResolved,
    String assignedTo,
  ) async {
    List<DateTime> bestTimes =
        await suggestBestTimes(conflictingTask, assignedTo);
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
                const Icon(Icons.access_time_filled,
                    size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Start: ${DateFormat('EEE, MMM d, hh:mm a').format(startTime)}',
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
                  'End: ${DateFormat('EEE, MMM d, hh:mm a').format(endTime)}',
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

class _TaskCreationDuoState extends State<TaskCreationDuo> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String taskType = 'duo';
  String? _selectedMember;
  String? _selectedDuoSpace;
  final List<String> _DuoSpace = [];
  final List<String> _member = [];
  Map<String, String> _memberMap = {}; // Define the _memberMap variable
  Map<String, String> _spaceIdMap = {}; // Maps spaceId to spaceName

  List<PlatformFile> _selectedFiles = []; // List to store selected files

  @override
  void initState() {
    super.initState();
    _fetchDuoSpacesAndMembers();
    _descriptionController.addListener(() {
      setState(() {
        _descriptionCharCount = _descriptionController.text.length;
      });
    });
  }

  Future<void> _fetchDuoSpacesAndMembers() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    try {
      // Fetch Duo Spaces
      QuerySnapshot duoSpacesSnapshot = await FirebaseFirestore.instance
          .collection('spaces')
          .where('members', arrayContains: userId)
          .where('spaceType', isEqualTo: 'duo')
          .get();

      Map<String, String> duoSpaces = {
        for (var doc in duoSpacesSnapshot.docs)
          doc.id: doc['name'] as String, // Map spaceId to space name
      };

      setState(() {
        _DuoSpace.clear();
        _DuoSpace.addAll(
            duoSpaces.entries.map((entry) => entry.value).toList());
        _spaceIdMap = duoSpaces; // Store the spaceId-to-name mapping
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching duo spaces: $e')),
      );
    }
  }

  Future<void> _fetchMembersOfSelectedSpace(String selectedSpace) async {
    try {
      // Fetch the selected space document
      QuerySnapshot spaceSnapshot = await FirebaseFirestore.instance
          .collection('spaces')
          .where('name', isEqualTo: selectedSpace)
          .get();

      if (spaceSnapshot.docs.isNotEmpty) {
        DocumentSnapshot spaceDoc = spaceSnapshot.docs.first;
        List<dynamic> memberIds = spaceDoc['members'];

        // Fetch Members of the selected space
        Map<String, String> members = {};
        for (var memberId in memberIds) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(memberId)
              .get();
          String memberName = '${userDoc['firstName']} ${userDoc['lastName']}';
          if (!members.containsKey(memberId)) {
            members[memberId] = memberName;
          }
        }

        setState(() {
          _memberMap = members; // Store the UID and name in a map
          _member.clear();
          _member
              .addAll(members.values); // Populate the _member list with names
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error fetching members of the selected space: $e')),
      );
    }
  }

  int _descriptionCharCount = 0;
  double _priority = 1;
  double _urgency = 1;
  double _complexity = 1;

  // State variable for the toggle button
  bool _autoFillEnabled = true;

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
            colorScheme: const ColorScheme.light(primary: Color(0xFF2275AA)),
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

  Future<void> _pickFiles() async {
    try {
      // Ensure FilePicker is properly initialized
      if (FilePicker.platform == null) {
        throw Exception('FilePicker platform is not initialized.');
      }

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

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _createTaskInFirestore() async {
    String taskName = _taskNameController.text.trim();
    String? createdBy = FirebaseAuth.instance.currentUser?.uid;

    if (createdBy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    String? selectedMemberUid = _memberMap.entries
        .firstWhereOrNull((entry) => entry.value == _selectedMember)
        ?.key;

    if (selectedMemberUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected member UID not found')),
      );
      return;
    }

    // Ensure a task name is provided
    if (taskName.isEmpty) {
      _showAlertDialog('Please provide a task name before proceeding.');
      return;
    }

    TaskManager taskManager = TaskManager();
    Map<String, double> criteriaWeights = {
      'priority': _priority,
      'urgency': _urgency,
      'complexity': _complexity,
    };

    // Load tasks and wait until they are retrieved
    await taskManager.loadTasksFromFirestore(
        selectedMemberUid, criteriaWeights);

    print("Loaded tasks count: ${taskManager.tasks.length}");

    if (taskManager.tasks.isEmpty) {
      print("No tasks found for selected member");
    } else {
      // Find existing task assigned to the selected user with the same task name
      TaskDuo? existingTask;
      for (var task in taskManager.tasks) {
        print(
            "Checking task: ${task.taskName}, assignedTo: ${task.assignedTo}");
        if (task.assignedTo == selectedMemberUid &&
            task.taskName.toLowerCase() == taskName.toLowerCase()) {
          existingTask = task;
          break;
        }
      }

      if (_autoFillEnabled && existingTask != null) {
        print("Auto-filling task: ${existingTask.taskName}");
        setState(() {
          _taskNameController.text = existingTask!.taskName;
          _descriptionController.text = existingTask.description;
          _priority = existingTask.priority;
          _urgency = existingTask.urgency;
          _complexity = existingTask.complexity;
        });

        // Suggest best time slots
        List<DateTime> bestTimes =
            await taskManager.suggestBestTimes(existingTask, selectedMemberUid);

        if (bestTimes.isEmpty) {
          print("No available time slots found.");
        } else {
          print("Suggested time slot: ${bestTimes[0]}");
          setState(() {
            _dueDateController.text =
                DateFormat('yyyy-MM-dd HH:mm').format(bestTimes[0]);
            _startTimeController.text =
                DateFormat('yyyy-MM-dd HH:mm').format(bestTimes[0]);
            _endTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(
                bestTimes[0].add(
                    existingTask!.endTime.difference(existingTask.startTime)));
          });
        }
        return; // **Exit to prevent duplicate task creation**
      }
    }

    // Validate required fields
    if (_taskNameController.text.isEmpty ||
        _dueDateController.text.isEmpty ||
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

    TaskDuo newTask = TaskDuo(
      userId: selectedMemberUid,
      taskName: taskName,
      dueDate: dueDate,
      startTime: startTime,
      endTime: endTime,
      description: _descriptionController.text,
      priority: _priority,
      urgency: _urgency,
      complexity: _complexity,
      taskType: taskType,
      assignedTo: selectedMemberUid,
      createdBy: createdBy,
    );

    await taskManager.addTaskWithConflictResolution(
      newTask,
      context,
      selectedMemberUid,
      (resolvedTask) async {
        await _addTaskToFirestore(resolvedTask, createdBy);
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

  Future<void> _addTaskToFirestore(TaskDuo task, String createdBy) async {
    try {
      // Add the task to the Firestore 'tasks' collection
      DocumentReference taskRef =
          await FirebaseFirestore.instance.collection('tasks').add({
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
        'userId': task.userId,
        'status': 'pending',
        'taskType': task.taskType,
        'assignedTo': task.assignedTo,
        'createdBy': createdBy,
        'spaceId': _selectedDuoSpace, // Save the spaceId (document ID)
      });

      // Fetch user details for notifications and activities
      DocumentSnapshot createdByUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(createdBy)
          .get();
      String createdByName =
          '${createdByUserDoc['firstName']} ${createdByUserDoc['lastName']}';

      DocumentSnapshot? assignedToUserDoc;
      String? assignedToName;
      if (task.assignedTo != createdBy) {
        assignedToUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(task.assignedTo)
            .get();
        assignedToName =
            '${assignedToUserDoc['firstName']} ${assignedToUserDoc['lastName']}';
      }

      // Add a notification
      if (task.assignedTo == createdBy) {
        // Notification for the creator (self-assigned task)
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': createdBy,
          'receiverId': createdBy, // Receiver is the creator
          'message':
              '$createdByName created a task in duo space $_selectedDuoSpace',
          'timestamp': Timestamp.now(),
          'taskId': taskRef.id,
          'type': 'space', // Added type field
          'title': 'space', // Added title field
        });
      } else {
        // Notification for the assigned user
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': task.assignedTo,
          'receiverId': task.assignedTo, // Receiver is the assigned user
          'message': '$createdByName created a task for you!',
          'timestamp': Timestamp.now(),
          'taskId': taskRef.id,
          'type': 'space', // Added type field
          'title': 'space', // Added title field
        });
      }

      // Add an activity
      if (task.assignedTo == createdBy) {
        // Activity for self-assigned task
        await FirebaseFirestore.instance.collection('activities').add({
          'timestamp': FieldValue.serverTimestamp(),
          'createdBy': createdBy,
          'assignedTo': task.assignedTo,
          'taskName': task.taskName,
          'message': '$createdByName created a task for themselves',
          'spaceId': _selectedDuoSpace, // Include the spaceUid
          'taskId': taskRef.id,
          'type': 'task_created', // Added type field
        });
      } else {
        // Activity for assigned task
        await FirebaseFirestore.instance.collection('activities').add({
          'createdBy': createdBy,
          'assignedTo': task.assignedTo,
          'message': '$createdByName created a task for $assignedToName',
          'timestamp': Timestamp.now(),
          'spaceId': _selectedDuoSpace, // Include the spaceUid
          'taskId': taskRef.id,
          'type': 'task_created', // Added type field
        });
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating task: $e')),
      );
    }
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
          'Create a Shared Task',
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
                    width: 300,
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
                    child: _DuoSpace.isEmpty
                        ? const Text(
                            "No shared space to choose from.",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedDuoSpace,
                            dropdownColor: Colors.blueGrey,
                            decoration: const InputDecoration(
                              labelText: "Shared Space",
                              labelStyle: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              border: UnderlineInputBorder(),
                            ),
                            items: _spaceIdMap.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key, // Use spaceId as the value
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 250),
                                  child: Text(
                                    entry.value, // Display the space name
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedDuoSpace =
                                    newValue; // Store the selected spaceId
                                _selectedMember = null; // Reset selected member
                                if (newValue != null) {
                                  _fetchMembersOfSelectedSpace(_spaceIdMap[
                                      newValue]!); // Fetch members of the selected space
                                }
                              });
                            },
                            selectedItemBuilder: (BuildContext context) {
                              return _spaceIdMap.entries.map((entry) {
                                return ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 250),
                                  child: Text(
                                    entry.value, // Display the space name
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList();
                            },
                            menuMaxHeight: 300,
                          ),
                  ),
                  const SizedBox(height: 9),
                  if (_selectedDuoSpace != null)
                    SizedBox(
                      width: 300,
                      child: DropdownButtonFormField<String>(
                        value: _selectedMember,
                        dropdownColor: Colors.blueGrey,
                        decoration: const InputDecoration(
                          labelText: "Share with",
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                        items: _member.map((String friends) {
                          return DropdownMenuItem<String>(
                            value: friends,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 250),
                              child: Text(
                                friends,
                                overflow: TextOverflow.visible,
                                maxLines: null,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedMember = newValue;
                          });
                        },
                        selectedItemBuilder: (BuildContext context) {
                          return _member.map((String friends) {
                            return ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 250),
                              child: Text(
                                friends,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList();
                        },
                        menuMaxHeight: 300,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 45),
            Container(
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
                  SizedBox(
                    width: 325,
                    child: GestureDetector(
                      onTap: () {
                        // Open the date picker when the field is tapped
                        _selectDateTime(context, _dueDateController);
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _dueDateController,
                          readOnly: true,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: "Due Date",
                            labelStyle: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            border: const UnderlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today,
                                  color: Colors.black),
                              onPressed: () {
                                _selectDateTime(context, _dueDateController);
                              },
                            ),
                            hintText: 'yyyy-mm-dd hh:mm',
                            hintStyle: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
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
                      inputFormatters: [LengthLimitingTextInputFormatter(250)],
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
                  const SizedBox(height: 45),
                  _buildFileUploadNote(),
                  ElevatedButton(
                    onPressed: _pickFiles,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 20),
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF2275AA),
                    ),
                    child: const Text('Attach Files'),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedFiles.isNotEmpty)
                    Column(
                      children: _selectedFiles.asMap().entries.map((entry) {
                        int index = entry.key;
                        PlatformFile file = entry.value;
                        return ListTile(
                          leading: const Icon(Icons.insert_drive_file,
                              color: Colors.blue),
                          title: Text(file.name),
                          subtitle: Text(
                              '${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeFile(index),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 45),
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
          divisions: 4, // Only 5 values: 1, 2, 3, 4, 5
          onChanged: onChanged,
          activeColor: const Color(0xFF2275AA), // Set active color to blue
          inactiveColor:
              const Color(0xFFB0C4DE), // Set inactive color to light blue
        ),
      ],
    );
  }
}
