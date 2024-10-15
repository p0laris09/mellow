import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

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

  // Method to get the user's full name
  Future<String> _getUserFullName(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data();
      String firstName = data?['firstName'] ?? '';
      String lastName = data?['lastName'] ?? '';
      return '$firstName $lastName'; // Combine first and last name
    }
    return 'User'; // Return a default value if the user is not found
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: FutureBuilder<String>(
        future: user != null
            ? _getUserFullName(user.uid)
            : Future.value('User'), // Get full name if user is logged in
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
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 40,
                      child: IconButton(
                        onPressed: () {
                          // Navigate to the profile page
                          Navigator.pushNamed(context, '/profile');
                        },
                        icon: Icon(
                          Icons.person,
                          color: Colors.blueGrey[900],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Display user's full name
                    Text(
                      snapshot.connectionState == ConnectionState.waiting
                          ? 'Loading...'
                          : snapshot.hasData
                              ? snapshot.data!
                              : 'User', // Default value if name is not found
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
                  // Handle Press for settings
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
