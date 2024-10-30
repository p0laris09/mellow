import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountReviewScreen extends StatefulWidget {
  final String firstName;
  final String middleName;
  final String lastName;
  final String birthday;
  final String university;
  final String college;
  final String program;
  final String year;
  final String section;
  final String phoneNumber;
  final String email;
  final String password;

  const AccountReviewScreen({
    super.key,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.birthday,
    required this.university,
    required this.college,
    required this.program,
    required this.year,
    required this.section,
    required this.phoneNumber,
    required this.email,
    required this.password,
  });

  @override
  _AccountReviewScreenState createState() => _AccountReviewScreenState();
}

class _AccountReviewScreenState extends State<AccountReviewScreen> {
  bool _isPasswordVisible = false;
  bool termsAccepted = false; // State to track checkbox

  Future<void> _signUpUser() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Create a new user with email and password
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      // Save additional details to Firestore
      if (userCredential.user != null) {
        await firestore.collection('users').doc(userCredential.user!.uid).set({
          'firstName': widget.firstName,
          'middleName': widget.middleName,
          'lastName': widget.lastName,
          'birthday': widget.birthday,
          'university': widget.university,
          'college': widget.college,
          'program': widget.program,
          'year': widget.year,
          'phoneNumber': widget.phoneNumber,
          'section': widget.section,
          // Do not store password here
        });

        // Navigate to homepage after successful sign-up
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showErrorDialog(context, "Email address is already registered.");
      } else if (e.code == 'weak-password') {
        _showErrorDialog(context, "Password provided is too weak.");
      } else if (e.code == 'invalid-email') {
        _showErrorDialog(context, "The email address is invalid.");
      } else {
        _showErrorDialog(context, "An error occurred. Please try again.");
      }
    } catch (error) {
      _showErrorDialog(
          context, "An unexpected error occurred. Please try again.");
    }
  }

  // Helper method to show a dialog
  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(errorMessage),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3C3C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3C3C),
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
                    "Check if your information is correct before\ncompleting the sign up.",
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
              height: 730,
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
                    const SizedBox(height: 20),
                    const Text(
                      'Login Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    _buildReviewRow("Phone Number:", widget.phoneNumber),
                    _buildReviewRow("Email:", widget.email),
                    Row(
                      children: [
                        const Text(
                          "Password:",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isPasswordVisible
                                ? widget.password
                                : widget.password.replaceAll(RegExp(r"."), "*"),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: termsAccepted,
                          onChanged: (bool? newValue) {
                            setState(() {
                              termsAccepted = newValue ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: "I agree to the ",
                              style: const TextStyle(color: Colors.black87),
                              children: [
                                TextSpan(
                                  text: "Terms of Service",
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pushNamed(context, '/terms');
                                    },
                                ),
                                const TextSpan(text: " and "),
                                TextSpan(
                                  text: "Privacy Policy",
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pushNamed(context, '/privacy');
                                    },
                                ),
                                const TextSpan(text: "."),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        width: 315,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: termsAccepted ? _signUpUser : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: const Color(0xFF2C3C3C),
                          ),
                          child: const Text(
                            "SIGN UP",
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
