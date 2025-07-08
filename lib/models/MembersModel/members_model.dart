import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MembersModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, List<Map<String, String>>>>
      getFriendsAndSuggestedPeers() async {
    final user = _auth.currentUser;
    final uid = user?.uid;
    Map<String, List<Map<String, String>>> members = {
      'friends': [],
      'peers': []
    };

    if (uid == null) return members;

    // Fetch friends data from friends_db collection
    final friendsQuery = await FirebaseFirestore.instance
        .collection('friends_db')
        .doc(uid)
        .collection('friends')
        .get();

    if (friendsQuery.docs.isNotEmpty) {
      members['friends'] = await Future.wait(friendsQuery.docs.map((doc) async {
        final friendId =
            doc['friendId']; // Get the friend's ID from the friendId field
        final friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .get();

        if (friendDoc.exists) {
          final friendData = friendDoc.data() as Map<String, dynamic>;
          String fullName =
              "${friendData['firstName']} ${friendData['middleName']?.isNotEmpty == true ? friendData['middleName'][0] + '. ' : ''}${friendData['lastName']}";
          return {'uid': friendId, 'name': fullName};
        }
        return {'uid': friendId, 'name': 'Unknown User'};
      }));
    }

    // Fetch user data for suggested peers
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

    return members;
  }

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

  final Map<String, int> yearMapping = {
    '1st Year': 1,
    '2nd Year': 2,
    '3rd Year': 3,
    '4th Year': 4,
    '5th Year': 5
  };

  final Map<String, int> programMapping = {
    'Bachelor of Science in Office Administration': 1,
    'Bachelor of Science in Entrepreneurial Management': 2,
    'Bachelor of Science in Financial Management': 3,
    'Bachelor of Science in Business Administration major in Marketing Management':
        4,
    'Bachelor of Science in Business Administration major in Human Resource Development Management':
        5,
    'Bachelor of Science in Business Administration major in Supply Management':
        6,
    'Bachelor of Science in Business Administration major in Building and Property Management':
        7,
    'Associate in Sales Management': 8,
    'Associate in Office Management Technology': 9,
    'Associate in Entrepreneurship': 10,
    'Associate in Supply Management': 11,
    'Associate in Building and Property Management': 12,
    'Bachelor of Arts in Political Science Major in Local Government Administration':
        13,
    'Bachelor in Automotive Technology': 14,
    'Bachelor in Industrial Facilities Technology Management': 15,
    'Bachelor of Science in Business Administration Major in Human Resource Development Management':
        16,
    'Bachelor of Science in Entrepreneurship': 17,
    'Certificate in Barangay Governance': 18,
    'Certificate in Katarungang Pambarangay and Alternative Dispute Resolution':
        19,
    'Diploma in Development Management and Governance': 20,
    'Master of Arts in Education (Admin & Supervision / Guidance and Counselling)':
        21,
    'Master of Arts in Innovative Education (various majors including Biology, Business Ed, etc.)':
        22,
    'Master of Arts in Special Education (Autism & Mental Retardism / Early Childhood Ed)':
        23,
    'Master of Arts in Nursing': 24,
    'Master in Business Administration (Building Property Management / Entrepreneurship / Healthcare Mgmt)':
        25,
    'Master in Development Management and Governance': 26,
    'Master in Public Administration (+ Major in Local Governance)': 27,
    'Master of Science in Radiologic Technology': 28,
    'Doctor of Education (Innovative Educational Mgmt)': 29,
    'Doctor of Philosophy in Special Education': 30,
    'Doctor of Philosophy in Leadership (Business, Education, Public Mgmt Tracks)':
        31,
    'Doctor of Public Administration': 32,
    'Executive Doctorate in Leadership (Business, Education, Public Mgmt Tracks)':
        33,
    'Bachelor of Science in Information Technology (Information & Network Security)':
        34,
    'Bachelor of Science in Computer Science (Computational and Data Sciences)':
        35,
    'Bachelor of Science in Computer Science (Application Development)': 36,
    'Diploma in Application Development': 37,
    'Diploma in Computer Network Administration': 38,
    'Bachelor of Science in Civil Engineering': 39,
    'Bachelor of Science in Building Technology Management': 40,
    'Bachelor of Science in Electrical Technology': 41,
    'Bachelor of Science in Electronics and Telecommunication Technology': 42,
    'Diploma in Electrical Technology': 43,
    'Diploma in Industrial Facilities Technology': 44,
    'Diploma in Industrial Facilities Technology Major in Service Mechanics':
        45,
    'Associate in Electronics Technology': 46,
    'Certificate in Building Technology Management': 47,
    'Bachelor of Arts in Political Science major in Paralegal Studies': 48,
    'Bachelor of Arts in Political Science major in Policy Management': 49,
    'Bachelor of Arts in Political Science major in Local Government Administration':
        50,
    'Bachelor of Science in Exercise and Sports Science Major in Sports and Fitness Management':
        51,
    'Bachelor of Elementary Education': 52,
    'Bachelor of Secondary Education Major in English': 53,
    'Bachelor of Secondary Education Major in Mathematics': 54,
    'Bachelor of Secondary Education Major in Social Studies': 55,
    'Bachelor of Science in Hospitality Management': 56,
    'Bachelor of Science in Tourism Management': 57,
    'Associate in Hospitality Management': 58,
    'BA Multimedia Arts (Animation Specialization)': 59,
    'BA Multimedia Arts (Film Specialization)': 60,
    'BA Communication': 61,
    'Associate in Customer Service Communication': 62,
    'Bachelor of Science in Accountancy (BSA)': 63,
    'Bachelor of Science in Management Accounting (BSMA)': 64,
    'Bachelor of Science in Pharmacy': 65,
    'Associate of Applied Science in Pharmacy Technology': 66,
    'Diploma in Pharmaceutical Marketing': 67,
    'Bachelor of Science in Nursing': 68,
    'Bachelor of Science in Psychology': 69,
    'Bachelor of Science in Social Work (BSSW)': 70,
    'Automotive Servicing': 71,
    'Computer System Servicing': 72,
    'Electrical Installation': 73,
    'Food and Beverage Service': 74,
    'Fiber Optic Technician': 75,
    'Ref and Air-Con Servicing': 76,
    'Welding and Fabrication': 77,
    'HWMS – Hilot Wellness Massage Specialist': 78,
    'MMSPS – Manual Machine Shop Production Specialist': 79,
    'Juris Doctor with Thesis': 80,
    'Technical, Vocational, Livelihood Track': 81,
    'Arts and Design Track': 82,
    'Sports Track': 83,
  };

  final Map<String, int> collegeMapping = {
    'College of Business and Financial Sciences (CBFS)': 1,
    'College of Continuing, Advanced and Professional Studies (CCAPS)': 2,
    'College of Computing and Information Sciences (CCIS)': 3,
    'College of Construction Sciences and Engineering (CCSE)': 4,
    'College of Engineering Technology (CET)': 5,
    'College of Governance and Public Policy (CGPP)': 6,
    'College of Human Kinetics (CHK)': 7,
    'College of Innovative Teacher Education (CITE)': 8,
    'College of Tourism and Hospitality Management (CTHM)': 9,
    'Institute of Arts and Design (IAD)': 10,
    'Institute of Accountancy (IOA)': 11,
    'Institute of Pharmacy (IOP)': 12,
    'Institute of Nursing (ION)': 13,
    'Institute of Psychology (IOPsy)': 14,
    'Institute for Social Development and Nation Building (ISDNB)': 15,
    'Institute of Technical Education and Skills Training (ITEST)': 16,
    'School of Law (SOL)': 17,
    'Higher School ng UMak (CITE-HSU)': 18,
  };
}
