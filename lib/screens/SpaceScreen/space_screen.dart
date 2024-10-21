import 'package:flutter/material.dart';
import 'package:mellow/widgets/cards/SpaceCards/recently_space_card.dart';
import 'package:mellow/widgets/cards/SpaceCards/space_card.dart';

class SpaceScreen extends StatelessWidget {
  const SpaceScreen({super.key});

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
                children: const [
                  // Using SpaceCard instead of _buildTaskCard
                  SpaceCard(
                    spaceName: 'Elective 3',
                    description: '2/10 Task Finished',
                    date: 'October 10, 2023',
                  ),
                  SizedBox(height: 8),
                  SpaceCard(
                    spaceName: 'Elective 4',
                    description: '5/10 Task Finished',
                    date: 'October 15, 2023',
                  ),
                  SizedBox(height: 8),
                  SpaceCard(
                    spaceName: 'Thesis 1',
                    description: '5/10 Task Finished',
                    date: 'November 1, 2023',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight, // Align button to the right
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add,
                    color: Colors.white), // Change icon color to white
                label: const Text(
                  'Create New Space',
                  style: TextStyle(
                      color: Colors.white), // Change text color to white
                ),
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
        children: const [
          // Using RecentSpaceCard instead of _buildRecentlyOpenedCard
          RecentSpaceCard(
            spaceName: 'Thesis 1',
            description: 'Chapter 1-5 Making',
            date: 'September 18, 2024',
          ),
          SizedBox(width: 8),
          RecentSpaceCard(
            spaceName: 'Project 2',
            description: 'Front-End Development',
            date: 'October 20, 2023',
          ),
        ],
      ),
    );
  }
}
