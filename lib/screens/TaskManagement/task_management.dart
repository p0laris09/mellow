import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mellow/screens/TaskCreation/task_creation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskManagementScreen extends StatefulWidget {
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
    int daysFromSunday =
        selectedDate.weekday % 7; // Sunday is the start of the week
    _startOfWeek = selectedDate.subtract(Duration(days: daysFromSunday));
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
      DateTime startOfWeek = _startOfWeek;
      DateTime endOfWeek = startOfWeek.add(Duration(days: 7));

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: uid)
          .where('startTime', isGreaterThanOrEqualTo: startOfWeek)
          .where('startTime', isLessThan: endOfWeek)
          .get();

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
    List<String> weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

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
              weekdays[day.weekday % 7],
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
      appBar: AppBar(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskCreationScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C3C3C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 16.0),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 8.0),
                  Text(
                    'Create Task',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  setState(() {
                    _startOfWeek = _getStartOfWeekFromIndex(index);
                    // No need to manually fetch tasks here; StreamBuilder will handle updates
                  });
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
            const SizedBox(height: 16),
            _buildTaskSection(), // This will now use StreamBuilder for real-time updates
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSection() {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DateTime startOfWeek = _startOfWeek;
    DateTime endOfWeek = startOfWeek.add(Duration(days: 7));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "Tasks",
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
                .where('startTime', isGreaterThanOrEqualTo: startOfWeek)
                .where('startTime', isLessThan: endOfWeek)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text("Error loading tasks: ${snapshot.error}");
              }

              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var taskDocs = snapshot.data!.docs;

              if (taskDocs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No tasks available for the selected day.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                );
              }

              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: taskDocs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot task = taskDocs[index];
                  DateTime startTime =
                      (task['startTime'] as Timestamp?)?.toDate() ??
                          DateTime.now();
                  DateTime dueDate =
                      (task['endTime'] as Timestamp?)?.toDate() ??
                          DateTime.now();
                  String name = task['taskName'] ?? 'Unnamed Task';

                  String formattedStartTime =
                      DateFormat('hh:mm a').format(startTime);
                  String formattedDueDate =
                      DateFormat('yyyy-MM-dd').format(dueDate);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildProgressTask(
                        name,
                        formattedDueDate,
                        formattedStartTime,
                        startTime, // Pass start time
                        dueDate // Pass due date
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

  Widget _buildProgressTask(String taskName, String dueDate, String startTime,
      DateTime taskStartTime, DateTime taskDueDate) {
    DateTime now = DateTime.now();
    String taskStatus;
    Color iconColor;

    // Determine the status and icon color based on the time comparison
    if (now.isAfter(taskDueDate)) {
      taskStatus = "Overdue";
      iconColor = Colors.red;
    } else if (now.isAfter(taskStartTime) && now.isBefore(taskDueDate)) {
      taskStatus = "Ongoing";
      iconColor = Colors.green;
    } else {
      taskStatus = "Pending";
      iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(
          vertical: 8), // Adding margin to increase space between task cards
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2), // Changes position of shadow
          ),
        ],
      ),
      child: Row(
        children: [
          // Task icon with dynamic color based on task status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor, // Use the dynamic icon color
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.task, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  taskName,
                  style: TextStyle(
                    fontSize: 18, // Increased font size for better visibility
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Due: $dueDate | Start: $startTime',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                // Displaying task status
                Text(
                  'Status: $taskStatus',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        iconColor, // Matching the color of the status text with the icon
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {
              // Handle options button
            },
          ),
        ],
      ),
    );
  }
}
