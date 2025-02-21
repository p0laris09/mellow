import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SpaceActivityFeedScreen extends StatefulWidget {
  final String spaceId;

  const SpaceActivityFeedScreen({super.key, required this.spaceId});

  @override
  State<SpaceActivityFeedScreen> createState() =>
      _SpaceActivityFeedScreenState();
}

class _SpaceActivityFeedScreenState extends State<SpaceActivityFeedScreen> {
  late Stream<QuerySnapshot> activitiesStream;

  @override
  void initState() {
    super.initState();
    activitiesStream = FirebaseFirestore.instance
        .collection('activities')
        .where('spaceId', isEqualTo: widget.spaceId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          'Activity Feed',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: activitiesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No activities available",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            final activities = snapshot.data!.docs.toList();
            return ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activityDoc = activities[index];
                final activity = activityDoc.data() as Map<String, dynamic>;
                final createdBy = activity['createdBy'] as String;
                final taskName = activity['taskName'] as String;
                final assignedToUids = activity['assignedTo'] as List<dynamic>;
                final timestamp = (activity['timestamp'] as Timestamp).toDate();
                final timeAgo = timeAgoSinceDate(timestamp);

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(createdBy)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    final userName =
                        "${userData['firstName']} ${userData['lastName']}";

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .where(FieldPath.documentId, whereIn: assignedToUids)
                          .get(),
                      builder: (context, assignedToSnapshot) {
                        if (!assignedToSnapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final assignedToNames =
                            assignedToSnapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return "${data['firstName']} ${data['lastName']}";
                        }).join(", ");

                        return ActivityItem(
                          userName: userName,
                          description:
                              "$userName created task $taskName and assigned it to $assignedToNames",
                          timestamp: timeAgo,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  String timeAgoSinceDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 8) {
      return DateFormat('yyyy-MM-dd').format(date);
    } else if ((difference.inDays / 7).floor() >= 1) {
      return '1 week ago';
    } else if (difference.inDays >= 2) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays >= 1) {
      return '1 day ago';
    } else if (difference.inHours >= 2) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours >= 1) {
      return '1 hour ago';
    } else if (difference.inMinutes >= 2) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inMinutes >= 1) {
      return '1 minute ago';
    } else if (difference.inSeconds >= 3) {
      return '${difference.inSeconds} seconds ago';
    } else {
      return 'just now';
    }
  }
}

class ActivityItem extends StatelessWidget {
  final String userName;
  final String description;
  final String timestamp;

  const ActivityItem({
    super.key,
    required this.userName,
    required this.description,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.event_note, color: Color(0xFF2275AA)),
        title: Text(description,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Created $timestamp"),
      ),
    );
  }
}
