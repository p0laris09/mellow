import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mellow/screens/AnalyticsScreen/ViewAnalytics/view_analytics_screen.dart';

class WeightAnalyticsCard extends StatefulWidget {
  final double totalWeight;

  const WeightAnalyticsCard({Key? key, required this.totalWeight})
      : super(key: key);

  @override
  _WeightAnalyticsCardState createState() => _WeightAnalyticsCardState();
}

class _WeightAnalyticsCardState extends State<WeightAnalyticsCard> {
  double _totalWeight = 0.0; // Store total weight fetched from Firestore
  bool _isLoading = true; // Controls loading state

  @override
  void initState() {
    super.initState();

    // If totalWeight is 0 or invalid, fetch from Firestore
    if (widget.totalWeight == 0.0) {
      _fetchTotalWeight();
    } else {
      _totalWeight = widget.totalWeight; // Use passed totalWeight
      _isLoading = false; // Stop loading if totalWeight is passed
    }
  }

  /// Fetch total weight from Firestore
  Future<void> _fetchTotalWeight() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("User not logged in");

      // Query Firestore for tasks of the current user
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: uid)
          .get();

      double totalWeight = 0.0;

      // Calculate the total weight
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        totalWeight += (data['priority'] ?? 0) +
            (data['urgency'] ?? 0) +
            (data['importance'] ?? 0) +
            (data['complexity'] ?? 0);
      }

      setState(() {
        _totalWeight = totalWeight; // Update total weight
        _isLoading = false; // Stop loading
      });
    } catch (e) {
      setState(() {
        _totalWeight = 0.0; // Reset to 0 on error
        _isLoading = false; // Stop loading
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading weights: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ViewAnalyticsScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF2275AA),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          // Centering the content
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // Vertically center content
            crossAxisAlignment:
                CrossAxisAlignment.center, // Horizontally center content
            children: [
              const Text(
                'Total Weight',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _totalWeight.toStringAsFixed(
                          1), // Display fetched or passed totalWeight
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
