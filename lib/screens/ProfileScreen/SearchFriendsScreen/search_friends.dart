import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mellow/screens/ProfileScreen/AcceptDeclineFriendRequest/add_friend.dart';
import 'package:mellow/screens/ProfileScreen/AcceptDeclineFriendRequest/friend_request.dart';
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
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("User is not authenticated");
      return;
    }

    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final users = querySnapshot.docs.map((doc) {
        final data = doc.data();
        final firstName = data['firstName'] ?? 'Unnamed';
        final middleName = data['middleName'] ?? '';
        final lastName = data['lastName'] ?? '';

        String formattedName = '$firstName';
        if (middleName.isNotEmpty) {
          formattedName += ' ${middleName[0]}.';
        }
        if (lastName.isNotEmpty) {
          formattedName += ' $lastName';
        }

        return {
          'userId': doc.id,
          'name': formattedName,
          'profileImageUrl':
              data['profileImageUrl'] ?? 'assets/img/default_profile.png',
        };
      }).toList();

      final filteredUsers =
          users.where((user) => user['userId'] != currentUser.uid).toList();

      setState(() {
        allUsers = users;
        this.filteredUsers = filteredUsers;
      });
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

  void _navigateToFriendPage(String selectedUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final outgoingRequestDoc = await FirebaseFirestore.instance
          .collection('friends_db')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(selectedUserId)
          .get();

      final incomingRequestDoc = await FirebaseFirestore.instance
          .collection('friends_db')
          .doc(selectedUserId)
          .collection('friends')
          .doc(currentUser.uid)
          .get();

      // Check for friend or request status
      String friendRequestStatus;
      String fromUserId = '';
      String toUserId = '';

      if (outgoingRequestDoc.exists) {
        friendRequestStatus = outgoingRequestDoc['status'];
        fromUserId = outgoingRequestDoc['fromUserId'];
        toUserId = outgoingRequestDoc['toUserId'];
      } else if (incomingRequestDoc.exists) {
        friendRequestStatus = incomingRequestDoc['status'];
        fromUserId = incomingRequestDoc['fromUserId'];
        toUserId = incomingRequestDoc['toUserId'];
      } else {
        friendRequestStatus = 'none';
      }

      Widget targetPage;

      if (friendRequestStatus == 'accepted') {
        targetPage = ViewProfile(userId: selectedUserId);
      } else if (friendRequestStatus == 'pending' &&
          fromUserId == currentUser.uid) {
        targetPage = AddFriend(userId: selectedUserId);
      } else if (friendRequestStatus == 'pending' &&
          toUserId == currentUser.uid) {
        targetPage = FriendRequest(userId: selectedUserId);
      } else {
        targetPage = AddFriend(userId: selectedUserId);
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetPage),
      );
    } catch (e) {
      if (e.toString().contains('unavailable')) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('Network Issue'),
            content: Text(
                'The service is currently unavailable. Please try again later.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        print('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2275AA),
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
            width: MediaQuery.of(context).size.width * 0.75,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3A5D73),
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
          ? const Center(child: CircularProgressIndicator())
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
                      _navigateToFriendPage(user['userId']);
                    },
                  ),
                );
              },
            ),
    );
  }
}
