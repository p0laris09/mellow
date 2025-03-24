import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewTaskPreference extends StatelessWidget {
  const ViewTaskPreference({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _getTaskPreference() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('task_preference')
        .doc(userId)
        .get();

    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    } else {
      throw Exception('Task preference not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Light grey background
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
        elevation: 0,
        title: const Text(
          'Task Preferences',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getTaskPreference(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No task preferences found'));
          } else {
            Map<String, dynamic> taskPreference = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        _buildPreferenceCard('Biggest Distraction',
                            taskPreference['biggestDistraction']),
                        _buildPreferenceCard('Break Frequency',
                            taskPreference['breakFrequency']),
                        _buildPreferenceCard('Collaboration Preference',
                            taskPreference['collaborationPreference']),
                        _buildPreferenceCard('Deadline Preference',
                            taskPreference['deadlinePreference']),
                        _buildPreferenceCard('Long-Term Project Frequency',
                            taskPreference['longTermProjectFrequency']),
                        _buildPreferenceCard('Notification Check Frequency',
                            taskPreference['notificationCheckFrequency']),
                        _buildPreferenceCard('Productive Time',
                            taskPreference['productiveTime']),
                        _buildPreferenceCard('Task Completion Estimate',
                            taskPreference['taskCompletionEstimate']),
                        _buildPreferenceCard('Task Completion Style',
                            taskPreference['taskCompletionStyle']),
                        _buildPreferenceCard(
                            'Task Duration', taskPreference['taskDuration']),
                        _buildPreferenceCard('Task Prioritization',
                            taskPreference['taskPrioritization']),
                        _buildTaskTypes(taskPreference['taskTypes']),
                        _buildPreferenceCard(
                            'Tasks Per Hour', taskPreference['tasksPerHour']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildEditButton(context),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPreferenceCard(String title, dynamic value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value ?? 'N/A', style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildTaskTypes(dynamic taskTypes) {
    if (taskTypes == null || taskTypes is! List) {
      return _buildPreferenceCard('Task Types', 'N/A');
    }
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: const Text(
          'Task Types',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: taskTypes.map<Widget>((task) => Text('- $task')).toList(),
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Navigate to Edit Page (to be implemented)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditTaskPreference()),
          );
        },
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text(
          'Edit Preferences',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2275AA),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

// Placeholder for Edit Page
class EditTaskPreference extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Task Preferences")),
      body: const Center(child: Text("Edit Page Coming Soon...")),
    );
  }
}
