import 'package:flutter/material.dart';

class CollaborationScreen extends StatelessWidget {
  const CollaborationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Light background color
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shared Spaces',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3C3C),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recently Opened',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3C3C),
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentlyOpenedSection(),
            const SizedBox(height: 24), // Additional space before task cards
            Expanded(
              child: ListView(
                children: [
                  _buildTaskCard('Elective 3', '2/10 Task Finished'),
                  const SizedBox(height: 8),
                  _buildTaskCard('Elective 4', '5/10 Task Finished'),
                  const SizedBox(height: 8),
                  _buildTaskCard('Thesis 1', '5/10 Task Finished'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Create New Space'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3C3C),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyOpenedSection() {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildRecentlyOpenedCard(
            'Thesis 1',
            'Chapter 1-5 Making',
            'September 18, 2024',
          ),
          const SizedBox(width: 8),
          _buildRecentlyOpenedCard(
            'Project 2',
            'Front-End Development',
            'October 20, 2023',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyOpenedCard(String title, String subtitle, String date) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3C3C),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
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
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 12,
                child: Icon(
                  Icons.person,
                  size: 12,
                  color: const Color(0xFF2C3C3C),
                ),
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 12,
                child: Icon(
                  Icons.person,
                  size: 12,
                  color: const Color(0xFF2C3C3C),
                ),
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 12,
                child: Icon(
                  Icons.person,
                  size: 12,
                  color: const Color(0xFF2C3C3C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String title, String subtitle) {
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
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3C3C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[300],
                radius: 12,
                child: Icon(
                  Icons.person,
                  size: 12,
                  color: const Color(0xFF2C3C3C),
                ),
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                backgroundColor: Colors.grey[300],
                radius: 12,
                child: Icon(
                  Icons.person,
                  size: 12,
                  color: const Color(0xFF2C3C3C),
                ),
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                backgroundColor: Colors.grey[300],
                radius: 12,
                child: Icon(
                  Icons.person,
                  size: 12,
                  color: const Color(0xFF2C3C3C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
