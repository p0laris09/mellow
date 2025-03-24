import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mellow/screens/ProfileScreen/AcceptDeclineFriendRequest/friend_request.dart';
import 'package:mellow/screens/ProfileScreen/AcceptDeclineFriendRequest/add_friend.dart';
import 'package:mellow/screens/ProfileScreen/ViewProfile/view_profile.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> tasksNotifications = [];
  List<Map<String, dynamic>> spaceNotifications = [];
  List<Map<String, dynamic>> friendRequests = [];

  List<Map<String, dynamic>> displayedNotifications = [];
  String selectedFilter = 'All';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      // Fetch task notifications
      QuerySnapshot tasksSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('type', isEqualTo: 'task')
          .where('receiverId', isEqualTo: currentUserId)
          .get();
      tasksNotifications = tasksSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'title': doc['title'],
                'message': doc['message'],
                'timestamp': doc['timestamp'],
                'type': doc['type'],
                'receiverId': doc['receiverId'],
              })
          .toList();
      print('Tasks Notifications: $tasksNotifications');

      // Fetch space notifications
      QuerySnapshot spaceSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('type', isEqualTo: 'space')
          .where('receiverId', isEqualTo: currentUserId)
          .get();
      spaceNotifications = spaceSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'title': doc['title'],
                'message': doc['message'],
                'timestamp': doc['timestamp'],
                'type': doc['type'],
                'receiverId': doc['receiverId'],
              })
          .toList();
      print('Space Notifications: $spaceNotifications');

      // Fetch friend requests
      QuerySnapshot friendRequestsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('type', isEqualTo: 'friend request')
          .where('receiverId', isEqualTo: currentUserId)
          .get();
      friendRequests = await Future.wait(friendRequestsSnapshot.docs
          .map((doc) async {
            String fromUserId = (doc.data() != null &&
                    (doc.data() as Map<String, dynamic>)
                        .containsKey('fromUserId'))
                ? doc['fromUserId']
                : '';
            String profileImageUrl = '';
            if (fromUserId.isNotEmpty) {
              DocumentSnapshot userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(fromUserId)
                  .get();
              if (userDoc.exists) {
                final data = userDoc.data() as Map<String, dynamic>;
                profileImageUrl = data['profileImageUrl'] ?? '';
                if (profileImageUrl.isEmpty) {
                  try {
                    final defaultImageRef = FirebaseStorage.instance
                        .ref()
                        .child('default_images/default_profile.png');
                    profileImageUrl = await defaultImageRef.getDownloadURL();
                  } catch (e) {
                    profileImageUrl = 'assets/img/default_profile.png';
                  }
                }
              }
            }

            // Check if already friends
            bool isFriend = await _checkIfAlreadyFriends(fromUserId);

            if (isFriend) {
              // If already friends, remove the notification
              await FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(doc.id)
                  .delete();
              return null;
            } else {
              return {
                'id': doc.id,
                'fromUserId': fromUserId,
                'status': doc['status'],
                'title': doc['title'],
                'message': doc['message'],
                'timestamp': doc['timestamp'],
                'type': doc['type'],
                'receiverId': doc['receiverId'],
                'profileImageUrl': profileImageUrl,
              };
            }
          })
          .where((future) => future != null)
          .toList() as List<Future<Map<String, dynamic>>>);

      // Remove null entries from friendRequests
      friendRequests.removeWhere((request) => request == null);

      print('Friend Requests: $friendRequests');

      // Fetch tasks to check for overdue tasks
      QuerySnapshot tasksQuerySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: currentUserId)
          .get();

      for (var doc in tasksQuerySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        DateTime dueDate = (data['dueDate'] as Timestamp).toDate();
        String status = data['status'];

        if (dueDate.isBefore(DateTime.now()) && status != 'Finished') {
          // Add overdue task notification
          tasksNotifications.add({
            'id': doc.id,
            'title': 'Overdue Task',
            'message': 'Your task "${data['taskName']}" is overdue.',
            'timestamp': Timestamp.now(),
            'type': 'task',
            'receiverId': currentUserId,
          });
        }
      }

      _filterNotifications();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching notifications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> _checkIfAlreadyFriends(String fromUserId) async {
    QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
        .collection('friends')
        .where('userId1', isEqualTo: currentUserId)
        .where('userId2', isEqualTo: fromUserId)
        .get();

    if (friendsSnapshot.docs.isNotEmpty) {
      return true;
    }

    friendsSnapshot = await FirebaseFirestore.instance
        .collection('friends')
        .where('userId1', isEqualTo: fromUserId)
        .where('userId2', isEqualTo: currentUserId)
        .get();

    return friendsSnapshot.docs.isNotEmpty;
  }

  void _filterNotifications() {
    switch (selectedFilter) {
      case 'Tasks':
        displayedNotifications = tasksNotifications;
        break;
      case 'Space':
        displayedNotifications = spaceNotifications;
        break;
      case 'Friend Requests':
        displayedNotifications = friendRequests;
        break;
      default:
        displayedNotifications = [
          ...tasksNotifications,
          ...spaceNotifications,
          ...friendRequests
        ];
        break;
    }
  }

  Future<void> _acceptFriendRequest(String fromUserId) async {
    try {
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc('$fromUserId-$currentUserId')
          .update({'status': 'accepted'});

      await FirebaseFirestore.instance.collection('friends').add({
        'userId1': currentUserId,
        'userId2': fromUserId,
      });

      setState(() {
        friendRequests
            .removeWhere((request) => request['fromUserId'] == fromUserId);
        _filterNotifications();
      });
    } catch (e) {
      print('Error accepting friend request: $e');
    }
  }

  Future<void> _declineFriendRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(requestId)
          .delete();

      setState(() {
        friendRequests.removeWhere((request) => request['id'] == requestId);
        _filterNotifications();
      });
    } catch (e) {
      print('Error declining friend request: $e');
    }
  }

  void _navigateToProfileDetail(String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final outgoingRequestDoc = await FirebaseFirestore.instance
          .collection('friends_db')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(userId)
          .get();

      final incomingRequestDoc = await FirebaseFirestore.instance
          .collection('friends_db')
          .doc(userId)
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
        targetPage = ViewProfile(userId: userId);
      } else if (friendRequestStatus == 'pending' &&
          fromUserId == currentUser.uid) {
        targetPage = AddFriend(userId: userId);
      } else if (friendRequestStatus == 'pending' &&
          toUserId == currentUser.uid) {
        targetPage = FriendRequest(userId: userId);
      } else {
        targetPage = AddFriend(userId: userId);
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
            title: const Text('Network Issue'),
            content: const Text(
                'The service is currently unavailable. Please try again later.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
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
      backgroundColor: Colors.white, // Set background color to white
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
        centerTitle: true,
        title: const Text(
          'Notifications Page',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _filterButton('All'),
                        _filterButton('Tasks'),
                        _filterButton('Space'),
                        _filterButton('Friend Requests'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...displayedNotifications.map((notification) {
                      if (notification['type'] == 'friend request') {
                        return _buildFriendRequestCard(notification);
                      } else if (notification['type'] == 'task') {
                        return _buildTaskNotificationCard(notification);
                      } else if (notification['type'] == 'space') {
                        return _buildSpaceNotificationCard(notification);
                      } else {
                        return Container();
                      }
                    }).toList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _filterButton(String label) {
    return TextButton(
      onPressed: () {
        setState(() {
          selectedFilter = label;
          _filterNotifications();
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: selectedFilter == label
            ? const Color(0xFF2275AA)
            : Colors.grey[300],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selectedFilter == label ? Colors.white : Colors.black,
          fontWeight:
              selectedFilter == label ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildFriendRequestCard(Map<String, dynamic> notification) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      _navigateToProfileDetail(notification['fromUserId']),
                  child: CircleAvatar(
                    radius: 35, // Bigger avatar
                    backgroundImage: notification['profileImageUrl'].isNotEmpty
                        ? NetworkImage(notification['profileImageUrl'])
                        : const AssetImage('assets/img/default_profile.png')
                            as ImageProvider,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Friend Request',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${notification['fromUserId']} sent you a friend request!',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTimestamp(notification['timestamp']),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () =>
                      _acceptFriendRequest(notification['fromUserId']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Accept', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: () => _declineFriendRequest(notification['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Decline', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskNotificationCard(Map<String, dynamic> notification) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.shade400,
                  child: const Icon(Icons.task, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'] ?? 'Task Notification',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            notification['expanded'] =
                                !(notification['expanded'] ?? false);
                          });
                        },
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Text(
                            notification['message'] ?? 'No details provided',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines:
                                notification['expanded'] == true ? null : 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(notification['timestamp']),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('tasks')
                        .doc(notification['id'])
                        .update({'status': 'Finished'});

                    setState(() {
                      tasksNotifications.removeWhere(
                          (task) => task['id'] == notification['id']);
                      _filterNotifications();
                    });
                  } catch (e) {
                    print('Error marking task as done: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.task_alt, size: 18),
                label:
                    const Text('Mark as Done', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpaceNotificationCard(Map<String, dynamic> notification) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.deepPurple.shade400,
                  child: const Icon(Icons.group, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'] ?? 'Space Notification',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            notification['expanded'] =
                                !(notification['expanded'] ?? false);
                          });
                        },
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Text(
                            notification['message'] ?? 'No details provided',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines:
                                notification['expanded'] == true ? null : 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(notification['timestamp']),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Formats Firestore timestamp into a readable format
  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
