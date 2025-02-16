import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TaskListView extends StatefulWidget {
  final PageController pageController;
  final DateTime startOfWeek;
  final DateTime Function(int) getStartOfWeekFromIndex;
  final Widget Function() buildOverdueSection;
  final Widget Function() buildTaskSection;
  final List<Widget> Function(DateTime) buildDayPicker;

  const TaskListView({
    required this.pageController,
    required this.startOfWeek,
    required this.getStartOfWeekFromIndex,
    required this.buildOverdueSection,
    required this.buildTaskSection,
    required this.buildDayPicker,
    Key? key,
  }) : super(key: key);

  @override
  _TaskListViewState createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  late DateTime _currentStartOfWeek;
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _currentStartOfWeek = widget.startOfWeek;
  }

  void _filterTasks() {
    // Implement your task filtering logic here based on the selectedFilter
    // For example, you can filter tasks from a list of tasks based on the selected filter
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: PageView.builder(
                controller: widget.pageController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStartOfWeek = widget.getStartOfWeekFromIndex(index);
                  });
                },
                itemBuilder: (context, index) {
                  DateTime weekStart = widget.getStartOfWeekFromIndex(index);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: widget.buildDayPicker(weekStart),
                  );
                },
              ),
            ),
            const SizedBox(height: 2),
            SingleChildScrollView(
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
            ),
            const SizedBox(height: 16),
            widget.buildOverdueSection(),
            const SizedBox(height: 16),
            widget.buildTaskSection(),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String label) {
    return TextButton(
      onPressed: () {
        setState(() {
          selectedFilter = label;
          _filterTasks();
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
}
