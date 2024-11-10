import 'package:flutter/material.dart';
import 'package:mellow/screens/SpaceScreen/CreateSpaceScreen/create_space.dart';
import 'package:mellow/widgets/cards/SpaceCards/recently_space_card.dart';
import 'package:mellow/widgets/cards/SpaceCards/space_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SpaceScreen extends StatefulWidget {
  const SpaceScreen({super.key});

  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<SpaceScreen> {
  List<Map<String, dynamic>> recentSpaces = []; // Define recentSpaces here

  @override
  void initState() {
    super.initState();
    _fetchRecentSpaces(); // Fetch recent spaces when the widget is initialized
  }

  Future<void> _fetchRecentSpaces() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;
      if (uid == null) return;

      // Fetch spaces where the user is either an admin or a member
      final spacesQuery = await FirebaseFirestore.instance
          .collection('spaces')
          .where('members', arrayContains: uid)
          .get();

      final spacesWithAdminQuery = await FirebaseFirestore.instance
          .collection('spaces')
          .where('admin', isEqualTo: uid)
          .get();

      // Combine both queries
      final allSpaces = [
        ...spacesQuery.docs.map((doc) => doc.data()),
        ...spacesWithAdminQuery.docs.map((doc) => doc.data())
      ];

      // Sort spaces by `lastOpened` timestamp, in descending order
      allSpaces.sort((a, b) {
        final lastOpenedA = a['lastOpened'] != null &&
                a['lastOpened'] is Timestamp
            ? (a['lastOpened'] as Timestamp).toDate()
            : DateTime
                .now(); // Default to current date if null or not a valid Timestamp
        final lastOpenedB = b['lastOpened'] != null &&
                b['lastOpened'] is Timestamp
            ? (b['lastOpened'] as Timestamp).toDate()
            : DateTime
                .now(); // Default to current date if null or not a valid Timestamp

        return lastOpenedB.compareTo(lastOpenedA);
      });

      // Get the most recent space
      final mostRecentSpace = allSpaces.isNotEmpty ? allSpaces.first : null;

      // Format the date of the most recent space
      String formattedDate = 'No recent spaces';
      if (mostRecentSpace != null) {
        DateTime? createdAt = mostRecentSpace['dateCreated'] != null &&
                mostRecentSpace['dateCreated'] is Timestamp
            ? (mostRecentSpace['dateCreated'] as Timestamp).toDate()
            : null;

        formattedDate = createdAt != null
            ? DateFormat('MMM d, yyyy').format(createdAt)
            : 'No date available';
      }

      // Update the recentSpaces state with the most recent space
      setState(() {
        recentSpaces = mostRecentSpace != null
            ? [
                {
                  'spaceName': mostRecentSpace['name'] ?? 'Unnamed Space',
                  'admin': mostRecentSpace['admin'] ?? 'Unknown Admin',
                  'description': mostRecentSpace['description'] ??
                      'No description available',
                  'date': formattedDate,
                }
              ]
            : []; // Empty list if no recent space
      });
    } catch (e) {
      // Handle errors if necessary
      print('Error fetching recent spaces: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
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
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('spaces')
                    .where('members',
                        arrayContains: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading spaces.'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No spaces available.'));
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;

                      // Check if 'createdAt' exists and is a valid Timestamp before casting
                      Timestamp? createdAt = data['createdAt'] as Timestamp?;
                      DateTime date = createdAt?.toDate() ??
                          DateTime.now(); // Default to current date if null

                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: 8.0), // Adding space around each card
                        child: SpaceCard(
                          spaceId: doc.id, // Pass the spaceId (document ID)
                          spaceName: data['name'] ?? 'Unnamed Space',
                          description: data['description'] ?? 'No description',
                          date: DateFormat('MMM d, yyyy')
                              .format(date), // Pass formatted date
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateSpacePage()),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Create New Space',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3C3C),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 12.0),
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
    // If there are no recent spaces, show a message
    if (recentSpaces.isEmpty) {
      return const Center(child: Text('No space was recently opened.'));
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recentSpaces.length,
        itemBuilder: (context, index) {
          final spaceData = recentSpaces[index];

          return Padding(
            padding:
                const EdgeInsets.only(right: 8.0), // Add space between cards
            child: RecentSpaceCard(
              spaceId: spaceData['spaceId'], // Pass the spaceId here
              spaceName: spaceData['spaceName'] ?? 'Unnamed Space',
              description:
                  spaceData['description'] ?? 'No description available',
              date: spaceData['date'] ?? 'No date available',
            ),
          );
        },
      ),
    );
  }
}
