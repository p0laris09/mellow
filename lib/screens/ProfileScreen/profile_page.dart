import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mellow/screens/ProfileScreen/UpdateProfileInfo/update_personal_info.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Method to fetch user data from Firestore
  Future<Map<String, dynamic>> _fetchUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userProfile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userProfile.exists) {
        return userProfile.data() as Map<String, dynamic>; // Return user data
      } else {
        throw Exception('User profile does not exist');
      }
    } else {
      throw Exception('No user is currently logged in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Account Information',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2C3C3C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserProfile(), // Call the fetch method
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            var data = snapshot.data!;
            // Convert full name to uppercase
            String fullName = '${data['firstName'] ?? ''} ${data['middleName'] ?? ''} ${data['lastName'] ?? ''}'.toUpperCase();
            String birthday = data['birthday'] ?? '';
            String university = data['university'] ?? '';
            String college = data['college'] ?? '';
            String program = data['program'] ?? '';
            String year = data['year'] ?? '';
            String phoneNumber = data['phoneNumber'] ?? '';
            String email = data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Display full name in uppercase
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Display the user details dynamically
                    _buildProfileDetail('Birthday', birthday),
                    _buildProfileDetail('University', university),
                    _buildProfileDetail('College', college),
                    _buildProfileDetail('Program', program),
                    _buildProfileDetail('Year', year),
                    _buildProfileDetail('Phone Number', phoneNumber),
                    // Email section with edit icon
                    _buildProfileDetail(
                      'Email',
                      email,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.teal),
                        onPressed: () {
                          // Handle Edit Button Press
                          print('Edit Email Clicked');
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        width: 315,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to UpdatePersonalInfo page
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UpdatePersonalInfo()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C3C3C),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'UPDATE ACCOUNT INFO',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          print('Delete Account Pressed');
                        },
                        child: const Text(
                          'DELETE ACCOUNT',
                          style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: Text('No data found'));
          }
        },
      ),
    );
  }

  // Helper method to build profile detail rows
  Widget _buildProfileDetail(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Column for label and value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4), // Space between label and value
                Padding(
                  padding: const EdgeInsets.only(left: 12.0), // Adjusted padding
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 19, // Slightly larger font size for the value
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Trailing icon for editing
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
