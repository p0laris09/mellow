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
  double weight; // Add this field to store the calculated weight

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
  }) : weight = 0.0; // Initialize weight to zero

  // Calculate and update the task's weight based on AHP criteria
  void updateWeight(Map<String, double> criteriaWeights) {
    weight = (priority * criteriaWeights['priority']!) +
        (urgency * criteriaWeights['urgency']!) +
        (importance * criteriaWeights['importance']!) +
        (complexity * criteriaWeights['complexity']!);
  }

  // Method to validate the task times
  bool validateTaskTimes() {
    return startTime.isBefore(endTime);
  }

  // Method to check if two tasks overlap in time
  bool overlapsWith(Task other) {
    return startTime.isBefore(other.endTime) &&
        endTime.isAfter(other.startTime);
  }

  @override
  String toString() {
    return 'Task(taskName: $taskName, dueDate: $dueDate, startTime: $startTime, '
        'endTime: $endTime, priority: $priority, urgency: $urgency, '
        'importance: $importance, complexity: $complexity, weight: $weight)';
  }
}

class TaskManager {
  List<Task> tasks = [];
  Map<String, double> criteriaWeights = {
    'priority': 0.4,
    'urgency': 0.3,
    'importance': 0.2,
    'complexity': 0.1,
  };

  final double weightLimit = 15.0; // The weight limit threshold

  // AHP step: Normalize weights and store in criteriaWeights
  void applyAHP() {
    double total = criteriaWeights.values.reduce((a, b) => a + b);
    criteriaWeights =
        criteriaWeights.map((key, value) => MapEntry(key, value / total));
  }

  // Check if the total weight for a time slot exceeds the limit
  bool checkWeightInTimeSlot(DateTime startTime, DateTime endTime) {
    double totalWeight = 0.0;

    // Check tasks in the same time slot
    for (var task in tasks) {
      if ((task.startTime.isBefore(endTime) &&
          task.endTime.isAfter(startTime))) {
        totalWeight += task.weight;
      }
    }

    // Return whether the total weight exceeds the limit
    return totalWeight <= weightLimit;
  }

  // Add a task to the manager if valid and within the weight limit
  void addTask(Task task) {
    if (task.validateTaskTimes()) {
      task.updateWeight(
          criteriaWeights); // Update the task's weight before adding

      // Check if the task can be added without exceeding the weight limit
      if (!checkWeightInTimeSlot(task.startTime, task.endTime)) {
        print('Conflict: Adding task "${task.taskName}" exceeds weight limit.');
        return; // Task is not added due to weight conflict
      }

      tasks.add(task);
      print(
          'Task "${task.taskName}" added successfully with weight ${task.weight}.');
    } else {
      print('Task "${task.taskName}" has invalid times and cannot be added.');
    }
  }

  // IJFA step: Optimize task schedule based on task weights
  List<Task> applyIJFA() {
    List<Task> population = List.from(tasks);
    int iterations = 10; // Define the number of iterations for IJFA
    List<Task> bestArrangement = List.from(population);
    double bestFitness = calculateFitness(bestArrangement);

    for (int i = 0; i < iterations; i++) {
      // Shuffle tasks to simulate jellyfish movement
      population.shuffle();
      double currentFitness = calculateFitness(population);

      if (currentFitness > bestFitness) {
        bestArrangement = List.from(population);
        bestFitness = currentFitness;
      }
    }
    return bestArrangement;
  }

  // Calculate the fitness of a task arrangement based on their weights
  double calculateFitness(List<Task> taskArrangement) {
    return taskArrangement.fold(0.0, (sum, task) => sum + task.weight);
  }

  // Hyper Min-Max step: Balance task load to prevent peaks and idle slots
  void applyHyperMinMax() {
    Map<int, List<Task>> timeSlots = {};

    // Group tasks by time slots and calculate load
    for (var task in tasks) {
      int timeSlot = task.startTime.hour; // Example time slot by hour
      timeSlots[timeSlot] = (timeSlots[timeSlot] ?? [])..add(task);
    }

    // Adjust task times to balance load across slots
    for (var slot in timeSlots.keys) {
      List<Task> overloadedTasks = timeSlots[slot]!;
      if (overloadedTasks.length > 1) {
        for (var task in overloadedTasks) {
          DateTime newStartTime = task.startTime.add(Duration(hours: 1));
          task.startTime = newStartTime;
        }
      }
    }
  }

  // Get sorted and optimized tasks for a specific time
  List<Task> getOptimizedTaskList(DateTime time) {
    applyAHP(); // Apply AHP to update criteria weights
    var optimizedTasks = applyIJFA(); // Apply IJFA to get optimized arrangement
    applyHyperMinMax(); // Balance load using Hyper Min-Max

    // Filter tasks that overlap the specified time
    return optimizedTasks
        .where((task) =>
            task.startTime.isBefore(time) && task.endTime.isAfter(time))
        .toList();
  }

  // Show optimized task priorities for a given time
  void showTaskPrioritiesForTime(DateTime time) {
    var optimizedTasks = getOptimizedTaskList(time);

    if (optimizedTasks.isEmpty) {
      print('No tasks scheduled for this time.');
      return;
    }

    print('Optimized tasks prioritized for $time:');
    for (var task in optimizedTasks) {
      print('${task.taskName} - Weight: ${task.weight}');
    }
  }

  // Enhanced conflict detector that suggests alternative times
  void detectConflictsWithSuggestions() {
    for (int i = 0; i < tasks.length; i++) {
      for (int j = i + 1; j < tasks.length; j++) {
        if (tasks[i].overlapsWith(tasks[j])) {
          print(
              'Conflict detected between "${tasks[i].taskName}" and "${tasks[j].taskName}"');
          List<DateTime> alternativeTimes =
              suggestAlternativeTimes(tasks[j], 2);
          print('Suggested alternative times for "${tasks[j].taskName}":');
          for (var time in alternativeTimes) {
            print('- $time');
          }
        }
      }
    }
  }

  // Method to suggest alternative times for a conflicting task
  List<DateTime> suggestAlternativeTimes(Task task, int numSuggestions) {
    List<DateTime> suggestions = [];
    DateTime current = task.startTime;
    Duration interval = Duration(hours: 1); // Example interval

    while (suggestions.length < numSuggestions) {
      DateTime proposedStart = current.add(interval);
      DateTime proposedEnd =
          proposedStart.add(task.endTime.difference(task.startTime));

      // Check if the proposed time conflicts with other tasks
      bool conflict = tasks.any((t) =>
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
}
