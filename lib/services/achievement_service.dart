// lib/services/achievement_service.dart

import 'package:flutter/foundation.dart';
import '../models/achievement.dart';
import '../data/repositories/achievement_repository.dart';
import '../data/achievement_checker.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  Future<void> checkAchievements({
    required int totalSteps,
    required int dailySteps,
    required int completedRoutes,
    required Set<String> completedRouteIds,
    required int creaturesOpened,
    required int consecutiveDays,
  }) async {
    try {
      final repo = await AchievementRepository.getInstance();
      
      // ✅ Получаем все достижения
      final allAchievements = await repo.getAllAchievements();
      
      final userAchievements = await repo.loadUserAchievements();
      
      final newlyUnlocked = AchievementChecker.check(
        totalSteps: totalSteps,
        dailySteps: dailySteps,
        morningSteps: 0,
        nightSteps: 0,
        completedRoutes: completedRoutes,
        completedRouteIds: completedRouteIds,
        creaturesOpened: creaturesOpened,
        consecutiveDays: consecutiveDays,
        currentStreak: consecutiveDays,
        weeklySteps: dailySteps * 7,
        isFirstLaunchToday: false,
        now: DateTime.now(),
        routeCompletionDays: {},
        allAchievements: allAchievements,  // ✅ передаём список
      );
      
      for (final achievement in newlyUnlocked) {
        final userAchievement = userAchievements[achievement.id];
        if (userAchievement != null && !userAchievement.isUnlocked) {
          final updated = UserAchievement(
            achievement: achievement,
            isUnlocked: true,
            currentProgress: _getProgressForAchievement(
              achievement, 
              totalSteps, 
              dailySteps, 
              completedRoutes,
            ),
            unlockedAt: DateTime.now(),
          );
          await repo.saveUserAchievement(updated);
          debugPrint('🏆 Достижение разблокировано: ${achievement.title}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in AchievementService: $e');
    }
  }
  
  int _getProgressForAchievement(
    Achievement achievement,
    int totalSteps,
    int dailySteps,
    int completedRoutes,
  ) {
    switch (achievement.condition.type) {
      case ConditionType.totalSteps:
        return totalSteps;
      case ConditionType.dailySteps:
        return dailySteps;
      case ConditionType.routesCompleted:
        return completedRoutes;
      default:
        return 0;
    }
  }
}