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

  Future<double> calculateProgress(String spaceId) async {
    try {
      // Fetch tasks associated with the spaceId
      QuerySnapshot taskSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('spaceId', isEqualTo: spaceId)
          .get();

      if (taskSnapshot.docs.isEmpty) {
        return 0.0; // No tasks, progress is 0%
      }

      int totalTasks = taskSnapshot.docs.length;
      int finishedTasks = taskSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data.containsKey('status') && data['status'] == 'Finished';
      }).length;

      // Calculate progress as a percentage
      return finishedTasks / totalTasks;
    } catch (e) {
      print("Error calculating progress: $e");
      return 0.0; // Return 0% progress in case of an error
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
      child: FutureBuilder<double>(
        future: calculateProgress(spaceId), // Fetch progress
        builder: (context, snapshot) {
          double progress = snapshot.data ?? 0.0;

          return Container(
            width: 250,
            height: 120, // Adjusted height to include progress bar
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color:
                  const Color(0xFF2275AA), // Background color to match the card
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
                  overflow:
                      TextOverflow.ellipsis, // Add ellipsis if text overflows
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                // Progress bar
                LinearProgressIndicator(
                  value: progress, // Progress value (0.0 to 1.0)
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.greenAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${(progress * 100).toStringAsFixed(1)}% completed",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
