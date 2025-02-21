import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = 'Loading...';
  String profileImageUrl = '';
  String userSection = 'Loading...';
  String college = 'Loading...';
  String program = 'Loading...';
  String year = 'Loading...';
  bool isLoading = true;
  int tasksCount = 0;
  int friendsCount = 0;
  int spaceCount = 0;

  // Task category counts
  int overdueCount = 0;
  int pendingCount = 0;
  int ongoingCount = 0;
  int finishedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _fetchAnalyticsData(); // Fetch overall analytics data
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = userDoc.data();

    if (data != null) {
      String imageUrl = data['profileImageUrl'] ?? '';
      if (imageUrl.isEmpty) {
        // Fetch default profile image from Firebase Storage
        final defaultImageRef = FirebaseStorage.instance
            .ref()
            .child('default_images/default_profile.png');
        imageUrl = await defaultImageRef.getDownloadURL();
      }

      setState(() {
        userName = data['firstName'] ?? 'Loading...';
        profileImageUrl = imageUrl;
        userSection = data['section'] ?? 'Loading...';
        college = data['college'] ?? 'Loading...';
        program = data['program'] ?? 'Loading...';
        year = data['year'] ?? 'Loading...';
        tasksCount = data['tasksCount'] ?? 0;
        friendsCount = data['friendsCount'] ?? 0;
        spaceCount = data['spaceCount'] ?? 0;
        isLoading = false;
      });
    }
  }

  Future<void> _fetchAnalyticsData() async {
    final firestore = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    int overdueTasks = 0;
    int pendingTasks = 0;
    int ongoingTasks = 0;
    int finishedTasks = 0;

    final tasksQuery = await firestore
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .get();

    for (var doc in tasksQuery.docs) {
      final data = doc.data();
      final status = data['status'] ?? '';
      final dueDate =
          (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now();

      if (dueDate.isBefore(DateTime.now()) && status != 'Finished') {
        overdueTasks++;
      } else if (status == 'pending') {
        pendingTasks++;
      } else if (status == 'ongoing') {
        ongoingTasks++;
      } else if (status == 'Finished') {
        finishedTasks++;
      }
    }

    setState(() {
      overdueCount = overdueTasks;
      pendingCount = pendingTasks;
      ongoingCount = ongoingTasks;
      finishedCount = finishedTasks;

      // Update total task count
      tasksCount = tasksQuery.docs.length;
    });

    // Fetch spaces the user is in
    final spacesQuery = await firestore
        .collection('spaces')
        .where('members', arrayContains: uid)
        .get();

    setState(() {
      spaceCount = spacesQuery.docs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child: profileImageUrl.isEmpty
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(tasksCount.toString(), 'Tasks'),
                              _buildStatItem(spaceCount.toString(), 'Space'),
                              _buildStatItem(
                                  friendsCount.toString(), 'Friends'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('College: $college',
                              style: const TextStyle(color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text('Program: $program',
                              style: const TextStyle(color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text('Year: $year',
                              style: const TextStyle(color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text('Section: $userSection',
                              style: const TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getTaskCategoryLabel(index),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getTaskCategoryCount(index).toString(),
                                  style: const TextStyle(fontSize: 36),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/search_friends');
        },
        label: const Text(
          'Add Friends',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        icon: const Icon(
          Icons.person_add,
          color: Colors.white,
        ),
        backgroundColor: const Color(0xFF2275AA),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.black87),
        ),
      ],
    );
  }

  String _getTaskCategoryLabel(int index) {
    switch (index) {
      case 0:
        return 'Overdue Tasks';
      case 1:
        return 'Ongoing Tasks';
      case 2:
        return 'Pending Tasks';
      case 3:
        return 'Finished Tasks';
      default:
        return '';
    }
  }

  int _getTaskCategoryCount(int index) {
    switch (index) {
      case 0:
        return overdueCount;
      case 1:
        return ongoingCount;
      case 2:
        return pendingCount;
      case 3:
        return finishedCount;
      default:
        return 0;
    }
  }
}
