import 'package:flutter/material.dart';

class MyBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const MyBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFFF4F6F8), // This should set the color
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey[400],
      showSelectedLabels: false,
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Task Management',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: 'Collaboration Space',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Analytics',
        ),
      ],
    );
  }
}
