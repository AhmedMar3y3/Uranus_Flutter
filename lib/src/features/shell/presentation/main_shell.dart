import 'package:flutter/material.dart';

import '../../chat/presentation/screens/home_screen.dart';
import '../../friends/presentation/screens/friends_list_screen.dart';
import '../../profile/presentation/screens/my_profile_screen.dart';
import '../../search/presentation/screens/user_search_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    UserSearchScreen(),
    FriendsListScreen(),
    MyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() => _index = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.manage_search),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: 'Friends',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
