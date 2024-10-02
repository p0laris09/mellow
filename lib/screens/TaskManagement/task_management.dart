import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _updateStartOfWeek(_selectedDay);
    _currentYear = _selectedDay.year;
    _currentMonthIndex = _selectedDay.month - 1; // Month index (0-11)
    _pageController = PageController(
      initialPage: 5000, // Arbitrary large number for infinite week navigation
      viewportFraction: 1.0, // Full width for each week
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Set start of the week to the selected date's week
  void _updateStartOfWeek(DateTime selectedDate) {
    _startOfWeek =
        selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
  }

  // Navigate to the week that corresponds to the page index
  DateTime _getStartOfWeekFromIndex(int index) {
    return _startOfWeek.add(Duration(days: (index - 5000) * 7));
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDay = day;
    });
  }

  // Show the year and month picker
  void _showYearMonthPicker(BuildContext context) {
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
                              initialItem: _currentMonthIndex),
                          itemExtent: 32.0,
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              _currentMonthIndex = index;
                              _selectedDay =
                                  DateTime(_currentYear, index + 1, 1);
                            });
                          },
                          children: List<Widget>.generate(12, (int index) {
                            return Center(
                                child: Text(DateFormat('MMMM')
                                    .format(DateTime(0, index + 1))));
                          }),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                              initialItem: _currentYear - 2000),
                          itemExtent: 32.0,
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              _currentYear = 2000 + index;
                              _selectedDay = DateTime(
                                  _currentYear, _currentMonthIndex + 1, 1);
                            });
                          },
                          children: List<Widget>.generate(102, (int index) {
                            return Center(
                                child: Text((2000 + index).toString()));
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close picker
                    _updateStartOfWeek(
                        _selectedDay); // Update week to first week of the selected month
                    _pageController.jumpToPage(5000); // Jump to the new week
                    setState(() {});
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
    List<Widget> dayWidgets = [];
    List<String> weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    for (int i = 0; i < 7; i++) {
      DateTime day = startOfWeek.add(Duration(days: i));
      bool isSelected = day.day == _selectedDay.day &&
          day.month == _selectedDay.month &&
          day.year == _selectedDay.year;

      dayWidgets.add(
        GestureDetector(
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
        ),
      );
    }
    return dayWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showYearMonthPicker(context),
          child: Text(
            DateFormat('MMMM yyyy').format(_selectedDay),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF2C3C3C),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
              onPressed: () {}, // Functionality to add task
              child: const Text(
                "Add Task",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              physics: ClampingScrollPhysics(), // Prevents excessive scrolling
              onPageChanged: (index) {
                // Update the start of the week based on the page index
                setState(() {
                  _startOfWeek = _getStartOfWeekFromIndex(index);
                });
              },
              itemBuilder: (context, index) {
                DateTime weekStart = _getStartOfWeekFromIndex(index);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _buildDayPicker(weekStart),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
