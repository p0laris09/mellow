import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mellow/screens/ProfileScreen/ViewProfile/view_profile.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> tasksNotifications = [];
  List<Map<String, dynamic>> spaceNotifications = [];
  List<Map<String, dynamic>> friendRequests = [];

  List<Map<String, dynamic>> displayedNotifications = [];
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      QuerySnapshot tasksSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('type', isEqualTo: 'task')
          .get();
      tasksNotifications = tasksSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      QuerySnapshot spaceSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('type', isEqualTo: 'space')
          .get();
      spaceNotifications = spaceSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      QuerySnapshot friendRequestsSnapshot = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('toUserId', isEqualTo: currentUserId)
          .get();
      friendRequests = friendRequestsSnapshot.docs
          .map((doc) => {
                'fromUserId': doc['fromUserId'],
                'status': doc['status'],
                'id': doc.id
              })
          .toList();

      _filterNotifications();

      setState(() {});
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  void _filterNotifications() {
    switch (selectedFilter) {
      case 'Tasks':
        displayedNotifications = tasksNotifications;
        break;
      case 'Space':
        displayedNotifications = spaceNotifications;
        break;
      case 'Friend Requests':
        displayedNotifications = friendRequests;
        break;
      default:
        displayedNotifications = []
          ..addAll(tasksNotifications)
          ..addAll(spaceNotifications)
          ..addAll(friendRequests);
        break;
    }
  }

  Future<void> _acceptFriendRequest(String fromUserId) async {
    try {
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc('$fromUserId-$currentUserId')
          .update({'status': 'accepted'});

      await FirebaseFirestore.instance.collection('friends').add({
        'userId1': currentUserId,
        'userId2': fromUserId,
      });

      setState(() {
        friendRequests
            .removeWhere((request) => request['fromUserId'] == fromUserId);
        _filterNotifications();
      });
    } catch (e) {
      print('Error accepting friend request: $e');
    }
  }

  Future<void> _declineFriendRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(requestId)
          .delete();

      setState(() {
        friendRequests.removeWhere((request) => request['id'] == requestId);
        _filterNotifications();
      });
    } catch (e) {
      print('Error declining friend request: $e');
    }
  }

  void _navigateToProfileDetail(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewProfile(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3C3C),
        elevation: 0,
        title: const Text(
          'Notifications Page',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _filterButton('All'),
                  _filterButton('Tasks'),
                  _filterButton('Space'),
                  _filterButton('Friend Requests'),
                ],
              ),
              const SizedBox(height: 20),
              ...displayedNotifications.map((notification) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: friendRequests.contains(notification)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () => _navigateToProfileDetail(
                                    notification['fromUserId']),
                                child: Text(
                                    'Friend request from ${notification['fromUserId']}'),
                              ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      _acceptFriendRequest(
                                          notification['fromUserId']);
                                    },
                                    child: const Text('Accept'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: const Color(0xFF2C3C3C),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      _declineFriendRequest(notification['id']);
                                    },
                                    child: const Text('Decline'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Text(notification['message'] ?? 'Notification'),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterButton(String label) {
    return TextButton(
      onPressed: () {
        setState(() {
          selectedFilter = label;
          _filterNotifications();
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: selectedFilter == label
            ? const Color(0xFF2C3C3C)
            : Colors.grey[300],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selectedFilter == label ? Colors.white : Colors.black,
          fontWeight:
              selectedFilter == label ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
