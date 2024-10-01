import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mellow/auth/onboarding/onboarding.dart';
import 'package:mellow/auth/signup/sign_up_personal_details.dart';
import 'package:mellow/screens/HomeScreen/home_screen.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  String? _errorMessage;

  Future<void> signIn() async {
    setState(() {
      _errorMessage = null; // Clear previous error message
    });

    // Check if fields are empty
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields!';
      });
      return;
    }

    try {
      // Attempt to sign in
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Retrieve the User object
      User? user = userCredential.user;

      // Navigate to HomeScreen and pass the user's uid
      if (user != null) {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(uid: user.uid), // Pass the user's uid
            ),
          );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Password and email do not match!'; // Set the error message
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C3C3C), // Matches the dark greenish background
      appBar: AppBar(
        backgroundColor: Color(0xFF2C3C3C), // Matches background color
        elevation: 0, // Remove shadow under AppBar
        leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white), // Custom back icon
        onPressed: () {
          // Navigate back to the onboarding page
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => OnboardingPage()), // Replace with your actual onboarding page widget
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
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // Error message container
                    Container(
                      height: 40, // Fixed height for error message
                      margin: const EdgeInsets.only(bottom: 16), // Add some space below the error message
                      alignment: Alignment.center,
                      child: _errorMessage != null 
                        ? Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : null,
                    ),

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
                                _obscureText = !_obscureText; // Toggle the visibility
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
                    const SizedBox(height: 50),

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
                            backgroundColor: const Color(0xFF2C3C3C),
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
                      alignment: Alignment.centerRight, // Align the column to the right
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
                                MaterialPageRoute(builder: (context) => SignUpPersonalDetails()),
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
