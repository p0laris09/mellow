import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import 'package:flutter/material.dart';
import 'package:mellow/screens/AnalyticsScreen/analytics_screen.dart';
import 'package:mellow/screens/CollaborationScreen/collaboration_screen.dart';
import 'package:mellow/screens/TaskManagement/task_management.dart';
import 'package:mellow/widgets/appbar/myappbar.dart';
import 'package:mellow/widgets/bottomnav/mybottomnavbar.dart';
import 'package:mellow/widgets/cards/task_card.dart';
import 'package:mellow/widgets/drawer/mydrawer.dart';

class HomeScreen extends StatefulWidget {
  final String uid; // User ID passed as a parameter

  const HomeScreen({super.key, required this.uid});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Track the selected bottom navigation

  // Define a list of pages to show based on the selected index
  late final List<Widget> _pages = [
    HomeScreenContent(uid: widget.uid), // Pass UID to HomeScreenContent
    const TaskManagementScreen(),
    const CollaborationScreen(),
    const AnalyticsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(), // Use the existing MyAppBar widget
      drawer: const MyDrawer(), // Use the existing MyDrawer widget
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: MyBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

// Widget for the home page content
class HomeScreenContent extends StatelessWidget {
  final String uid; // Receive the user's UID

  const HomeScreenContent({super.key, required this.uid});

  // Fetch the user's first name from Firestore using the UID
  Future<String?> _getFirstName() async {
    final DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists) {
      return userDoc['firstName'] as String?; // Retrieve the firstName field
    }
    return null; // Return null if no such document exists
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getFirstName(),
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final String firstName = snapshot.data ?? 'User';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello $firstName!", // Display the fetched first name
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  "Have a nice day.",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTaskCards(),
                const SizedBox(height: 32),
                _buildProgressSection(),
              ],
            ),
          );
        } else {
          return const Center(child: Text("Hello User!"));
        }
      },
    );
  }

  Widget _buildTaskCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          TaskCard(
            project: "Project 1",
            title: "Front-End Development",
            date: "30 September 2024",
          ),
          const SizedBox(width: 16),
          TaskCard(
            project: "Project 2",
            title: "Back-End Development",
            date: "20 October 2024",
            opacity: 0.5, // Less visible
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Progress",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        _buildProgressTask("Design Changes", "2 Days ago"),
        const SizedBox(height: 8),
        _buildProgressTask("API Integration", "3 Days ago"),
      ],
    );
  }

  Widget _buildProgressTask(String taskName, String taskDate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.task, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                taskName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                taskDate,
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Handle options button
            },
          ),
        ],
      ),
    );
  }
}
