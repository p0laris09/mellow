import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailUpdatePage extends StatefulWidget {
  const EmailUpdatePage({super.key});

  @override
  State<EmailUpdatePage> createState() => _EmailUpdatePageState();
}

class _EmailUpdatePageState extends State<EmailUpdatePage> {
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _confirmNewEmailController =
      TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController(); // For re-authentication

  String? _errorMessage;

  // Function to re-authenticate the user
  Future<void> _reauthenticateUser(String password) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      try {
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = "Re-authentication failed: ${e.message}";
        });
        throw e; // Re-throw the error to prevent email update if re-authentication fails
      }
    }
  }

  // Function to submit the new email
  Future<void> _submitNewEmail() async {
    String newEmail = _newEmailController.text.trim();
    String confirmNewEmail = _confirmNewEmailController.text.trim();
    String password = _passwordController.text.trim();

    // Check if the emails match
    if (newEmail != confirmNewEmail) {
      setState(() {
        _errorMessage = "Emails do not match.";
      });
      return;
    }

    // Validate the email format
    if (!_isValidEmail(newEmail)) {
      setState(() {
        _errorMessage = "Invalid email format.";
      });
      return;
    }

    try {
      // Re-authenticate the user before updating the email
      await _reauthenticateUser(password);

      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update the user's email in Firebase Auth
        await user.updateEmail(newEmail);
        await user.reload();
        user = FirebaseAuth.instance.currentUser;

        setState(() {
          _errorMessage = "Email updated successfully!";
        });

        // Navigate back to the profile page
        Navigator.pop(
            context); // This will close the EmailUpdatePage and go back to the previous page
      } else {
        setState(() {
          _errorMessage = "No user is logged in.";
        });
      }
    } on FirebaseAuthException catch (e) {
      // Handle different error codes
      if (e.code == 'email-already-in-use') {
        setState(() {
          _errorMessage = "This email is already in use by another account.";
        });
      } else if (e.code == 'invalid-email') {
        setState(() {
          _errorMessage = "The email address is not valid.";
        });
      } else if (e.code == 'requires-recent-login') {
        setState(() {
          _errorMessage = "Please re-authenticate and try again.";
        });
      } else {
        setState(() {
          _errorMessage = "An unknown error occurred: ${e.message}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to update email: $e";
      });
    }
  }

  // Helper function to validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3C3C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3C3C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to the profile page
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Update your\nEmail",
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Input your new email!",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 610,
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
                    // Error Message Container
                    Container(
                      height: 30,
                      margin: const EdgeInsets.only(bottom: 16),
                      alignment: Alignment.center,
                      child: _errorMessage != null
                          ? Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : null,
                    ),
                    // New Email
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _newEmailController,
                        maxLength: 254, // Limiting the max characters to 254
                        decoration: const InputDecoration(
                          labelText: "New Email",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                          counterText: "", // Hide the character count
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),

                    // Confirm New Email
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _confirmNewEmailController,
                        maxLength: 254, // Limiting the max characters to 254
                        decoration: const InputDecoration(
                          labelText: "Confirm New Email",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                          counterText: "", // Hide the character count
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),

                    // Password for re-authentication
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true, // Hide password input
                        decoration: const InputDecoration(
                          labelText: "Password",
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Submit Button
                    SizedBox(
                      width: 315,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitNewEmail,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: const Color(0xFF2C3C3C),
                        ),
                        child: const Text(
                          "Submit",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
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
}
