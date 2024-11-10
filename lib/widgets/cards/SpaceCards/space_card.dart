import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
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
            const Icon(Icons.calendar_today, color: Color(0xFF2C3C3C)),
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
