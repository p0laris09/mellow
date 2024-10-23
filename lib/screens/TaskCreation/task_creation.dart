import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mellow/models/task_model.dart'; // Import your Task model

class IJFA {
  static double evaluate(Task task) {
    // Example logic for evaluation
    return (task.priority + task.urgency + task.importance) / task.complexity;
  }
}

class TaskCreationScreen extends StatefulWidget {
  const TaskCreationScreen({super.key});

  @override
  State<TaskCreationScreen> createState() => _TaskCreationScreenState();
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
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
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

        String formattedDateTime =
            DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);
        controller.text = formattedDateTime;
      }
    }
  }

  Future<bool> _checkForConflicts(DateTime startTime, DateTime endTime) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('startTime', isLessThan: endTime)
        .where('endTime', isGreaterThan: startTime)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  void _showConflictDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Conflict Detected"),
          content: const Text(
              "This task conflicts with another task. Would you like to see suggested times?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _suggestAlternativeTimes();
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text("Show Suggestions"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _suggestAlternativeTimes() async {
    // Fetch existing tasks to implement your scheduling algorithm
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .get();

    // Get existing tasks' start and end times
    List<DateTime> existingStartTimes = [];
    List<DateTime> existingEndTimes = [];
    for (var doc in querySnapshot.docs) {
      existingStartTimes.add((doc['startTime'] as Timestamp).toDate());
      existingEndTimes.add((doc['endTime'] as Timestamp).toDate());
    }

    // Define time range for suggestions (e.g., 1 hour later to 3 hours later)
    DateTime now = DateTime.now();
    DateTime earliestSuggestion = now.add(Duration(hours: 1));
    DateTime latestSuggestion = now.add(Duration(hours: 3));

    // Find available time slots
    List<DateTime> suggestedTimes = [];
    for (DateTime time = earliestSuggestion;
        time.isBefore(latestSuggestion);
        time = time.add(Duration(minutes: 30))) {
      bool isConflicted = false;
      for (int i = 0; i < existingStartTimes.length; i++) {
        if ((time.isAfter(existingStartTimes[i]) &&
                time.isBefore(existingEndTimes[i])) ||
            (time.isBefore(existingStartTimes[i]) &&
                time
                    .add(Duration(minutes: 30))
                    .isAfter(existingStartTimes[i]))) {
          isConflicted = true;
          break;
        }
      }
      if (!isConflicted) {
        suggestedTimes.add(time);
      }
    }

    // Show suggestions to the user
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Suggested Times"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: suggestedTimes.isNotEmpty
                ? suggestedTimes.map((time) {
                    return Text(DateFormat('yyyy-MM-dd HH:mm').format(time));
                  }).toList()
                : [const Text("No available times found.")],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
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

    // Check for empty fields
    if (taskName.isEmpty) {
      _showErrorSnackBar("Task name is required.");
      return;
    }
    if (dueDate == null) {
      _showErrorSnackBar("Due date is required.");
      return;
    }
    if (startTime == null) {
      _showErrorSnackBar("Start time is required.");
      return;
    }
    if (endTime == null) {
      _showErrorSnackBar("End time is required.");
      return;
    }
    if (userId == null) {
      _showErrorSnackBar("User ID not found.");
      return;
    }

    // Check for conflicts before creating the task
    bool hasConflict = await _checkForConflicts(startTime, endTime);
    if (hasConflict) {
      _showConflictDialog(); // Show conflict dialog
    } else {
      // Create an instance of Task
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

      // Evaluate the task using IJFA
      double fitnessScore = IJFA.evaluate(newTask);
      print(
          'Evaluating task: ${newTask.taskName} with IJFA. Fitness Score: $fitnessScore');

      // Example: Adjust task attributes based on fitness score (modify logic as needed)
      if (fitnessScore < 1) {
        newTask.priority = 1; // Example adjustment
      } else if (fitnessScore > 4) {
        newTask.priority = 5; // Example adjustment
      }

      // Get current time and determine initial status
      DateTime currentTime = DateTime.now();
      String status;
      if (currentTime.isBefore(startTime)) {
        status = 'pending';
      } else if (currentTime.isAfter(startTime) &&
          currentTime.isBefore(dueDate)) {
        status = 'ongoing';
      } else {
        status = 'overdue';
      }

      CollectionReference tasks =
          FirebaseFirestore.instance.collection('tasks');

      try {
        await tasks.add({
          'taskName': taskName,
          'dueDate': Timestamp.fromDate(dueDate),
          'startTime': Timestamp.fromDate(startTime),
          'endTime': Timestamp.fromDate(endTime),
          'description': description,
          'priority': newTask.priority,
          'urgency': _urgency,
          'importance': _importance,
          'complexity': _complexity,
          'createdAt': Timestamp.now(),
          'userId': userId,
          'status': status,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully!')),
        );

        print('Task created successfully, popping context...');
        Navigator.pop(context); // Ensure this is reached
      } catch (e) {
        print('Error creating task: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error creating task')),
        );
      }
    }
  }

// Helper method to show error messages
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3C3C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3C3C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _taskNameController,
                      style: const TextStyle(color: Colors.white),
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
                      decoration: const InputDecoration(
                        labelText: "Due Date",
                        labelStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        border: UnderlineInputBorder(),
                      ),
                      onTap: () {
                        _selectDateTime(context, _dueDateController);
                      },
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
                            decoration: const InputDecoration(
                              labelText: "Start Time",
                              labelStyle: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              border: UnderlineInputBorder(),
                            ),
                            onTap: () {
                              _selectDateTime(context, _startTimeController);
                            },
                          ),
                        ),
                        const SizedBox(width: 25),
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _endTimeController,
                            readOnly: true,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: "End Time",
                              labelStyle: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              border: UnderlineInputBorder(),
                            ),
                            onTap: () {
                              _selectDateTime(context, _endTimeController);
                            },
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Low', style: TextStyle(fontSize: 12)),
            const Text('Medium', style: TextStyle(fontSize: 12)),
            const Text('High', style: TextStyle(fontSize: 12)),
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
