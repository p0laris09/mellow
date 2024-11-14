import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  Future<Map<String, List<FlSpot>>> _fetchDailyTaskData() async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();

    // Define task statuses
    final statuses = ["pending", "overdue", "finished", "ongoing"];
    final taskData = {
      "pending": <FlSpot>[],
      "overdue": <FlSpot>[],
      "finished": <FlSpot>[],
      "ongoing": <FlSpot>[],
    };

    // Fetch task data for the last 5 days
    for (int i = 0; i < 5; i++) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);

      for (String status in statuses) {
        final query = await firestore
            .collection('tasks')
            .where('status', isEqualTo: status)
            .where('createdAt', isGreaterThanOrEqualTo: dayStart)
            .where('createdAt', isLessThan: dayStart.add(Duration(days: 1)))
            .get();

        // Add the task count to the appropriate list for the line chart
        taskData[status]
            ?.add(FlSpot(4 - i.toDouble(), query.docs.length.toDouble()));
      }
    }

    return taskData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(),
            const SizedBox(height: 20),
            _buildTaskMetricsSection(),
            const SizedBox(height: 20),
            _buildUserProgressSection(),
            const SizedBox(height: 20),
            _buildTaskSegmentationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return FutureBuilder<Map<String, List<FlSpot>>>(
      future: _fetchDailyTaskData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          final taskData = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Overview",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: taskData['pending'] ?? [],
                        isCurved: true,
                        barWidth: 2,
                        color: Colors.blueAccent,
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blueAccent.withOpacity(0.2),
                        ),
                      ),
                      LineChartBarData(
                        spots: taskData['overdue'] ?? [],
                        isCurved: true,
                        barWidth: 2,
                        color: Colors.redAccent,
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.redAccent.withOpacity(0.2),
                        ),
                      ),
                      LineChartBarData(
                        spots: taskData['finished'] ?? [],
                        isCurved: true,
                        barWidth: 2,
                        color: Colors.greenAccent,
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.greenAccent.withOpacity(0.2),
                        ),
                      ),
                      LineChartBarData(
                        spots: taskData['ongoing'] ?? [],
                        isCurved: true,
                        barWidth: 2,
                        color: Colors.orangeAccent,
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.orangeAccent.withOpacity(0.2),
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const titles = ["Mon", "Tue", "Wed", "Thu", "Fri"];
                            return Text(
                              titles[value.toInt()],
                              style: const TextStyle(color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: const TextStyle(color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          return const Text("Error loading data");
        }
      },
    );
  }

  Widget _buildTaskMetricsSection() {
    return const Text("Placeholder for Task Metrics");
  }

  Widget _buildUserProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "User Progress Insights",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          height: 150,
          color: Colors.blueGrey.withOpacity(0.1),
          child: const Center(
            child: Text(
              "Progress Over Time Visualization Here",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskSegmentationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Task Segmentation",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          height: 150,
          color: Colors.deepPurple.withOpacity(0.1),
          child: const Center(
            child: Text(
              "Task Categorization Visualization Here",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
