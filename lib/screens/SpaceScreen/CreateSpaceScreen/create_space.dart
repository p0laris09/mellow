import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mellow/models/MembersModel/members_model.dart';

class CreateSpacePage extends StatefulWidget {
  const CreateSpacePage({super.key});

  @override
  State<CreateSpacePage> createState() => _CreateSpacePageState();
}

class _CreateSpacePageState extends State<CreateSpacePage> {
  final TextEditingController _spaceNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final MembersModel _membersModel = MembersModel();

  int _descriptionCharCount = 0;
  List<String> selectedMembers = []; // Storing UIDs instead of names
  Map<String, String> memberNamesMap = {}; // Map UID to name
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(() {
      setState(() {
        _descriptionCharCount = _descriptionController.text.length;
      });
    });
  }

  Future<void> showSelectMemberDialog(BuildContext context) async {
    final members = await _membersModel.getFriendsAndSuggestedPeers();
    final friends = members['friends']!;
    final peers = members['peers']!;

    // Creating a map of UID to Name
    final uidNameMap = <String, String>{};
    friends.forEach((friend) {
      uidNameMap[friend['uid']!] = friend['name'] ?? 'Unknown';
    });
    peers.forEach((peer) {
      uidNameMap[peer['uid']!] = peer['name'] ?? 'Unknown';
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2275AA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Center(
                child: const Text(
                  'Select Members',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              content: Center(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Friends',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      friends.isEmpty
                          ? const Text(
                              'You have no friends.',
                              style: TextStyle(color: Colors.red),
                            )
                          : Wrap(
                              spacing: 8,
                              children: friends.map((friend) {
                                bool isSelected =
                                    selectedMembers.contains(friend['uid']);
                                return ChoiceChip(
                                  label: Text(friend['name'] ?? 'Unknown'),
                                  selected: isSelected,
                                  selectedColor: Colors.green,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedMembers
                                            .add(friend['uid']!); // Add UID
                                      } else {
                                        selectedMembers.remove(
                                            friend['uid']); // Remove UID
                                      }
                                    });
                                  },
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  backgroundColor: Colors.white,
                                  selectedShadowColor: Colors.green,
                                  shadowColor: Colors.grey,
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 20),
                      const Text(
                        'Suggestions',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      peers.isEmpty
                          ? const Text(
                              'No peers to suggest',
                              style: TextStyle(color: Colors.red),
                            )
                          : Wrap(
                              spacing: 8,
                              children: peers.map((peer) {
                                bool isSelected =
                                    selectedMembers.contains(peer['uid']);
                                return ChoiceChip(
                                  label: Text(peer['name'] ?? 'Unknown'),
                                  selected: isSelected,
                                  selectedColor: Colors.green,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedMembers
                                            .add(peer['uid']!); // Add UID
                                      } else {
                                        selectedMembers
                                            .remove(peer['uid']); // Remove UID
                                      }
                                    });
                                  },
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  backgroundColor: Colors.white,
                                  selectedShadowColor: Colors.green,
                                  shadowColor: Colors.grey,
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Select'),
                  onPressed: () {
                    Navigator.of(context).pop(selectedMembers);
                    // Update the member names map with selected UIDs
                    setState(() {
                      memberNamesMap = uidNameMap;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((selectedMembers) {
      if (selectedMembers != null) {
        setState(() {
          this.selectedMembers = List<String>.from(selectedMembers);
        });
      }
    });
  }

  Future<void> _createSpace() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      // Handle unauthenticated state, e.g., prompt login
      return;
    }

    final uid = currentUser.uid;
    final spaceName = _spaceNameController.text.trim();
    final description = _descriptionController.text.trim();

    if (spaceName.isEmpty) {
      // Show error for empty space name
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Space name cannot be empty')),
      );
      return;
    }

    try {
      // Add the space to Firestore
      await FirebaseFirestore.instance.collection('spaces').add({
        'name': spaceName,
        'description': description,
        'createdBy': uid,
        'admin': uid,
        'members': [
          uid, // Include the creator's UID
          ...selectedMembers, // Include the selected members' UIDs
        ],
        'createdAt':
            FieldValue.serverTimestamp(), // server timestamp for consistency
        'dateCreated': DateTime.now(), // adds precise local date and time
        'lastOpened':
            FieldValue.serverTimestamp(), // Add the timestamp of creation
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Space created successfully')),
      );

      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      // Show error if creation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create space: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2275AA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Create New Space',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: TextField(
                controller: _spaceNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Space Name",
                  labelStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  border: UnderlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 45),
            Container(
              height: 810,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 325,
                    child: TextField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.black),
                      maxLines: 4,
                      inputFormatters: [LengthLimitingTextInputFormatter(250)],
                      decoration: InputDecoration(
                        labelText: "Description",
                        labelStyle: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        border: const UnderlineInputBorder(),
                        suffixText: "$_descriptionCharCount/250",
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    width: 325,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Members',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => showSelectMemberDialog(context),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFF2275AA),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Add Members'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: selectedMembers
                              .map((memberUid) => Chip(
                                    label: Text(
                                        memberNamesMap[memberUid] ?? 'Unknown'),
                                    deleteIcon: const Icon(Icons.close),
                                    onDeleted: () {
                                      setState(() {
                                        selectedMembers.remove(memberUid);
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Center(
                    child: ElevatedButton(
                      onPressed: _createSpace,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 20,
                        ),
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF2275AA),
                      ),
                      child: const Text('Create Space'),
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
