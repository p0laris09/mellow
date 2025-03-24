import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewProfile extends StatefulWidget {
  final String userId;

  const ViewProfile({Key? key, required this.userId}) : super(key: key);

  @override
  _ViewProfileState createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile> {
  String userName = 'Loading...';
  String profileImageUrl = '';
  String userSection = 'Loading...';
  String college = 'Loading...';
  String program = 'Loading...';
  String year = 'Loading...';
  bool isLoading = true;
  String errorMessage = '';
  String currentUserId = '';
  bool isFriend = false;

  int taskCount = 0;
  int spaceCount = 0;
  int friendCount = 0;
  int overdueCount = 0;
  int pendingCount = 0;
  int ongoingCount = 0;
  int finishedCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeProfileAndFriendStatus();
  }

  Future<void> _initializeProfileAndFriendStatus() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          errorMessage = 'User not authenticated';
          isLoading = false;
        });
        return;
      }
      currentUserId = currentUser.uid;

      // Check if the current user is friends with the profile user
      await _checkFriendshipStatus();

      if (isFriend) {
        // Load user profile if friends
        await _loadUserProfile();
      } else {
        setState(() {
          errorMessage = 'You are not friends with this user.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _checkFriendshipStatus() async {
    try {
      DocumentSnapshot friendDoc = await FirebaseFirestore.instance
          .collection('friends_db')
          .doc(currentUserId)
          .collection('friends')
          .doc(widget.userId)
          .get();

      if (friendDoc.exists) {
        setState(() {
          isFriend = true;
        });
      } else {
        setState(() {
          isFriend = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to check friendship status.';
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        // Fetch the friend count from the friends_db collection
        QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
            .collection('friends_db')
            .doc(widget.userId)
            .collection('friends')
            .get();

        setState(() {
          userName = '${data['firstName']} ${data['lastName']}'.toUpperCase();
          userSection = data['section'] ?? 'N/A';
          college = data['college'] ?? 'N/A';
          program = data['program'] ?? 'N/A';
          year = data['year'] ?? 'N/A';
          profileImageUrl = data['profileImageUrl'] ?? '';

          // Set counts to zero if the data is not present or empty
          taskCount = (data['tasks'] as List<dynamic>?)?.length ??
              0; // Assume tasks is a list
          friendCount =
              friendsSnapshot.docs.length; // Count the number of friends
          spaceCount = data['spaces'] ?? 0; // Assume spaces is a numeric value

          // Additional counts for task categories
          overdueCount = data['overdueCount'] ?? 0;
          pendingCount = data['pendingCount'] ?? 0;
          ongoingCount = data['ongoingCount'] ?? 0;
          finishedCount = data['finishedCount'] ?? 0;

          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'User not found.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load profile.';
        isLoading = false;
      });
    }
  }

  Future<void> _unfriendUser() async {
    try {
      await FirebaseFirestore.instance
          .collection('friends_db')
          .doc(currentUserId)
          .collection('friends')
          .doc(widget.userId)
          .delete();

      await FirebaseFirestore.instance
          .collection('friends_db')
          .doc(widget.userId)
          .collection('friends')
          .doc(currentUserId)
          .delete();

      setState(() {
        isFriend = false;
        friendCount--; // Decrease friend count
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to unfriend user: $e';
      });
    }
  }

  void _showUnfriendConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2275AA),
          title: const Text('Unfriend', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to unfriend $userName?',
              style: const TextStyle(color: Colors.white)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _unfriendUser();
              },
              child:
                  const Text('Unfriend', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
        title: Text(userName, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(errorMessage,
                      style: const TextStyle(color: Colors.red)),
                )
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
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
                      : const AssetImage('assets/img/default_profile.png')
                          as ImageProvider,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(taskCount.toString(), 'Tasks'),
                      _buildStatItem(spaceCount.toString(), 'Space'),
                      _buildStatItem(friendCount.toString(), 'Friends'),
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
                  Text(userName,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  const SizedBox(height: 8),
                  Text('Section: $userSection',
                      style: const TextStyle(color: Colors.black)),
                  const SizedBox(height: 4),
                  Text('College: $college',
                      style: const TextStyle(color: Colors.black)),
                  const SizedBox(height: 4),
                  Text('Program: $program',
                      style: const TextStyle(color: Colors.black)),
                  const SizedBox(height: 4),
                  Text('Year: $year',
                      style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2275AA),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Friends',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2275AA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.more_vert),
                    color: Colors.white,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return ListView(
                            shrinkWrap: true,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.person_remove),
                                title: const Text('Unfriend'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _showUnfriendConfirmationDialog();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTaskCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCards() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                Icon(
                  _getTaskCategoryIcon(index),
                  size: 40,
                  color: _getTaskCategoryColor(index),
                ),
                const SizedBox(height: 8),
                Text(
                  _getTaskCategoryLabel(index),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getTaskCategoryColor(index),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getTaskCategoryCount(index).toString(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTaskCategoryLabel(int index) {
    switch (index) {
      case 0:
        return 'Overdue';
      case 1:
        return 'Ongoing';
      case 2:
        return 'Pending';
      case 3:
        return 'Finished';
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

  IconData _getTaskCategoryIcon(int index) {
    switch (index) {
      case 0:
        return Icons.error_outline;
      case 1:
        return Icons.play_circle_outline;
      case 2:
        return Icons.pending_actions;
      case 3:
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  Color _getTaskCategoryColor(int index) {
    switch (index) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(count,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black)),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class ChatScreen extends StatelessWidget {
  final String userId;

  const ChatScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: const Color(0xFF2275AA),
      ),
      body: Center(
        child: Text('Chat with $userId'),
      ),
    );
  }
}
