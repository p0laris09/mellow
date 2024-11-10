import 'package:flutter/material.dart';

class ViewSpace extends StatefulWidget {
  final String spaceId;
  final String spaceName;
  final String description;
  final String date;

  const ViewSpace({
    super.key,
    required this.spaceId,
    required this.spaceName,
    required this.description,
    required this.date,
  });

  @override
  State<ViewSpace> createState() => _ViewSpaceState();
}

class _ViewSpaceState extends State<ViewSpace> {
  late Future<List<Task>> tasksFuture;
  late Future<List<Activity>> recentActivitiesFuture;

  @override
  void initState() {
    super.initState();
    // Assuming these functions fetch data from a database using spaceId
    tasksFuture = fetchTasks(widget.spaceId);
    recentActivitiesFuture = fetchRecentActivities(widget.spaceId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3C3C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search, color: Colors.white70),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Search for task, files, etc...",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.account_circle, color: Colors.white, size: 30),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.spaceName, // Display the passed space name
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3C3C),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.description, // Display the passed description
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              'Created on: ${widget.date}', // Display the passed date
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Timeline Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilterButton(label: 'All'),
                FilterButton(label: 'Sort by date'),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Timeline FutureBuilder
            FutureBuilder<List<Task>>(
              future: tasksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("No tasks available.");
                } else {
                  final tasks = snapshot.data!;
                  return Column(
                    children:
                        tasks.map((task) => TimelineItem(task: task)).toList(),
                  );
                }
              },
            ),

            const SizedBox(height: 24),

            // Recent Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3C3C),
                  ),
                ),
                Text(
                  'See all',
                  style: TextStyle(color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recent Activity FutureBuilder
            FutureBuilder<List<Activity>>(
              future: recentActivitiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("No recent activity.");
                } else {
                  final activities = snapshot.data!;
                  return Column(
                    children: activities
                        .map((activity) =>
                            RecentActivityItem(activity: activity))
                        .toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Task model to hold task data
class Task {
  final String date;
  final String time;
  final String title;
  final String assignedTo;

  Task(this.date, this.time, this.title, this.assignedTo);
}

// Activity model to hold recent activity data
class Activity {
  final String timeAgo;
  final String user;
  final String activity;
  final String fileName;
  final String fileDate;
  final String fileSize;

  Activity(this.timeAgo, this.user, this.activity, this.fileName, this.fileDate,
      this.fileSize);
}

// Placeholder for database fetch functions
Future<List<Task>> fetchTasks(String spaceId) async {
  // Replace with actual database query
  return [
    Task("Monday, 23 September 2024", "12:00 am",
        "Revised Version of Chapter 1", "Jocelyn Dayrit"),
    Task("Tuesday, 24 September 2024", "12:00 am",
        "Mellow User Interface Design", "Ezra Montealegre"),
    Task("Wednesday, 25 September 2024", "10:30 am", "Google Meet Meeting",
        "Everyone"),
  ];
}

Future<List<Activity>> fetchRecentActivities(String spaceId) async {
  // Replace with actual database query
  return [
    Activity("1h ago", "Anne Lorraine Ramos", "shared a file",
        "Chapter 1-5 Template", "19 September, 2024", "12 MB"),
    Activity("2h ago", "Ezra David Montealegre", "completed a task",
        "Chapter 2 Draft", "18 September, 2024", "10 MB"),
  ];
}

class FilterButton extends StatelessWidget {
  final String label;

  const FilterButton({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, color: Colors.black54),
      ),
    );
  }
}

class TimelineItem extends StatelessWidget {
  final Task task;

  const TimelineItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(task.date, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(task.time, style: const TextStyle(color: Colors.black54)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  Text("Assigned to: ${task.assignedTo}",
                      style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.more_vert, color: Colors.black54),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class RecentActivityItem extends StatelessWidget {
  final Activity activity;

  const RecentActivityItem({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey[300],
          radius: 20,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${activity.user} ",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    TextSpan(
                      text: activity.activity,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.fileName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Text("${activity.fileDate} • ${activity.fileSize}",
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Text(activity.timeAgo, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
