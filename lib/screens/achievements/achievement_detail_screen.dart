// lib/screens/achievements/achievement_detail_screen.dart

import 'package:flutter/material.dart';
import '../../models/achievement.dart';
import '../../widgets/asset_image_or_icon.dart';
import '../../widgets/simple_confetti.dart';

class AchievementDetailScreen extends StatelessWidget {
  final UserAchievement userAchievement;
  final VoidCallback onAchievementUpdated;

  const AchievementDetailScreen({
    super.key,
    required this.userAchievement,
    required this.onAchievementUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final achievement = userAchievement.achievement;
    final isUnlocked = userAchievement.isUnlocked;
    final tierColor = Color(achievement.tier.color);
    final categoryColor = Color(achievement.category.color);
    
    // Проверяем, нужно ли показывать конфетти
    final showConfetti = isUnlocked && 
        (achievement.tier == AchievementTier.gold || 
         achievement.tier == AchievementTier.diamond);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(achievement.title),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Основной контент с прокруткой
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Крупное изображение
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: isUnlocked
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              tierColor.withValues(alpha: 0.3),
                              tierColor.withValues(alpha: 0.1),
                            ],
                          )
                        : null,
                    color: !isUnlocked ? Colors.grey.withValues(alpha: 0.1) : null,
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: isUnlocked ? tierColor : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: isUnlocked ? [
                      BoxShadow(
                        color: tierColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ] : [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: isUnlocked
                        ? AssetImageOrIcon(
                            assetPath: achievement.iconPath,
                            fallbackIcon: _getIconForCategory(achievement.category),
                            iconColor: tierColor,
                            iconSize: 50,
                            imageWidth: 120,
                            imageHeight: 120,
                          )
                        : Center(
                            child: Icon(
                              Icons.lock_outline,
                              size: 50,
                              color: Colors.grey.shade400,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Название и уровень
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tierColor,
                        tierColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    achievement.tier.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Категория
                Chip(
                  avatar: Text(achievement.category.icon),
                  label: Text(achievement.category.displayName),
                  backgroundColor: categoryColor.withValues(alpha: 0.1),
                  side: BorderSide(color: categoryColor.withValues(alpha: 0.3)),
                ),
                const SizedBox(height: 24),
                
                // Описание
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          achievement.description,
                          style: const TextStyle(fontSize: 16, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Награда:',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.stars, color: Colors.amber, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  '${achievement.xpReward} XP',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (!isUnlocked && achievement.isNumericCondition) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Прогресс:',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                userAchievement.progressText,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: userAchievement.progressPercent.clamp(0.0, 1.0),
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                            borderRadius: BorderRadius.circular(8),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Осталось: ${userAchievement.remainingProgress}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                        if (isUnlocked && userAchievement.unlockedAt != null) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Получено:',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                _formatDate(userAchievement.unlockedAt!),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Условие получения
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text(
                            'Как получить',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getConditionDescription(achievement),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          // ✅ Конфетти только для золотых/алмазных — поверх контента, но не мешает прокрутке
          if (showConfetti)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: const SimpleConfetti(isActive: true),
              ),
            ),
        ],
      ),
    );
  }
  
  IconData _getIconForCategory(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.steps:
        return Icons.directions_walk;
      case AchievementCategory.consistency:
        return Icons.calendar_today;
      case AchievementCategory.routes:
        return Icons.map;
      case AchievementCategory.exploration:
        return Icons.search;
      case AchievementCategory.records:
        return Icons.emoji_events;
      case AchievementCategory.seasonal:
        return Icons.wb_sunny;
      case AchievementCategory.secret:
        return Icons.lock;
    }
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
  
  String _getConditionDescription(Achievement achievement) {
    final condition = achievement.condition;
    final value = condition.value;
    
    switch (condition.type) {
      case ConditionType.totalSteps:
        return 'Накопить $value шагов за всё время';
      case ConditionType.dailySteps:
        return 'Пройти $value шагов за один день';
      case ConditionType.morningSteps:
        return 'Пройти $value шагов до 12:00';
      case ConditionType.nightSteps:
        return 'Пройти $value шагов после 22:00';
      case ConditionType.routesCompleted:
        return 'Завершить $value маршрут(а/ов)';
      case ConditionType.routeCompleted:
        return 'Завершить маршрут "${_getRouteName(value as String)}"';
      case ConditionType.creaturesOpened:
        return 'Открыть $value существ(а) в галерее';
      case ConditionType.consecutiveDays:
        return 'Использовать приложение $value дней подряд';
      case ConditionType.perfectWeek:
        return 'Проходить 5 000+ шагов каждый день недели';
      default:
        return achievement.description;
    }
  }
  
  String _getRouteName(String routeId) {
    switch (routeId) {
      case 'jurassic':
        return 'Юрский период';
      case 'whale':
        return 'Назад в океан';
      case 'cenozoic':
        return 'От раптора до колибри';
      default:
        return routeId;
    }
  }
}