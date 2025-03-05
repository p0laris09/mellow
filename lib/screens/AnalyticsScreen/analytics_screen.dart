import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int selectedPeriod = 7; // Default to 7 days

  Future<Map<String, dynamic>> _fetchAnalyticsData() async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final daysWithMostTasks =
        <Map<String, dynamic>>[]; // Tracks the number of tasks per day

    int overdueTasks = 0;
    int pendingTasks = 0;
    int ongoingTasks = 0;
    int finishedTasks = 0;

    // Fetch all tasks for the user to get the overall task count
    final userTasksQuery = await firestore
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .get();

    // Fetch all tasks assigned to the user
    final assignedTasksQuery = await firestore
        .collection('tasks')
        .where('assignedTo', arrayContains: uid)
        .get();

    // Combine the results
    final allTasks = userTasksQuery.docs + assignedTasksQuery.docs;

    // Remove duplicates by taskId (if any)
    Set<String> taskIds = Set();
    List<QueryDocumentSnapshot> uniqueTasks = [];
    for (var doc in allTasks) {
      String taskId = doc.id;
      if (!taskIds.contains(taskId)) {
        taskIds.add(taskId);
        uniqueTasks.add(doc);
      }
    }

    final overallTaskCount = uniqueTasks.length; // Total tasks

    // Filter tasks based on the selected period
    final startDate = now.subtract(Duration(days: selectedPeriod));

    for (int i = 0; i < selectedPeriod; i++) {
      final day = startDate.add(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final label = DateFormat('MMM dd').format(day);

      final query = uniqueTasks.where((doc) {
        final startTime =
            (doc.data() as Map<String, dynamic>)['startTime'] as Timestamp?;
        return startTime != null &&
            startTime.toDate().isAfter(dayStart) &&
            startTime.toDate().isBefore(dayEnd);
      }).toList();

      final totalTasks = query.length;

      if (totalTasks > 0) {
        daysWithMostTasks.add({'date': label, 'tasks': totalTasks});
      }

      for (var doc in query) {
        final data = doc.data() as Map<String, dynamic>;

        // Determine task status and color
        String status = data['status'] ?? 'pending';

        // Get the start and due date of the task
        final startTime = (data['startTime'] as Timestamp?)?.toDate() ?? now;
        final dueDate = (data['dueDate'] as Timestamp?)?.toDate() ?? now;

        // Check if the due date has passed and the task isn't finished
        if (status == 'Finished') {
          // Finished -> Green
          finishedTasks++;
        } else if (status == 'pending' && dueDate.isBefore(now)) {
          status = 'overdue'; // Dynamically set status to overdue
          // Overdue -> Red
          overdueTasks++;
        } else if (status == 'pending' &&
            now.isAfter(startTime) &&
            now.isBefore(dueDate)) {
          status = 'ongoing'; // Dynamically set status to ongoing
          // Ongoing -> Blue
          ongoingTasks++;
        } else if (status == 'pending') {
          // Pending -> Grey
          pendingTasks++;
        }
      }
    }

    // Sort days by most tasks and limit to top 5
    daysWithMostTasks.sort((a, b) => b['tasks'].compareTo(a['tasks']));

    return {
      "overallTaskCount":
          overallTaskCount, // Ensure this reflects total task count
      "daysWithMostTasks": daysWithMostTasks.take(5).toList(),
      "overdueTasks": overdueTasks,
      "pendingTasks": pendingTasks,
      "ongoingTasks": ongoingTasks,
      "finishedTasks": finishedTasks,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          'Task Analytics Page',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchAnalyticsData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              final data = snapshot.data!;
              final daysWithMostTasks = data['daysWithMostTasks'];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTaskCardSection(card: data),
                  const SizedBox(height: 15),
                  _buildCardSection(
                    cards: [
                      {
                        'title': 'Overdue Tasks',
                        'color': Colors.red,
                        'value': data['overdueTasks']
                      },
                      {
                        'title': 'Pending Tasks',
                        'color': Colors.grey,
                        'value': data['pendingTasks']
                      },
                      {
                        'title': 'Ongoing Tasks',
                        'color': Colors.blue,
                        'value': data['ongoingTasks']
                      },
                      {
                        'title': 'Finished Tasks',
                        'color': Colors.green,
                        'value': data['finishedTasks']
                      },
                    ],
                  ),
                  if (daysWithMostTasks.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildListSection(
                      title: 'Days with Most Tasks',
                      items: daysWithMostTasks,
                      keyField: 'date',
                      valueField: 'tasks',
                    ),
                  ],
                ],
              );
            }
            return const Text('Error loading data.');
          },
        ),
      ),
    );
  }

  Widget _buildTaskCardSection({required Map<String, dynamic> card}) {
    return Container(
      width: double.infinity, // Make the container fill the entire width
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2275AA),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Tasks',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            card['overallTaskCount'].toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({required List<Map<String, dynamic>> cards}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card['color'] as Color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: (card['color'] as Color).withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                card['title'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                card['value'].toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListSection({
    required String title,
    required List<Map<String, dynamic>> items,
    required String keyField,
    required String valueField,
    bool showStatusColor = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Set title text color to black
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) {
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(
                item[keyField].toString(),
                style: const TextStyle(
                    color: Colors.black), // Set item text color to black
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item[valueField].toString(),
                    style: const TextStyle(
                        color:
                            Colors.black), // Set item value text color to black
                  ),
                  if (showStatusColor)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: item['statusColor'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
