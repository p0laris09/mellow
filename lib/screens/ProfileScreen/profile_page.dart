import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:mellow/provider/BannerImageProvider/banner_image_provider.dart';
import 'package:mellow/provider/ProfileImageProvider/profile_image_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = 'Loading...';
  String profileImageUrl = '';
  String bannerImageUrl = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profileImageProvider =
        Provider.of<ProfileImageProvider>(context, listen: false);
    final bannerImageProvider =
        Provider.of<BannerImageProvider>(context, listen: false);
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        String userId = user.uid;

        // Fetch user data from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          setState(() {
            userName =
                '${userDoc['firstName']} ${userDoc['lastName']}'.toUpperCase();
            isLoading = false; // Set loading to false after fetching user data
          });

          // Fetch images from providers
          await profileImageProvider.fetchProfileImage(user);
          await bannerImageProvider.fetchBannerImage(user);

          // Update the image URLs from providers
          setState(() {
            profileImageUrl = profileImageProvider.profileImageUrl ?? '';
            bannerImageUrl = bannerImageProvider.bannerImageUrl ?? '';
          });
        }
      } catch (e) {
        print('Error loading user profile: $e');
        setState(() {
          isLoading = false; // Set loading to false even if there's an error
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
              child: Column(
                children: [
                  Stack(
                    children: [
                      // Using Consumer to listen to changes in BannerImageProvider
                      Consumer<BannerImageProvider>(
                        builder: (context, bannerImageProvider, child) {
                          return Container(
                            height: 220,
                            decoration: BoxDecoration(
                              image: bannerImageProvider
                                      .bannerImageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(
                                          bannerImageProvider.bannerImageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: bannerImageProvider.bannerImageUrl.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : null,
                          );
                        },
                      ),
                      // Profile avatar
                      Positioned(
                        top: 80,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 4.0,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundImage: profileImageUrl.isNotEmpty
                                    ? NetworkImage(
                                        profileImageUrl) // User's profile image
                                    : null,
                                child: profileImageUrl.isEmpty
                                    ? const Icon(Icons.person,
                                        size: 60) // Placeholder icon
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Profile Details
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'IV-BCSAD', // Placeholder profession
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  // Social media and follow stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('30', 'Followers'),
                        _buildStatItem('61', 'Following'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Social media icons
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.facebook,
                          size: 35, color: Colors.blue),
                      SizedBox(width: 20),
                      FaIcon(FontAwesomeIcons.twitter,
                          size: 35, color: Colors.blue),
                      SizedBox(width: 20),
                      FaIcon(FontAwesomeIcons.instagram,
                          size: 35, color: Colors.pink),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Skills and Details about the user/student
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily UI #5 - User Profile',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('$userName · yesterday'),
                        const SizedBox(height: 15),
                        // Additional details can go here
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
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
