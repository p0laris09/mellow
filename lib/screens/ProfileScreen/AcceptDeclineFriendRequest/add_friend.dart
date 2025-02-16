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
  String tasksCount = '0';
  String spaceCount = '0';
  String friendsCount = '0';
  bool isLoading = true;
  String errorMessage = '';

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
      await _loadCounts();
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

  Future<void> _loadCounts() async {
    try {
      // Load task count
      QuerySnapshot tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: widget.userId)
          .get();
      setState(() {
        tasksCount =
            tasksSnapshot.size > 0 ? tasksSnapshot.size.toString() : '0';
      });

      // Load collaboration space count
      QuerySnapshot spacesSnapshot = await FirebaseFirestore.instance
          .collection('spaces')
          .where('members', arrayContains: widget.userId)
          .get();
      setState(() {
        spaceCount =
            spacesSnapshot.size > 0 ? spacesSnapshot.size.toString() : '0';
      });

      // Load friends count
      QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
          .collection('friends_db')
          .doc(widget.userId)
          .collection('friends')
          .get();
      setState(() {
        friendsCount =
            friendsSnapshot.size > 0 ? friendsSnapshot.size.toString() : '0';
      });
    } catch (e) {
      print('Error loading counts: $e');
      setState(() {
        tasksCount = '0';
        spaceCount = '0';
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

    setState(() {
      requestStatus = 'none';
    });
  }

  Future<void> _sendNotification(
      String receiverId, String title, String message) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'receiverId': receiverId,
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'status':
          requestStatus == 'pending' ? 'Request Sent' : 'Request Canceled',
    });
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
                  Text('Section: $userSection',
                      style: const TextStyle(color: Colors.black)),
                  Text('College: $college',
                      style: const TextStyle(color: Colors.black)),
                  Text('Program: $program',
                      style: const TextStyle(color: Colors.black)),
                  Text('Year: $year',
                      style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildFriendRequestButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendRequestButton() {
    return Center(
      child: requestStatus == 'pending'
          ? ElevatedButton(
              onPressed: _cancelFriendRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text("Cancel Friend Request"),
            )
          : ElevatedButton(
              onPressed: _sendFriendRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text("Send Friend Request"),
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
