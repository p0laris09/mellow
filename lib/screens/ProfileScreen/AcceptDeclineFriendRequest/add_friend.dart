import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddFriend extends StatefulWidget {
  final String userId;

  const AddFriend({Key? key, required this.userId}) : super(key: key);

  @override
  _AddFriendState createState() => _AddFriendState();
}

class _AddFriendState extends State<AddFriend> {
  String requestStatus = 'none';
  String currentUserId = '';
  String userName = 'Loading...';
  String profileImageUrl = '';
  String userSection = 'Loading...';
  String college = 'Loading...';
  String program = 'Loading...';
  String year = 'Loading...';
  int overdueCount = 0;
  int pendingCount = 0;
  int ongoingCount = 0;
  int finishedCount = 0;
  bool isLoading = true;
  String errorMessage = '';
  String tasksCount = '0';
  String spaceCount = '0';
  String friendsCount = '0';

  @override
  void initState() {
    super.initState();
    _initializeProfileAndFriendStatus();
  }

  Future<void> _initializeProfileAndFriendStatus() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      currentUserId = currentUser.uid;
      await _loadUserProfile();
      await _checkFriendRequestStatus();
      await _loadTaskCounts();
      await _loadFriendsCount();
    }
  }

  Future<void> _loadUserProfile() async {
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
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = 'User not found.';
        isLoading = false;
      });
    }
  }

  Future<void> _checkFriendRequestStatus() async {
    // Check if there is an existing friend request
    DocumentSnapshot requestDoc = await FirebaseFirestore.instance
        .collection('friends_db')
        .doc(currentUserId)
        .collection('requests')
        .doc(widget.userId)
        .get();

    if (requestDoc.exists) {
      setState(() {
        requestStatus = requestDoc['status'] ?? 'none';
      });
    } else {
      // If no friend request, check if they are already friends
      DocumentSnapshot friendDoc = await FirebaseFirestore.instance
          .collection('friends_db')
          .doc(currentUserId)
          .collection('friends')
          .doc(widget.userId)
          .get();

      if (friendDoc.exists) {
        setState(() {
          requestStatus = 'friends';
        });
      } else {
        // If no friend or request document, set status as 'none'
        setState(() {
          requestStatus = 'none';
        });
      }
    }
  }

  Future<void> _loadTaskCounts() async {
    try {
      // Load task counts
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
        tasksCount = tasksSnapshot.docs.length.toString();
      });
    } catch (e) {
      print('Error loading task counts: $e');
      setState(() {
        overdueCount = 0;
        pendingCount = 0;
        ongoingCount = 0;
        finishedCount = 0;
        tasksCount = '0';
      });
    }
  }

  Future<void> _loadFriendsCount() async {
    try {
      // Load friends count
      QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
          .collection('friends_db')
          .doc(widget.userId)
          .collection('friends')
          .get();

      setState(() {
        friendsCount = friendsSnapshot.docs.length.toString();
      });
    } catch (e) {
      print('Error loading friends count: $e');
      setState(() {
        friendsCount = '0';
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    await FirebaseFirestore.instance
        .collection('friends_db')
        .doc(widget.userId)
        .collection('requests')
        .doc(currentUserId)
        .set({
      'fromUserId': currentUserId,
      'toUserId': widget.userId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('friends_db')
        .doc(currentUserId)
        .collection('requests')
        .doc(widget.userId)
        .set({
      'fromUserId': currentUserId,
      'toUserId': widget.userId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      requestStatus = 'pending';
    });

    _sendNotification(
        widget.userId, 'Friend Request', 'You have a new friend request.');
  }

  Future<void> _cancelFriendRequest() async {
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

    // Delete the notification
    QuerySnapshot notificationsSnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: widget.userId)
        .where('title', isEqualTo: 'Friend Request')
        .where('message', isEqualTo: 'You have a new friend request.')
        .get();

    for (var doc in notificationsSnapshot.docs) {
      await doc.reference.delete();
    }

    setState(() {
      requestStatus = 'none';
    });
  }

  Future<void> _sendNotification(
      String receiverId, String title, String message) async {
    if (receiverId != currentUserId) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverId': receiverId,
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'friend request',
        'status':
            requestStatus == 'pending' ? 'Request Sent' : 'Request Canceled',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
        centerTitle: true,
        title: Text(userName, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(errorMessage,
                      style: const TextStyle(color: Colors.red)))
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
                      _buildStatItem(tasksCount, 'Tasks'),
                      _buildStatItem(spaceCount, 'Spaces'),
                      _buildStatItem(friendsCount, 'Friends'),
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
            _buildFriendRequestButton(),
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

  Widget _buildFriendRequestButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: SizedBox(
        width: double.infinity,
        child: requestStatus == 'pending'
            ? ElevatedButton(
                onPressed: _cancelFriendRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2275AA),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                ),
                child: const Text(
                  "Cancel Friend Request",
                  style: TextStyle(color: Colors.white),
                ),
              )
            : ElevatedButton(
                onPressed: _sendFriendRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2275AA),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                ),
                child: const Text(
                  "Send Friend Request",
                  style: TextStyle(color: Colors.white),
                ),
              ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black)),
      ],
    );
  }
}
