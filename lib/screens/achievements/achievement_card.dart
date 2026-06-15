// lib/screens/achievements/achievement_card.dart

import 'package:flutter/material.dart';
import '../../models/achievement.dart';


class AchievementCard extends StatelessWidget {
  final UserAchievement userAchievement;
  final VoidCallback onTap;

  const AchievementCard({
    super.key,
    required this.userAchievement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final achievement = userAchievement.achievement;
    final isUnlocked = userAchievement.isUnlocked;
    final tierColor = Color(achievement.tier.color);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked ? tierColor : Colors.grey[300]!,
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked ? [
            BoxShadow(
              color: tierColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Иконка
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: isUnlocked 
                    ? tierColor.withValues(alpha: 0.15)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: isUnlocked
                    ? Icon(
                        _getIconForCategory(achievement.category),
                        size: 28,
                        color: tierColor,
                      )
                    : Icon(
                        Icons.lock_outline,
                        size: 24,
                        color: Colors.grey[400],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Название
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isUnlocked ? Colors.black87 : Colors.grey[500],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Прогресс
            if (!isUnlocked && achievement.isNumericCondition) ...[
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: userAchievement.progressPercent,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                borderRadius: BorderRadius.circular(4),
                minHeight: 3,
              ),
              const SizedBox(height: 2),
              Text(
                userAchievement.progressText,
                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
              ),
            ],
            
            if (isUnlocked) ...[
              const SizedBox(height: 6),
              const Icon(Icons.check_circle, size: 12, color: Colors.green),
            ],
          ],
        ),
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
}