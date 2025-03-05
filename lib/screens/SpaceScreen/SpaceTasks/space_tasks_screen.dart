import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mellow/screens/TaskCreation/task_creation_space.dart';
import 'package:mellow/widgets/cards/TaskCards/task_card.dart';

class SpaceTasksScreen extends StatefulWidget {
  final String spaceId;

  const SpaceTasksScreen({super.key, required this.spaceId});

  @override
  State<SpaceTasksScreen> createState() => _SpaceTasksScreenState();
}

class _SpaceTasksScreenState extends State<SpaceTasksScreen> {
  late Stream<QuerySnapshot> tasksStream;
  late Stream<DocumentSnapshot> spaceDetailsStream;
  late DateTime _selectedDay;
  late DateTime _startOfWeek;
  late PageController _pageController;
  String spaceName = '';
  bool isMatrixView = true;
  late int _currentYear;
  late int _currentMonthIndex;

  @override
  void initState() {
    super.initState();
    tasksStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('spaceId', isEqualTo: widget.spaceId)
        .orderBy('createdAt', descending: false)
        .snapshots();

    spaceDetailsStream = FirebaseFirestore.instance
        .collection('spaces')
        .doc(widget.spaceId)
        .snapshots();

    _selectedDay = DateTime.now();
    _updateStartOfWeek(_selectedDay);
    _pageController = PageController(initialPage: 5000, viewportFraction: 1.0);

    _currentYear = _selectedDay.year;
    _currentMonthIndex = _selectedDay.month - 1;

    // Fetch space name
    spaceDetailsStream.listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          spaceName =
              (snapshot.data() as Map<String, dynamic>?)?['name'] ?? 'Space';
        });
      }
    });
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
      _updateStartOfWeek(day);
    });
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
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: FixedExtentScrollController(
                              initialItem: tempMonth),
                          itemExtent: 32.0,
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              tempMonth = index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              return Center(
                                child: Text(
                                  DateFormat('MMMM')
                                      .format(DateTime(0, index + 1)),
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              );
                            },
                            childCount: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: FixedExtentScrollController(
                              initialItem: tempYear - 2000),
                          itemExtent: 32.0,
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              tempYear = 2000 + index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              return Center(
                                child: Text(
                                  (2000 + index).toString(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              );
                            },
                            childCount: 102,
                          ),
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
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Pick Date",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          spaceName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2275AA),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      _showYearMonthPicker(context); // Show the picker on tap
                    },
                    child: Text(
                      DateFormat('MMMM, yyyy').format(_selectedDay),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
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
            ),
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
            const SizedBox(height: 2),
            Expanded(
              child: isMatrixView
                  ? _buildEisenhowerMatrix()
                  : _buildTaskListView(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskCreationSpace()),
          );
        },
        backgroundColor: const Color(0xFF2275AA),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Task', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEisenhowerMatrix() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildQuadrant("Urgent & Important", Colors.green),
              _buildQuadrant("Not Urgent & Important", Colors.orange),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              _buildQuadrant("Urgent & Not Important", Colors.blue),
              _buildQuadrant("Not Urgent & Not Important", Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuadrant(String title, Color color) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: tasksStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error fetching tasks"));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No tasks available"));
                  }

                  final tasks = snapshot.data!.docs.where((taskDoc) {
                    final task = taskDoc.data() as Map<String, dynamic>;
                    // Filter tasks based on the quadrant
                    switch (title) {
                      case "Urgent & Important":
                        return task['urgent'] == true &&
                            task['important'] == true;
                      case "Not Urgent & Important":
                        return task['urgent'] == false &&
                            task['important'] == true;
                      case "Urgent & Not Important":
                        return task['urgent'] == true &&
                            task['important'] == false;
                      case "Not Urgent & Not Important":
                        return task['urgent'] == false &&
                            task['important'] == false;
                      default:
                        return false;
                    }
                  }).toList();

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(task['taskName'] ?? 'Unnamed Task'),
                        subtitle: Text(
                          'Assigned to: ${task['assignedTo']?.join(", ") ?? "Unassigned"}\n'
                          'Date Created: ${(task['createdAt'] as Timestamp?)?.toDate().toString() ?? "Unknown"}',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: tasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error fetching tasks"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No tasks available"));
        }

        final tasks = snapshot.data!.docs.toList();

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index].data() as Map<String, dynamic>;
            return TaskCard(
              taskId: tasks[index].id,
              taskName: task['taskName'] ?? 'Unnamed Task',
              dueDate: (task['dueDate'] as Timestamp).toDate().toString(),
              startTime: (task['startTime'] as Timestamp).toDate().toString(),
              startDateTime: (task['startTime'] as Timestamp).toDate(),
              dueDateTime: (task['dueDate'] as Timestamp).toDate(),
              taskStatus: task['status'] ?? 'Pending',
            );
          },
        );
      },
    );
  }
}
