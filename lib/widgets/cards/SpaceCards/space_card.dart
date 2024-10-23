import 'package:flutter/material.dart';

class SpaceCard extends StatelessWidget {
  final String spaceName;
  final String description;
  final String date;

  const SpaceCard({
    required this.spaceName,
    required this.description,
    required this.date,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white, // Match the task card background color
        borderRadius: BorderRadius.circular(12.0), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6.0,
            offset: const Offset(0, 2), // Soft shadow
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
          const SizedBox(width: 16),
          _buildAvatarsRow(),
        ],
      ),
    );
  }

  Widget _buildAvatarsRow() {
    return const Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey,
          radius: 12,
          child: Icon(
            Icons.person,
            size: 12,
            color: Color(0xFF2C3C3C),
          ),
        ),
        SizedBox(width: 4),
        CircleAvatar(
          backgroundColor: Colors.grey,
          radius: 12,
          child: Icon(
            Icons.person,
            size: 12,
            color: Color(0xFF2C3C3C),
          ),
        ),
        SizedBox(width: 4),
        CircleAvatar(
          backgroundColor: Colors.grey,
          radius: 12,
          child: Icon(
            Icons.person,
            size: 12,
            color: Color(0xFF2C3C3C),
          ),
        ),
      ],
    );
  }
}
