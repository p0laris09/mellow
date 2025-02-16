class Task {
  String userId; // Track task ownership
  String taskName;
  DateTime dueDate;
  DateTime startTime;
  DateTime endTime;
  String description;
  double priority;
  double urgency;
  double complexity;
  double weight = 0.0;
  String taskType; // New field for task type

  Task({
    required this.userId,
    required this.taskName,
    required this.dueDate,
    required this.startTime,
    required this.endTime,
    this.description = '',
    this.priority = 0.0,
    this.urgency = 0.0,
    this.complexity = 0.0,
    required this.taskType, // Initialize the taskType field
  }) : weight = 0.0; // Initialize weight

  // Calculate and update the task's weight based on criteria weights
  void updateWeight(Map<String, double> criteriaWeights) {
    priority = (priority / 3.0).clamp(0.0, 1.0);
    urgency = (urgency / 3.0).clamp(0.0, 1.0);
    complexity = (complexity / 3.0).clamp(0.0, 1.0);

    double weightedPriority = priority * criteriaWeights['priority']!;
    double weightedUrgency = urgency * criteriaWeights['urgency']!;
    double weightedComplexity = complexity * criteriaWeights['complexity']!;

    weight = weightedPriority + weightedUrgency + weightedComplexity;

    // Debugging: Print updated weight
    print("Updated Task Weight for '${taskName}': $weight");
  }

  // Validate task times
  bool validateTaskTimes() {
    return startTime.isBefore(endTime);
  }

  // Check if two tasks overlap in time
  bool overlapsWith(Task other) {
    return startTime.isBefore(other.endTime) &&
        endTime.isAfter(other.startTime);
  }

  // Classify the task using the Eisenhower Matrix
  String categorizeUsingEisenhowerMatrix() {
    if (urgency > 0.5 && complexity > 0.5) {
      return 'Quadrant I (Urgent and Important)'; // Do first
    } else if (urgency <= 0.5 && complexity > 0.5) {
      return 'Quadrant II (Not Urgent but Important)'; // Schedule
    } else if (urgency > 0.5 && complexity <= 0.5) {
      return 'Quadrant III (Urgent but Not Important)'; // Delegate
    } else {
      return 'Quadrant IV (Not Urgent and Not Important)'; // Eliminate
    }
  }

  @override
  String toString() {
    return 'Task(taskName: $taskName, taskType: $taskType, dueDate: $dueDate, startTime: $startTime, '
        'endTime: $endTime, priority: $priority, urgency: $urgency, '
        'complexity: $complexity, weight: $weight)';
  }
}

class TaskManager {
  String currentUserId;
  List<Task> tasks = [];
  Map<String, double> criteriaWeights = {
    'priority': 0.4,
    'urgency': 0.3,
    'complexity': 0.3, // Adjusted for complexity without importance
  };

  final double weightLimit = 60.0;

  TaskManager({required this.currentUserId});

  // Apply AHP to normalize weights
  void applyAHP() {
    double total = criteriaWeights.values.reduce((a, b) => a + b);
    criteriaWeights =
        criteriaWeights.map((key, value) => MapEntry(key, value / total));
  }

  // Check if total weight in a time slot exceeds the limit
  bool checkWeightInTimeSlot(Task newTask) {
    DateTime start = newTask.startTime;
    DateTime end = newTask.endTime;

    // Iterate over every hour the new task spans
    while (start.isBefore(end)) {
      // Calculate the total weight of tasks in the current hour (start to start+1 hour)
      double hourWeight = tasks
          .where((task) =>
              task.userId == currentUserId &&
              task.startTime.isBefore(start.add(Duration(hours: 1))) &&
              task.endTime.isAfter(start))
          .fold(0.0, (sum, task) => sum + task.weight);

      // Add the weight of the new task to the weight of the current hour
      hourWeight += newTask.weight;

      // Print the cumulative weight for debugging
      print("Time: $start - Cumulative Hour Weight: $hourWeight, "
          "New Task Weight: ${newTask.weight}, Weight Limit: $weightLimit");

      if (hourWeight > weightLimit) {
        // If the weight limit is exceeded, return false (don't add the task)
        return false;
      }

      // Move to the next hour to check for overlap in that hour
      start = start.add(Duration(hours: 1));
    }

    // If no hour exceeded the weight limit, allow the task to be added
    return true;
  }

  // Add a task if valid and within weight limit
  void addTask(Task task) {
    if (task.validateTaskTimes()) {
      task.updateWeight(
          criteriaWeights); // Ensure weight is updated before conflict check

      if (!checkWeightInTimeSlot(task)) {
        print(
            'Conflict: Adding task "${task.taskName}" exceeds weight limit in one or more hours.');
        return;
      }

      tasks.add(task);
      print(
          'Task "${task.taskName}" added successfully with weight ${task.weight}.');
    } else {
      print('Task "${task.taskName}" has invalid times and cannot be added.');
    }
  }

  // Optimize task schedule with IJFA
  List<Task> applyIJFA() {
    List<Task> population = List.from(tasks);
    int iterations = 10;
    List<Task> bestArrangement = List.from(population);
    double bestFitness = calculateFitness(bestArrangement);

    for (int i = 0; i < iterations; i++) {
      population.shuffle();
      double currentFitness = calculateFitness(population);

      if (currentFitness > bestFitness) {
        bestArrangement = List.from(population);
        bestFitness = currentFitness;
      }
    }
    return bestArrangement;
  }

  // Calculate fitness of a task arrangement
  double calculateFitness(List<Task> taskArrangement) {
    return taskArrangement.fold(0.0, (sum, task) => sum + task.weight);
  }

  // Balance task load to prevent peaks and idle slots with Hyper Min-Max
  void applyHyperMinMax() {
    Map<int, List<Task>> timeSlots = {};

    for (var task in tasks) {
      int timeSlot = task.startTime.hour;
      timeSlots[timeSlot] = (timeSlots[timeSlot] ?? [])..add(task);
    }

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

  // Get optimized task list for a specific time
  List<Task> getOptimizedTaskList(DateTime time) {
    applyAHP();
    var optimizedTasks = applyIJFA();
    applyHyperMinMax();

    return optimizedTasks
        .where((task) =>
            task.startTime.isBefore(time) && task.endTime.isAfter(time))
        .toList();
  }

  // Display task priorities for a specific time
  void showTaskPrioritiesForTime(DateTime time) {
    var optimizedTasks = getOptimizedTaskList(time);

    if (optimizedTasks.isEmpty) {
      print('No tasks scheduled for this time.');
      return;
    }

    print('Optimized tasks prioritized for $time:');
    for (var task in optimizedTasks) {
      print(
          '${task.taskName} - Weight: ${task.weight} - Category: ${task.categorizeUsingEisenhowerMatrix()}');
    }
  }

  // Conflict detector that considers weight limit before suggesting alternative times
  void detectConflictsWithSuggestions() {
    for (int i = 0; i < tasks.length; i++) {
      for (int j = i + 1; j < tasks.length; j++) {
        Task taskA = tasks[i];
        Task taskB = tasks[j];

        // Skip tasks with weight 0.0
        if (taskA.weight == 0.0 || taskB.weight == 0.0) continue;

        // Check if tasks overlap in time
        if (taskA.overlapsWith(taskB)) {
          print(
              'Conflict detected between "${taskA.taskName}" and "${taskB.taskName}"');

          // Check if weight limit is exceeded in the overlapping time slot for taskB
          bool exceedsWeightLimit = !checkWeightInTimeSlot(taskB);

          if (exceedsWeightLimit) {
            print('Adding "${taskB.taskName}" would exceed weight limit.');

            // Suggest alternative times for taskB only if weight limit is exceeded
            List<DateTime> alternativeTimes = suggestAlternativeTimes(taskB, 2);
            print('Suggested alternative times for "${taskB.taskName}":');
            for (var time in alternativeTimes) {
              print('- $time');
            }
          } else {
            print(
                'Conflict detected, but weight limit is not exceeded for "${taskB.taskName}".');
          }
        }
      }
    }
  }

  // Suggest alternative times for a conflicting task based on weight limits
  List<DateTime> suggestAlternativeTimes(Task task, int numSuggestions) {
    List<DateTime> suggestions = [];
    DateTime current = task.startTime;
    Duration interval = Duration(hours: 1);

    DateTime endOfDay =
        DateTime(current.year, current.month, current.day, 23, 59, 59);

    while (suggestions.length < numSuggestions) {
      DateTime proposedStart = current.add(interval);
      DateTime proposedEnd =
          proposedStart.add(task.endTime.difference(task.startTime));

      if (proposedStart.isAfter(endOfDay)) break;

      // Check if this time slot does not exceed the weight limit
      bool withinWeightLimit = checkWeightInTimeSlot(Task(
        userId: task.userId,
        taskName: task.taskName,
        dueDate: task.dueDate,
        startTime: proposedStart,
        endTime: proposedEnd,
        priority: task.priority,
        urgency: task.urgency,
        complexity: task.complexity,
        taskType: task.taskType,
      ));

      if (withinWeightLimit) {
        suggestions.add(proposedStart);
      }

      current = proposedStart;
    }

    return suggestions;
  }
}
