import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewAnalyticsScreen extends StatefulWidget {
  const ViewAnalyticsScreen({super.key});

  @override
  _ViewAnalyticsScreenState createState() => _ViewAnalyticsScreenState();
}

class _ViewAnalyticsScreenState extends State<ViewAnalyticsScreen> {
  int selectedPeriod = 7; // Default to 7 days

  // Fetch the user's first task date
  Future<DateTime> _fetchUserFirstTaskDate(String uid) async {
    final firestore = FirebaseFirestore.instance;

    final query = await firestore
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .orderBy('startTime')
        .limit(1) // Only need the first task
        .get();

    if (query.docs.isNotEmpty) {
      final firstTask = query.docs.first.data();
      return (firstTask['startTime'] as Timestamp).toDate();
    } else {
      throw Exception('No tasks found for user.');
    }
  }

  // Fetch the task data for the default period (7 days)
  Future<Map<String, dynamic>> _fetchTaskData() async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Fetch user's first task date
    final firstTaskDate = await _fetchUserFirstTaskDate(uid);

    // Ensure that we start from the first task date, not before
    final startDate =
        now.subtract(Duration(days: selectedPeriod)).isBefore(firstTaskDate)
            ? firstTaskDate
            : now.subtract(Duration(days: selectedPeriod));

    final taskCounts = <FlSpot>[];
    final weights = <FlSpot>[];
    final labels = <String>[];

    double totalTasksSum = 0.0;
    double totalWeightSum = 0.0;

    for (int i = 0; i < selectedPeriod; i++) {
      final day = startDate.add(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final label = DateFormat('MMM dd').format(day);

      // Query Firestore using startTime
      final query = await firestore
          .collection('tasks')
          .where('userId', isEqualTo: uid)
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('startTime', isLessThan: Timestamp.fromDate(dayEnd))
          .get();

      // Total Tasks
      final totalTasks = query.docs.length.toDouble();
      taskCounts.add(FlSpot(i.toDouble(), totalTasks));
      totalTasksSum += totalTasks;

      // Total Weight
      double totalWeight = 0.0;
      for (var doc in query.docs) {
        final data = doc.data();
        totalWeight += (data['priority'] ?? 0) +
            (data['urgency'] ?? 0) +
            (data['importance'] ?? 0) +
            (data['complexity'] ?? 0);
      }
      weights.add(FlSpot(i.toDouble(), totalWeight));
      totalWeightSum += totalWeight;

      labels.add(label);
    }

    return {
      "taskCounts": taskCounts,
      "weights": weights,
      "labels": labels,
      "totalTasks": totalTasksSum,
      "totalWeight": totalWeightSum,
    };
  }

  // UI build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          'Analytics Page',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _fetchTaskData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasData) {
                  final data = snapshot.data!;
                  final totalTasks = data['totalTasks'];
                  final totalWeight = data['totalWeight'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChartSection(
                        "Task Metrics",
                        data['taskCounts'],
                        data['labels'],
                        Colors.blueAccent,
                      ),
                      Text(
                        "You have created a total of ${totalTasks.toInt()} tasks since you created your account!",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildChartSection(
                        "Task Weights",
                        data['weights'],
                        data['labels'],
                        Colors.purpleAccent,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "You've accumulated a total ${totalWeight.toInt()} of weight with all your tasks.",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Text("Error loading data");
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Builds the chart section
  Widget _buildChartSection(
      String title, List<FlSpot> spots, List<String> labels, Color lineColor) {
    final maxY = spots.isNotEmpty
        ? spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b)
        : 0.0;

    // Ensure the horizontal interval is never zero
    final horizontalInterval = maxY > 0 ? maxY / 4 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: horizontalInterval, // Safe interval
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: horizontalInterval, // Safe interval
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      return (index >= 0 && index < labels.length)
                          ? Text(labels[index],
                              style: const TextStyle(fontSize: 10))
                          : const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 2,
                  color: lineColor,
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final date = labels[spot.x.toInt()];
                      return LineTooltipItem(
                        '$date: ${spot.y.toInt()}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
