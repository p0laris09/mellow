import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mellow/screens/ProfileScreen/ViewProfile/view_profile.dart';

class SearchFriends extends StatefulWidget {
  const SearchFriends({Key? key}) : super(key: key);

  @override
  State<SearchFriends> createState() => _SearchFriendsState();
}

class _SearchFriendsState extends State<SearchFriends> {
  List<Map<String, dynamic>> filteredUsers = [];
  List<Map<String, dynamic>> allUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch users from Firestore
  }

  Future<void> _fetchUsers() async {
    // Check if user is authenticated
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("User is not authenticated");
      return; // Exit if not authenticated
    }

    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      print("Number of documents fetched: ${querySnapshot.docs.length}");

      final users = querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Construct the name based on first, middle, and last names
        final firstName = data['firstName'] ?? 'Unnamed';
        final middleName = data['middleName'] ?? '';
        final lastName = data['lastName'] ?? '';

        // Format the name as required: "First MiddleInitial Last"
        String formattedName = '$firstName';
        if (middleName.isNotEmpty) {
          formattedName += ' ${middleName[0]}.';
        }
        if (lastName.isNotEmpty) {
          formattedName += ' $lastName';
        }

        // Return the user data with an additional userId field for filtering
        return {
          'userId': doc.id, // Store the document ID for reference
          'name': formattedName,
          'profileImageUrl':
              data['profileImageUrl'] ?? 'assets/img/default_profile.png',
        };
      }).toList();

      // Filter out the current user's data
      final filteredUsers =
          users.where((user) => user['userId'] != currentUser.uid).toList();

      setState(() {
        allUsers = users;
        this.filteredUsers =
            filteredUsers; // Start with all users excluding the current user
      });

      print("Fetched users: $allUsers");
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  void _filterUsers(String query) {
    setState(() {
      filteredUsers = allUsers.where((user) {
        final name = user['name']!.toLowerCase();
        final searchLower = query.toLowerCase();
        return name.contains(searchLower);
      }).toList();

      // Sort users to show matching results at the top
      filteredUsers.sort((a, b) {
        final aName = a['name']!.toLowerCase();
        final bName = b['name']!.toLowerCase();
        if (aName.startsWith(query.toLowerCase()) &&
            !bName.startsWith(query.toLowerCase())) {
          return -1;
        } else if (!aName.startsWith(query.toLowerCase()) &&
            bName.startsWith(query.toLowerCase())) {
          return 1;
        }
        return 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3C3C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Align(
          alignment: Alignment.center,
          child: Container(
            height: 35,
            width: MediaQuery.of(context).size.width *
                0.75, // Adjust width as needed
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B4B4B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              onChanged: _filterUsers,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                hintText: 'Search friends',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
      body: filteredUsers.isEmpty
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loading indicator while fetching
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user['profileImageUrl']!
                              .startsWith('http')
                          ? NetworkImage(user['profileImageUrl']!)
                          : const AssetImage('assets/img/default_profile.png')
                              as ImageProvider,
                    ),
                    title: Text(
                      user['name']!,
                      style: const TextStyle(color: Colors.black),
                    ),
                    onTap: () {
                      // Navigate to ProfileDetailPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ViewProfile(userId: user['userId']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
