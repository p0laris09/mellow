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
  String requestStatus = 'none';

  StreamSubscription<DocumentSnapshot>? _friendRequestSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _initializeFriendRequestListener();
  }

  @override
  void dispose() {
    // Cancel any active subscription to avoid memory leaks
    _friendRequestSubscription?.cancel();
    super.dispose();
  }

  Future<void> _sendNotification(String notificationId, String title,
      String message, String receiverId) async {
    await _performFirestoreOperation(
      () async {
        Map<String, dynamic> notificationData = {
          'title': title,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'receiverId': receiverId,
        };

        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notificationId)
            .set(notificationData);
      },
      'Error sending notification',
    );
  }

  Future<void> _loadUserProfile() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      currentUserId = currentUser.uid;
    } else {
      return;
    }

    await _performFirestoreOperation(
      () async {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              userName =
                  '${data['firstName']} ${data['lastName']}'.toUpperCase();
              userSection = data['section'] ?? 'N/A';
              college = data['college'] ?? 'N/A';
              program = data['program'] ?? 'N/A';
              year = data['year'] ?? 'N/A';
              profileImageUrl = data['profileImageUrl'] ?? '';
              isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              errorMessage = 'User not found.';
              isLoading = false;
            });
          }
        }
      },
      'Failed to load profile.',
    );
  }

  void _initializeFriendRequestListener() {
    _friendRequestSubscription = FirebaseFirestore.instance
        .collection('friend_requests')
        .doc('$currentUserId-${widget.userId}')
        .snapshots()
        .listen((docSnapshot) {
      if (docSnapshot.exists) {
        final status = docSnapshot.data()?['status'] ?? 'none';
        if (mounted) {
          setState(() {
            requestStatus = status;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            requestStatus = 'none';
          });
        }
      }
    });
  }

  Future<void> _sendFriendRequest() async {
    String notificationId =
        '${currentUserId}-${widget.userId}-${DateTime.now().millisecondsSinceEpoch}';

    await _performFirestoreOperation(
      () async {
        await FirebaseFirestore.instance
            .collection('friend_requests')
            .doc('$currentUserId-${widget.userId}')
            .set({
          'fromUserId': currentUserId,
          'toUserId': widget.userId,
          'status': 'pending',
        });

        await _sendNotification(
          notificationId,
          'Friend Request',
          '$userName sent you a friend request.',
          widget.userId,
        );

        if (mounted) {
          setState(() {
            requestStatus = 'pending';
          });
        }
      },
      'Error sending friend request.',
    );
  }

  Future<void> _cancelFriendRequest() async {
    await _performFirestoreOperation(
      () async {
        await FirebaseFirestore.instance
            .collection('friend_requests')
            .doc('$currentUserId-${widget.userId}')
            .delete();

        if (mounted) {
          setState(() {
            requestStatus = 'none';
          });
        }
      },
      'Error canceling friend request.',
    );
  }

  Future<void> _acceptFriendRequest() async {
    String notificationId =
        '${widget.userId}-${currentUserId}-${DateTime.now().millisecondsSinceEpoch}';

    await _performFirestoreOperation(
      () async {
        await FirebaseFirestore.instance
            .collection('friend_requests')
            .doc('${widget.userId}-$currentUserId')
            .update({'status': 'accepted'});

        await _sendNotification(
          notificationId,
          'Friend Request Accepted',
          '$userName accepted your friend request.',
          widget.userId,
        );

        if (mounted) {
          setState(() {
            requestStatus = 'accepted';
          });
        }
      },
      'Error accepting friend request.',
    );
  }

  Future<void> _declineFriendRequest() async {
    await _performFirestoreOperation(
      () async {
        await FirebaseFirestore.instance
            .collection('friend_requests')
            .doc('${widget.userId}-$currentUserId')
            .delete();

        if (mounted) {
          setState(() {
            requestStatus = 'none';
          });
        }
      },
      'Error declining friend request.',
    );
  }

  Future<void> _performFirestoreOperation(
      Future<void> Function() operation, String errorMessage) async {
    try {
      await operation();
    } catch (e) {
      if (mounted) {
        setState(() {
          this.errorMessage = errorMessage;
        });
      }
      _showSnackbar(errorMessage);
      print('$errorMessage: $e');
    }
  }

  void _showSnackbar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
            // User profile and details
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
            const SizedBox(height: 20),
            _buildFriendRequestButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendRequestButtons() {
    switch (requestStatus) {
      case 'pending':
        return OutlinedButton(
          onPressed: _cancelFriendRequest,
          child: const Text('Cancel Request'),
        );
      case 'received':
        return Row(
          children: [
            ElevatedButton(
                onPressed: _acceptFriendRequest, child: const Text('Accept')),
            const SizedBox(width: 10),
            OutlinedButton(
                onPressed: _declineFriendRequest, child: const Text('Decline')),
          ],
        );
      default:
        return ElevatedButton(
          onPressed: _sendFriendRequest,
          child: const Text('Send Friend Request'),
        );
    }
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
