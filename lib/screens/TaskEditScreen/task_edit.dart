import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mellow/models/TaskModel/edittask_model.dart';

class TaskEditScreen extends StatefulWidget {
  final bool isEditMode;
  final String taskId;
  final String taskName;
  final String startTime;
  final String dueDate;
  final String status;
  final String description;
  final double priority;
  final double urgency;
  final double complexity;

  const TaskEditScreen({
    super.key,
    required this.isEditMode,
    required this.taskId,
    required this.taskName,
    required this.startTime,
    required this.dueDate,
    required this.status,
    required this.description,
    required this.priority,
    required this.urgency,
    required this.complexity,
  });

  @override
  _TaskEditScreenState createState() => _TaskEditScreenState();
}

class TaskManager {
  List<Task> tasks = [];
  final String userId;

  TaskManager({required this.userId});

  // Load existing tasks from Firestore, specific to the user
  Future<void> loadTasksFromFirestore() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .get();

    tasks = querySnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data();
      return Task(
        userId: data['userId'],
        taskName: data['taskName'],
        dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        startTime:
            (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        description: data['description'] ?? '',
        priority: data['priority']?.toDouble() ?? 1.0,
        urgency: data['urgency']?.toDouble() ?? 1.0,
        complexity: data['complexity']?.toDouble() ?? 1.0,
        taskId: doc.id,
      );
    }).toList();
    print("Loaded tasks for user $userId: ${tasks.length}");
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

        double hourWeight = tasks
            .where((task) =>
                task.startTime.isBefore(proposedEnd) &&
                task.endTime.isAfter(proposedStart))
            .fold(0.0, (sum, task) => sum + task.weight);

        if (hourWeight + newTask.weight <= weightLimit &&
            proposedStart.isAfter(now)) {
          bestTimes.add(proposedStart);
        }
      }
    }

    return bestTimes.take(2).toList();
  }

  bool checkWeightInTimeSlotExcludingTask(
      Task newTask, DateTime startTime, DateTime endTime, double weightLimit) {
    double totalWeight = tasks.fold(0.0, (sum, task) {
      if (task.startTime.isBefore(endTime) && task.endTime.isAfter(startTime)) {
        return sum + task.weight;
      }
      return sum;
    });

    return totalWeight + newTask.weight <= weightLimit;
  }

  Future<void> addOrUpdateTaskWithConflictResolution(
    Task task,
    BuildContext context,
    String currentUserId,
    Function(Task) onTaskResolved,
    double weightLimit,
    Map<String, double> criteriaWeights,
  ) async {
    await loadTasksFromFirestore();

    if (!checkWeightInTimeSlotExcludingTask(
        task, task.startTime, task.endTime, weightLimit)) {
      List<DateTime> alternativeTimes = suggestBestTimes(task, weightLimit);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Conflict detected. Suggested times: $alternativeTimes')),
        );
      }
    } else {
      if (task.taskId.isNotEmpty) {
        await _updateTaskInFirestore(task);
      } else {
        await _addTaskToFirestore(task);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Task "${task.taskName}" added/updated successfully.')),
        );
      }

      onTaskResolved(task);
    }
  }

  Future<void> _addTaskToFirestore(Task task) async {
    try {
      DocumentReference docRef =
          await FirebaseFirestore.instance.collection('tasks').add({
        'userId': task.userId,
        'taskName': task.taskName,
        'startTime': task.startTime,
        'endTime': task.endTime,
        'dueDate': task.dueDate,
        'description': task.description,
        'priority': task.priority,
        'urgency': task.urgency,
        'complexity': task.complexity,
      });
      task.taskId = docRef.id;
    } catch (e) {
      print("Failed to add task: $e");
    }
  }

  Future<void> _updateTaskInFirestore(Task task) async {
    if (task.taskId.isEmpty) {
      print("Task ID is missing, cannot update.");
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(task.taskId)
          .update({
        'taskName': task.taskName,
        'startTime': task.startTime,
        'endTime': task.endTime,
        'dueDate': task.dueDate,
        'description': task.description,
        'priority': task.priority,
        'urgency': task.urgency,
        'complexity': task.complexity,
      });
    } catch (e) {
      print("Failed to update task: $e");
    }
  }
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  int _descriptionCharCount = 0;
  double _priority = 1;
  double _urgency = 1;
  double _complexity = 1;

  late TaskManager taskManager;
  late Task taskBeingEdited;

  @override
  void initState() {
    super.initState();
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    taskManager = TaskManager(userId: currentUserId);
    _loadTask();
    _descriptionController.addListener(() {
      setState(() {
        _descriptionCharCount = _descriptionController.text.length;
      });
    });
  }

  // Load the task from Firestore and set values for editing
  Future<void> _loadTask() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Initialize taskBeingEdited with the data
        taskBeingEdited = Task(
          userId: FirebaseAuth.instance.currentUser!.uid,
          taskId: widget.taskId,
          taskName: data['taskName'] ?? '',
          startTime:
              (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          description: data['description'] ?? '',
          priority: data['priority']?.toDouble() ?? 1,
          urgency: data['urgency']?.toDouble() ?? 1,
          complexity: data['complexity']?.toDouble() ?? 1,
        );

        setState(() {
          _taskNameController.text = taskBeingEdited.taskName;
          _dueDateController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(taskBeingEdited.dueDate);
          _startTimeController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(taskBeingEdited.startTime);
          _endTimeController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(taskBeingEdited.endTime);
          _descriptionController.text = taskBeingEdited.description;
          _priority = taskBeingEdited.priority;
          _urgency = taskBeingEdited.urgency;
          _complexity = taskBeingEdited.complexity;
        });
      }
    } catch (e) {
      print("Error loading task: $e");
    }
  }

  // Suggest best times for the task
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
          'Edit Task',
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
                    _buildSlider("Complexity", _complexity, (value) {
                      setState(() {
                        _complexity = value;
                      });
                    }),
                    const SizedBox(height: 25),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Update taskBeingEdited with new values from controllers
                          taskBeingEdited = Task(
                            userId: FirebaseAuth.instance.currentUser!.uid,
                            taskId: widget.taskId,
                            taskName: _taskNameController.text,
                            startTime: DateFormat('yyyy-MM-dd HH:mm')
                                .parse(_startTimeController.text),
                            endTime: DateFormat('yyyy-MM-dd HH:mm')
                                .parse(_endTimeController.text),
                            dueDate: DateFormat('yyyy-MM-dd HH:mm')
                                .parse(_dueDateController.text),
                            description: _descriptionController.text,
                            priority: _priority,
                            urgency: _urgency,
                            complexity: _complexity,
                          );

                          // Attempt to add or update task with conflict resolution
                          await taskManager
                              .addOrUpdateTaskWithConflictResolution(
                            taskBeingEdited,
                            context,
                            FirebaseAuth.instance.currentUser!.uid,
                            (resolvedTask) {
                              print('Task resolved and updated.');
                            },
                            15, // Replace with actual weight limit as needed
                            {
                              'priority': _priority,
                              'urgency': _urgency,
                              'complexity': _complexity,
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 20),
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF2275AA),
                        ),
                        child: const Text('Update Task'),
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
