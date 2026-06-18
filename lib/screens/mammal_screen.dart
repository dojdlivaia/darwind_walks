// lib/screens/mammal_screen.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/mammal.dart';
import '../models/creature_info.dart';
import '../widgets/evolution_progress_bar.dart';
import '../widgets/bouncing_creature.dart';
import '../widgets/bubbles_background.dart';
import '../widgets/forest_leaves_background.dart';
import '../widgets/rain_background.dart';
import '../widgets/final_creature_intro.dart';
import '../widgets/simple_confetti.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/breathing_gradient_background.dart';
import '../widgets/creature_blueprint.dart';
import '../data/repositories/route_state_repository.dart';
import '../data/daily_steps_repository.dart';
import '../services/current_route_manager.dart';

class MammalScreen extends StatefulWidget {
  const MammalScreen({super.key});

  @override
  State<MammalScreen> createState() => _MammalScreenState();
}

class _MammalScreenState extends State<MammalScreen> {
  // ============================
  // Данные маршрута
  // ============================
  MammalData? _data;
  bool _isLoading = true;
  bool _hasReachedFinal = false;
  bool _showFinalConfetti = false;

  // ============================
  // Прогресс пользователя
  // ============================
  int _userSteps = 0;
  MammalNode? _selectedNode;
  
  RouteStateRepository? _routeRepo;
  bool _isRouteCompleted = false;

  // ============================
  // Таймер для обновления UI
  // ============================
  Timer? _updateTimer;
  bool _isUpdating = false;
  static const Duration _updateInterval = Duration(seconds: 8);

  // ============================
  // Цвета фона
  // ============================
  static const List<Color> _backgroundColors = [
    Color(0xFF2D1B3D),
    Color(0xFF4A2B5A),
    Color(0xFF6B3F7A),
    Color(0xFF2D1B3D),
  ];

  // ============================
  // Жизненный цикл
  // ============================
  @override
  void initState() {
    super.initState();
    _loadData();
    _loadRouteStatus();
    _startPeriodicUpdate();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _routeRepo?.close();
    super.dispose();
  }

  // ============================
  // Загрузка статуса маршрута
  // ============================
  Future<void> _loadRouteStatus() async {
    _routeRepo = await RouteStateRepository.getInstance();
    final isCompleted = await _routeRepo!.isRouteCompleted('mammals');
    final activeRoute = await _routeRepo!.getActiveRoute();
    
    if (activeRoute?.routeId == 'mammals' && !isCompleted) {
      CurrentRouteManager.instance.startRoute('mammals');
    } else if (CurrentRouteManager.instance.currentRouteId == 'mammals') {
      CurrentRouteManager.instance.stopRoute();
    }
    
    if (mounted) {
      setState(() {
        _isRouteCompleted = isCompleted;
      });
    }
    
    if (!isCompleted) {
      _loadStepsFromRepository();
    }
  }

  // ============================
  // Загрузка шагов из БД
  // ============================
  Future<void> _loadStepsFromRepository() async {
    try {
      final startDate = DateTime(2026, 1, 1);
      final today = DateTime.now();
      
      final stepsRepo = await DailyStepsRepository.getInstance();
      final stats = await stepsRepo.getRange(
        from: startDate,
        to: today,
      );
      
      if (mounted) {
        setState(() {
          _userSteps = stats.fold(0, (sum, stat) => sum + (stat.stepsByRoute['mammals'] ?? 0));
          _updateSelectedNode();
        });
        _checkRouteCompletion();
      }
    } catch (e) {
      debugPrint('Error loading cumulative steps: $e');
    }
  }

  void _updateSelectedNode() {
    if (_data == null || _data!.nodes.isEmpty) return;
    final latestUnlocked = _findLastUnlockedNode(_data!.nodes, _userSteps);
    if (_selectedNode == null || 
        _selectedNode!.cumulativeSteps < latestUnlocked.cumulativeSteps) {
      _selectedNode = latestUnlocked;
    }
  }

  // ============================
  // Периодическое обновление
  // ============================
  void _startPeriodicUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(_updateInterval, (timer) {
      if (mounted && !_isUpdating) {
        _refreshSteps();
      }
    });
  }

  Future<void> _refreshSteps() async {
    if (_isUpdating) return;
    _isUpdating = true;
    
    try {
      final startDate = DateTime(2026, 1, 1);
      final today = DateTime.now();
      
      final stepsRepo = await DailyStepsRepository.getInstance();
      final stats = await stepsRepo.getRange(
        from: startDate,
        to: today,
      );
      
      if (mounted) {
        final newSteps = stats.fold(0, (sum, stat) => sum + (stat.stepsByRoute['mammals'] ?? 0));
        
        if (newSteps != _userSteps) {
          setState(() {
            _userSteps = newSteps;
            _updateSelectedNode();
          });
          _checkRouteCompletion();
        }
      }
    } catch (e) {
      // Подавляем ошибки обновления для стабильности
    } finally {
      _isUpdating = false;
    }
  }

  // ============================
  // Проверка завершения маршрута
  // ============================
  Future<void> _checkRouteCompletion() async {
    if (_data == null || _isRouteCompleted) return;
    
    final isComplete = _userSteps >= _data!.totalSteps;
    if (isComplete && !_hasReachedFinal) {
      setState(() {
        _hasReachedFinal = true;
        _showFinalConfetti = true;
      });
      
      Future.delayed(const Duration(seconds: 6), () {
        if (!mounted) return;
        setState(() {
          _showFinalConfetti = false;
        });
      });
    }
  }

  // ============================
  // Загрузка данных маршрута
  // ============================
  Future<void> _loadData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/mammals.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final data = MammalData.fromJson(jsonMap);

      setState(() {
        _data = data;
        _selectedNode = data.nodes.isNotEmpty ? data.nodes.first : null;
        _isLoading = false;
      });
      
      _checkRouteCompletion();
    } catch (e) {
      debugPrint('Error loading mammal data: $e');
      setState(() => _isLoading = false);
    }
  }

  // ============================
  // Логика навигации по узлам
  // ============================
  MammalNode _findLastUnlockedNode(List<MammalNode> nodes, int steps) {
    MammalNode result = nodes.first;
    for (final node in nodes) {
      if (node.cumulativeSteps <= steps) {
        result = node;
      } else {
        break;
      }
    }
    return result;
  }

  bool _isNodeUnlocked(MammalNode node) {
    return node.cumulativeSteps <= _userSteps;
  }

  void _onNodeSelected(MammalNode node) {
    setState(() {
      _selectedNode = node;
    });
  }

  // ============================
  // Завершение маршрута
  // ============================
  Future<void> _completeRoute() async {
    if (_data == null) return;
    
    if (_userSteps < _data!.totalSteps) {
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Маршрут не пройден'),
          content: Text(
            'Вы прошли только $_userSteps из ${_data!.totalSteps} шагов. '
            'Завершить маршрут можно только после полного прохождения.\n\n'
            'Продолжайте ходить! 🚶‍♀️',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
      return;
    }
    
    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Завершить маршрут?'),
        content: const Text(
          'Вы действительно хотите завершить маршрут "Мир млекопитающих"?\n\n'
          '✅ Маршрут будет отмечен как пройденный\n'
          '✅ Вы получите доступ к новым маршрутам\n'
          '❌ Это действие нельзя отменить',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
    
    if (shouldComplete == true && mounted) {
      setState(() => _isLoading = true);
      
      try {
        await _routeRepo?.markRouteCompleted('mammals');
        await _routeRepo?.clearActiveRoute();
        CurrentRouteManager.instance.stopRoute();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Поздравляем! Маршрут "Мир млекопитающих" завершён! 🎉'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint('Error completing route: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка при завершении маршрута'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // ============================
  // Детали существа
  // ============================
  void _showBlueprint(MammalNode node) {
    final creature = CreatureInfo(
      species: node.species,
      imageUrl: node.imageUrl,
      lengthM: node.lengthM,
      heightM: node.heightM,
      weightKg: node.weightKg,
      wingspanM: node.wingspanM,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CreatureBlueprint(
            creature: creature,
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  // ============================
  // Виджеты отображения существ
  // ============================
  Widget _buildLockedImage(Widget image) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0xFF27301F), BlendMode.srcATop),
      child: Opacity(opacity: 0.6, child: image),
    );
  }

  Widget _buildSizedImage(String imageUrl, bool isUnlocked) {
    return Image.asset(
      imageUrl,
      width: 600,
      height: 600,
      fit: BoxFit.contain,
      key: ValueKey('img_${imageUrl}_$isUnlocked'),
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.image_not_supported,
          size: 80,
          color: Colors.white54,
        );
      },
    );
  }

  Widget _buildCreatureImage(MammalNode node) {
    final bool isUnlocked = _isNodeUnlocked(node);
    final baseImage = _buildSizedImage(node.imageUrl, isUnlocked);

    if (!isUnlocked) return _buildLockedImage(baseImage);

    Widget creatureWidget = BouncingCreature(
      amplitude: 12,
      duration: const Duration(seconds: 4),
      shadowOffset: 40,
      showShadow: true,
      child: baseImage,
    );

    // Для финального узла добавляем специальную анимацию
    if (node.species.contains('Человек') && !_hasReachedFinal) {
      creatureWidget = FinalCreatureIntro(
        play: !_hasReachedFinal,
        child: creatureWidget,
      );
    }

    return GestureDetector(
      onTap: isUnlocked ? () => _showBlueprint(node) : null,
      behavior: HitTestBehavior.opaque,
      child: creatureWidget,
    );
  }

  Widget _buildBackground(MammalNode node) {
    switch (node.background) {
      case 'ForestLeavesBackground':
        return const ForestLeavesBackground(leavesCount: 20);
      case 'RainBackground':
        return const RainBackground(dropsCount: 35);
      case 'BubblesBackground':
      default:
        return const BubblesBackground(bubblesCount: 17);
    }
  }

  // ============================
  // Build
  // ============================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return BreathingGradientBackground(
        colors: _backgroundColors,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
          ),
        ),
      );
    }

    if (_data == null || _selectedNode == null) {
      return BreathingGradientBackground(
        colors: _backgroundColors,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Text(
              'Ошибка загрузки данных',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    final node = _selectedNode!;
    final isCompleted = _isRouteCompleted;
    final isFullyUnlocked = _userSteps >= _data!.totalSteps;

    return BreathingGradientBackground(
      colors: _backgroundColors,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (isFullyUnlocked && !isCompleted)
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.flag,
                    color: Colors.white,
                  ),
                  onPressed: _completeRoute,
                  tooltip: 'Завершить маршрут',
                ),
              ),
            if (isCompleted)
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'ПРОЙДЕН',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.transparent,
                      child: _buildBackground(node),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: _buildCreatureImage(node),
                        ),
                      ),
                    ),
                    SimpleConfetti(isActive: _showFinalConfetti),
                  ],
                ),
              ),
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(
                                top: 80,
                                bottom: 16,
                                left: 24,
                                right: 24,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    node.funfact,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.4,
                                      color: Color(0xFF061B14),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    node.text,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.3,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                            color: Colors.white,
                            child: Column(
                              children: [
                                EvolutionProgressBar<MammalNode>(
                                  currentSteps: _userSteps,
                                  totalSteps: _data!.totalSteps,
                                  nodes: _data!.nodes,
                                  stepsOf: (n) => n.cumulativeSteps,
                                  labelOf: (n) => n.species,
                                  onNodeSelected: _onNodeSelected,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.directions_walk,
                                      size: 16,
                                      color: Color(0xFF4B5E09),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_userSteps / ${_data!.totalSteps} шагов',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF061B14),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (isCompleted)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: Colors.green,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IgnorePointer(
                      child: Container(
                        height: 80,
                        alignment: Alignment.center,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            node.species,
                            key: ValueKey(node.species),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF061B14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DarwinBottomBar(
                currentIndex: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}