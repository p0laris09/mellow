import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mellow/screens/TaskCreation/task_creation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mellow/widgets/cards/TaskCards/task_card.dart';

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

      // Get the start of the selected day and end of the selected day
      DateTime startOfDay = DateTime(
          _selectedDay.year, _selectedDay.month, _selectedDay.day, 0, 0);
      DateTime endOfDay = DateTime(
          _selectedDay.year, _selectedDay.month, _selectedDay.day, 23, 59, 59);

      // Query for tasks that start on or before the selected day and end on or after the selected day
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: uid)
          .where('startTime',
              isLessThanOrEqualTo:
                  endOfDay) // Task starts before or on the selected day
          .where('endTime',
              isGreaterThanOrEqualTo:
                  startOfDay) // Task ends after or on the selected day
          .orderBy('startTime',
              descending: false) // Ensure tasks are ordered by startTime
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
            _buildOverdueSection(),
            const SizedBox(height: 8),
            _buildTaskSection(), // This will now use StreamBuilder for real-time updates
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
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
        ],
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
                  DateTime startTime =
                      (task['startTime'] as Timestamp).toDate();
                  DateTime dueDate = (task['endTime'] as Timestamp).toDate();
                  String name = task['taskName'] ?? 'Unnamed Task';

                  String formattedStartTime =
                      DateFormat('yyyy-MM-dd hh:mm a').format(startTime);
                  String formattedDueDate =
                      DateFormat('yyyy-MM-dd hh:mm a').format(dueDate);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TaskCard(
                      taskName: name,
                      dueDate: formattedDueDate,
                      startTime: formattedStartTime,
                      startDateTime: startTime,
                      dueDateTime: dueDate,
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
}
