import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Overview Section
            _buildOverviewSection(),
            const SizedBox(height: 20),

            // 2. Task Metrics
            _buildTaskMetricsSection(),
            const SizedBox(height: 20),

            // 3. User Progress Insights
            _buildUserProgressSection(),
            const SizedBox(height: 20),

            // 4. Task Segmentation
            _buildTaskSegmentationSection(),
            const SizedBox(height: 20),

            // 5. Trends and Patterns
            _buildTrendsAndPatternsSection(),
            const SizedBox(height: 20),

            // 6. Goals and Benchmarks
            _buildGoalsAndBenchmarksSection(),
            const SizedBox(height: 20),

            // 7. Feedback Loop
            _buildFeedbackSection(),
          ],
        ),
      ),
    );
  }

  // Helper method to build the Overview section
  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Overview",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryCard("Total Tasks", "1,200", Colors.greenAccent),
            _buildSummaryCard("Completed", "800", Colors.blueAccent),
            _buildSummaryCard("Overdue", "150", Colors.redAccent),
          ],
        ),
      ],
    );
  }

  // Helper method to create a summary card
  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Helper method to build the Task Metrics section
  Widget _buildTaskMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Task Metrics",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricCard("Tasks Due Today", "30", Icons.today),
            _buildMetricCard("Pending", "400", Icons.hourglass_empty),
            _buildMetricCard("In Progress", "70", Icons.work_outline),
          ],
        ),
      ],
    );
  }

  // Helper method to create a metric card
  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: Colors.orangeAccent),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Helper method to build the User Progress section
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

  // Helper method to build the Task Segmentation section
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

  // Helper method to build the Trends and Patterns section
  Widget _buildTrendsAndPatternsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Trends and Patterns",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          height: 150,
          color: Colors.green.withOpacity(0.1),
          child: const Center(
            child: Text(
              "Trends Analysis Graphs Here",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build the Goals and Benchmarks section
  Widget _buildGoalsAndBenchmarksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Goals and Benchmarks",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          height: 100,
          color: Colors.teal.withOpacity(0.1),
          child: const Center(
            child: Text(
              "Goal Achievement Indicators Here",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build the Feedback section
  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Feedback",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          height: 100,
          color: Colors.red.withOpacity(0.1),
          child: const Center(
            child: Text(
              "Feedback Form / User Suggestions Here",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
