import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String taskName;
  DateTime dueDate;
  DateTime startTime;
  DateTime endTime;
  String description;
  double priority;
  double urgency;
  double importance;
  double complexity;
  int reminderMinutes; // Minutes before start time for a reminder

  Task({
    required this.taskName,
    required this.dueDate,
    required this.startTime,
    required this.endTime,
    required this.description,
    required this.priority,
    required this.urgency,
    required this.importance,
    required this.complexity,
    this.reminderMinutes = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'taskName': taskName,
      'dueDate': dueDate.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'description': description,
      'priority': priority,
      'urgency': urgency,
      'importance': importance,
      'complexity': complexity,
      'reminderMinutes': reminderMinutes,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskName: json['taskName'],
      dueDate: DateTime.parse(json['dueDate']),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      description: json['description'],
      priority: json['priority'],
      urgency: json['urgency'],
      importance: json['importance'],
      complexity: json['complexity'],
      reminderMinutes: json['reminderMinutes'] ?? 0,
    );
  }

  bool validateTaskTimes() {
    return startTime.isBefore(endTime);
  }

  @override
  String toString() {
    return 'Task(taskName: $taskName, dueDate: $dueDate, startTime: $startTime, endTime: $endTime, '
        'description: $description, priority: $priority, urgency: $urgency, '
        'importance: $importance, complexity: $complexity, reminderMinutes: $reminderMinutes)';
  }

  @override
  bool operator <(Task other) => priority < other.priority;

  @override
  bool operator >(Task other) => priority > other.priority;
}

class TaskManager {
  List<Task> tasks = [];
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Add a task to the manager, reschedule if there's a conflict
  Future<void> addTask(Task task) async {
    if (task.validateTaskTimes()) {
      if (!hasConflict(task)) {
        tasks.add(task);
        await _saveToFirestore(task);
        print('Task "${task.taskName}" added successfully.');
      } else {
        print(
            'Conflict detected. Attempting to reschedule task "${task.taskName}".');
        Task? rescheduledTask = _resolveConflict(task);
        if (rescheduledTask != null) {
          tasks.add(rescheduledTask);
          await _saveToFirestore(rescheduledTask);
          print(
              'Task "${rescheduledTask.taskName}" rescheduled and added successfully.');
        }
      }
    } else {
      print('Task "${task.taskName}" cannot be added due to invalid times.');
    }
  }

  // Save task to Firestore
  Future<void> _saveToFirestore(Task task) async {
    await firestore.collection('tasks').add(task.toJson());
  }

  // Check for conflicts with existing tasks
  bool hasConflict(Task newTask) {
    for (var task in tasks) {
      if ((newTask.startTime.isBefore(task.endTime) &&
          newTask.endTime.isAfter(task.startTime))) {
        return true; // Conflict detected
      }
    }
    return false; // No conflict
  }

  // Resolve conflict by rescheduling the new task
  Task? _resolveConflict(Task conflictingTask) {
    DateTime newStartTime =
        conflictingTask.endTime; // Start after the conflicting task ends
    DateTime newEndTime =
        newStartTime.add(Duration(hours: 1)); // Add a default duration
    Task rescheduledTask = Task(
      taskName: conflictingTask.taskName,
      dueDate: conflictingTask.dueDate,
      startTime: newStartTime,
      endTime: newEndTime,
      description: conflictingTask.description,
      priority: conflictingTask.priority,
      urgency: conflictingTask.urgency,
      importance: conflictingTask.importance,
      complexity: conflictingTask.complexity,
      reminderMinutes: conflictingTask.reminderMinutes,
    );

    // Check if the new task still conflicts
    if (!hasConflict(rescheduledTask)) {
      return rescheduledTask; // Rescheduled task is valid
    } else {
      print('Unable to reschedule task "${conflictingTask.taskName}".');
      return null; // Unable to resolve
    }
  }

  // Evaluate the fitness of tasks and select the best one
  Task? evaluateAndSelectBestTask(
      {double priorityWeight = 0.4,
      double urgencyWeight = 0.3,
      double importanceWeight = 0.2,
      double complexityWeight = 0.1}) {
    if (tasks.isEmpty) return null;

    double bestFitness = -1;
    Task? bestTask;

    for (var task in tasks) {
      double fitness = evaluateTask(task, priorityWeight, urgencyWeight,
          importanceWeight, complexityWeight);
      print('Task "${task.taskName}" has fitness: $fitness');

      if (fitness > bestFitness) {
        bestFitness = fitness;
        bestTask = task;
      }
    }

    return bestTask;
  }

  // Evaluate a task's fitness with customizable weights
  double evaluateTask(Task task, double priorityWeight, double urgencyWeight,
      double importanceWeight, double complexityWeight) {
    double fitness = (task.priority * priorityWeight) +
        (task.urgency * urgencyWeight) +
        (task.importance * importanceWeight) -
        (task.complexity * complexityWeight);

    return max(fitness, 0);
  }
}
