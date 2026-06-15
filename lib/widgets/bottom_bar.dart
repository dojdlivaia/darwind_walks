// lib/widgets/bottom_bar.dart

import 'package:flutter/material.dart';
import 'package:darwin_walk/screens/ready_routes_screen.dart';
import 'package:darwin_walk/screens/statistics/statistics_screen.dart';
import 'package:darwin_walk/screens/profile_screen.dart';
import 'package:darwin_walk/screens/achievements/achievements_screen.dart';
import 'package:darwin_walk/data/daily_steps_repository.dart';

class DarwinBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onHomeTapped;
  final ValueChanged<int>? onRoutesTapped;
  final ValueChanged<int>? onStatsTapped;
  final ValueChanged<int>? onAchievementsTapped;
  final ValueChanged<int>? onProfileTapped;

  const DarwinBottomBar({
    super.key,
    required this.currentIndex,
    this.onHomeTapped,
    this.onRoutesTapped,
    this.onStatsTapped,
    this.onAchievementsTapped,
    this.onProfileTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Домой -> главный экран (HomeScreen)
          IconButton(
            icon: Icon(
              Icons.home_outlined,
              size: 28,
              color: currentIndex == 0 ? Colors.black : Colors.black54,
            ),
            onPressed: () {
              if (onHomeTapped != null) {
                onHomeTapped!(0);
              }
            },
          ),
          
          // Маршруты -> экран выбора маршрутов
          IconButton(
            icon: Icon(
              Icons.map_outlined,
              size: 28,
              color: currentIndex == 1 ? Colors.black : Colors.black54,
            ),
            onPressed: () {
              if (onRoutesTapped != null) {
                onRoutesTapped!(1);
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const ReadyRoutesScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
          
          // Статистика -> экран статистики
          IconButton(
            icon: Icon(
              Icons.bar_chart_outlined,
              size: 28,
              color: currentIndex == 2 ? Colors.black : Colors.black54,
            ),
            onPressed: () async {
              if (onStatsTapped != null) {
                onStatsTapped!(2);
              } else {
                final stepsRepo = await DailyStepsRepository.getInstance();
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StatisticsScreen(repository: stepsRepo),
                    ),
                  );
                }
              }
            },
          ),
          
          // Достижения -> экран достижений
          IconButton(
            icon: Icon(
              Icons.emoji_events_outlined,
              size: 28,
              color: currentIndex == 3 ? Colors.black : Colors.black54,
            ),
            onPressed: () {
              if (onAchievementsTapped != null) {
                onAchievementsTapped!(3);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AchievementsScreen(),
                  ),
                );
              }
            },
          ),
          
          // Профиль -> экран профиля
          IconButton(
            icon: Icon(
              Icons.person_outline,
              size: 28,
              color: currentIndex == 4 ? Colors.black : Colors.black54,
            ),
            onPressed: () {
              if (onProfileTapped != null) {
                onProfileTapped!(4);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}