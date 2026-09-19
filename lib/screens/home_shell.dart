import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import 'mock_screen.dart';
import 'notebook_screen.dart';
import 'practice_screen.dart';
import 'profile_screen.dart';

/// Root scaffold holding the 4 primary tabs behind a persistent bottom nav.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _screens = const [
    PracticeScreen(),
    MockScreen(),
    NotebookScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i != _index) sfx.tap();
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'វិញ្ញាសា',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            label: 'ប្រឡងសាកល្បង',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_rounded),
            label: 'សៀវភៅកត់ត្រា',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'គណនី',
          ),
        ],
      ),
    );
  }
}
