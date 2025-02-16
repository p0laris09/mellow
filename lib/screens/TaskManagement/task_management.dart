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
    _fetchTasks(); // Fetch tasks initially
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
          .where('userId', isEqualTo: uid)
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
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: isMatrixView
              ? EisenhowerMatrixView(
                  key: ValueKey("Eisenhower"),
                  pageController: _pageController,
                  startOfWeek: _startOfWeek,
                  getStartOfWeekFromIndex: _getStartOfWeekFromIndex,
                  buildOverdueSection: _buildOverdueSection,
                  buildDayPicker: _buildDayPicker,
                )
              : TaskListView(
                  key: ValueKey("TaskList"),
                  pageController: _pageController,
                  startOfWeek: _startOfWeek,
                  getStartOfWeekFromIndex: _getStartOfWeekFromIndex,
                  buildOverdueSection: _buildOverdueSection,
                  buildTaskSection: _buildTaskSection,
                  buildDayPicker: _buildDayPicker,
                ),
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
            .where('userId', isEqualTo: uid)
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

          var overdueTaskDocs = snapshot.data!.docs;

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
                  String taskId = task.id; // Get Firestore's document ID
                  DateTime startTime =
                      (task['startTime'] as Timestamp).toDate();
                  DateTime dueDate = (task['endTime'] as Timestamp).toDate();
                  String name = task['taskName'] ?? 'Unnamed Task';

                  String formattedStartTime =
                      DateFormat('yyyy-MM-dd hh:mm a').format(startTime);
                  String formattedDueDate =
                      DateFormat('yyyy-MM-dd hh:mm a').format(dueDate);

                  // Determine task status based on the end time
                  String taskStatus;
                  if (task['status'] == 'Finished') {
                    taskStatus =
                        'Finished'; // Set status to Finished if it is finished
                  } else if (dueDate.isBefore(now)) {
                    taskStatus = 'Overdue'; // Task is overdue
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

  Widget _buildTaskSection() {
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
                .where('userId', isEqualTo: uid)
                .where('startTime',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                .where('startTime',
                    isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
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

              var taskDocs = snapshot.data!.docs;

              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: taskDocs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot task = taskDocs[index];
                  String taskId = task.id;
                  DateTime startTime =
                      (task['startTime'] as Timestamp).toDate();
                  DateTime dueDate = (task['endTime'] as Timestamp).toDate();
                  String name = task['taskName'] ?? 'Unnamed Task';
                  String taskStatus =
                      task['status'] ?? 'Pending'; // Fetch task status

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
