import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mellow/widgets/cards/TaskCards/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<DocumentSnapshot> tasks = [];
  List<DocumentSnapshot> filteredTasks = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedTimeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // Query for tasks where assignedTo is an array containing the user
      QuerySnapshot arrayQuery = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', arrayContains: currentUserId)
          .get();

      // Query for tasks where assignedTo is a direct string match
      QuerySnapshot stringQuery = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: currentUserId)
          .get();

      // Merge both lists and remove duplicates
      Set<String> taskIds = {};
      List<DocumentSnapshot> allTasks = [];

      for (var doc in arrayQuery.docs + stringQuery.docs) {
        if (!taskIds.contains(doc.id)) {
          taskIds.add(doc.id);
          allTasks.add(doc);
        }
      }

      setState(() {
        tasks = allTasks;
        _applyFilters();
      });

      print('Fetched ${tasks.length} tasks assigned to the user.');
    } catch (e) {
      print('Error fetching tasks: $e');
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    DateTime now = DateTime.now();
    DateTime last7Days = now.subtract(Duration(days: 7));
    DateTime lastMonth = DateTime(now.year, now.month - 1, now.day);

    filteredTasks = tasks.where((task) {
      final taskData = task.data() as Map<String, dynamic>;

      final taskName = (taskData['taskName'] ?? '').toString().toLowerCase();
      final taskStatus =
          taskData['status'] ?? 'Pending'; // Default to 'Pending' if missing
      final startTime =
          (taskData['startTime'] as Timestamp?)?.toDate() ?? DateTime.now();
      final endTime =
          (taskData['endTime'] as Timestamp?)?.toDate() ?? DateTime.now();
      final dueDate =
          (taskData['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now();

      // Compute dynamic status
      bool isOverdue = now.isAfter(dueDate) && taskStatus != 'Finished';
      bool isOngoing = now.isAfter(startTime) && now.isBefore(endTime);

      String statusLabel;
      if (taskStatus == 'Finished') {
        statusLabel = 'Finished';
      } else if (isOngoing) {
        statusLabel = 'Ongoing';
      } else if (isOverdue) {
        statusLabel = 'Overdue';
      } else {
        statusLabel = 'Pending';
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty && !taskName.contains(_searchQuery)) {
        return false;
      }

      // Apply status filter
      if (_selectedStatus != 'All' && statusLabel != _selectedStatus) {
        return false;
      }

      // Apply time filter
      if (_selectedTimeFilter == 'Last 7 Days' && dueDate.isBefore(last7Days)) {
        return false;
      }

      if (_selectedTimeFilter == 'Last Month' && dueDate.isBefore(lastMonth)) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Task History',
            style: TextStyle(color: Colors.white, fontSize: 20)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DropdownButton<String>(
                value: _selectedStatus,
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                    _applyFilters();
                  });
                },
                items: ['All', 'Finished', 'Pending', 'Ongoing', 'Overdue']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
              ),
              DropdownButton<String>(
                value: _selectedTimeFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedTimeFilter = value!;
                    _applyFilters();
                  });
                },
                items: ['All', 'Last 7 Days', 'Last Month']
                    .map((filter) => DropdownMenuItem(
                          value: filter,
                          child: Text(filter),
                        ))
                    .toList(),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                DocumentSnapshot task = filteredTasks[index];
                final taskData = task.data() as Map<String, dynamic>;

                return TaskCard(
                  taskId: task.id,
                  taskName: taskData['taskName'] ??
                      'Unnamed Task', // Default to 'Unnamed Task'
                  dueDate: (taskData['dueDate'] as Timestamp?)
                          ?.toDate()
                          .toString() ??
                      '',
                  startTime: (taskData['startTime'] as Timestamp?)
                          ?.toDate()
                          .toString() ??
                      '',
                  startDateTime:
                      (taskData['startDateTime'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                  dueDateTime:
                      (taskData['dueDateTime'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                  taskStatus:
                      taskData['status'] ?? 'Pending', // Default to 'Pending'
                  completionTime:
                      (taskData['completionTime'] as Timestamp?)?.toDate(),
                  onTaskFinished: () {
                    // Add your logic here for when the task is finished
                    print('Task ${task.id} finished');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
