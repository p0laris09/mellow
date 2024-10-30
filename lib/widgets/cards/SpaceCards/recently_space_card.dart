import 'package:flutter/material.dart';

class RecentSpaceCard extends StatelessWidget {
  final String spaceName;
  final String description;
  final String date;
  final List<String> memberImages; // List of member image URLs

  const RecentSpaceCard({
    required this.spaceName,
    required this.description,
    required this.date,
    required this.memberImages, // Receive member images
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 100, // Adjusted height to match the compact design
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3C3C), // Background color to match the card
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
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                date,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              _buildAvatarsRow(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarsRow() {
    // Show only the first 3 members
    return Row(
      children: memberImages.take(3).map((imageUrl) {
        return Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: CircleAvatar(
            radius: 10,
            backgroundImage: NetworkImage(imageUrl), // Use image URL here
            backgroundColor: Colors.white,
          ),
        );
      }).toList(),
    );
  }
}
