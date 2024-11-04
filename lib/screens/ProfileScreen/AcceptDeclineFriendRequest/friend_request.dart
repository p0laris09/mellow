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

  Future<void> _acceptFriendRequest() async {
    try {
      // Update friend request status to 'accepted'
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc('${widget.userId}-$currentUserId')
          .update({'status': 'accepted'});

      // Add each other as friends
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'friends': FieldValue.arrayUnion([widget.userId])
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'friends': FieldValue.arrayUnion([currentUserId])
      });

      print('Friend request accepted. Updated friends lists.');

      // Send a notification
      await _sendNotification(
          widget.userId, 'Friend Request Accepted', 'You are now friends.');

      // Navigate to ViewProfile
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ViewProfile(userId: widget.userId)),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Error accepting friend request.';
      });
      print('Error accepting friend request: $e'); // Debugging
    }
  }

  Future<void> _declineFriendRequest() async {
    try {
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc('${widget.userId}-$currentUserId')
          .delete();

      // Send a notification
      await _sendNotification(
          widget.userId, 'Friend Request Declined', 'Friend request declined.');

      // Navigate to AddFriend
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => AddFriend(userId: widget.userId)),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Error declining friend request.';
      });
    }
  }

  Future<void> _sendNotification(
      String receiverId, String title, String message) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'receiverId': receiverId,
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'status': title == 'Friend Request Accepted'
          ? 'Now Friends'
          : 'Request Declined',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3C3C),
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
                      _buildStatItem('671', 'Tasks'),
                      _buildStatItem('10.6k', 'Space'),
                      _buildStatItem('562', 'Friends'),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _acceptFriendRequest,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Accept'),
                ),
                ElevatedButton(
                  onPressed: _declineFriendRequest,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Decline'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
