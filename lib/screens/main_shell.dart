import 'package:flutter/material.dart';
import 'package:darwin_walk/screens/home_screen.dart';
import 'package:darwin_walk/screens/ready_routes_screen.dart';
import 'package:darwin_walk/screens/statistics/statistics_screen.dart';
import 'package:darwin_walk/screens/profile_screen.dart';
import 'package:darwin_walk/data/daily_steps_repository.dart';
import '../widgets/bottom_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  
  late final List<Widget> _pages;
  Widget? _statisticsScreen;

  @override
  void initState() {
    super.initState();
    
    _pages = [
      const HomeScreen(),
      const ReadyRoutesScreen(),
      const SizedBox(), // временная заглушка для статистики
      const ProfileScreen(),
    ];
    
    _initStatisticsScreen();
  }

  Future<void> _initStatisticsScreen() async {
    final stepsRepo = await DailyStepsRepository.getInstance();
    if (mounted) {
      setState(() {
        _statisticsScreen = StatisticsScreen(repository: stepsRepo);
        _pages[2] = _statisticsScreen!;
      });
    }
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: DarwinBottomBar(
        currentIndex: _currentIndex,
        onHomeTapped: (_) => _onTabSelected(0),
        onInfoTapped: (_) => _onTabSelected(2),  // статистика
      ),
    );
  }
}