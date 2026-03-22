// lib/widgets/bottom_bar.dart

import 'package:flutter/material.dart';
import 'package:darwin_walk/screens/profile_screen.dart';
import 'package:darwin_walk/screens/ready_routes_screen.dart';
import 'package:darwin_walk/screens/statistics/statistics_screen.dart';
import 'package:darwin_walk/main.dart';

class DarwinBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onHomeTapped;
  final ValueChanged<int>? onInfoTapped;

  const DarwinBottomBar({
    super.key,
    required this.currentIndex,
    this.onHomeTapped,
    this.onInfoTapped,
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
          // Домой -> главный экран (ReadyRoutesScreen)
          IconButton(
            icon: Icon(
              Icons.home_outlined,
              size: 28,
              color: currentIndex == 0 ? Colors.black : Colors.black54,
            ),
            onPressed: () {
              // если родитель хочет сам обработать — даём ему шанс
              if (onHomeTapped != null) {
                onHomeTapped!(0);
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

          // Профиль -> отдельный экран поверх текущей вкладки
          IconButton(
            icon: Icon(
              Icons.person_outline,
              size: 28,
              color: currentIndex == 1 ? Colors.black : Colors.black54,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),

          // Info -> статистика
          IconButton(
            icon: Icon(
              Icons.info_outline,
              size: 28,
              color: currentIndex == 2 ? Colors.black : Colors.black54,
            ),
            onPressed: () {
              if (onInfoTapped != null) {
                onInfoTapped!(2);
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StatisticsScreen(
                      repository: dailyStepsRepository,
                    ),
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