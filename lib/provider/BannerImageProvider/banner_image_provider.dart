import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class BannerImageProvider with ChangeNotifier {
  String _bannerImageUrl = '';

  String get bannerImageUrl => _bannerImageUrl;

  Future<void> fetchBannerImage(User user) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc['bannerImageUrl'] != null) {
          _bannerImageUrl = userDoc['bannerImageUrl'];
        } else {
          _bannerImageUrl = await _getDefaultBannerImageUrl();
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching banner image: $e');
    }
  }

  Future<String> _getDefaultBannerImageUrl() async {
    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('default_images/default_banner.png');
    return await storageRef.getDownloadURL();
  }
}
