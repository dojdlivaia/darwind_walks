// lib/screens/achievements/achievements_screen.dart

import 'package:flutter/material.dart';
import '../../models/achievement.dart';
import '../../data/repositories/achievement_repository.dart';
import 'achievement_detail_screen.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late Future<Map<String, UserAchievement>> _userAchievementsFuture;
  late Future<List<Achievement>> _allAchievementsFuture;
  
  String _searchQuery = '';
  bool _showOnlyUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final repo = AchievementRepository.getInstance();
    _userAchievementsFuture = repo.then((r) => r.loadUserAchievements());
    _allAchievementsFuture = repo.then((r) => r.loadAchievements());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Достижения'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: Icon(
              _showOnlyUnlocked ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showOnlyUnlocked ? Colors.green : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _showOnlyUnlocked = !_showOnlyUnlocked;
              });
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([_allAchievementsFuture, _userAchievementsFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }
          
          final allAchievements = snapshot.data?[0] as List<Achievement>;
          final userAchievements = snapshot.data?[1] as Map<String, UserAchievement>;
          
          if (allAchievements.isEmpty) {
            return const Center(child: Text('Нет достижений'));
          }
          
          // Группировка по категориям
          final categories = _groupAchievementsByCategory(allAchievements, userAchievements);
          
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories.keys.elementAt(index);
              final achievementsInCategory = categories[category]!;
              
              // Фильтрация
              var filtered = achievementsInCategory;
              if (_searchQuery.isNotEmpty) {
                filtered = filtered.where((a) =>
                  a.achievement.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  a.achievement.description.toLowerCase().contains(_searchQuery.toLowerCase())
                ).toList();
              }
              if (_showOnlyUnlocked) {
                filtered = filtered.where((a) => a.isUnlocked).toList();
              }
              
              if (filtered.isEmpty) return const SizedBox.shrink();
              
              return _buildCategorySection(
                category: category,
                achievements: filtered,
              );
            },
          );
        },
      ),
    );
  }
  
  Map<AchievementCategory, List<UserAchievement>> _groupAchievementsByCategory(
    List<Achievement> achievements,
    Map<String, UserAchievement> userAchievements,
  ) {
    final Map<AchievementCategory, List<UserAchievement>> result = {};
    
    for (final achievement in achievements) {
      if (!result.containsKey(achievement.category)) {
        result[achievement.category] = [];
      }
      result[achievement.category]!.add(userAchievements[achievement.id]!);
    }
    
    return result;
  }
  
  Widget _buildCategorySection({
    required AchievementCategory category,
    required List<UserAchievement> achievements,
  }) {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок категории
        Container(
          margin: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(category.color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(category.color).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                category.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(category.color),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(category.color),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unlockedCount/$totalCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Сетка бейджей (3 в ряд)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final userAchievement = achievements[index];
            return _buildBadgeCard(userAchievement, category.color);
          },
        ),
      ],
    );
  }
  
  Widget _buildBadgeCard(UserAchievement userAchievement, int categoryColor) {
    final achievement = userAchievement.achievement;
    final isUnlocked = userAchievement.isUnlocked;
    final tierColor = Color(achievement.tier.color);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AchievementDetailScreen(
              userAchievement: userAchievement,
              onAchievementUpdated: _loadData,
            ),
          ),
        );
      },
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
            // Иконка / Силуэт
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
                    ? _buildAchievementIcon(achievement, tierColor)
                    : _buildSilhouetteIcon(achievement),
              ),
            ),
            const SizedBox(height: 6),
            
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
            
            // Прогресс (только для неразблокированных числовых)
            if (!isUnlocked && achievement.isNumericCondition) ...[
              const SizedBox(height: 4),
              Container(
                width: 60,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  widthFactor: userAchievement.progressPercent.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: tierColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userAchievement.progressText,
                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
              ),
            ],
            
            if (isUnlocked) ...[
              const SizedBox(height: 4),
              const Icon(Icons.check_circle, size: 12, color: Colors.green),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Иконка для разблокированного достижения
  Widget _buildAchievementIcon(Achievement achievement, Color tierColor) {
    // Пытаемся загрузить иконку из ассетов
    if (achievement.iconPath.isNotEmpty) {
      return Image.asset(
        achievement.iconPath,
        width: 32,
        height: 32,
        errorBuilder: (context, error, stackTrace) {
          // Если иконки нет — показываем символ
          return Icon(
            _getIconForCategory(achievement.category),
            size: 28,
            color: tierColor,
          );
        },
      );
    }
    
    // Если путь пустой — показываем символ
    return Icon(
      _getIconForCategory(achievement.category),
      size: 28,
      color: tierColor,
    );
  }
  
  /// Силуэт для заблокированного достижения
  Widget _buildSilhouetteIcon(Achievement achievement) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Силуэт иконки (серый полупрозрачный)
        Opacity(
          opacity: 0.3,
          child: Icon(
            _getIconForCategory(achievement.category),
            size: 28,
            color: Colors.grey[600],
          ),
        ),
        // Замочек поверх
        const Icon(
          Icons.lock_outline,
          size: 16,
          color: Colors.grey,
        ),
      ],
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
  
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Поиск достижений'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Название или описание...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}