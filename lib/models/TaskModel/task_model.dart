import 'dart:math';

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

  // Calculate a task's weighted importance for scheduling
  double calculateTaskWeight() {
    return (priority * 0.4) +
        (urgency * 0.3) +
        (importance * 0.2) +
        (complexity * 0.1);
  }

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
  });

  // Convert a Task object to a Map object for JSON serialization
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
    };
  }

  // Create a Task object from a Map object (for JSON deserialization)
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
    );
  }

  // Method to validate the task times
  bool validateTaskTimes() {
    return startTime.isBefore(endTime);
  }

  @override
  String toString() {
    return 'Task(taskName: $taskName, dueDate: $dueDate, startTime: $startTime, endTime: $endTime, '
        'description: $description, priority: $priority, urgency: $urgency, '
        'importance: $importance, complexity: $complexity)';
  }

  // Comparison operators based on priority
  @override
  bool operator <(Task other) => priority < other.priority;

  @override
  bool operator >(Task other) => priority > other.priority;
}

class TaskManager {
  List<Task> tasks = [];

  // Add a task to the manager if there's no time conflict
  void addTask(Task task) {
    if (task.validateTaskTimes() && !hasConflict(task)) {
      tasks.add(task);
      print('Task "${task.taskName}" added successfully.');
    } else {
      print(
          'Task "${task.taskName}" cannot be added due to time conflict or invalid times.');
    }
  }

  // Check if a task conflicts with existing tasks
  bool hasConflict(Task newTask) {
    for (var task in tasks) {
      if ((newTask.startTime.isBefore(task.endTime) &&
          newTask.endTime.isAfter(task.startTime))) {
        return true; // Conflict detected
      }
    }
    return false; // No conflict
  }

  // Evaluate the fitness of tasks and select the best one
  Task? evaluateAndSelectBestTask() {
    if (tasks.isEmpty) return null;

    // Evaluate fitness for each task
    double bestFitness = -1;
    Task? bestTask;

    for (var task in tasks) {
      double fitness = evaluateTask(task);
      print('Task "${task.taskName}" has fitness: $fitness');

      if (fitness > bestFitness) {
        bestFitness = fitness;
        bestTask = task;
      }
    }

    return bestTask;
  }

  // Evaluate a task's fitness
  double evaluateTask(Task task) {
    // Simple fitness calculation based on task parameters
    double fitness = (task.priority * 0.4) +
        (task.urgency * 0.3) +
        (task.importance * 0.2) -
        (task.complexity * 0.1);

    // Ensure fitness is non-negative
    return max(fitness, 0);
  }
}
