import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SpaceSettingScreen extends StatefulWidget {
  final String spaceId;
  final String spaceName;
  final String description;

  const SpaceSettingScreen({
    super.key,
    required this.spaceId,
    required this.spaceName,
    required this.description,
  });

  @override
  State<SpaceSettingScreen> createState() => _SpaceSettingScreenState();
}

class _SpaceSettingScreenState extends State<SpaceSettingScreen> {
  String spaceName = '';
  String description = '';
  List<String> members = [];
  String collabGoal = '';

  @override
  void initState() {
    super.initState();
    _loadSpaceData();
  }

  void _loadSpaceData() async {
    try {
      final spaceDoc = await FirebaseFirestore.instance
          .collection('spaces')
          .doc(widget.spaceId)
          .get();

      if (spaceDoc.exists) {
        final spaceData = spaceDoc.data() as Map<String, dynamic>;
        List<String> memberUids = List<String>.from(spaceData['members'] ?? []);
        List<String> memberNames = [];

        for (String uid in memberUids) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            String firstName = userData['firstName'] ?? '';
            String middleName = userData['middleName'] ?? '';
            String lastName = userData['lastName'] ?? '';
            String fullName =
                '$firstName ${middleName.isNotEmpty ? middleName[0] + '. ' : ''}$lastName';
            memberNames.add(fullName);
          }
        }

        setState(() {
          spaceName = spaceData['name'] ?? 'No name';
          description = spaceData['description'] ?? 'No description';
          members = memberNames;
          collabGoal = spaceData['collabGoal'] ?? 'No collaboration goal';
        });
      } else {
        print("Space document does not exist");
      }
    } catch (e) {
      print("Error loading space data: $e");
    }
  }

  // ✅ Add a new member
  void _addMember() async {
    TextEditingController memberController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Member"),
        content: TextField(
          controller: memberController,
          decoration: const InputDecoration(hintText: "Enter member name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              String newMember = memberController.text.trim();
              if (newMember.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance
                      .collection('spaces')
                      .doc(widget.spaceId)
                      .update({
                    'members': FieldValue.arrayUnion([newMember]),
                  });
                  setState(() {
                    members.add(newMember);
                  });
                  Navigator.pop(context);
                } catch (e) {
                  print("Error adding member: $e");
                }
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // ✅ Delete Space
  void _deleteSpace() async {
    bool confirmDelete = await _showDeleteConfirmationDialog();
    if (confirmDelete) {
      try {
        await FirebaseFirestore.instance
            .collection('spaces')
            .doc(widget.spaceId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Space deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting space: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Delete Confirmation Dialog
  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Space',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Are you sure you want to delete this space? This action cannot be undone.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          'Space Settings',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard(
              icon: Icons.space_dashboard_rounded,
              label: 'Space Name',
              value: spaceName,
            ),
            _buildDetailCard(
              icon: Icons.description_rounded,
              label: 'Description',
              value: description,
            ),
            const SizedBox(height: 10),
            const Text(
              'Members',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            members.isEmpty
                ? const Text('No members added yet.')
                : Expanded(
                    child: ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(members[index]),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _addMember,
              icon: const Icon(Icons.add),
              label: const Text('Add Member'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: _deleteSpace,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 5,
          ),
          child: const Text(
            'DELETE SPACE',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// ✅ Detail Card Widget
Widget _buildDetailCard({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value.isNotEmpty ? value : 'Not available',
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    ),
  );
}
