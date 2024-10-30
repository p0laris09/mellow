import 'package:flutter/material.dart';
import 'package:mellow/widgets/cards/SpaceCards/recently_space_card.dart';
import 'package:mellow/widgets/cards/SpaceCards/space_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpaceScreen extends StatefulWidget {
  const SpaceScreen({super.key});

  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<SpaceScreen> {
  List<Map<String, dynamic>> recentSpaces = [];

  Future<void> createSpace(
      String spaceName, String description, List<String> memberUids) async {
    final user = FirebaseAuth.instance.currentUser;
    final leaderUid = user?.uid ?? '';

    if (leaderUid.isEmpty) {
      throw Exception("User is not logged in");
    }

    final spaceData = {
      'spaceName': spaceName,
      'description': description,
      'dateCreated': FieldValue.serverTimestamp(),
      'leader': leaderUid,
      'members': [leaderUid, ...memberUids],
    };

    await FirebaseFirestore.instance.collection('spaces').add(spaceData);

    setState(() {
      recentSpaces.insert(
        0,
        {
          'spaceName': spaceName,
          'description': description,
          'date': DateTime.now().toString(),
          'memberImages': memberUids,
        },
      );
      if (recentSpaces.length > 5) recentSpaces.removeLast();
    });
  }

  // Function to get friends and suggestions
  Future<Map<String, List<Map<String, String>>>>
      _getFriendsAndSuggestions() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    Map<String, List<Map<String, String>>> members = {
      'friends': [],
      'peers': []
    };

    if (uid == null) return members;

    final friendsQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('friends')
        .get();

    if (friendsQuery.docs.isNotEmpty) {
      members['friends'] = friendsQuery.docs.map((doc) {
        String fullName =
            "${doc['firstName']} ${doc['middleName']?.isNotEmpty == true ? doc['middleName'][0] + '. ' : ''}${doc['lastName']}";
        return {'uid': doc.id, 'name': fullName};
      }).toList();
    }

    if (members['friends']!.isEmpty) {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data();

      if (userData != null) {
        final peerQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('college', isEqualTo: userData['college'])
            .where('year', isEqualTo: userData['year'])
            .where('program', isEqualTo: userData['program'])
            .where('section', isEqualTo: userData['section'])
            .get();

        members['peers'] = peerQuery.docs.map((doc) {
          String fullName =
              "${doc['firstName']} ${doc['middleName']?.isNotEmpty == true ? doc['middleName'][0] + '. ' : ''}${doc['lastName']}";
          return {'uid': doc.id, 'name': fullName};
        }).toList();
      }
    }

    return members;
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
                stream:
                    FirebaseFirestore.instance.collection('spaces').snapshots(),
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
                      return SpaceCard(
                        spaceName: data['spaceName'] ?? 'Unnamed Space',
                        description: data['description'] ?? 'No description',
                        date: (data['dateCreated'] as Timestamp)
                            .toDate()
                            .toString(),
                        memberIcons: List<String>.from(data['members'] ?? []),
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
                  _showSpaceCreationDialog(context);
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
    if (recentSpaces.isEmpty) {
      return const Center(child: Text('No space was recently opened.'));
    }

    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: recentSpaces.map((spaceData) {
          return RecentSpaceCard(
            spaceName: spaceData['spaceName'],
            description: spaceData['description'],
            date: spaceData['date'],
            memberImages: spaceData['memberImages'],
          );
        }).toList(),
      ),
    );
  }

  void _showSpaceCreationDialog(BuildContext context,
      [List<String> selectedMemberUids = const []]) {
    String spaceName = '';
    String spaceDetails = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Space'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Space Name'),
                    onChanged: (value) {
                      spaceName = value;
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    onChanged: (value) {
                      spaceDetails = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Members'),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.teal),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showMemberSelectionDialog(
                              context, selectedMemberUids);
                        },
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8.0,
                    children: selectedMemberUids.map((uid) {
                      return Chip(label: Text(uid));
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    createSpace(spaceName, spaceDetails, selectedMemberUids);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Create Space'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // In the _showMemberSelectionDialog method
  void _showMemberSelectionDialog(
      BuildContext context, List<String> initialSelectedUids) async {
    final members = await _getFriendsAndSuggestions();
    Set<String> selectedUids = {...initialSelectedUids};

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Members'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (members['friends']!
                      .isNotEmpty) // Use ! to assert it's not null
                    Column(
                      children: [
                        const Text('Friends'),
                        Wrap(
                          spacing: 8.0,
                          children: members['friends']!.map((friend) {
                            // Use ! to assert it's not null
                            bool isSelected =
                                selectedUids.contains(friend['uid']);
                            return ChoiceChip(
                              label: Text(friend['name']!),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedUids.add(friend['uid']!);
                                  } else {
                                    selectedUids.remove(friend['uid']!);
                                  }
                                });
                              },
                              selectedColor: Colors.green.withOpacity(0.7),
                            );
                          }).toList(),
                        ),
                      ],
                    )
                  else
                    const Text('No available Friends'),
                  const SizedBox(height: 16),
                  if (members['peers']!
                      .isNotEmpty) // Use ! to assert it's not null
                    Column(
                      children: [
                        const Text('Suggested Peers'),
                        Wrap(
                          spacing: 8.0,
                          children: members['peers']!.map((peer) {
                            // Use ! to assert it's not null
                            bool isSelected =
                                selectedUids.contains(peer['uid']);
                            return ChoiceChip(
                              label: Text(peer['name']!),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedUids.add(peer['uid']!);
                                  } else {
                                    selectedUids.remove(peer['uid']!);
                                  }
                                });
                              },
                              selectedColor: Colors.blue.withOpacity(0.7),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showSpaceCreationDialog(context, initialSelectedUids);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showSpaceCreationDialog(context, selectedUids.toList());
                  },
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
