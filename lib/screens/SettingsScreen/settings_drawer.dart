import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:mellow/screens/SettingsScreen/AccountInformation/account_information_page.dart';
import 'package:mellow/screens/SettingsScreen/settings_page.dart';
import 'package:mellow/screens/TaskPreference/view_task_preference.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  // Method to get the user's email
  String? _getUserEmail(User? user) {
    return user?.email; // Return the email of the authenticated user
  }

  Future<String?> _getProfileImageUrl(User? user) async {
    if (user != null && user.photoURL != null) {
      return user.photoURL; // Return the user's photo URL from Firebase Auth
    }
    // If no photoURL in Firebase Auth, attempt to retrieve from Firestore
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

  Future<String> _getDefaultProfileImageUrl() async {
    try {
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('default_images/default_profile.png');
      String imageUrl = await storageRef.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Error fetching default profile image: $e');
      return ''; // Return empty string or a fallback URL
    }
  }

  // Method to get the user's full name
  Future<String> _getUserFullName(User? user) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .get();
    if (doc.exists) {
      final data = doc.data();
      String firstName = data?['firstName'] ?? '';
      String lastName = data?['lastName'] ?? '';
      return '${firstName.toUpperCase()} ${lastName.toUpperCase()}'; // Combine and convert to uppercase
    }
    return 'USER'; // Return default uppercase value if the user is not found
  }

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

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA), // Darker app bar color
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<String>(
        future: _getUserFullName(user), // Fetch the user's full name
        builder: (context, snapshot) {
          String fullName = snapshot.data ?? 'USER'; // Default if no data
          String? email = _getUserEmail(user);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Section (Top)
              FutureBuilder<String?>(
                // Fetch the profile image
                future: _getProfileImageUrl(user),
                builder: (context, imageSnapshot) {
                  String? imageUrl = imageSnapshot.data;

                  return ListTile(
                    // In the ListTile where you fetch the image
                    leading: FutureBuilder<String>(
                      future: imageUrl != null && imageUrl.isNotEmpty
                          ? Future.value(imageUrl)
                          : _getDefaultProfileImageUrl(),
                      builder: (context, defaultImageSnapshot) {
                        if (defaultImageSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircleAvatar(
                            radius: 30,
                            child: CircularProgressIndicator(),
                          );
                        } else if (defaultImageSnapshot.hasError) {
                          return const CircleAvatar(
                            radius: 30,
                            child: Icon(Icons.error, size: 30),
                          );
                        } else {
                          String resolvedImageUrl = defaultImageSnapshot.data!;
                          return CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(resolvedImageUrl),
                          );
                        }
                      },
                    ),

                    title: Text(
                      fullName, // Display fetched full name
                      style: const TextStyle(
                        color: Colors.black, // Text color
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      email ?? 'No email', // Display fetched email
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      // Action on tapping the profile section (e.g., navigate to profile settings)
                    },
                  );
                },
              ),
              const SizedBox(height: 20), // Space between sections
              const Divider(color: Colors.grey), // Grey divider for contrast

              // General section
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'GENERAL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.black),
                title: const Text('Account',
                    style: TextStyle(color: Colors.black)),
                trailing:
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () {
                  // Navigate to AccountInformationPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountInformationPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.black),
                title: const Text('Settings',
                    style: TextStyle(color: Colors.black)),
                trailing:
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () {
                  // Navigate to Notifications page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.task, color: Colors.black),
                title: const Text('Task Preference',
                    style: TextStyle(color: Colors.black)),
                trailing:
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () {
                  // Navigate to ViewTaskPreferencePage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ViewTaskPreference(),
                    ),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.bug_report_sharp, color: Colors.black),
                title: const Text(
                  'Report a Bug',
                  style: TextStyle(color: Colors.black),
                ),
                trailing:
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () {
                  // Navigate to the SendfeedbackScreen using the named route
                  Navigator.pushNamed(context, '/reportbugs');
                },
              ),
              ListTile(
                leading: const Icon(Icons.feedback, color: Colors.black),
                title: const Text(
                  'Send feedback',
                  style: TextStyle(color: Colors.black),
                ),
                trailing:
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () {
                  // Navigate to the SendfeedbackScreen using the named route
                  Navigator.pushNamed(context, '/sendfeedback');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.black),
                title:
                    const Text('Logout', style: TextStyle(color: Colors.black)),
                trailing:
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
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
