import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskListView extends StatefulWidget {
  final PageController pageController;
  final DateTime startOfWeek;
  final DateTime Function(int) getStartOfWeekFromIndex;
  final Widget Function() buildOverdueSection;
  final Widget Function(List<Map<String, dynamic>>) buildTaskSection;
  final Stream<QuerySnapshot> tasksStream;
  final String selectedFilter;

  const TaskListView({
    required this.pageController,
    required this.startOfWeek,
    required this.getStartOfWeekFromIndex,
    required this.buildOverdueSection,
    required this.buildTaskSection,
    required this.tasksStream,
    required this.selectedFilter,
    Key? key,
  }) : super(key: key);

  @override
  _TaskListViewState createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  List<Map<String, dynamic>> filteredTasks = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            widget.buildOverdueSection(),
            const SizedBox(height: 16),
            widget.buildTaskSection(filteredTasks),
          ],
        ),
      ),
    );
  }
}
