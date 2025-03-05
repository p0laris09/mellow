import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mellow/auth/forgotpassword/forgot_password.dart';
import 'package:mellow/auth/onboarding/onboarding.dart';
import 'package:mellow/auth/signup/sign_up_personal_details.dart';
import 'package:mellow/screens/DashboardScreen/dashboard_screen.dart';
import 'package:mellow/screens/TaskPreference/task_preference_screen.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  Future<void> signIn() async {
    // Check if fields are empty
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Please fill in all fields!');
      return;
    }

    try {
      // Attempt to sign in
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Retrieve the User object
      User? user = userCredential.user;

      if (user != null) {
        // Check if the email is verified
        if (user.emailVerified) {
          // Check if the user has task preferences set up
          DocumentSnapshot taskPreferenceSnapshot = await FirebaseFirestore
              .instance
              .collection('task_preference')
              .doc(user.uid)
              .get();

          if (taskPreferenceSnapshot.exists) {
            // Navigate to the regular DashboardScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(),
              ),
            );
          } else {
            // Navigate to the TaskPreferenceScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TaskPreferenceScreen(),
              ),
            );
          }
        } else {
          // Sign out the user
          await FirebaseAuth.instance.signOut();

          // Show error message
          _showErrorDialog('Please verify your email before signing in.');
        }
      }
    } catch (e) {
      _showErrorDialog('Password and email do not match!');
    }
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2275AA),
          title: const Text("Error", style: TextStyle(color: Colors.white)),
          content:
              Text(errorMessage, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: const Text("OK", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
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
      backgroundColor:
          const Color(0xFF2275AA), // Matches the dark greenish background
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA), // Matches background color
        elevation: 0, // Remove shadow under AppBar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white), // Custom back icon
          onPressed: () {
            // Navigate back to the onboarding page
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingPage()),
              (route) => false, // Remove all previous routes
            );
          },
        ),
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
                    "Welcome\nBack!",
                    style: TextStyle(
                      fontSize: 50, // Adjusted size for better fit
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Log back into your account\nand manage your tasks.",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: Colors.white70, // Light gray text
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 590, // Set your desired height here
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
                  children: [
                    // Email TextField with fixed width
                    SizedBox(
                      width: 300, // Set your desired width here
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9), // Spacing between fields

                    // Password TextField with fixed width
                    SizedBox(
                      width: 300, // Set your desired width here
                      child: TextField(
                        obscureText: _obscureText, // Use the _obscureText state
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: const UnderlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureText =
                                    !_obscureText; // Toggle the visibility
                              });
                            },
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(right: 38.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPassword()),
                                );
                              },
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Sign in button
                    SizedBox(
                      width: 315,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: signIn,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: const Color(0xFF2275AA),
                        ),
                        child: const Text(
                          "SIGN IN",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Go to Sign up Page
                    Align(
                      alignment: Alignment
                          .centerRight, // Align the column to the right
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 5), // Space between text
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SignUpPersonalDetails()),
                              );
                            },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
