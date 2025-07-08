import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mellow/screens/ProfileScreen/AcceptDeclineFriendRequest/add_friend.dart';
import 'package:mellow/screens/ProfileScreen/ViewProfile/view_profile.dart';

class FriendRequest extends StatefulWidget {
  final String userId;

  const FriendRequest({Key? key, required this.userId}) : super(key: key);

  @override
  _FriendRequestState createState() => _FriendRequestState();
}

class _FriendRequestState extends State<FriendRequest> {
  String currentUserId = '';
  String userName = 'Loading...';
  String profileImageUrl = '';
  String userSection = 'Loading...';
  String college = 'Loading...';
  String program = 'Loading...';
  String year = 'Loading...';
  int taskCount = 0;
  int spaceCount = 0;
  int friendCount = 0;
  int overdueCount = 0;
  int pendingCount = 0;
  int ongoingCount = 0;
  int finishedCount = 0;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setCurrentUser();
    _loadUserProfile();
  }

  Future<void> _setCurrentUser() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      currentUserId = currentUser.uid;
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
        setState(() {
          userName = '${data['firstName']} ${data['lastName']}'.toUpperCase();
          userSection = data['section'] ?? 'N/A';
          college = data['college'] ?? 'N/A';
          program = data['program'] ?? 'N/A';
          year = data['year'] ?? 'N/A';
          profileImageUrl = data['profileImageUrl'] ?? '';
        });

        await _loadCounts();
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

  Future<void> _loadCounts() async {
    try {
      QuerySnapshot taskSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: widget.userId)
          .get();
      taskCount = taskSnapshot.docs.length;

      // Fetch the friend count from the friends_db collection
      QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
          .collection('friends_db')
          .doc(widget.userId)
          .collection('friends')
          .get();
      friendCount = friendsSnapshot.docs.length;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        spaceCount = data['spaces'] ?? 0;
      } else {
        taskCount = 0;
        friendCount = 0;
        spaceCount = 0;
      }

      await _loadTaskCounts();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data counts.';
        isLoading = false;
      });
    }
  }

  Future<void> _loadTaskCounts() async {
    try {
      QuerySnapshot tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: widget.userId)
          .get();

      int overdueTasks = 0;
      int pendingTasks = 0;
      int ongoingTasks = 0;
      int finishedTasks = 0;

      for (var doc in tasksSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
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
      });
    } catch (e) {
      print('Error loading task counts: $e');
      setState(() {
        overdueCount = 0;
        pendingCount = 0;
        ongoingCount = 0;
        finishedCount = 0;
      });
    }
  }

  Future<void> _acceptFriendRequest() async {
    try {
      // Check if the request document exists
      DocumentSnapshot requestDoc = await FirebaseFirestore.instance
          .collection('friends_db')
          .doc(widget.userId)
          .collection('requests')
          .doc(currentUserId)
          .get();

      if (requestDoc.exists) {
        // Delete the request document from the sender's requests subcollection
        await FirebaseFirestore.instance
            .collection('friends_db')
            .doc(widget.userId)
            .collection('requests')
            .doc(currentUserId)
            .delete();

        // Delete the request document from the receiver's requests subcollection
        await FirebaseFirestore.instance
            .collection('friends_db')
            .doc(currentUserId)
            .collection('requests')
            .doc(widget.userId)
            .delete();

        // Add the friend to the current user's friends collection
        await FirebaseFirestore.instance
            .collection('friends_db')
            .doc(currentUserId)
            .collection('friends')
            .doc(widget.userId)
            .set({'friendId': widget.userId});

        // Add the current user to the friend's friends collection
        await FirebaseFirestore.instance
            .collection('friends_db')
            .doc(widget.userId)
            .collection('friends')
            .doc(currentUserId)
            .set({'friendId': currentUserId});

        // Send a notification about the accepted friend request
        await _sendNotification(
            widget.userId, 'Friend Request Accepted', 'You are now friends.');

        // Navigate to the ViewProfile screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ViewProfile(userId: widget.userId),
          ),
        );
      } else {
        setState(() {
          errorMessage = 'Friend request not found.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error accepting friend request.';
      });
    }
  }

  Future<void> _declineFriendRequest() async {
    try {
      await FirebaseFirestore.instance
          .collection('friends_db')
          .doc(widget.userId)
          .collection('requests')
          .doc(currentUserId)
          .delete();

      await FirebaseFirestore.instance
          .collection('friends_db')
          .doc(currentUserId)
          .collection('requests')
          .doc(widget.userId)
          .delete();

      await _sendNotification(
          widget.userId, 'Friend Request Declined', 'Friend request declined.');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AddFriend(userId: widget.userId),
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Error declining friend request.';
      });
    }
  }

  Future<void> _sendNotification(
      String receiverId, String title, String message) async {
    try {
      // Fetch the current user's name
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      String senderName = 'Unknown User';
      if (currentUserDoc.exists) {
        final data = currentUserDoc.data() as Map<String, dynamic>;
        senderName = '${data['firstName']} ${data['lastName']}';
      }

      // Send the notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'friend_request',
        'senderId': currentUserId,
        'receiverId': receiverId,
        'title': title,
        'message': '$senderName $message', // Include the sender's name
        'timestamp': FieldValue.serverTimestamp(),
        'status': title == 'Friend Request Accepted'
            ? 'Now Friends'
            : 'Request Declined',
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
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
              : _buildFriendRequestContent(),
    );
  }

  Widget _buildFriendRequestContent() {
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _acceptFriendRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Accept',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _declineFriendRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Decline',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
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
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }
}
