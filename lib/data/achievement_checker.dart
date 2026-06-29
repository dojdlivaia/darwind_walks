// lib/data/achievement_checker.dart

import '../models/achievement.dart';

/// Сервис для проверки условий достижений
class AchievementChecker {
  /// Проверка всех достижений на основе текущих данных пользователя
  static List<Achievement> check({
    required int totalSteps,
    required int dailySteps,
    required int morningSteps,
    required int nightSteps,
    required int completedRoutes,
    required Set<String> completedRouteIds,
    required int creaturesOpened,
    required int consecutiveDays,
    required int currentStreak,
    required int weeklySteps,
    required bool isFirstLaunchToday,
    required DateTime now,
    required Map<String, int> routeCompletionDays,
    required List<Achievement> allAchievements,  // ✅ добавить список всех достижений
  }) {
    final newlyUnlocked = <Achievement>[];
    
    // ============ ШАГИ ============
    // Ходок (5 000)
    if (totalSteps >= 5000) {
      final achievement = _getAchievementById('walker', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Путешественник (20 000)
    if (totalSteps >= 20000) {
      final achievement = _getAchievementById('traveler', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Марафонец (42 000)
    if (totalSteps >= 42000) {
      final achievement = _getAchievementById('marathon_total', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Исследователь миров (50 000)
    if (totalSteps >= 50000) {
      final achievement = _getAchievementById('world_explorer', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Легенда эволюции (100 000)
    if (totalSteps >= 100000) {
      final achievement = _getAchievementById('evolution_legend', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Первые шаги (100)
    if (totalSteps >= 100) {
      final achievement = _getAchievementById('first_steps', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // ============ ЕЖЕДНЕВНЫЕ ШАГИ ============
    // Дневной странник (5 000 за день)
    if (dailySteps >= 5000) {
      final achievement = _getAchievementById('day_wanderer', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Марафонец дня (10 000 за день)
    if (dailySteps >= 10000) {
      final achievement = _getAchievementById('day_marathoner', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Ранняя пташка (3 000 до 12:00)
    if (morningSteps >= 3000) {
      final achievement = _getAchievementById('early_bird', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Ночной ходок (1 000 после 22:00)
    if (nightSteps >= 1000) {
      final achievement = _getAchievementById('night_walker', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // ============ МАРШРУТЫ ============
    // Первое путешествие
    if (completedRoutes >= 1) {
      final achievement = _getAchievementById('first_journey', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Опытный путешественник (3 маршрута)
    if (completedRoutes >= 3) {
      final achievement = _getAchievementById('experienced_traveler', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Специфичные маршруты
    if (completedRouteIds.contains('jurassic')) {
      final achievement = _getAchievementById('paleontologist', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    if (completedRouteIds.contains('whale')) {
      final achievement = _getAchievementById('oceanographer', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    if (completedRouteIds.contains('cenozoic')) {
      final achievement = _getAchievementById('ornithologist', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    if (completedRouteIds.contains('mammals')) {
      final achievement = _getAchievementById('zoologist', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Скоростной эволюционер (маршрут за 7 дней)
    for (final entry in routeCompletionDays.entries) {
      if (entry.value <= 7) {
        final achievement = _getAchievementById('speed_evolution', allAchievements);
        if (achievement != null) newlyUnlocked.add(achievement);
        break;
      }
    }
    
    // ============ РЕГУЛЯРНОСТЬ ============
    // Первый день
    if (isFirstLaunchToday) {
      final achievement = _getAchievementById('first_day', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Недельный исследователь (7 дней подряд)
    if (consecutiveDays >= 7) {
      final achievement = _getAchievementById('weekly_researcher', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Преданный палеонтолог (14 дней подряд)
    if (consecutiveDays >= 14) {
      final achievement = _getAchievementById('loyal_paleontologist', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Эволюция привычки (30 дней подряд)
    if (consecutiveDays >= 30) {
      final achievement = _getAchievementById('habit_evolution', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Легендарный странник (90 дней подряд)
    if (consecutiveDays >= 90) {
      final achievement = _getAchievementById('legendary_traveler', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Идеальная неделя (5 000+ шагов каждый день недели)
    if (weeklySteps >= 35000) {
      final achievement = _getAchievementById('perfect_week', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // ============ ИССЛЕДОВАНИЕ ============
    // Любопытный (5 существ)
    if (creaturesOpened >= 5) {
      final achievement = _getAchievementById('curious', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // Исследователь (10 существ)
    if (creaturesOpened >= 10) {
      final achievement = _getAchievementById('researcher', allAchievements);
      if (achievement != null) newlyUnlocked.add(achievement);
    }
    
    // ============ УДАЛЯЕМ ДУБЛИКАТЫ ============
    return newlyUnlocked.toSet().toList();
  }
  
  /// Получение достижения по ID из списка
  static Achievement? _getAchievementById(String id, List<Achievement> allAchievements) {
    try {
      return allAchievements.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
  
  /// Проверка конкретного типа условия
  static bool checkCondition(
    ConditionType type,
    dynamic requiredValue,
    int totalSteps,
    int dailySteps,
    int completedRoutes,
    int creaturesOpened,
  ) {
    switch (type) {
      case ConditionType.totalSteps:
        return totalSteps >= (requiredValue as int);
      case ConditionType.dailySteps:
        return dailySteps >= (requiredValue as int);
      case ConditionType.routesCompleted:
        return completedRoutes >= (requiredValue as int);
      case ConditionType.creaturesOpened:
        return creaturesOpened >= (requiredValue as int);
      default:
        return false;
    }
  }
}