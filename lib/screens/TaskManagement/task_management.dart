import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mellow/screens/TaskCreation/task_creation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mellow/screens/TaskCreation/task_creation_duo.dart';
import 'package:mellow/screens/TaskCreation/task_creation_space.dart';
import 'package:mellow/screens/TaskManagement/EisenHowerMatrixScreen/eisenhowermatrix_screen.dart';
import 'package:mellow/screens/TaskManagement/TaskListViewScreen/task_list_view_screen.dart';
import 'package:mellow/widgets/cards/TaskCards/task_card.dart' as taskcard;

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  _TaskManagementScreenState createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  DateTime _selectedDay = DateTime.now();
  late DateTime _startOfWeek;
  late PageController _pageController;
  late int _currentYear;
  late int _currentMonthIndex;
  List<DocumentSnapshot> _tasks = [];
  bool _fabExpanded = false;
  String selectedFilter = 'All';
  bool isMatrixView = true;

  @override
  void initState() {
    super.initState();
    _updateStartOfWeek(_selectedDay);
    _currentYear = _selectedDay.year;
    _currentMonthIndex = _selectedDay.month - 1;
    _pageController = PageController(
      initialPage: 5000,
      viewportFraction: 1.0,
    );
    _fetchTasks(); // Fetch tasks initiallyZ
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchTasks(); // Fetch tasks when the widget dependencies change
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _updateStartOfWeek(DateTime selectedDate) {
    int daysFromMonday =
        (selectedDate.weekday - 1) % 7; // Monday as the start of the week
    _startOfWeek = selectedDate.subtract(Duration(days: daysFromMonday));
  }

  DateTime _getStartOfWeekFromIndex(int index) {
    int weeksFromInitialPage = index - 5000;
    return _startOfWeek.add(Duration(days: weeksFromInitialPage * 7));
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDay = day;
      _fetchTasks();
    });
  }

  void _fetchTasks() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      DateTime startOfDay = DateTime(
          _selectedDay.year, _selectedDay.month, _selectedDay.day, 0, 0);
      DateTime endOfDay = DateTime(
          _selectedDay.year, _selectedDay.month, _selectedDay.day, 23, 59, 59);

      Query tasksQuery = FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', arrayContains: uid) // Filter by assignedTo
          .where('startTime', isLessThanOrEqualTo: endOfDay)
          .where('endTime', isGreaterThanOrEqualTo: startOfDay)
          .orderBy('startTime', descending: false)
          .orderBy('weight', descending: true); // Chain order by weight

      QuerySnapshot querySnapshot = await tasksQuery.get();

      setState(() {
        _tasks = querySnapshot.docs;
      });
    } catch (e) {
      print("Error fetching tasks: $e");
    }
  }

  void _showYearMonthPicker(BuildContext context) {
    int tempMonth = _currentMonthIndex;
    int tempYear = _currentYear;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            height: 300,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                              initialItem: tempMonth),
                          itemExtent: 32.0,
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              tempMonth = index;
                            });
                          },
                          children: List<Widget>.generate(12, (int index) {
                            return Center(
                              child: Text(DateFormat('MMMM')
                                  .format(DateTime(0, index + 1))),
                            );
                          }),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                              initialItem: tempYear - 2000),
                          itemExtent: 32.0,
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              tempYear = 2000 + index;
                            });
                          },
                          children: List<Widget>.generate(102, (int index) {
                            return Center(
                              child: Text((2000 + index).toString()),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentMonthIndex = tempMonth;
                      _currentYear = tempYear;
                      _selectedDay =
                          DateTime(_currentYear, _currentMonthIndex + 1, 1);
                      _updateStartOfWeek(_selectedDay);
                      _pageController.jumpToPage(5000); // Reset to initial page
                      _fetchTasks(); // Fetch tasks for the updated month/year
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Pick Date"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildDayPicker(DateTime startOfWeek) {
    List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return List.generate(7, (i) {
      DateTime day = startOfWeek.add(Duration(days: i));
      bool isSelected = day.day == _selectedDay.day &&
          day.month == _selectedDay.month &&
          day.year == _selectedDay.year;

      return GestureDetector(
        onTap: () => _onDaySelected(day),
        child: Column(
          children: [
            Text(
              weekdays[(day.weekday - 1) % 7], // Weekdays start from Monday
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: day.weekday == DateTime.saturday ||
                        day.weekday == DateTime.sunday
                    ? Colors.red
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _filterButton(String label) {
    return TextButton(
      onPressed: () {
        setState(() {
          selectedFilter = label;
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: selectedFilter == label
            ? const Color(0xFF2275AA)
            : Colors.grey[300],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selectedFilter == label ? Colors.white : Colors.black,
          fontWeight:
              selectedFilter == label ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            _filterButton('All'),
            const SizedBox(width: 8),
            _filterButton('Personal'),
            const SizedBox(width: 8),
            _filterButton('Shared'),
            const SizedBox(width: 8),
            _filterButton('Collaboration Space'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
        automaticallyImplyLeading:
            false, // Prevents the back button from appearing
        title: GestureDetector(
          onTap: () {
            _showYearMonthPicker(context); // Show the picker on tap
          },
          child: Text(
            DateFormat('MMMM, yyyy').format(_selectedDay),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3C3C),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isMatrixView ? Icons.list : Icons.border_all),
            onPressed: () {
              setState(() {
                isMatrixView = !isMatrixView;
              });
            },
          ),
        ],
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        child: Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {});
                },
                itemBuilder: (context, index) {
                  DateTime weekStart = _getStartOfWeekFromIndex(index);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _buildDayPicker(weekStart),
                  );
                },
              ),
            ),
            const SizedBox(height: 2),
            _buildFilterSection(),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: isMatrixView
                    ? EisenhowerMatrixView(
                        key: const ValueKey("Eisenhower"),
                        pageController: _pageController,
                        startOfWeek: _startOfWeek,
                        getStartOfWeekFromIndex: _getStartOfWeekFromIndex,
                        tasksStream: FirebaseFirestore.instance
                            .collection('tasks')
                            .snapshots(),
                        selectedFilter: selectedFilter,
                      )
                    : TaskListView(
                        key: const ValueKey("TaskList"),
                        pageController: _pageController,
                        startOfWeek: _startOfWeek,
                        getStartOfWeekFromIndex: _getStartOfWeekFromIndex,
                        buildOverdueSection: _buildOverdueSection,
                        buildTaskSection: (tasks) => _buildTaskSection(tasks),
                        tasksStream: FirebaseFirestore.instance
                            .collection('tasks')
                            .snapshots(),
                        selectedFilter: selectedFilter,
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildOverdueSection() {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DateTime now = DateTime.now(); // Current date and time

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('endTime',
                isLessThan: Timestamp.fromDate(now)) // Overdue tasks
            .where('status', isNotEqualTo: 'Finished') // Exclude finished tasks
            .orderBy('endTime', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("Error loading overdue tasks: ${snapshot.error}");
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Return an empty container if there are no overdue tasks
            return const SizedBox.shrink();
          }

          var overdueTaskDocs = snapshot.data!.docs.where((task) {
            Map<String, dynamic> taskData = task.data() as Map<String, dynamic>;
            if (selectedFilter == 'All') {
              return (taskData['assignedTo']?.contains(uid) ?? false) ||
                  taskData['userId'] == uid;
            } else if (selectedFilter == 'Personal') {
              return taskData['userId'] == uid &&
                  taskData['taskType'] == 'personal';
            } else if (selectedFilter == 'Shared') {
              return taskData['taskType'] == 'duo';
            } else if (selectedFilter == 'Collaboration Space') {
              return taskData['taskType'] == 'space' &&
                  (taskData['assignedTo']?.contains(uid) ?? false);
            }
            return false;
          }).toList();

          if (overdueTaskDocs.isEmpty) {
            // Return an empty container if there are no overdue tasks
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  "Overdue",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: overdueTaskDocs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot task = overdueTaskDocs[index];
                  Map<String, dynamic> taskData =
                      task.data() as Map<String, dynamic>;
                  String taskId = task.id; // Get Firestore's document ID
                  DateTime startTime =
                      (taskData['startTime'] as Timestamp).toDate();
                  DateTime dueDate =
                      (taskData['endTime'] as Timestamp).toDate();
                  String name = taskData['taskName'] ?? 'Unnamed Task';

                  String formattedStartTime =
                      DateFormat('yyyy-MM-dd hh:mm a').format(startTime);
                  String formattedDueDate =
                      DateFormat('yyyy-MM-dd hh:mm a').format(dueDate);

                  // Determine task status based on the end time
                  String taskStatus;
                  if (taskData.containsKey('status') &&
                      taskData['status'] == 'Finished') {
                    taskStatus =
                        'Finished'; // Set status to Finished if it is finished
                  } else if (dueDate.isBefore(now)) {
                    taskStatus = 'Overdue'; // Task is overdue
                  } else if (startTime.isAfter(now)) {
                    taskStatus = 'Pending'; // Task is pending
                  } else {
                    taskStatus = 'Ongoing'; // Task is still ongoing
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: taskcard.TaskCard(
                      taskId: taskId,
                      taskName: name,
                      dueDate: formattedDueDate,
                      startTime: formattedStartTime,
                      startDateTime: startTime,
                      dueDateTime: dueDate,
                      taskStatus: taskStatus, // This is passed correctly
                      onTaskFinished: () {
                        // Handle task finished logic here
                        _fetchTasks(); // Refresh tasks after finishing a task
                      },
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskSection(List<Map<String, dynamic>> tasks) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    DateTime startOfDay =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 0, 0);
    DateTime endOfDay = DateTime(
        _selectedDay.year, _selectedDay.month, _selectedDay.day, 23, 59, 59);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "Tasks for ${DateFormat('EEEE, MMM d').format(_selectedDay)}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tasks')
                .where('startTime',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                .where('startTime',
                    isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
                .where('status',
                    isNotEqualTo: 'Finished') // Exclude finished tasks
                .orderBy('startTime', descending: false)
                .orderBy('weight', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text("Error loading tasks: ${snapshot.error}");
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No tasks available for ${DateFormat('EEEE, MMM d').format(_selectedDay)}.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                );
              }

              var taskDocs = snapshot.data!.docs.where((task) {
                Map<String, dynamic> taskData =
                    task.data() as Map<String, dynamic>;
                if (selectedFilter == 'All') {
                  return (taskData['taskType'] == 'personal' &&
                          taskData['userId'] == uid) ||
                      ((taskData['taskType'] == 'duo' ||
                              taskData['taskType'] == 'space') &&
                          taskData['assignedTo'].contains(uid));
                } else if (selectedFilter == 'Personal') {
                  return taskData['userId'] == uid &&
                      taskData['taskType'] == 'personal';
                } else if (selectedFilter == 'Shared') {
                  return taskData['taskType'] == 'duo' &&
                      taskData['assignedTo'].contains(uid);
                } else if (selectedFilter == 'Collaboration Space') {
                  return taskData['taskType'] == 'space' &&
                      taskData['assignedTo'].contains(uid);
                }
                return false;
              }).toList();

              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: taskDocs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot task = taskDocs[index];
                  Map<String, dynamic> taskData =
                      task.data() as Map<String, dynamic>;
                  String taskId = task.id;
                  DateTime startTime =
                      (taskData['startTime'] as Timestamp).toDate();
                  DateTime dueDate =
                      (taskData['endTime'] as Timestamp).toDate();
                  String name = taskData['taskName'] ?? 'Unnamed Task';
                  String taskStatus = taskData.containsKey('status')
                      ? taskData['status']
                      : 'Pending'; // Provide default value if status is missing

                  String formattedStartTime =
                      DateFormat('yyyy-MM-dd hh:mm a').format(startTime);
                  String formattedDueDate =
                      DateFormat('yyyy-MM-dd hh:mm a').format(dueDate);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: taskcard.TaskCard(
                      taskId: taskId,
                      taskName: name,
                      dueDate: formattedDueDate,
                      startTime: formattedStartTime,
                      startDateTime: startTime,
                      dueDateTime: dueDate,
                      taskStatus: taskStatus, // Pass the real task status
                      onTaskFinished: () {
                        // Handle task finished logic here
                        _fetchTasks(); // Refresh tasks after finishing a task
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Build the Floating Action Button with expansion feature
  Widget _buildFab() {
    return Stack(
      children: [
        Align(
          alignment:
              Alignment.bottomRight, // Align the content to the bottom-right
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.end, // Align buttons to the right
            children: [
              // Show additional buttons when FAB is expanded
              if (_fabExpanded) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle "Personal" task creation
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskCreationScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF2275AA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text("Create a Personal"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle "Duo" task creation
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskCreationDuo(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF2275AA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text("Create a Duo Task"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle "Space" task creation
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskCreationSpace(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF2275AA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text("Create a Space Task"),
                  ),
                ),
              ],
              // Main Floating Action Button
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _fabExpanded = !_fabExpanded; // Toggle expansion state
                    });
                  },
                  backgroundColor: const Color(0xFF2275AA),
                  child: Icon(
                    _fabExpanded
                        ? Icons.close
                        : Icons.add, // Toggle between "close" and "add" icons
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
