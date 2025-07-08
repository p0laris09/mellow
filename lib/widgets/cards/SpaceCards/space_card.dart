import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:mellow/screens/SpaceScreen/ViewSpaceScreen/view_space.dart';

class SpaceCard extends StatelessWidget {
  final String spaceId; // Add spaceId (UID) to uniquely identify the space
  final String spaceName;
  final String description;
  final String date;

  const SpaceCard({
    required this.spaceId,
    required this.spaceName,
    required this.description,
    required this.date,
    super.key,
  });

  // Method to update the lastOpened field in Firestore
  Future<void> updateLastOpened(String spaceId) async {
    try {
      // Get the current time
      DateTime now = DateTime.now();

      // Update Firestore document with the current time as a Timestamp
      await FirebaseFirestore.instance
          .collection('spaces')
          .doc(spaceId)
          .update({
        'lastOpened': Timestamp.fromDate(now), // Store as Firestore Timestamp
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

        // Navigate to the ViewSpace screen and pass space details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewSpace(
              spaceId: spaceId, // Pass the spaceId to ViewSpace
              spaceName: spaceName,
              description: description,
              date: date,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF2275AA)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spaceName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3C3C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 1, // Ensures only one line is displayed
                    overflow:
                        TextOverflow.ellipsis, // Adds "..." if text overflows
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
