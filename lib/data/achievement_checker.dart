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
  }) {
    final newlyUnlocked = <Achievement>[];
    
    // ============ ШАГИ ============
    
    // Первые шаги (100)
    if (totalSteps >= 100) {
      newlyUnlocked.add(_getAchievementById('first_steps'));
    }
    
    // Ходок (5 000)
    if (totalSteps >= 5000) {
      newlyUnlocked.add(_getAchievementById('walker'));
    }
    
    // Путешественник (20 000)
    if (totalSteps >= 20000) {
      newlyUnlocked.add(_getAchievementById('traveler'));
    }
    
    // Исследователь миров (50 000)
    if (totalSteps >= 50000) {
      newlyUnlocked.add(_getAchievementById('world_explorer'));
    }
    
    // Легенда эволюции (100 000)
    if (totalSteps >= 100000) {
      newlyUnlocked.add(_getAchievementById('evolution_legend'));
    }
    
    // Марафонец (42 000)
    if (totalSteps >= 42000) {
      newlyUnlocked.add(_getAchievementById('marathon_total'));
    }
    
    // ============ ЕЖЕДНЕВНЫЕ ШАГИ ============
    
    // Дневной странник (5 000 за день)
    if (dailySteps >= 5000) {
      newlyUnlocked.add(_getAchievementById('day_wanderer'));
    }
    
    // Марафонец дня (10 000 за день)
    if (dailySteps >= 10000) {
      newlyUnlocked.add(_getAchievementById('day_marathoner'));
    }
    
    // Ранняя пташка (3 000 до 12:00)
    if (morningSteps >= 3000) {
      newlyUnlocked.add(_getAchievementById('early_bird'));
    }
    
    // Ночной ходок (1 000 после 22:00)
    if (nightSteps >= 1000) {
      newlyUnlocked.add(_getAchievementById('night_walker'));
    }
    
    // ============ МАРШРУТЫ ============
    
    // Первое путешествие
    if (completedRoutes >= 1) {
      newlyUnlocked.add(_getAchievementById('first_journey'));
    }
    
    // Опытный путешественник (3 маршрута)
    if (completedRoutes >= 3) {
      newlyUnlocked.add(_getAchievementById('experienced_traveler'));
    }
    
    // Специфичные маршруты
    if (completedRouteIds.contains('jurassic')) {
      newlyUnlocked.add(_getAchievementById('paleontologist'));
    }
    if (completedRouteIds.contains('whale')) {
      newlyUnlocked.add(_getAchievementById('oceanographer'));
    }
    if (completedRouteIds.contains('cenozoic')) {
      newlyUnlocked.add(_getAchievementById('ornithologist'));
    }
    
    // Скоростной эволюционер (маршрут за 7 дней)
    for (final entry in routeCompletionDays.entries) {
      if (entry.value <= 7) {
        newlyUnlocked.add(_getAchievementById('speed_evolution'));
        break;
      }
    }
    
    // ============ РЕГУЛЯРНОСТЬ ============
    
    // Первый день
    if (isFirstLaunchToday) {
      newlyUnlocked.add(_getAchievementById('first_day'));
    }
    
    // Недельный исследователь (7 дней подряд)
    if (consecutiveDays >= 7) {
      newlyUnlocked.add(_getAchievementById('weekly_researcher'));
    }
    
    // Преданный палеонтолог (14 дней подряд)
    if (consecutiveDays >= 14) {
      newlyUnlocked.add(_getAchievementById('loyal_paleontologist'));
    }
    
    // Эволюция привычки (30 дней подряд)
    if (consecutiveDays >= 30) {
      newlyUnlocked.add(_getAchievementById('habit_evolution'));
    }
    
    // Легендарный странник (90 дней подряд)
    if (consecutiveDays >= 90) {
      newlyUnlocked.add(_getAchievementById('legendary_traveler'));
    }
    
    // Идеальная неделя (5 000+ шагов каждый день недели)
    if (weeklySteps >= 35000) { // 7 дней * 5000
      newlyUnlocked.add(_getAchievementById('perfect_week'));
    }
    
    // ============ ИССЛЕДОВАНИЕ ============
    
    // Любопытный (5 существ)
    if (creaturesOpened >= 5) {
      newlyUnlocked.add(_getAchievementById('curious'));
    }
    
    // Исследователь (10 существ)
    if (creaturesOpened >= 10) {
      newlyUnlocked.add(_getAchievementById('researcher'));
    }
    
    // ============ СЕЗОННЫЕ ============
    
    // Проверка сезонов
    final month = now.month;
    if (month == 1) { // январь
      newlyUnlocked.add(_getAchievementById('new_year_start'));
    }
    
    // Весна (март, апрель, май)
    if (month >= 3 && month <= 5 && totalSteps >= 10000) {
      newlyUnlocked.add(_getAchievementById('spring_traveler'));
    }
    
    // ============ УДАЛЯЕМ ДУБЛИКАТЫ ============
    
    return newlyUnlocked.toSet().toList();
  }
  
  /// Вспомогательный метод для получения достижения по ID
  static Achievement _getAchievementById(String id) {
    // Этот метод будет использовать AchievementRepository
    // Но для простоты пока возвращаем заглушку
    // В реальности нужно получать из репозитория
    return Achievement(
      id: id,
      title: '',
      description: '',
      category: AchievementCategory.steps,
      tier: AchievementTier.bronze,
      iconPath: '',
      condition: const AchievementCondition(
        type: ConditionType.totalSteps,
        value: 0,
      ),
      isSecret: false,
      xpReward: 0,
    );
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