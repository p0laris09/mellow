import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SendfeedbackScreen extends StatefulWidget {
  const SendfeedbackScreen({super.key});

  @override
  State<SendfeedbackScreen> createState() => _SendfeedbackScreenState();
}

class _SendfeedbackScreenState extends State<SendfeedbackScreen> {
  int _selectedRating = 0;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String? _errorMessage;

  void _validateAndSubmitFeedback() async {
    setState(() {
      _errorMessage = null;
    });

    if (_selectedRating == 0) {
      setState(() {
        _errorMessage = "Please select a rating.";
      });
      return;
    }

    if (_commentController.text.length > 250) {
      setState(() {
        _errorMessage = "Comment must be 250 characters or less.";
      });
      return;
    }

    // If validation passes, save feedback to Firestore
    try {
      // Prepare feedback data
      final feedbackData = {
        'email': _emailController.text.isEmpty ? null : _emailController.text,
        'experience': _selectedRating,
        'comment':
            _commentController.text.isEmpty ? null : _commentController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth
            .instance.currentUser?.uid, // Store the userId if authenticated
      };

      // Add feedback to Firestore
      await FirebaseFirestore.instance.collection('feedback').add(feedbackData);

      // Show Thank You dialog
      _showThankYouDialog();
    } catch (e) {
      setState(() {
        _errorMessage = "Error saving feedback: $e";
      });
    }
  }

  // Function to display the Thank You AlertDialog
  void _showThankYouDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF2275AA),
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                "Thank you!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "By making your voice heard, you help us improve our app.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/dashboard'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF2275AA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("GO BACK TO DASHBOARD"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          'Send Feedback',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Email address (optional)",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: "Enter your email address",
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Rate your experience",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _selectedRating ? Icons.star : Icons.star_border,
                    color: index < _selectedRating ? Colors.blue : Colors.black,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedRating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            const Text(
              "Comment (up to 250 characters)",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLength: 250, // Limit to 250 characters
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: "Say something here...",
                counterText:
                    "${_commentController.text.length}/250", // Character counter
              ),
              onChanged: (value) {
                setState(() {}); // Update counter dynamically
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 20,
              child: _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _validateAndSubmitFeedback,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF2275AA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("PUBLISH FEEDBACK"),
            ),
          ],
        ),
      ),
    );
  }
}
