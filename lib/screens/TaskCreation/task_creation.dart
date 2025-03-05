import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mellow/models/TaskModel/task_model.dart';

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
        Map<String, dynamic> data = doc.data();
        Task task = Task(
          userId: data['userId'],
          taskName: data['taskName'],
          dueDate: (data['dueDate'] as Timestamp).toDate(),
          startTime: (data['startTime'] as Timestamp).toDate(),
          endTime: (data['endTime'] as Timestamp).toDate(),
          description: data['description'] ?? '',
          priority: (data['priority'] as num).toDouble(),
          urgency: (data['urgency'] as num).toDouble(),
          complexity: (data['complexity'] as num).toDouble(),
          taskType: data['taskType'],
        );
        task.updateWeight(criteriaWeights); // Pass criteriaWeights
        return task;
      }).toList();

      print("Loaded ${tasks.length} tasks for user $userId.");
    } catch (e) {
      print("Error loading tasks: $e");
    }
  }

  List<DateTime> suggestBestTimes(Task newTask, double weightLimit) {
    List<DateTime> bestTimes = [];
    Duration taskDuration = newTask.endTime.difference(newTask.startTime);

    const int daysToCheck = 7;
    DateTime now = DateTime.now();

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

        // Debugging: Print the proposed time being checked
        print("Checking time: ${proposedStart.toIso8601String()}");

        // Check for cumulative weight in the proposed time slot (without including the new task)
        double hourWeight = tasks
            .where((task) =>
                task.startTime.isBefore(proposedEnd) &&
                task.endTime.isAfter(proposedStart))
            .fold(0.0, (sum, task) => sum + task.weight);

        // Debugging: Print the weight for the time slot
        print(
            "hourWeight: $hourWeight, newTask.weight: ${newTask.weight}, weightLimit: $weightLimit");

        // Ensure the total weight does not exceed the limit, including the new task's weight
        if (hourWeight + newTask.weight <= weightLimit &&
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
    double weightLimit,
    Map<String, double> criteriaWeights,
  ) async {
    // Adjust task details based on existing tasks with the same name
    adjustTaskDetails(newTask);

    // Update the task's weight before checking conflicts
    newTask.updateWeight(criteriaWeights);

    // Initialize total weight with the new task's weight
    double totalWeight = newTask.weight;

    // Check for any conflicts and calculate the cumulative weight for overlapping tasks
    for (var task in tasks) {
      task.updateWeight(
          criteriaWeights); // Ensure each task's weight is updated
      if (newTask.overlapsWith(task)) {
        totalWeight += task.weight; // Add weight of the conflicting task
        print(
            "Conflict with task: ${task.taskName}, Weight: ${task.weight}, Total weight now: $totalWeight");
      }
    }

    print("Total weight after checking for conflicts: $totalWeight");

    // Check if total weight exceeds the limit
    if (totalWeight > weightLimit) {
      print("Total weight exceeds the limit, showing conflict dialog.");
      await showConflictDialog(newTask, context, onTaskResolved, weightLimit);
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

  Future<void> showConflictDialog(Task conflictingTask, BuildContext context,
      Function(Task) onTaskResolved, double weightLimit) async {
    List<DateTime> bestTimes = suggestBestTimes(conflictingTask, weightLimit);
    final duration =
        conflictingTask.endTime.difference(conflictingTask.startTime);

    if (bestTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available time slots found.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Task Conflict Detected',
            style: TextStyle(
              color: Color(0xFF2275AA),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The task "${conflictingTask.taskName}" conflicts with other tasks in your schedule.',
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < bestTimes.length; i++)
                _buildTimeCard(
                  context: context,
                  time: bestTimes[i],
                  label: i == 0 ? "Suggested Best Time" : "Second Best Time",
                  onSelect: () {
                    // Update task's start and end time here
                    conflictingTask.startTime = bestTimes[i];
                    conflictingTask.endTime = bestTimes[i].add(duration);
                    onTaskResolved(
                        conflictingTask); // Resolve with updated task
                    Navigator.pop(context); // Close dialog
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text(
                'Change Time Manually',
                style: TextStyle(color: Color(0xFF2275AA)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeCard({
    required BuildContext context,
    required DateTime time,
    required String label,
    required VoidCallback onSelect,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2275AA),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(time),
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: onSelect,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF2275AA),
                ),
                child: const Text('Choose This Time'),
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
    String dueDateString = _dueDateController.text;
    String startTimeString = _startTimeController.text;
    String endTimeString = _endTimeController.text;
    String description = _descriptionController.text;
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    DateTime? dueDate = dueDateString.isNotEmpty
        ? DateFormat('yyyy-MM-dd HH:mm').parse(dueDateString)
        : null;
    DateTime? startTime = startTimeString.isNotEmpty
        ? DateFormat('yyyy-MM-dd HH:mm').parse(startTimeString)
        : null;
    DateTime? endTime = endTimeString.isNotEmpty
        ? DateFormat('yyyy-MM-dd HH:mm').parse(endTimeString)
        : null;

    if (taskName.isNotEmpty &&
        dueDate != null &&
        startTime != null &&
        endTime != null) {
      Task newTask = Task(
        userId: userId,
        taskName: taskName,
        dueDate: dueDate,
        startTime: startTime,
        endTime: endTime,
        description: description,
        priority: _priority,
        urgency: _urgency,
        complexity: _complexity,
        taskType: taskType,
      );

      TaskManager taskManager = TaskManager();

      Map<String, double> criteriaWeights = {
        'priority': _priority,
        'urgency': _urgency,
        'complexity': _complexity,
      };

      await taskManager.loadTasksFromFirestore(userId, criteriaWeights);

      // Check for existing tasks with the same name
      Task? existingTask;
      try {
        existingTask = taskManager.tasks.firstWhere(
          (task) => task.taskName == taskName && task.userId == userId,
        );
      } catch (e) {
        existingTask = null;
      }

      if (existingTask != null) {
        // Show alert dialog if a matching task is found
        await _showTaskConflictDialog(
            newTask, existingTask, taskManager, context);
      } else {
        // No conflict, add the task directly
        await _addTaskToFirestore(newTask, userId);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }

  Future<void> _showTaskConflictDialog(Task newTask, Task existingTask,
      TaskManager taskManager, BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'The system identified a task with similar information',
            style: TextStyle(
              color: Color(0xFF2275AA), // Match the page primary color
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'You have created a task with the same name before.',
                  style: TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Existing Task Details:',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
                Text('Description: ${newTask.description}',
                    style: const TextStyle(color: Colors.black)),
                Text('Priority: ${newTask.priority.toInt()}',
                    style: const TextStyle(color: Colors.black)),
                Text('Urgency: ${newTask.urgency.toInt()}',
                    style: const TextStyle(color: Colors.black)),
                Text('Complexity: ${newTask.complexity.toInt()}',
                    style: const TextStyle(color: Colors.black)),
                const SizedBox(height: 16),
                const Text(
                  'Do you want to create the task with the following details?',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
                Text(
                    'Due Date: ${DateFormat('yyyy-MM-dd HH:mm').format(existingTask.dueDate)}',
                    style: const TextStyle(color: Colors.black)),
                Text(
                    'Start Time: ${DateFormat('yyyy-MM-dd HH:mm').format(existingTask.startTime)}',
                    style: const TextStyle(color: Colors.black)),
                Text(
                    'End Time: ${DateFormat('yyyy-MM-dd HH:mm').format(existingTask.endTime)}',
                    style: const TextStyle(color: Colors.black)),
                Text('Description: ${existingTask.description}',
                    style: const TextStyle(color: Colors.black)),
                Text('Priority: ${existingTask.priority.toInt()}',
                    style: const TextStyle(color: Colors.black)),
                Text('Urgency: ${existingTask.urgency.toInt()}',
                    style: const TextStyle(color: Colors.black)),
                Text('Complexity: ${existingTask.complexity.toInt()}',
                    style: const TextStyle(color: Colors.black)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Create Exactly How I Made It',
                  style: TextStyle(color: Color(0xFF2275AA))),
              onPressed: () async {
                Navigator.of(context).pop();
                await _addTaskToFirestore(newTask, newTask.userId);
              },
            ),
            TextButton(
              child: const Text('Create Task Like This',
                  style: TextStyle(color: Color(0xFF2275AA))),
              onPressed: () async {
                Navigator.of(context).pop();
                taskManager.adjustTaskDetails(newTask);
                await _showTaskDetailsDialog(newTask, context);
              },
            ),
            TextButton(
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF2275AA))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTaskDetailsDialog(
      Task newTask, BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirm Task Details',
            style: TextStyle(
              color: Color(0xFF2275AA), // Match the page primary color
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'The task will be created with the following details:',
                  style: TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                    'Due Date: ${DateFormat('yyyy-MM-dd HH:mm').format(newTask.dueDate)}',
                    style: const TextStyle(color: Colors.black)),
                Text(
                    'Start Time: ${DateFormat('yyyy-MM-dd HH:mm').format(newTask.startTime)}',
                    style: const TextStyle(color: Colors.black)),
                Text(
                    'End Time: ${DateFormat('yyyy-MM-dd HH:mm').format(newTask.endTime)}',
                    style: const TextStyle(color: Colors.black)),
                Text('Description: ${newTask.description}',
                    style: const TextStyle(color: Colors.black)),
                Text('Priority: ${newTask.priority.toInt()}',
                    style: const TextStyle(color: Colors.black)),
                Text('Urgency: ${newTask.urgency.toInt()}',
                    style: const TextStyle(color: Colors.black)),
                Text('Complexity: ${newTask.complexity.toInt()}',
                    style: const TextStyle(color: Colors.black)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Create Task',
                  style: TextStyle(color: Color(0xFF2275AA))),
              onPressed: () async {
                Navigator.of(context).pop();
                await _addTaskToFirestore(newTask, newTask.userId);
              },
            ),
            TextButton(
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF2275AA))),
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
      'userId': userId,
      'status': 'pending',
      'taskType': task.taskType,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task created successfully')),
    );
    Navigator.pop(context);
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
              height: 720,
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
                    Center(
                      child: ElevatedButton(
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
          ],
        ),
        Slider(
          value: value,
          min: 1, // Start at 1
          max: 3, // End at 3
          divisions: 2, // Only 3 values: 1, 2, 3
          label: value == 1
              ? 'Low'
              : value == 2
                  ? 'Medium'
                  : 'High',
          onChanged: onChanged,
          activeColor: const Color(0xFF2275AA), // Set active color to blue
          inactiveColor:
              const Color(0xFFB0C4DE), // Set inactive color to light blue
        ),
      ],
    );
  }
}
