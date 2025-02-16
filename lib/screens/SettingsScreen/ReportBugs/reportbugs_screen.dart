import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class ReportBugsScreen extends StatefulWidget {
  const ReportBugsScreen({super.key});

  @override
  State<ReportBugsScreen> createState() => _ReportBugsScreenState();
}

class _ReportBugsScreenState extends State<ReportBugsScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bugDescriptionController =
      TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  String? _errorMessage;
  File? _selectedImage;
  bool _isSubmitting = false;

  // Function to pick an image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImage != null) {
      setState(() {
        _errorMessage = "You can only attach one image.";
      });
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _errorMessage = null;
      });
    }
  }

  // Function to remove the selected image
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  // Function to upload the image to Firebase Storage and return the URL
  Future<String?> _uploadImage(File imageFile) async {
    try {
      String imageId = const Uuid().v4();
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('bug_reports/images/$imageId.jpg');
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  // Function to save the bug report to Firestore
  Future<void> _saveBugReport(
      String email, String description, String steps, String? imageUrl) async {
    try {
      await FirebaseFirestore.instance.collection('bug_reports').add({
        'email': email,
        'description': description,
        'steps': steps,
        'imageUrl': imageUrl ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error saving bug report: $e";
      });
    }
  }

  // Validation and submission function
  Future<void> _validateAndSubmitBugReport() async {
    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    String email = _emailController.text.trim();
    String description = _bugDescriptionController.text.trim();
    String steps = _stepsController.text.trim();

    if (description.isEmpty) {
      setState(() {
        _errorMessage = "Bug description is required.";
        _isSubmitting = false;
      });
      return;
    }

    if (steps.isEmpty) {
      setState(() {
        _errorMessage = "Steps to reproduce the issue are required.";
        _isSubmitting = false;
      });
      return;
    }

    if (description.length > 500) {
      setState(() {
        _errorMessage = "Bug description must be 500 characters or less.";
        _isSubmitting = false;
      });
      return;
    }

    try {
      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      // Save bug report to Firestore
      await _saveBugReport(email, description, steps, imageUrl);

      // Show thank-you dialog on success
      _showThankYouDialog();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to submit bug report. Please try again.";
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Thank You Dialog
  void _showThankYouDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
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
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your bug report has been submitted. We appreciate your help in making our app better!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  Navigator.pushNamed(context, '/dashboard'); // Go to dashboard
                },
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
        title: const Text(
          "Report a Bug",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Email Address (optional)",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              maxLength: 254,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: "Enter your email address",
                counterText: "",
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Bug Description",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bugDescriptionController,
              maxLength: 500,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: "Describe the bug in detail...",
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Steps to Reproduce",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _stepsController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: "Provide the steps to reproduce the issue...",
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Attach a Screenshot (optional)",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              "Note: Only one image can be attached.",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Take Photo"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF2275AA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Choose from Gallery"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF2275AA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              child: Image.file(_selectedImage!),
                            );
                          },
                        );
                      },
                      child: Center(
                        child: Image.file(
                          _selectedImage!,
                          height: 200,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _removeImage,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Remove Image"),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _validateAndSubmitBugReport,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF2275AA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("SUBMIT BUG REPORT"),
                  ),
          ],
        ),
      ),
    );
  }
}
