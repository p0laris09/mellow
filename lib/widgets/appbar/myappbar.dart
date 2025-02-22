import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mellow/provider/ProfileImageProvider/profile_image_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;

  const MyAppBar({super.key, required this.selectedIndex});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final profileImageProvider = Provider.of<ProfileImageProvider>(context);

    // Fetch the profile image URL if not already fetched
    if (profileImageProvider.profileImageUrl == null) {
      profileImageProvider.fetchProfileImage(user);
    }

    return AppBar(
      backgroundColor: const Color(0xFFF4F6F8),
      leadingWidth: 170,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Image.asset(
              'assets/img/logo.png',
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'MELLOW',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
      title: const Text(''),
      actions: [
        if (selectedIndex != 1) // Hide the icon when on TaskManagementScreen
          IconButton(
            onPressed: () {
              if (selectedIndex == 4) {
                // Navigate to messages screen when selectedIndex is 4
                Navigator.pushNamed(context, '/messages');
              } else {
                // Navigate to task creation screen for other cases
                Navigator.pushNamed(context, '/taskCreation');
              }
            },
            icon: Icon(
              selectedIndex == 4 ? Icons.message : Icons.add_box,
            ),
          ),
        if (selectedIndex == 1)
          IconButton(
            onPressed: () {
              if (selectedIndex == 1) {
                Navigator.pushNamed(context, '/taskhistory');
              }
            },
            icon: Icon(selectedIndex == 1 ? Icons.task_alt : Icons.task_alt),
          ),
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/notification');
          },
          icon: const Icon(Icons.notifications),
        ),
        const SizedBox(width: 7.5),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/settingsdrawer');
          },
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white,
            backgroundImage: profileImageProvider.profileImageUrl != null
                ? NetworkImage(profileImageProvider.profileImageUrl!)
                : AssetImage('assets/img/default_profile.png') as ImageProvider,
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
