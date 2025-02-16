import 'package:flutter/material.dart';

class AdminBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const AdminBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFFF4F6F8),
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey[400],
      showSelectedLabels: false,
      currentIndex: selectedIndex,
      onTap: onItemTapped, // Tapping will notify the DashboardScreen
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bug_report),
          label: 'Bugs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.mail),
          label: 'Feedback',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Analytics',
        ),
      ],
    );
  }
}
