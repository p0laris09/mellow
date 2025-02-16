import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountUpdateScreen extends StatefulWidget {
  final String firstName;
  final String middleName;
  final String lastName;
  final String birthday;
  final String phoneNumber;
  final String gender;
  final String university;
  final String college;
  final String program;
  final String year;
  final String section;

  const AccountUpdateScreen({
    super.key,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.birthday,
    required this.phoneNumber,
    required this.gender,
    required this.university,
    required this.college,
    required this.program,
    required this.year,
    required this.section,
  });

  @override
  _AccountUpdateScreenState createState() => _AccountUpdateScreenState();
}

class _AccountUpdateScreenState extends State<AccountUpdateScreen> {
  // Method to handle updating user data in Firestore
  Future<void> _updateUserData() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;

    User? user = auth.currentUser;

    if (user != null) {
      try {
        // Update user details in Firestore
        await firestore.collection('users').doc(user.uid).update({
          'firstName': widget.firstName,
          'middleName': widget.middleName,
          'lastName': widget.lastName,
          'birthday': widget.birthday,
          'phoneNumber': widget.phoneNumber,
          'gender': widget.gender,
          'university': widget.university,
          'college': widget.college,
          'program': widget.program,
          'year': widget.year,
          'section': widget.section,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account updated successfully!')),
        );

        // Navigate to homepage after successful update
        Navigator.pushReplacementNamed(context, '/dashboard');
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update account: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2275AA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Account Details",
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Check if your information is correct before\ncompleting the update.",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: Colors.white70,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 660,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    _buildReviewRow("First Name:", widget.firstName),
                    _buildReviewRow("Middle Name:", widget.middleName),
                    _buildReviewRow("Last Name:", widget.lastName),
                    _buildReviewRow("Birthday:", widget.birthday),
                    _buildReviewRow("Phone Number:", widget.phoneNumber),
                    _buildReviewRow("Gender:", widget.gender),
                    const SizedBox(height: 20),
                    const Text(
                      'School Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    _buildReviewRow("University:", widget.university),
                    _buildReviewRow("College:", widget.college),
                    _buildReviewRow("Program:", widget.program),
                    _buildReviewRow("Year:", widget.year),
                    _buildReviewRow("Section:", widget.section),
                    const SizedBox(height: 40),
                    Center(
                      child: SizedBox(
                        width: 315,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              _updateUserData, // Trigger the Firestore update on button press
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: const Color(0xFF2275AA),
                          ),
                          child: const Text(
                            "UPDATE",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build rows for the review
  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
