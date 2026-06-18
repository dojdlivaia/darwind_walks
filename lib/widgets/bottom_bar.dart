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
          // Домой
          _buildNavButton(
            context: context,
            icon: Icons.home_outlined,
            index: 0,
            onTap: onHomeTapped,
            defaultAction: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const ReadyRoutesScreen()),
                (route) => false,
              );
            },
          ),
          
          // Маршруты
          _buildNavButton(
            context: context,
            icon: Icons.map_outlined,
            index: 1,
            onTap: onRoutesTapped,
            defaultAction: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const ReadyRoutesScreen()),
                (route) => false,
              );
            },
          ),
          
          // Статистика
          _buildNavButton(
            context: context,
            icon: Icons.bar_chart_outlined,
            index: 2,
            onTap: onStatsTapped,
            defaultAction: () async {
              final stepsRepo = await DailyStepsRepository.getInstance();
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StatisticsScreen(repository: stepsRepo),
                  ),
                );
              }
            },
          ),
          
          // Достижения
          _buildNavButton(
            context: context,
            icon: Icons.emoji_events_outlined,
            index: 3,
            onTap: onAchievementsTapped,
            defaultAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AchievementsScreen(),
                ),
              );
            },
          ),
          
          // Профиль
          _buildNavButton(
            context: context,
            icon: Icons.person_outline,
            index: 4,
            onTap: onProfileTapped,
            defaultAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required IconData icon,
    required int index,
    required ValueChanged<int>? onTap,
    required VoidCallback defaultAction,
  }) {
    final isSelected = currentIndex == index;
    
    return IconButton(
      icon: Icon(
        icon,
        size: 28,
        color: isSelected ? Colors.black : Colors.black54,
      ),
      onPressed: () {
        if (onTap != null) {
          onTap(index);
        } else {
          defaultAction();
        }
      },
    );
  }
}