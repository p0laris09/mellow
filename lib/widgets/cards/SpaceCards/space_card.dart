import 'package:flutter/material.dart';

class SpaceCard extends StatelessWidget {
  final String spaceName;
  final String description;
  final String date;
  final List<String> memberIcons;

  const SpaceCard({
    required this.spaceName,
    required this.description,
    required this.date,
    required this.memberIcons,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const SizedBox(width: 16),
          _buildAvatarsRow(),
        ],
      ),
    );
  }

  Widget _buildAvatarsRow() {
    return Row(
      children: memberIcons.take(3).map((iconUrl) {
        return Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: CircleAvatar(
            radius: 12,
            backgroundImage: NetworkImage(iconUrl),
            backgroundColor: Colors.grey,
          ),
        );
      }).toList(),
    );
  }
}
