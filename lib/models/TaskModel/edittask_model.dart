import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Task {
  String userId;
  String taskId;
  String taskName;
  DateTime dueDate;
  DateTime startTime;
  DateTime endTime;
  String description;
  double priority;
  double urgency;
  double importance;
  double complexity;
  double weight; // Add a weight property

  Task({
    required this.userId,
    required this.taskId,
    required this.taskName,
    required this.startTime,
    required this.endTime,
    required this.dueDate,
    required this.description,
    required this.priority,
    required this.urgency,
    required this.importance,
    required this.complexity,
    this.weight = 0.0, // Default weight to 0
  });

  // Method to calculate and update the weight
  void updateWeight(Map<String, double> criteriaWeights) {
    // Ensure max values of 3 are respected
    priority = priority > 3 ? 3 : priority;
    urgency = urgency > 3 ? 3 : urgency;
    importance = importance > 3 ? 3 : importance;
    complexity = complexity > 3 ? 3 : complexity;

    // Weight calculation based on criteria
    weight = (priority * criteriaWeights['priority']!) +
        (urgency * criteriaWeights['urgency']!) +
        (importance * criteriaWeights['importance']!) +
        (complexity * criteriaWeights['complexity']!);
  }

  // Method to check if the task's times are valid
  bool validateTaskTimes() {
    return startTime.isBefore(endTime);
  }

  // Method to check if two tasks overlap in time
  bool overlapsWith(Task other) {
    return startTime.isBefore(other.endTime) &&
        endTime.isAfter(other.startTime);
  }

  // Method to create Task from Firestore DocumentSnapshot
  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Task(
      userId: data['userId'],
      taskName: data['taskName'],
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      description: data['description'],
      priority: data['priority'],
      urgency: data['urgency'],
      importance: data['importance'],
      complexity: data['complexity'],
      taskId: doc.id,
    );
  }

  @override
  String toString() {
    return 'Task(taskId: $taskId, taskName: $taskName, weight: $weight)';
  }
}

class TaskManager {
  String currentUserId;
  List<Task> tasks = [];
  Map<String, double> criteriaWeights = {
    'priority': 0.4,
    'urgency': 0.3,
    'importance': 0.2,
    'complexity': 0.1,
  };

  final double weightLimit = 15.0;

  TaskManager({required this.currentUserId});

  void applyAHP() {
    double total = criteriaWeights.values.reduce((a, b) => a + b);
    criteriaWeights =
        criteriaWeights.map((key, value) => MapEntry(key, value / total));
  }

  Future<void> loadTasksFromFirestore(String userId) async {
    final taskCollection = FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: userId);
    final querySnapshot = await taskCollection.get();

    tasks = querySnapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
  }

  bool checkWeightInTimeSlotExcludingTask(
      Task editedTask, DateTime newStart, DateTime newEnd,
      {double? newWeight}) {
    DateTime start = newStart;
    DateTime end = newEnd;

    while (start.isBefore(end)) {
      double hourWeight = tasks
          .where((task) =>
              task.userId == currentUserId &&
              task.startTime.isBefore(start.add(Duration(hours: 1))) &&
              task.endTime.isAfter(start) &&
              task != editedTask)
          .fold(0.0, (sum, task) => sum + task.weight);

      if (newWeight != null) {
        hourWeight += newWeight;
      } else {
        hourWeight += editedTask.weight;
      }

      if (hourWeight > weightLimit) {
        return false;
      }

      start = start.add(Duration(hours: 1));
    }
    return true;
  }

  List<DateTime> suggestAlternativeTimes(Task task, int numSuggestions) {
    List<DateTime> suggestions = [];
    DateTime current = task.startTime;
    Duration interval = Duration(hours: 1);

    while (suggestions.length < numSuggestions) {
      DateTime proposedStart = current.add(interval);
      DateTime proposedEnd =
          proposedStart.add(task.endTime.difference(task.startTime));

      bool conflict = tasks.any((t) =>
          t.userId == currentUserId &&
          t != task &&
          (proposedStart.isBefore(t.endTime) &&
              proposedEnd.isAfter(t.startTime)));

      if (!conflict) {
        suggestions.add(proposedStart);
      }

      current = proposedStart;
    }

    return suggestions;
  }

  Future<void> addTaskWithConflictResolution(
    Task task,
    BuildContext context,
    String currentUserId,
    Function(Task) onResolved,
  ) async {
    // First, load tasks from Firestore
    await loadTasksFromFirestore(currentUserId);

    // Calculate and set task weight
    task.updateWeight(criteriaWeights);

    // Check for time conflicts
    if (!checkWeightInTimeSlotExcludingTask(
        task, task.startTime, task.endTime)) {
      print('Conflict detected! Suggesting alternative times.');

      // Suggest alternative times
      List<DateTime> alternativeTimes = suggestAlternativeTimes(task, 2);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Conflict detected. Suggested alternative times: $alternativeTimes')),
        );
      }
    } else {
      tasks.add(task);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Task "${task.taskName}" added successfully.')),
        );
      }
      onResolved(task); // Call the resolved callback
    }
  }
}
