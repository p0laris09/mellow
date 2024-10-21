import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileImageProvider with ChangeNotifier {
  String? _profileImageUrl;

  String? get profileImageUrl => _profileImageUrl;

  Future<void> fetchProfileImage(User? user) async {
    if (_profileImageUrl != null) {
      return; // Return early if the image URL is already fetched
    }

    try {
      if (user != null && user.photoURL != null) {
        _profileImageUrl = user.photoURL; // Use Firebase Auth URL
      } else {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .get();
        if (doc.exists) {
          _profileImageUrl =
              doc.data()?['profileImageUrl']; // Use Firestore URL
        }
      }
      if (_profileImageUrl == null) {
        // Fallback to default image if none is found
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('default_images/default_profile.png');
        _profileImageUrl = await storageRef.getDownloadURL();
      }
    } catch (e) {
      print("Error fetching profile image: $e");
    }

    notifyListeners(); // Notify listeners about the change
  }
}
