// lib/data/repositories/achievement_repository.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/achievement.dart';

class AchievementRepository {
  static AchievementRepository? _instance;
  List<Achievement>? _allAchievements;
  
  static Future<AchievementRepository> getInstance() async {
    if (_instance == null) {
      _instance = AchievementRepository._internal();
      await _instance!._init();
    }
    return _instance!;
  }
  
  AchievementRepository._internal();
  
  Future<void> _init() async {
    await loadAchievements();
  }
  
  /// Загрузка достижений из JSON
  Future<List<Achievement>> loadAchievements() async {
    if (_allAchievements != null) return _allAchievements!;
    
    try {
      final jsonString = await rootBundle.loadString('assets/data/achievements.json');
      final jsonMap = json.decode(jsonString);
      final achievementsList = jsonMap['achievements'] as List<dynamic>;
      
      _allAchievements = achievementsList
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList();
      
      return _allAchievements!;
    } catch (e) {
      print('Error loading achievements: $e');
      return [];
    }
  }
  
  /// Получить все достижения
  Future<List<Achievement>> getAllAchievements() async {
    return await loadAchievements();
  }
  
  /// Получить достижение по ID
  Future<Achievement?> getAchievementById(String id) async {
    final all = await loadAchievements();
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
  
  /// Получить достижения по категории
  Future<List<Achievement>> getAchievementsByCategory(AchievementCategory category) async {
    final all = await loadAchievements();
    return all.where((a) => a.category == category).toList();
  }
  
  /// Получить достижения по уровню
  Future<List<Achievement>> getAchievementsByTier(AchievementTier tier) async {
    final all = await loadAchievements();
    return all.where((a) => a.tier == tier).toList();
  }
  
  /// Загрузить состояние достижений пользователя
  Future<Map<String, UserAchievement>> loadUserAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final allAchievements = await loadAchievements();
    
    final Map<String, UserAchievement> result = {};
    
    for (final achievement in allAchievements) {
      final key = 'achievement_${achievement.id}';
      final saved = prefs.getString(key);
      
      if (saved != null) {
        final json = jsonDecode(saved);
        result[achievement.id] = UserAchievement(
          achievement: achievement,
          isUnlocked: json['isUnlocked'] as bool,
          currentProgress: json['currentProgress'] as int,
          unlockedAt: json['unlockedAt'] != null 
              ? DateTime.parse(json['unlockedAt']) 
              : null,
        );
      } else {
        result[achievement.id] = UserAchievement(
          achievement: achievement,
          isUnlocked: false,
          currentProgress: 0,
          unlockedAt: null,
        );
      }
    }
    
    return result;
  }
  
  /// Сохранить состояние достижения
  Future<void> saveUserAchievement(UserAchievement userAchievement) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'achievement_${userAchievement.achievement.id}';
    
    final json = {
      'isUnlocked': userAchievement.isUnlocked,
      'currentProgress': userAchievement.currentProgress,
      'unlockedAt': userAchievement.unlockedAt?.toIso8601String(),
    };
    
    await prefs.setString(key, jsonEncode(json));
  }
  
  /// Сохранить множество достижений
  Future<void> saveUserAchievements(List<UserAchievement> achievements) async {
    for (final achievement in achievements) {
      await saveUserAchievement(achievement);
    }
  }
  
  /// Получить общее количество XP
  Future<int> getTotalXP() async {
    final userAchievements = await loadUserAchievements();
    int total = 0;
    for (final a in userAchievements.values) {
      if (a.isUnlocked) {
        total += a.achievement.xpReward;
      }
    }
    return total;
  }
  
  /// Получить статистику достижений
  Future<Map<String, dynamic>> getStats() async {
    final userAchievements = await loadUserAchievements();
    final unlocked = userAchievements.values.where((a) => a.isUnlocked).length;
    final total = userAchievements.length;
    final totalXP = await getTotalXP();
    
    return {
      'unlocked': unlocked,
      'total': total,
      'percent': total > 0 ? (unlocked / total * 100).toStringAsFixed(0) : '0',
      'totalXP': totalXP,
    };
  }
  
  /// Обновить прогресс достижений на основе текущих данных
  Future<List<UserAchievement>> updateProgress({
    required int totalSteps,
    required int dailySteps,
    required int completedRoutes,
    required Set<String> completedRouteIds,
    required int creaturesOpened,
    required int consecutiveDays,
    required int weeklySteps,
    required int morningSteps,
    required int nightSteps,
  }) async {
    final userAchievements = await loadUserAchievements();
    final updated = <UserAchievement>[];
    
    for (final entry in userAchievements.entries) {
      var userAchievement = entry.value;
      if (userAchievement.isUnlocked) continue;
      
      final condition = userAchievement.achievement.condition;
      int newProgress = userAchievement.currentProgress;
      int targetValue = 0;
      
      // Определяем текущий прогресс в зависимости от типа условия
      switch (condition.type) {
        case ConditionType.totalSteps:
          newProgress = totalSteps;
          targetValue = condition.value as int;
          break;
        case ConditionType.dailySteps:
          newProgress = dailySteps;
          targetValue = condition.value as int;
          break;
        case ConditionType.morningSteps:
          newProgress = morningSteps;
          targetValue = condition.value as int;
          break;
        case ConditionType.nightSteps:
          newProgress = nightSteps;
          targetValue = condition.value as int;
          break;
        case ConditionType.routesCompleted:
          newProgress = completedRoutes;
          targetValue = condition.value as int;
          break;
        case ConditionType.routeCompleted:
          final requiredRoute = condition.value as String;
          if (completedRouteIds.contains(requiredRoute)) {
            newProgress = 1;
            targetValue = 1;
          }
          break;
        case ConditionType.allRoutesCompleted:
          // 5 маршрутов всего
          if (completedRoutes >= 5) {
            newProgress = 1;
            targetValue = 1;
          }
          break;
        case ConditionType.creaturesOpened:
          newProgress = creaturesOpened;
          targetValue = condition.value as int;
          break;
        case ConditionType.consecutiveDays:
          newProgress = consecutiveDays;
          targetValue = condition.value as int;
          break;
        case ConditionType.perfectWeek:
          if (weeklySteps >= 35000) {
            newProgress = 1;
            targetValue = 1;
          }
          break;
        default:
          continue;
      }
      
      final isUnlocked = newProgress >= targetValue;
      
      if (isUnlocked && !userAchievement.isUnlocked) {
        userAchievement = UserAchievement(
          achievement: userAchievement.achievement,
          isUnlocked: true,
          currentProgress: newProgress,
          unlockedAt: DateTime.now(),
        );
        updated.add(userAchievement);
      } else if (newProgress != userAchievement.currentProgress) {
        userAchievement = UserAchievement(
          achievement: userAchievement.achievement,
          isUnlocked: false,
          currentProgress: newProgress,
          unlockedAt: null,
        );
        updated.add(userAchievement);
      }
      
      await saveUserAchievement(userAchievement);
    }
    
    return updated;
  }
  
  /// Сбросить все достижения (для тестирования)
  Future<void> resetAllAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final allAchievements = await loadAchievements();
    
    for (final achievement in allAchievements) {
      await prefs.remove('achievement_${achievement.id}');
    }
  }
}