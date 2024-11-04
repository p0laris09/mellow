import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mellow/provider/ProfileImageProvider/profile_image_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profileImageProvider =
        Provider.of<ProfileImageProvider>(context, listen: false);
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        String userId = user.uid;
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          setState(() {
            userName =
                '${userDoc['firstName']} ${userDoc['lastName']}'.toUpperCase();
            userSection = userDoc['section'];
            college = userDoc['college'];
            program = userDoc['program'];
            year = userDoc['year'];
          });

          // Fetch profile image
          await profileImageProvider.fetchProfileImage(user);
          setState(() {
            profileImageUrl =
                profileImageProvider.profileImageUrl?.isNotEmpty == true
                    ? profileImageProvider.profileImageUrl!
                    : 'assets/img/default_profile.png';
          });

          // Fetch tasks count
          QuerySnapshot tasksSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('tasks')
              .get();
          setState(() {
            tasksCount = tasksSnapshot.size;
          });

          // Fetch accepted friends count from friend requests
          // Query for accepted friends where current user is toUserId
          QuerySnapshot friendsAsReceiverSnapshot = await FirebaseFirestore
              .instance
              .collection('friends_request')
              .where('status', isEqualTo: 'accepted')
              .where('toUserId', isEqualTo: userId)
              .get();

          // Query for accepted friends where current user is fromUserId
          QuerySnapshot friendsAsSenderSnapshot = await FirebaseFirestore
              .instance
              .collection('friends_request')
              .where('status', isEqualTo: 'accepted')
              .where('fromUserId', isEqualTo: userId)
              .get();

          // Combine counts
          setState(() {
            friendsCount =
                friendsAsReceiverSnapshot.size + friendsAsSenderSnapshot.size;
          });

          // Fetch space count if needed
          QuerySnapshot spaceSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('space')
              .get();
          setState(() {
            spaceCount = spaceSnapshot.size;
          });
        }
      } catch (e) {
        print('Error loading user profile: $e');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
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
                    // Profile image and statistics row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: profileImageUrl.startsWith('http')
                              ? NetworkImage(profileImageUrl)
                              : AssetImage(profileImageUrl) as ImageProvider,
                          child: profileImageUrl.isEmpty
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        const SizedBox(width: 20),
                        // Statistics Row
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
                    // User name and academic details below profile image
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
                          Text(
                            'College: $college',
                            style: const TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Program: $program',
                            style: const TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Year: $year',
                            style: const TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Section: $userSection',
                            style: const TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Additional content area
                    SizedBox(
                      height: 610,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 32, horizontal: 16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        // Additional content can be added here
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/search_friends');
        },
        label: const Text('Add Friends'),
        icon: const Icon(Icons.person_add),
        backgroundColor: Colors.blue,
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
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
