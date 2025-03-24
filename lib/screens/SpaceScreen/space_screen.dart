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
  List<Map<String, dynamic>> recentSpaces = [];
  bool _fabExpanded = false;
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchRecentSpaces();
  }

  Future<void> _fetchRecentSpaces() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;
      if (uid == null) return;

      final spacesQuery = await FirebaseFirestore.instance
          .collection('spaces')
          .where('members', arrayContains: uid)
          .get();

      final spacesWithAdminQuery = await FirebaseFirestore.instance
          .collection('spaces')
          .where('admin', isEqualTo: uid)
          .get();

      final allSpaces = [
        ...spacesQuery.docs.map((doc) => {...doc.data(), 'spaceId': doc.id}),
        ...spacesWithAdminQuery.docs
            .map((doc) => {...doc.data(), 'spaceId': doc.id}),
      ];

      allSpaces.sort((a, b) {
        final lastOpenedA =
            a['lastOpened'] != null && a['lastOpened'] is Timestamp
                ? (a['lastOpened'] as Timestamp).toDate()
                : DateTime.now();
        final lastOpenedB =
            b['lastOpened'] != null && b['lastOpened'] is Timestamp
                ? (b['lastOpened'] as Timestamp).toDate()
                : DateTime.now();
        return lastOpenedB.compareTo(lastOpenedA);
      });

      final mostRecentSpace = allSpaces.isNotEmpty ? allSpaces.first : null;

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

      setState(() {
        recentSpaces = mostRecentSpace != null
            ? [
                {
                  'spaceId': mostRecentSpace['spaceId'],
                  'spaceName': mostRecentSpace['name'] ?? 'Unnamed Space',
                  'admin': mostRecentSpace['admin'] ?? 'Unknown Admin',
                  'description': mostRecentSpace['description'] ??
                      'No description available',
                  'date': formattedDate,
                }
              ]
            : [];
      });
    } catch (e) {
      print('Error fetching recent spaces: $e');
    }
  }

  Widget _filterButton(String label) {
    bool isSelected = label == selectedFilter;
    return TextButton(
      onPressed: () {
        setState(() {
          selectedFilter = label;
          _filterSpaces();
        });
      },
      style: TextButton.styleFrom(
        backgroundColor:
            isSelected ? const Color(0xFF2275AA) : Colors.grey[300],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  void _filterSpaces() {
    // Example filtering logic:
    // Implement your filter functionality here
    switch (selectedFilter) {
      case 'All':
        // Show all spaces
        break;
      case 'Shared':
        // Filter for shared spaces
        break;
      case 'Collaboration Space':
        // Filter for collaboration spaces
        break;
      default:
        break;
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
              'Space and Collaboration',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3C3C),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _filterButton('All'),
                _filterButton('Shared'),
                _filterButton('Collaboration Space'),
              ],
            ),
            const SizedBox(height: 8),
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

                      Timestamp? createdAt = data['createdAt'] as Timestamp?;
                      DateTime date = createdAt?.toDate() ?? DateTime.now();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: SpaceCard(
                          spaceId: doc.id,
                          spaceName: data['name'] ?? 'Unnamed Space',
                          description: data['description'] ?? 'No description',
                          date: DateFormat('MMM d, yyyy').format(date),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    return Stack(
      children: [
        Align(
          alignment: Alignment
              .bottomRight, // Align the entire content to the bottom-right
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.end, // Align buttons to the right
            children: [
              if (_fabExpanded) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateSpacePage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor:
                          const Color(0xFF2275AA), // Set background color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text("Create Collaboration Space",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
              // Floating Action Button stays at the bottom-right and doesn't move when expanded
              Padding(
                padding: const EdgeInsets.only(
                    bottom:
                        16.0), // Add padding to space the FAB from the bottom
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _fabExpanded = !_fabExpanded;
                    });
                  },
                  backgroundColor:
                      const Color(0xFF2275AA), // Set background color of FAB
                  child: Icon(
                    _fabExpanded ? Icons.close : Icons.add,
                    color: Colors.white, // Set icon color to white
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentlyOpenedSection() {
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
            padding: const EdgeInsets.only(right: 8.0),
            child: RecentSpaceCard(
              spaceId: spaceData['spaceId'],
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
