import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:mellow/screens/SpaceScreen/ViewSpaceScreen/view_space.dart'; // Import ViewSpaceScreen

class RecentSpaceCard extends StatelessWidget {
  final String spaceName;
  final String description;
  final String date;
  final String spaceId; // Added spaceId parameter

  const RecentSpaceCard({
    required this.spaceName,
    required this.description,
    required this.date,
    required this.spaceId, // Add spaceId to constructor
    super.key,
  });

  // Method to update the lastOpened field in Firestore
  Future<void> updateLastOpened(String spaceId) async {
    try {
      // Get current time and day
      DateTime now = DateTime.now();
      String formattedDate =
          "${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}:${now.second}"; // Example: 2024-11-21 14:30:00

      // Update Firestore document with the current time in the lastOpened field
      await FirebaseFirestore.instance
          .collection('spaces')
          .doc(spaceId)
          .update({
        'lastOpened': formattedDate,
      });
    } catch (e) {
      print("Error updating lastOpened field: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Update the lastOpened field in Firestore before navigating
        updateLastOpened(spaceId);

        // Navigate to the ViewSpaceScreen and pass the required parameters
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewSpace(
              spaceId: spaceId,
              spaceName: spaceName, // Pass spaceName
              description: description, // Pass description
              date: date, // Pass date
            ),
          ),
        );
      },
      child: Container(
        width: 250,
        height: 100, // Adjusted height to match the compact design
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF2275AA), // Background color to match the card
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spaceName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Limiting the description to two lines and adding ellipsis for overflow
            Text(
              description,
              maxLines: 2, // Limit to 2 lines
              overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              date,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
