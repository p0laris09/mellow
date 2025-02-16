import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mellow/screens/SettingsScreen/AccountInformation/UpdateEmail/email_update.dart';
import 'dart:io';
import 'package:mellow/screens/SettingsScreen/AccountInformation/UpdateAccountInfo/update_personal_info.dart';

class AccountInformationPage extends StatefulWidget {
  const AccountInformationPage({super.key});

  @override
  _AccountInformationPageState createState() => _AccountInformationPageState();
}

class _AccountInformationPageState extends State<AccountInformationPage> {
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage; // To hold the selected image
  Future<Map<String, dynamic>>? _userProfileFuture;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _fetchUserProfile();
  }

  // Method to fetch user data from Firestore
  Future<Map<String, dynamic>> _fetchUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userProfile = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userProfile.exists) {
          var data = userProfile.data() as Map<String, dynamic>;
          setState(() {
            _profileImageUrl = data['profileImageUrl'];
          });
          return data;
        } else {
          throw Exception('User profile does not exist');
        }
      } catch (e) {
        throw Exception('Error fetching user profile: $e');
      }
    } else {
      throw Exception('No user is currently logged in');
    }
  }

  // Method to pick an image and upload to Firebase Storage
  Future<void> _pickAndUploadImage() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path); // Save the selected image
      });

      // Upload to Firebase Storage
      String filePath = 'profile_images/${user.uid}.png';
      await FirebaseStorage.instance.ref(filePath).putFile(_selectedImage!);

      // Get the download URL
      String downloadUrl =
          await FirebaseStorage.instance.ref(filePath).getDownloadURL();

      // Update Firestore with the image URL
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profileImageUrl': downloadUrl,
      });

      // Update the profile image URL in the state
      setState(() {
        _profileImageUrl = downloadUrl;
      });
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  // Method to delete the user account
  Future<void> _deleteAccount(String email) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Re-authenticate the user
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: 'user-password', // Replace with the actual user password
      );
      await user.reauthenticateWithCredential(credential);

      // Delete user data from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // Delete user account
      await user.delete();

      // Navigate to the login screen or home screen
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Error deleting account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }

  // Show confirmation dialog for account deletion
  void _showDeleteAccountDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Are you sure you want to delete this account?'),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Enter your email to confirm',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAccount(emailController.text.trim());
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          'Account Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            var data = snapshot.data!;
            String fullName =
                '${data['firstName'] ?? ''} ${data['middleName'] ?? ''} ${data['lastName'] ?? ''}'
                    .toUpperCase();
            String birthday = data['birthday'] ?? 'Not provided';
            String university = data['university'] ?? 'Not provided';
            String college = data['college'] ?? 'Not provided';
            String program = data['program'] ?? 'Not provided';
            String year = data['year'] ?? 'Not provided';
            String phoneNumber = data['phoneNumber'] ?? 'Not provided';
            String section = data['section'] ?? 'Not provided';
            String email = data['email'] ??
                FirebaseAuth.instance.currentUser?.email ??
                'Not provided';

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.grey[200],
                            child: ClipOval(
                              child: _profileImageUrl != null
                                  ? Image.network(
                                      _profileImageUrl!,
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      // Load default asset image
                                      'assets/img/default_profile.png',
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
                    _buildProfileDetail('Birthday', birthday),
                    _buildProfileDetail('University', university),
                    _buildProfileDetail('College', college),
                    _buildProfileDetail('Program', program),
                    _buildProfileDetail('Year', year),
                    _buildProfileDetail('Section', section),
                    _buildProfileDetail('Phone Number', phoneNumber),
                    // Add pen icon next to the email field
                    _buildProfileDetail(
                      'Email',
                      email,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EmailUpdatePage(),
                            ),
                          );
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const UpdatePersonalInfo()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2275AA),
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
                        onPressed: _showDeleteAccountDialog,
                        child: const Text(
                          'DELETE ACCOUNT',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                              fontWeight: FontWeight.bold),
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

  Widget _buildProfileDetail(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 19,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
