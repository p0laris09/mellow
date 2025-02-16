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
    final tasksWithMostWeight =
        <Map<String, dynamic>>[]; // Tracks tasks with the most weight

    double totalWeightSum = 0.0; // Ensure total weight sum starts at 0
    double totalTasksSum =
        0.0; // Not used directly in the code, but initialized

    int overdueTasks = 0;
    int pendingTasks = 0;
    int ongoingTasks = 0;
    int finishedTasks = 0;

    // Fetch all tasks for the user to get the overall task count
    final allTasksQuery = await firestore
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .get();

    final overallTaskCount = allTasksQuery.docs.length; // Total tasks

    // Filter tasks based on the selected period
    final startDate = now.subtract(Duration(days: selectedPeriod));

    for (int i = 0; i < selectedPeriod; i++) {
      final day = startDate.add(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final label = DateFormat('MMM dd').format(day);

      final query = await firestore
          .collection('tasks')
          .where('userId', isEqualTo: uid)
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('startTime', isLessThan: Timestamp.fromDate(dayEnd))
          .get();

      final totalTasks = query.docs.length;

      if (totalTasks > 0) {
        daysWithMostTasks.add({'date': label, 'tasks': totalTasks});
      }

      for (var doc in query.docs) {
        final data = doc.data();
        final priority = data['priority'] ?? 0;
        final urgency = data['urgency'] ?? 0;
        final importance = data['importance'] ?? 0;
        final complexity = data['complexity'] ?? 0;

        final weight = priority + urgency + importance + complexity;

        totalWeightSum += weight; // Add valid weight to the total sum

        // Determine task status and color
        String status = data['status'] ?? 'pending';
        Color statusColor;

        // Get the due date of the task
        final dueDate = (data['dueDate'] as Timestamp?)?.toDate() ?? now;

        // Check if the due date has passed and the task isn't finished
        if (dueDate.isBefore(now) && status != 'Finished') {
          status = 'overdue'; // Dynamically set status to overdue
        }

        // Update task count based on status
        if (status == 'Finished') {
          statusColor = Colors.green; // Finished -> Green
          finishedTasks++;
        } else if (status == 'ongoing') {
          statusColor =
              const Color.fromARGB(255, 33, 150, 243); // Ongoing -> Blue
          ongoingTasks++;
        } else if (status == 'overdue') {
          statusColor = Colors.red; // Overdue -> Red
          overdueTasks++;
        } else {
          statusColor = Colors.grey; // Pending -> Grey
          pendingTasks++;
        }

        final taskName = data['taskName'] ?? 'Unnamed Task';

        tasksWithMostWeight.add({
          'name': taskName,
          'weight': weight,
          'statusColor': statusColor,
          'status': status,
        });
      }
    }

    // Sort days and tasks by most tasks/weight and limit to top 5
    daysWithMostTasks.sort((a, b) => b['tasks'].compareTo(a['tasks']));
    tasksWithMostWeight.sort((a, b) => b['weight'].compareTo(a['weight']));

    return {
      "overallTaskCount":
          overallTaskCount, // Ensure this reflects total task count
      "daysWithMostTasks": daysWithMostTasks.take(5).toList(),
      "tasksWithMostWeight": tasksWithMostWeight.take(5).toList(),
      "overdueTasks": overdueTasks,
      "pendingTasks": pendingTasks,
      "ongoingTasks": ongoingTasks,
      "finishedTasks": finishedTasks,
      "totalWeight": totalWeightSum, // Add total weight here
    };
  }

  void _onCardTap(String cardType) {
    // Handle card tap actions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$cardType card tapped!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              final tasksWithMostWeight = data['tasksWithMostWeight'];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardSection(
                    cards: [
                      {
                        'title': 'Total Tasks',
                        'color': Colors.purple,
                        'value': data['overallTaskCount']
                      },
                      {
                        'title': 'Total Weight',
                        'color': Colors.orange,
                        'value': data['totalWeight'].toStringAsFixed(2)
                      },
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
                  if (tasksWithMostWeight.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildListSection(
                      title: 'Tasks with Most Weight',
                      items: tasksWithMostWeight,
                      keyField: 'name',
                      valueField: 'weight',
                      showStatusColor: true,
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
        return GestureDetector(
          onTap: () => _onCardTap(card['title']),
          child: Container(
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
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) {
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(item[keyField].toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item[valueField].toString()),
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
        }).toList(),
      ],
    );
  }
}
