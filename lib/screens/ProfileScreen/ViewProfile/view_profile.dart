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
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (currentUserDoc.exists) {
        final data = currentUserDoc.data() as Map<String, dynamic>;
        List<dynamic> friends = data['friends'] ?? [];

        if (friends.contains(widget.userId)) {
          setState(() {
            isFriend = true;
          });
        } else {
          setState(() {
            isFriend = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Current user not found.';
          isLoading = false;
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
        setState(() {
          userName = '${data['firstName']} ${data['lastName']}'.toUpperCase();
          userSection = data['section'] ?? 'N/A';
          college = data['college'] ?? 'N/A';
          program = data['program'] ?? 'N/A';
          year = data['year'] ?? 'N/A';
          profileImageUrl = data['profileImageUrl'] ?? '';
          taskCount = data['tasks']?.length ?? 0; // Assume tasks is a list
          spaceCount = data['space'] ?? 0; // Adjust as per your data structure
          friendCount =
              data['friends']?.length ?? 0; // Assume friends is a list
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
          .collection('users')
          .doc(currentUserId)
          .update({
        'friends': FieldValue.arrayRemove([widget.userId])
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'friends': FieldValue.arrayRemove([currentUserId])
      });

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
            // Unfriend button
            ElevatedButton(
              onPressed: isFriend ? _unfriendUser : null,
              child: const Text('Unfriend'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
