import 'package:flutter/material.dart';

import 'package:darwin_walk/screens/home_screen.dart';
import 'package:darwin_walk/screens/ready_routes_screen.dart';
import 'package:darwin_walk/screens/jurassic_screen.dart';
import 'package:darwin_walk/screens/profile_screen.dart';
import '../widgets/bottom_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const HomeScreen(),
    const ReadyRoutesScreen(),
    const JurassicScreen(),
    const ProfileScreen(),
  ];

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // или любой другой цвет фона
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: DarwinBottomBar(
        currentIndex: _currentIndex,
        onHomeTapped: (_) => _onTabSelected(0),
        onInfoTapped: (_) => _onTabSelected(1),
      ),
    );
  }
}
