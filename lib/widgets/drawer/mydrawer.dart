import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:mellow/screens/SettingsScreen/settings_drawer.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  // Logout method
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign the user out
      Navigator.pushReplacementNamed(
          context, '/signin'); // Navigate to the sign-in page
    } catch (e) {
      print('Error signing out: $e'); // Handle any errors during sign-out
    }
  }

  // Method to get the user's full name in uppercase
  Future<String> _getUserFullName(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data();
      String firstName = data?['firstName'] ?? '';
      String lastName = data?['lastName'] ?? '';
      return '${firstName.toUpperCase()} ${lastName.toUpperCase()}'; // Combine and convert to uppercase
    }
    return 'USER'; // Return default uppercase value if the user is not found
  }

  // Method to get the user's profile image URL
  Future<String?> _getProfileImageUrl(User? user) async {
    if (user != null && user.photoURL != null) {
      return user.photoURL; // Return the user's photo URL from Firebase Auth
    }
    // You can also fetch the profile picture from Firestore if stored there
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .get();
    if (doc.exists) {
      return doc
          .data()?['profileImageUrl']; // Get image from Firestore if stored
    }
    return null; // Return null if no image found
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: FutureBuilder<String>(
        future: user != null
            ? _getUserFullName(user.uid)
            : Future.value('USER'), // Get full name if user is logged in
        builder: (context, snapshot) {
          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blueGrey[100],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FutureBuilder<String?>(
                      future:
                          _getProfileImageUrl(user), // Get profile image URL
                      builder: (context, profileSnapshot) {
                        if (profileSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator(); // Show loader while fetching
                        }

                        return CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: profileSnapshot.hasData
                              ? NetworkImage(profileSnapshot
                                  .data!) // Show image if URL exists
                              : null, // Show no image if no URL
                          child: profileSnapshot.hasData
                              ? null
                              : IconButton(
                                  // Fallback to an icon if no image
                                  onPressed: () {
                                    // Navigate to the profile page
                                    Navigator.pushNamed(context, '/profile');
                                  },
                                  icon: Icon(
                                    Icons.person,
                                    color: Colors.blueGrey[900],
                                  ),
                                ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Display user's full name
                    Text(
                      snapshot.connectionState == ConnectionState.waiting
                          ? 'LOADING...'
                          : snapshot.hasData
                              ? snapshot.data!
                              : 'USER', // Default value if name is not found
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pushNamed(
                      context, '/profile'); // Navigate to the profile page
                },
              ),
              ListTile(
                title: const Text('Community'),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Settings'),
                onTap: () {
                  // Navigate to the Settings page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsDrawer(),
                    ),
                  );
                },
              ),
              const Divider(), // Divider before logout button
              ListTile(
                title: const Text('Logout'),
                onTap: () {
                  _logout(context); // Call the logout function when pressed
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
