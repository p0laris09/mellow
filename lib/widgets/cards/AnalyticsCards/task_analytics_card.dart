import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mellow/screens/AnalyticsScreen/ViewAnalytics/view_analytics_screen.dart';

class TaskAnalyticsCard extends StatefulWidget {
  final int totalTasks; // Add totalTasks parameter

  const TaskAnalyticsCard({Key? key, required this.totalTasks})
      : super(key: key);

  @override
  _TaskAnalyticsCardState createState() => _TaskAnalyticsCardState();
}

class _TaskAnalyticsCardState extends State<TaskAnalyticsCard> {
  int _totalTasks = 0; // Store total tasks fetched from Firestore
  bool _isLoading = true; // Controls loading state

  @override
  void initState() {
    super.initState();
    // If totalTasks is 0 or invalid, fetch from Firestore
    if (widget.totalTasks == 0) {
      _fetchTotalTasks();
    } else {
      _totalTasks = widget.totalTasks; // Use passed totalTasks
      _isLoading = false; // Stop loading if totalTasks is passed
    }
  }

  /// Fetch total tasks from Firestore
  Future<void> _fetchTotalTasks() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("User not logged in");

      // Query Firestore to fetch all tasks for the user
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: uid)
          .get();

      // Update total tasks in the state
      setState(() {
        _totalTasks = querySnapshot.docs.length;
        _isLoading = false; // Stop loading
      });
    } catch (e) {
      // Handle errors gracefully
      setState(() {
        _totalTasks = 0;
        _isLoading = false;
      });

      // Optionally show a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tasks: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ViewAnalyticsScreen(),
          ),
        );
      },
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
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
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    '$_totalTasks', // Display fetched or passed totalTasks
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
