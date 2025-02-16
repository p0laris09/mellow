import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mellow/screens/SettingsScreen/AccountInformation/UpdateEmail/email_update_sent.dart';

class EmailUpdatePage extends StatefulWidget {
  const EmailUpdatePage({super.key});

  @override
  State<EmailUpdatePage> createState() => _EmailUpdatePageState();
}

class _EmailUpdatePageState extends State<EmailUpdatePage> {
  final TextEditingController _currentEmailController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _confirmNewEmailController =
      TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController(); // For re-authentication
  bool _obscurePassword = true; // To toggle the visibility
  String? _errorMessage;

  // Function to set the error message
  void _setErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

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
        _setErrorMessage("Re-authentication failed: ${e.message}");
        rethrow; // Re-throw the error to prevent email update if re-authentication fails
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
      _setErrorMessage("Emails do not match.");
      return;
    }

    // Validate the email format
    if (!_isValidEmail(newEmail)) {
      _setErrorMessage("Invalid email format.");
      return;
    }

    // Validate current email
    String currentEmail = _currentEmailController.text.trim();
    if (currentEmail.isEmpty) {
      _setErrorMessage("Current email cannot be empty.");
      return;
    }

    try {
      // Re-authenticate the user before updating the email
      await _reauthenticateUser(password);

      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Use verifyBeforeUpdateEmail to send verification
        await user.verifyBeforeUpdateEmail(newEmail);
        await user.reload(); // This updates the user data

        _setErrorMessage(
            "A verification link has been sent to your new email.");

        // Logout the user
        await FirebaseAuth.instance.signOut();

        // Navigate to the EmailUpdateSent screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EmailUpdateSent()),
        );
      } else {
        _setErrorMessage("No user is logged in.");
      }
    } on FirebaseAuthException catch (e) {
      // Handle error codes
      switch (e.code) {
        case 'email-already-in-use':
          _setErrorMessage("This email is already in use by another account.");
          break;
        case 'invalid-email':
          _setErrorMessage("The email address is not valid.");
          break;
        case 'requires-recent-login':
          _setErrorMessage("Please re-authenticate and try again.");
          break;
        default:
          _setErrorMessage("An unknown error occurred: ${e.message}");
          break;
      }
    } catch (e) {
      _setErrorMessage("Failed to update email: $e");
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
      backgroundColor: const Color(0xFF2275AA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
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
                    // Current Email
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _currentEmailController,
                        maxLength: 254, // Limiting the max characters to 254
                        decoration: const InputDecoration(
                          labelText: "Current Email",
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
                        obscureText: _obscurePassword, // Use the boolean here
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          border: const UnderlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword; // Toggle the visibility
                              });
                            },
                          ),
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
                          backgroundColor: const Color(0xFF2275AA),
                        ),
                        child: const Text(
                          "Update Email",
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
