import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class MembersModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Define mappings for year, program, and college
  final Map<String, int> yearMapping = {
    '1st Year': 1,
    '2nd Year': 2,
    '3rd Year': 3,
    '4th Year': 4,
  };

  final Map<String, int> programMapping = {
    'Computer Science': 1,
    'Information Technology': 2,
    'Engineering': 3,
    'Business': 4,
    // Add more programs as needed
  };

  final Map<String, int> collegeMapping = {
    'College of Science': 1,
    'College of Engineering': 2,
    'College of Business': 3,
    'College of Arts': 4,
    // Add more colleges as needed
  };

  // K-means clustering algorithm
  List<List<Map<String, dynamic>>> kMeansClustering(
      List<Map<String, dynamic>> data, int k) {
    Random random = Random();
    List<List<Map<String, dynamic>>> clusters = List.generate(
      k,
      (_) => [],
    );
    List<Map<String, dynamic>> centroids = List.generate(
      k,
      (_) => data[random.nextInt(data.length)],
    );

    bool hasConverged = false;
    while (!hasConverged) {
      for (var cluster in clusters) {
        cluster.clear();
      }

      for (var item in data) {
        int closestCentroidIndex = _getClosestCentroid(item, centroids);
        clusters[closestCentroidIndex].add(item);
      }

      hasConverged = true;
      for (int i = 0; i < k; i++) {
        var newCentroid = _calculateCentroid(clusters[i]);
        if (_areDifferent(newCentroid, centroids[i])) {
          centroids[i] = newCentroid;
          hasConverged = false;
        }
      }
    }

    return clusters;
  }

  int _getClosestCentroid(
      Map<String, dynamic> item, List<Map<String, dynamic>> centroids) {
    double minDistance = double.infinity;
    int closestIndex = -1;

    for (int i = 0; i < centroids.length; i++) {
      double distance = _calculateDistance(item, centroids[i]);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  double _calculateDistance(
      Map<String, dynamic> item, Map<String, dynamic> centroid) {
    double distance = 0;

    // Check and calculate only for fields that exist
    if (item.containsKey('year') && centroid.containsKey('year')) {
      int itemYear = yearMapping[item['year']] ?? 0;
      int centroidYear = yearMapping[centroid['year']] ?? 0;
      distance += (itemYear - centroidYear).abs();
    }
    if (item.containsKey('program') && centroid.containsKey('program')) {
      int itemProgram = programMapping[item['program']] ?? 0;
      int centroidProgram = programMapping[centroid['program']] ?? 0;
      distance += (itemProgram - centroidProgram).abs();
    }
    if (item.containsKey('college') && centroid.containsKey('college')) {
      int itemCollege = collegeMapping[item['college']] ?? 0;
      int centroidCollege = collegeMapping[centroid['college']] ?? 0;
      distance += (itemCollege - centroidCollege).abs();
    }

    return distance;
  }

  Map<String, dynamic> _calculateCentroid(List<Map<String, dynamic>> cluster) {
    double totalYear = 0;
    double totalProgram = 0;
    double totalCollege = 0;
    int yearCount = 0;
    int programCount = 0;
    int collegeCount = 0;

    for (var item in cluster) {
      if (item.containsKey('year')) {
        totalYear += yearMapping[item['year']] ?? 0;
        yearCount++;
      }
      if (item.containsKey('program')) {
        totalProgram += programMapping[item['program']] ?? 0;
        programCount++;
      }
      if (item.containsKey('college')) {
        totalCollege += collegeMapping[item['college']] ?? 0;
        collegeCount++;
      }
    }

    // Calculate centroid only with available data
    return {
      if (yearCount > 0) 'year': totalYear / yearCount,
      if (programCount > 0) 'program': totalProgram / programCount,
      if (collegeCount > 0) 'college': totalCollege / collegeCount,
    };
  }

  bool _areDifferent(
      Map<String, dynamic> newCentroid, Map<String, dynamic> centroid) {
    bool different = false;
    if (newCentroid.containsKey('year') &&
        newCentroid['year'] != centroid['year']) different = true;
    if (newCentroid.containsKey('program') &&
        newCentroid['program'] != centroid['program']) different = true;
    if (newCentroid.containsKey('college') &&
        newCentroid['college'] != centroid['college']) different = true;
    return different;
  }

  Future<Map<String, List<Map<String, String>>>>
      getFriendsAndSuggestedPeers() async {
    final user = _auth.currentUser;
    final uid = user?.uid;
    Map<String, List<Map<String, String>>> members = {
      'friends': [],
      'peers': []
    };

    if (uid == null) return members;

    // Fetch friends data, excluding the current user from the results
    final friendsQuery = await FirebaseFirestore.instance
        .collection('friends')
        .doc(uid)
        .collection('friends')
        .get();

    if (friendsQuery.docs.isNotEmpty) {
      members['friends'] =
          friendsQuery.docs.where((doc) => doc.id != uid).map((doc) {
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
            .get();

        List<Map<String, dynamic>> peers =
            peerQuery.docs.where((doc) => doc.id != uid).map((doc) {
          return {
            'uid': doc.id,
            'name':
                "${doc['firstName']} ${doc['middleName']?.isNotEmpty == true ? doc['middleName'][0] + '. ' : ''}${doc['lastName']}",
            'year': doc['year'],
            'program': doc['program'],
            'college': doc['college'],
          };
        }).toList();

        // Apply K-means clustering to peers
        if (peers.isNotEmpty) {
          List<List<Map<String, dynamic>>> clusteredPeers =
              kMeansClustering(peers, 3); // Example with k=3 clusters
          members['peers'] = clusteredPeers.expand((x) => x).map((peer) {
            // Convert the peer map to a Map<String, String>
            return {
              'uid': peer['uid'] as String, // Ensure this is a String
              'name': peer['name'] as String, // Ensure this is a String
            };
          }).toList();
        }
      }
    }

    return members;
  }
}
