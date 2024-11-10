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

  // Load existing tasks from Firestore
  Future<void> loadTasksFromFirestore(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .get();

    tasks = querySnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data();
      return Task(
        taskName: data['taskName'],
        dueDate: (data['dueDate'] as Timestamp).toDate(),
        startTime: (data['startTime'] as Timestamp).toDate(),
        endTime: (data['endTime'] as Timestamp).toDate(),
        description: data['description'] ?? '',
        priority: data['priority'] ?? 1.0,
        urgency: data['urgency'] ?? 1.0,
        importance: data['importance'] ?? 1.0,
        complexity: data['complexity'] ?? 1.0,
      );
    }).toList();
  }

  // Calculate task weight based on priority, urgency, etc.
  double calculateTaskWeight(Task task) {
    return (task.priority * 0.3) +
        (task.urgency * 0.3) +
        (task.importance * 0.2) +
        (task.complexity * 0.2);
  }

  // Suggest best times based on existing tasks
  List<DateTime> suggestBestTimes(Task newTask) {
    List<DateTime> bestTimes = [];
    Duration taskDuration = newTask.endTime.difference(newTask.startTime);

    const int daysToCheck = 7; // Check for the next 7 days
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

        // Check if proposed time conflicts with existing tasks and is in the future
        bool conflict = tasks.any((task) {
          return (proposedStart.isBefore(task.endTime) &&
              proposedEnd.isAfter(task.startTime) &&
              task !=
                  newTask); // Ensure the task itself is not considered as a conflict
        });

        if (!conflict && proposedStart.isAfter(now)) {
          bestTimes.add(proposedStart);
        }
      }
    }

    return bestTimes.take(2).toList(); // Return top 2 best times
  }

  // Add task with conflict resolution, considering weight
  Future<void> addTaskWithConflictResolution(
    Task newTask,
    BuildContext context,
    String? userId,
    Function(Task) onTaskResolved,
    double weightLimit, // Add weightLimit as a parameter
    Map<String, double> criteriaWeights, // Add criteriaWeights as a parameter
  ) async {
    newTask.updateWeight(criteriaWeights); // Update weight for the task

    double totalWeight = 0.0;
    for (var task in tasks) {
      if (newTask.overlapsWith(task)) {
        totalWeight += task.weight; // Accumulate overlapping task weights
      }
    }

    if (totalWeight + newTask.weight > weightLimit) {
      await showConflictDialog(newTask, context, onTaskResolved);
    } else {
      onTaskResolved(newTask);
    }
  }

  Future<void> showConflictDialog(Task conflictingTask, BuildContext context,
      Function(Task) onTaskResolved) async {
    List<DateTime> bestTimes = suggestBestTimes(conflictingTask);
    final duration =
        conflictingTask.endTime.difference(conflictingTask.startTime);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Task Conflict Detected'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'The task "${conflictingTask.taskName}" conflicts with another task and can result to overdue tasks.'),
              const SizedBox(height: 16),
              if (bestTimes.isNotEmpty)
                _buildTimeCard(
                  context: context,
                  time: bestTimes[0],
                  label: "Suggested Best Time",
                  onSelect: () {
                    conflictingTask.startTime = bestTimes[0];
                    conflictingTask.endTime = bestTimes[0].add(duration);
                    onTaskResolved(conflictingTask);
                    Navigator.pop(context);
                  },
                ),
              if (bestTimes.length > 1)
                _buildTimeCard(
                  context: context,
                  time: bestTimes[1],
                  label: "Second Best Time",
                  onSelect: () {
                    conflictingTask.startTime = bestTimes[1];
                    conflictingTask.endTime = bestTimes[1].add(duration);
                    onTaskResolved(conflictingTask);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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
              style: TextStyle(
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

  int _descriptionCharCount = 0;
  double _priority = 1;
  double _urgency = 1;
  double _importance = 1;
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
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
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
        endTime != null &&
        userId != null) {
      Task newTask = Task(
        taskName: taskName,
        dueDate: dueDate,
        startTime: startTime,
        endTime: endTime,
        description: description,
        priority: _priority,
        urgency: _urgency,
        importance: _importance,
        complexity: _complexity,
      );

      // Initialize the TaskManager
      TaskManager taskManager = TaskManager();
      await taskManager.loadTasksFromFirestore(userId);

      // Define weightLimit and criteriaWeights (these values should be defined based on your logic)
      double weightLimit = 10.0; // Example weight limit
      Map<String, double> criteriaWeights = {
        'priority': _priority,
        'urgency': _urgency,
        'importance': _importance,
        'complexity': _complexity,
      };

      // Add conflict resolution before task creation
      await taskManager.addTaskWithConflictResolution(
        newTask,
        context,
        userId,
        (resolvedTask) async {
          // After resolving conflicts, add the task to Firestore
          await FirebaseFirestore.instance.collection('tasks').add({
            'taskName': resolvedTask.taskName,
            'dueDate': Timestamp.fromDate(resolvedTask.dueDate),
            'startTime': Timestamp.fromDate(resolvedTask.startTime),
            'endTime': Timestamp.fromDate(resolvedTask.endTime),
            'description': description,
            'priority': _priority,
            'urgency': _urgency,
            'importance': _importance,
            'complexity': _complexity,
            'weight': resolvedTask.weight, // Store the task weight
            'createdAt': Timestamp.now(),
            'userId': userId,
            'status': 'pending',
          });

          // Show success message after task is created
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task created successfully!')),
          );
          Navigator.pop(context); // Close the task creation screen
        },
        weightLimit, // Pass weightLimit
        criteriaWeights, // Pass criteriaWeights
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
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
                ],
              ),
            ),
            const SizedBox(height: 45),
            SizedBox(
              height: 810,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
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
                        const SizedBox(width: 25),
                        SizedBox(
                          width: 150,
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
                                  _selectDateTime(context, _endTimeController);
                                },
                              ),
                              hintText: 'hh:mm',
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
                    _buildSlider("Importance", _importance, (value) {
                      setState(() {
                        _importance = value;
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
                          backgroundColor: const Color(0xFF2C3C3C),
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Low', style: TextStyle(fontSize: 12)),
            Text('Medium', style: TextStyle(fontSize: 12)),
            Text('High', style: TextStyle(fontSize: 12)),
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
        ),
      ],
    );
  }
}
