// lib/models/achievement.dart

/// Категории достижений
enum AchievementCategory {
  /// Шаги и прогресс
  steps,
  
  /// Регулярность использования
  consistency,
  
  /// Маршруты
  routes,
  
  /// Исследование контента
  exploration,
  
  /// Рекорды
  records,
  
  /// Сезонные достижения
  seasonal,
  
  /// Секретные достижения
  secret;

  /// Человекочитаемое название категории
  String get displayName {
    switch (this) {
      case AchievementCategory.steps:
        return 'Шаги';
      case AchievementCategory.consistency:
        return 'Регулярность';
      case AchievementCategory.routes:
        return 'Маршруты';
      case AchievementCategory.exploration:
        return 'Исследование';
      case AchievementCategory.records:
        return 'Рекорды';
      case AchievementCategory.seasonal:
        return 'Сезонные';
      case AchievementCategory.secret:
        return 'Секретные';
    }
  }

  /// Иконка категории
  String get icon {
    switch (this) {
      case AchievementCategory.steps:
        return '👣';
      case AchievementCategory.consistency:
        return '🔥';
      case AchievementCategory.routes:
        return '🗺️';
      case AchievementCategory.exploration:
        return '';
      case AchievementCategory.records:
        return '🏆';
      case AchievementCategory.seasonal:
        return '🌸';
      case AchievementCategory.secret:
        return '🕵️';
    }
  }

  /// Цвет категории
  int get color {
    switch (this) {
      case AchievementCategory.steps:
        return 0xFF4B5E09; // olive green
      case AchievementCategory.consistency:
        return 0xFFD4760A; // orange
      case AchievementCategory.routes:
        return 0xFF2D4A6E; // blue
      case AchievementCategory.exploration:
        return 0xFF5A4E7C; // purple
      case AchievementCategory.records:
        return 0xFFC9A227; // gold
      case AchievementCategory.seasonal:
        return 0xFF7CBF7F; // green
      case AchievementCategory.secret:
        return 0xFF8B5A8B; // dark purple
    }
  }
}

/// Уровни редкости достижений
enum AchievementTier {
  /// Бронза (начальный уровень)
  bronze,
  
  /// Серебро (средний уровень)
  silver,
  
  /// Золото (продвинутый уровень)
  gold,
  
  /// Алмаз (максимальный уровень)
  diamond;

  /// Человекочитаемое название
  String get displayName {
    switch (this) {
      case AchievementTier.bronze:
        return 'Бронза';
      case AchievementTier.silver:
        return 'Серебро';
      case AchievementTier.gold:
        return 'Золото';
      case AchievementTier.diamond:
        return 'Алмаз';
    }
  }

  /// Цвет бейджа
  int get color {
    switch (this) {
      case AchievementTier.bronze:
        return 0xFFCD7F32; // bronze
      case AchievementTier.silver:
        return 0xFFC0C0C0; // silver
      case AchievementTier.gold:
        return 0xFFFFD700; // gold
      case AchievementTier.diamond:
        return 0xFFB9F2FF; // diamond blue
    }
  }

  /// XP множитель
  double get xpMultiplier {
    switch (this) {
      case AchievementTier.bronze:
        return 1.0;
      case AchievementTier.silver:
        return 1.5;
      case AchievementTier.gold:
        return 2.0;
      case AchievementTier.diamond:
        return 3.0;
    }
  }
}

/// Типы условий для достижений
enum ConditionType {
  // Шаги
  totalSteps,           // Всего шагов
  dailySteps,           // Шагов за день
  morningSteps,         // Утренних шагов (до 12:00)
  nightSteps,           // Ночных шагов (после 22:00)
  
  // Регулярность
  firstLaunch,          // Первый запуск
  consecutiveDays,      // Дней подряд
  weekendDays,          // Выходных дней
  daysWithSteps,        // Дней с определенным количеством шагов
  perfectWeek,          // Идеальная неделя
  
  // Маршруты
  routesCompleted,      // Завершенных маршрутов
  allRoutesCompleted,   // Все маршруты завершены
  routeCompleted,       // Конкретный маршрут завершен
  routeInDays,          // Маршрут за N дней
  routesInDays,         // N маршрутов за M дней
  morningRoute,         // Утренний маршрут
  nightRoute,           // Ночной маршрут
  
  // Исследование
  creaturesOpened,      // Открытых существ
  allCreaturesInRoute,  // Все существа в маршруте
  allFactsRead,         // Все факты прочитаны
  allCheckpointsFound,  // Все чекпоинты найдены
  
  // Рекорды
  dailyRecord,          // Дневной рекорд
  consecutiveRecords,   // Последовательные рекорды
  stepsInMinutes,       // Шагов за N минут
  slowWalk,             // Медленная ходьба
  
  // Сезонные
  routeInMonth,         // Маршрут в определенном месяце
  stepsInSeason,        // Шагов в сезоне
  routeInSeason,        // Маршрут в сезоне
  creaturesInSeason,    // Существ в сезоне
  specialDate,          // Особая дата
  
  // Секретные
  nightSessions,        // Ночных сессий
  secretCreature,       // Секретное существо
  earlyUser,            // Ранний пользователь
  appOpenMinutes;       // Минут приложения открыто

  /// Человекочитаемое название
  String get displayName {
    switch (this) {
      case ConditionType.totalSteps:
        return 'Всего шагов';
      case ConditionType.dailySteps:
        return 'Шагов за день';
      case ConditionType.morningSteps:
        return 'Утренних шагов';
      case ConditionType.nightSteps:
        return 'Ночных шагов';
      case ConditionType.firstLaunch:
        return 'Первый запуск';
      case ConditionType.consecutiveDays:
        return 'Дней подряд';
      case ConditionType.weekendDays:
        return 'Выходных дней';
      case ConditionType.daysWithSteps:
        return 'Дней с шагами';
      case ConditionType.perfectWeek:
        return 'Идеальная неделя';
      case ConditionType.routesCompleted:
        return 'Завершенных маршрутов';
      case ConditionType.allRoutesCompleted:
        return 'Все маршруты';
      case ConditionType.routeCompleted:
        return 'Маршрут завершен';
      case ConditionType.routeInDays:
        return 'Маршрут за дни';
      case ConditionType.routesInDays:
        return 'Маршруты за дни';
      case ConditionType.morningRoute:
        return 'Утренний маршрут';
      case ConditionType.nightRoute:
        return 'Ночной маршрут';
      case ConditionType.creaturesOpened:
        return 'Открытых существ';
      case ConditionType.allCreaturesInRoute:
        return 'Все существа в маршруте';
      case ConditionType.allFactsRead:
        return 'Все факты прочитаны';
      case ConditionType.allCheckpointsFound:
        return 'Все чекпоинты найдены';
      case ConditionType.dailyRecord:
        return 'Дневной рекорд';
      case ConditionType.consecutiveRecords:
        return 'Последовательные рекорды';
      case ConditionType.stepsInMinutes:
        return 'Шагов за минуты';
      case ConditionType.slowWalk:
        return 'Медленная ходьба';
      case ConditionType.routeInMonth:
        return 'Маршрут в месяце';
      case ConditionType.stepsInSeason:
        return 'Шагов в сезоне';
      case ConditionType.routeInSeason:
        return 'Маршрут в сезоне';
      case ConditionType.creaturesInSeason:
        return 'Существ в сезоне';
      case ConditionType.specialDate:
        return 'Особая дата';
      case ConditionType.nightSessions:
        return 'Ночных сессий';
      case ConditionType.secretCreature:
        return 'Секретное существо';
      case ConditionType.earlyUser:
        return 'Ранний пользователь';
      case ConditionType.appOpenMinutes:
        return 'Минут приложения открыто';
    }
  }
}

/// Условие выполнения достижения
class AchievementCondition {
  /// Тип условия
  final ConditionType type;
  
  /// Значение условия (int для чисел, String для ID маршрутов)
  final dynamic value;

  const AchievementCondition({
    required this.type,
    required this.value,
  });

  /// Создание из JSON
  factory AchievementCondition.fromJson(Map<String, dynamic> json) {
    return AchievementCondition(
      type: ConditionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ConditionType.totalSteps,
      ),
      value: json['value'],
    );
  }

  /// Сериализация в JSON
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'value': value,
  };

  @override
  String toString() => 'AchievementCondition(type: $type, value: $value)';
}

/// Модель достижения
class Achievement {
  /// Уникальный идентификатор
  final String id;
  
  /// Название достижения
  final String title;
  
  /// Описание достижения
  final String description;
  
  /// Категория достижения
  final AchievementCategory category;
  
  /// Уровень редкости
  final AchievementTier tier;
  
  /// Путь к иконке
  final String iconPath;
  
  /// Условие выполнения
  final AchievementCondition condition;
  
  /// Является ли секретным
  final bool isSecret;
  
  /// Награда в XP
  final int xpReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.tier,
    required this.iconPath,
    required this.condition,
    required this.isSecret,
    required this.xpReward,
  });

  /// Создание из JSON
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AchievementCategory.steps,
      ),
      tier: AchievementTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () => AchievementTier.bronze,
      ),
      iconPath: json['icon'] as String,
      condition: AchievementCondition.fromJson(json['condition']),
      isSecret: json['isSecret'] as bool? ?? false,
      xpReward: json['xpReward'] as int? ?? 0,
    );
  }

  /// Сериализация в JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category.name,
    'tier': tier.name,
    'icon': iconPath,
    'condition': condition.toJson(),
    'isSecret': isSecret,
    'xpReward': xpReward,
  };

  /// Человекочитаемое описание условия
  String get conditionDescription {
    if (condition.value is int) {
      return '${condition.type.displayName}: ${condition.value}';
    } else if (condition.value is String) {
      return '${condition.type.displayName}: ${condition.value}';
    }
    return condition.type.displayName;
  }

  @override
  String toString() => 'Achievement(id: $id, title: $title, tier: $tier)';
}

/// Состояние достижения у пользователя
class UserAchievement {
  /// Само достижение
  final Achievement achievement;
  
  /// Разблокировано ли
  final bool isUnlocked;
  
  /// Текущий прогресс (например, 3000 из 5000 шагов)
  final int currentProgress;
  
  /// Дата разблокировки
  final DateTime? unlockedAt;

  const UserAchievement({
    required this.achievement,
    required this.isUnlocked,
    required this.currentProgress,
    this.unlockedAt,
  });

  /// Процент выполнения (0.0 - 1.0)
  double get progressPercent {
    if (isUnlocked) return 1.0;
    
    final target = achievement.condition.value;
    if (target is int && target > 0) {
      return (currentProgress / target).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  /// Осталось до выполнения
  int get remainingProgress {
    final target = achievement.condition.value;
    if (target is int) {
      return (target - currentProgress).clamp(0, target);
    }
    return 0;
  }

  /// Человекочитаемый прогресс
  String get progressText {
    if (isUnlocked) return 'Выполнено';
    
    final target = achievement.condition.value;
    if (target is int) {
      return '$currentProgress / $target';
    }
    return '$currentProgress';
  }

  /// Копия с обновленным прогрессом
  UserAchievement copyWith({
    int? currentProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return UserAchievement(
      achievement: achievement,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      currentProgress: currentProgress ?? this.currentProgress,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  @override
  String toString() => 'UserAchievement(${achievement.id}: $progressText)';
}

/// Extension для работы с коллекциями достижений
extension AchievementListExtension on List<UserAchievement> {
  /// Получить разблокированные достижения
  List<UserAchievement> get unlocked => 
    where((a) => a.isUnlocked).toList();
  
  /// Получить заблокированные достижения
  List<UserAchievement> get locked => 
    where((a) => !a.isUnlocked).toList();
  
  /// Получить достижения по категории
  List<UserAchievement> byCategory(AchievementCategory category) => 
    where((a) => a.achievement.category == category).toList();
  
  /// Получить достижения по уровню редкости
  List<UserAchievement> byTier(AchievementTier tier) => 
    where((a) => a.achievement.tier == tier).toList();
  
  /// Общее количество XP
  int get totalXP => 
    unlocked.fold(0, (sum, a) => sum + a.achievement.xpReward);
  
  /// Процент выполнения всех достижений
  double get completionPercent {
    if (isEmpty) return 0.0;
    final unlocked = this.unlocked.length;
    return unlocked / length;
  }
}

/// Extension для работы с Achievement
extension AchievementExtension on Achievement {
  /// Проверка, является ли условие числовым
  bool get isNumericCondition => condition.value is int;
  
  /// Получить числовое значение условия
  int? get numericValue => condition.value is int ? condition.value as int : null;
  
  /// Получить строковое значение условия
  String? get stringValue => condition.value is String ? condition.value as String : null;
}