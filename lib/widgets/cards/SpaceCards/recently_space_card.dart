import 'package:flutter/material.dart';

class RecentSpaceCard extends StatelessWidget {
  final String spaceName;
  final String description;
  final String date;

  const RecentSpaceCard({
    required this.spaceName,
    required this.description,
    required this.date,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 150,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color:
            const Color(0xFF2C3C3C), // Similar color to match the recent card
        borderRadius: BorderRadius.circular(16.0),
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
          const SizedBox(height: 8),
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
    return Row(
      children: const [
        CircleAvatar(
          backgroundColor: Colors.white,
          radius: 12,
          child: Icon(
            Icons.person,
            size: 12,
            color: Color(0xFF2C3C3C),
          ),
        ),
        SizedBox(width: 4),
        CircleAvatar(
          backgroundColor: Colors.white,
          radius: 12,
          child: Icon(
            Icons.person,
            size: 12,
            color: Color(0xFF2C3C3C),
          ),
        ),
        SizedBox(width: 4),
        CircleAvatar(
          backgroundColor: Colors.white,
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
