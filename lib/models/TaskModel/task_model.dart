import 'package:cloud_firestore/cloud_firestore.dart';

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
  String assignedTo; // New field for assigned user

  Task({
    required this.userId,
    required this.taskName,
    required this.dueDate,
    required this.startTime,
    required this.endTime,
    this.description = '',
    this.priority = 1.0,
    this.urgency = 1.0,
    this.complexity = 1.0,
    required this.taskType, // Initialize the taskType field
    required this.assignedTo, // Initialize the assignedTo field
  }) : weight = 0.0; // Initialize weight

  // Calculate and update the task's weight based on criteria weights
  void updateWeight(Map<String, double> criteriaWeights) {
    double weightedPriority = (priority / 5.0) * criteriaWeights['priority']!;
    double weightedUrgency = (urgency / 5.0) * criteriaWeights['urgency']!;
    double weightedComplexity =
        (complexity / 5.0) * criteriaWeights['complexity']!;

    weight = weightedPriority + weightedUrgency + weightedComplexity;

    // Debugging: Print updated weight
    print("Updated Task Weight for '$taskName': $weight");
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
    return getEisenhowerQuadrant(urgency, priority);
  }

  String getEisenhowerQuadrant(double urgency, double priority) {
    if (urgency > 4 && priority > 4) {
      return 'Quadrant I (Urgent and Important)'; // Do First
    } else if (urgency <= 2 && priority > 3) {
      return 'Quadrant II (Not Urgent but Important)'; // Schedule
    } else if (urgency > 3 && priority <= 2) {
      return 'Quadrant III (Urgent but Not Important)'; // Delegate
    } else if (urgency <= 1 && priority <= 1) {
      return 'Quadrant IV (Not Urgent and Not Important)'; // Eliminate
    } else {
      return 'Uncategorized';
    }
  }

  @override
  String toString() {
    return 'Task(taskName: $taskName, taskType: $taskType, dueDate: $dueDate, startTime: $startTime, '
        'endTime: $endTime, priority: $priority, urgency: $urgency, '
        'complexity: $complexity, weight: $weight, assignedTo: $assignedTo)';
  }
}

class TaskManager {
  String currentUserId;
  List<Task> tasks = [];
  Map<String, double> criteriaWeights = {
    'priority': 0.4,
    'urgency': 0.3,
    'complexity': 0.3,
  };

  TaskManager({required this.currentUserId});

  // Apply AHP to normalize weights
  void applyAHP() {
    double total = criteriaWeights.values.reduce((a, b) => a + b);
    criteriaWeights =
        criteriaWeights.map((key, value) => MapEntry(key, value / total));
  }

  // Check if the number of tasks in a time slot exceeds the user's preference
  Future<bool> checkTaskPreferenceInTimeSlot(Task newTask) async {
    DateTime start = newTask.startTime;
    DateTime end = newTask.endTime;

    // Fetch the user's task preference from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    String taskPreferenceString = userDoc['task_preference'] ??
        "4+ tasks"; // Default to "4+ tasks" if not set
    int taskPreference = _parseTaskPreference(taskPreferenceString);

    // Iterate over every hour the new task spans
    while (start.isBefore(end)) {
      // Calculate the number of tasks in the current hour (start to start+1 hour)
      int taskCount = tasks
          .where((task) =>
              task.userId == currentUserId &&
              task.startTime.isBefore(start.add(const Duration(hours: 1))) &&
              task.endTime.isAfter(start))
          .length;

      // Add the new task to the count
      taskCount += 1;

      // Print the task count for debugging
      print("Time: $start - Task Count: $taskCount, "
          "Task Preference: $taskPreference");

      if (taskCount > taskPreference) {
        // If the task count exceeds the user's preference, return false (don't add the task)
        return false;
      }

      // Move to the next hour to check for overlap in that hour
      start = start.add(const Duration(hours: 1));
    }

    // If no hour exceeded the task preference, allow the task to be added
    return true;
  }

  // Parse the task preference string to an integer
  int _parseTaskPreference(String taskPreferenceString) {
    switch (taskPreferenceString) {
      case "1 task":
        return 1;
      case "2 tasks":
        return 2;
      case "3 tasks":
        return 3;
      case "4+ tasks":
        return 4;
      default:
        return 4; // Default to 4 if the string is unrecognized
    }
  }

  // Add a task if valid and within task preference
  Future<void> addTask(Task task) async {
    if (task.validateTaskTimes()) {
      task.updateWeight(
          criteriaWeights); // Ensure weight is updated before conflict check

      if (!await checkTaskPreferenceInTimeSlot(task)) {
        print(
            'Conflict: Adding task "${task.taskName}" exceeds task preference in one or more hours.');
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
          DateTime newStartTime = task.startTime.add(const Duration(hours: 1));
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

  // Conflict detector that considers task preference before suggesting alternative times
  Future<void> detectConflictsWithSuggestions() async {
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

          // Check if task preference is exceeded in the overlapping time slot for taskB
          bool exceedsTaskPreference =
              !await checkTaskPreferenceInTimeSlot(taskB);

          if (exceedsTaskPreference) {
            print('Adding "${taskB.taskName}" would exceed task preference.');

            // Suggest alternative times for taskB only if task preference is exceeded
            List<DateTime> alternativeTimes =
                await suggestAlternativeTimes(taskB, 2);
            print('Suggested alternative times for "${taskB.taskName}":');
            for (var time in alternativeTimes) {
              print('- $time');
            }
          } else {
            print(
                'Conflict detected, but task preference is not exceeded for "${taskB.taskName}".');
          }
        }
      }
    }
  }

  // Suggest alternative times for a conflicting task based on task preference
  Future<List<DateTime>> suggestAlternativeTimes(
      Task task, int numSuggestions) async {
    List<DateTime> suggestions = [];
    DateTime current = task.startTime;
    Duration interval = const Duration(hours: 1);

    DateTime endOfDay =
        DateTime(current.year, current.month, current.day, 23, 59, 59);

    while (suggestions.length < numSuggestions) {
      DateTime proposedStart = current.add(interval);
      DateTime proposedEnd =
          proposedStart.add(task.endTime.difference(task.startTime));

      if (proposedStart.isAfter(endOfDay)) break;

      // Check if this time slot does not exceed the task preference
      bool withinTaskPreference = await checkTaskPreferenceInTimeSlot(Task(
        userId: task.userId,
        taskName: task.taskName,
        dueDate: task.dueDate,
        startTime: proposedStart,
        endTime: proposedEnd,
        priority: task.priority,
        urgency: task.urgency,
        complexity: task.complexity,
        taskType: task.taskType,
        assignedTo: task.assignedTo, // Include assignedTo field
      ));

      if (withinTaskPreference) {
        suggestions.add(proposedStart);
      }

      current = proposedStart;
    }

    return suggestions;
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
          int daysToAdd = (task.dueDate.weekday - now.weekday) % 7;
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
          adjustedStartTime = adjustedStartTime.add(const Duration(days: 1));
          adjustedEndTime = adjustedEndTime.add(const Duration(days: 1));
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
}
