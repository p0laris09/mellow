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
            priority: data['priority'] ?? 1.0,
            urgency: data['urgency'] ?? 1.0,
            complexity: data['complexity'] ?? 1.0,
            taskType: data['tasktype']);
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
          title: const Text('Task Conflict Detected'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'The task "${conflictingTask.taskName}" conflicts with other tasks in your schedule.'),
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
                Navigator.pop(context); // Close dialog without selecting a time
              },
              child: const Text('Change Time Manually'),
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
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(time),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: onSelect,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).primaryColor,
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

    // Define the taskType (personal, duo, or space)
    String taskType =
        'personal'; // Set to 'personal' by default, you can change it based on user input

    if (taskName.isNotEmpty &&
        dueDate != null &&
        startTime != null &&
        endTime != null) {
      // Create a new Task object with the provided details
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
        taskType: taskType, // Add the taskType here
      );

      // Initialize the TaskManager
      TaskManager taskManager = TaskManager();

      // Define criteriaWeights
      Map<String, double> criteriaWeights = {
        'priority': _priority,
        'urgency': _urgency,
        'complexity': _complexity,
      };

      // Pass both userId and criteriaWeights when calling loadTasksFromFirestore
      await taskManager.loadTasksFromFirestore(userId, criteriaWeights);

      double weightLimit = 12.1; // Example weight limit

      // Add conflict resolution before task creation
      await taskManager.addTaskWithConflictResolution(
        newTask,
        context,
        userId,
        (resolvedTask) async {
          // Add the resolved task to Firestore
          await FirebaseFirestore.instance.collection('tasks').add({
            'taskName': resolvedTask.taskName,
            'dueDate': Timestamp.fromDate(resolvedTask.dueDate),
            'startTime': Timestamp.fromDate(resolvedTask.startTime),
            'endTime': Timestamp.fromDate(resolvedTask.endTime),
            'description': description,
            'priority': _priority,
            'urgency': _urgency,
            'complexity': _complexity,
            'weight': resolvedTask.weight,
            'createdAt': Timestamp.now(),
            'userId': userId,
            'status': 'pending',
            'taskType': taskType, // Add the taskType here in Firestore
          });

          // Show success message and close the screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task created successfully')),
          );
          Navigator.pop(context);
        },
        weightLimit,
        criteriaWeights,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
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
