import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(''),
      actions: [
        //For notifications
        IconButton(
          onPressed: () {
            // Handle person icon press
          },
          icon: const Icon(Icons.notifications),
        ),

        //For Messages
        IconButton(
          onPressed: () {
            // Handle person icon press
          },
          icon: const Icon(Icons.message_rounded),
        ),
      ],
    );
  }
}
