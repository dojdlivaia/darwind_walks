// lib/screens/evolution_route_screen.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

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

// ============================================================
// КОНФИГУРАЦИЯ МАРШРУТА
// ============================================================

/// Конфигурация маршрута для универсального экрана
class RouteConfig<T> {
  final String routeId;
  final String jsonPath;
  final List<Color> backgroundColors;
  final List<T> Function(Map<String, dynamic>) fromJson;
  final int Function(T) getCumulativeSteps;
  final String Function(T) getSpecies;
  final String Function(T) getFunFact;
  final String Function(T) getText;
  final String Function(T) getImageUrl;
  final String Function(T) getBackground;
  final double Function(T) getLength;
  final double? Function(T) getHeight;
  final double Function(T) getWeight;
  final double? Function(T) getWingspan;
  final bool Function(T, List<T>) isFinalNode;

  final Widget Function(BuildContext, List<T>, int)? timelineBuilder;
 
  const RouteConfig({
    required this.routeId,
    required this.jsonPath,
    required this.backgroundColors,
    required this.fromJson,
    required this.getCumulativeSteps,
    required this.getSpecies,
    required this.getFunFact,
    required this.getText,
    required this.getImageUrl,
    required this.getBackground,
    required this.getLength,
    required this.getHeight,
    required this.getWeight,
    required this.getWingspan,
    required this.isFinalNode,
    this.timelineBuilder, 
  });
}

// ============================================================
// УНИВЕРСАЛЬНЫЙ ЭКРАН МАРШРУТА
// ============================================================

class EvolutionRouteScreen<T> extends StatefulWidget {
  final RouteConfig<T> config;
  final String routeId;

  const EvolutionRouteScreen({
    super.key,
    required this.config,
    required this.routeId,
  });

  @override
  State<EvolutionRouteScreen<T>> createState() =>
      _EvolutionRouteScreenState<T>();
}

class _EvolutionRouteScreenState<T> extends State<EvolutionRouteScreen<T>> {
  // ============================
  // ДАННЫЕ МАРШРУТА
  // ============================
  List<T>? _nodes;
  int _totalSteps = 0;
  bool _isLoading = true;
  bool _hasReachedFinal = false;
  bool _showFinalConfetti = false;

  // ============================
  // ПРОГРЕСС ПОЛЬЗОВАТЕЛЯ
  // ============================
  int _userSteps = 0;
  T? _selectedNode;
  RouteStateRepository? _routeRepo;
  bool _isRouteCompleted = false;

  // ============================
  // ТАЙМЕР ОБНОВЛЕНИЯ
  // ============================
  Timer? _updateTimer;
  bool _isUpdating = false;
  static const Duration _updateInterval = Duration(seconds: 8);

  // ============================
  // ЖИЗНЕННЫЙ ЦИКЛ
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
  // ЗАГРУЗКА СТАТУСА МАРШРУТА
  // ============================
  Future<void> _loadRouteStatus() async {
    _routeRepo = await RouteStateRepository.getInstance();
    final isCompleted = await _routeRepo!.isRouteCompleted(widget.routeId);
    final activeRoute = await _routeRepo!.getActiveRoute();

    if (activeRoute?.routeId == widget.routeId && !isCompleted) {
      CurrentRouteManager.instance.startRoute(widget.routeId);
    } else if (CurrentRouteManager.instance.currentRouteId == widget.routeId) {
      CurrentRouteManager.instance.stopRoute();
    }

    if (mounted) {
      setState(() => _isRouteCompleted = isCompleted);
    }

    if (!isCompleted) {
      _loadStepsFromRepository();
    }
  }

  // ============================
  // ЗАГРУЗКА ШАГОВ ИЗ БД
  // ============================
  Future<void> _loadStepsFromRepository() async {
    try {
      final startDate = DateTime(2026, 1, 1);
      final today = DateTime.now();

      final stepsRepo = await DailyStepsRepository.getInstance();
      final stats = await stepsRepo.getRange(from: startDate, to: today);

      if (mounted) {
        setState(() {
          _userSteps = stats.fold(
            0,
            (sum, stat) => sum + (stat.stepsByRoute[widget.routeId] ?? 0),
          );
          _updateSelectedNode();
        });
        _checkRouteCompletion();
      }
    } catch (e) {
      debugPrint('Error loading steps for ${widget.routeId}: $e');
    }
  }

  /// Обновляет выбранный узел на основе текущих шагов
  void _updateSelectedNode() {
    if (_nodes == null || _nodes!.isEmpty) return;
    final latestUnlocked = _findLastUnlockedNode(_nodes!, _userSteps);
    if (_selectedNode == null ||
        widget.config.getCumulativeSteps(_selectedNode as T) <
            widget.config.getCumulativeSteps(latestUnlocked)) {
      _selectedNode = latestUnlocked;
    }
  }

  // ============================
  // ПЕРИОДИЧЕСКОЕ ОБНОВЛЕНИЕ
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
      final stats = await stepsRepo.getRange(from: startDate, to: today);

      if (mounted) {
        final newSteps = stats.fold(
          0,
          (sum, stat) => sum + (stat.stepsByRoute[widget.routeId] ?? 0),
        );

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
  // ПРОВЕРКА ЗАВЕРШЕНИЯ МАРШРУТА
  // ============================
  Future<void> _checkRouteCompletion() async {
    if (_nodes == null || _isRouteCompleted) return;

    final isComplete = _userSteps >= _totalSteps;
    if (isComplete && !_hasReachedFinal) {
      setState(() {
        _hasReachedFinal = true;
        _showFinalConfetti = true;
      });

      Future.delayed(const Duration(seconds: 6), () {
        if (!mounted) return;
        setState(() => _showFinalConfetti = false);
      });
    }
  }

  // ============================
  // ЗАГРУЗКА ДАННЫХ МАРШРУТА
  // ============================
  Future<void> _loadData() async {
    try {
      final jsonString = await rootBundle.loadString(widget.config.jsonPath);
      final jsonMap = json.decode(jsonString);
      
      final nodes = widget.config.fromJson(jsonMap);
      final totalSteps = jsonMap['total_steps'] as int? ?? 0;

      setState(() {
        _nodes = nodes;
        _totalSteps = totalSteps;
        _selectedNode = nodes.isNotEmpty ? nodes.first : null;
        _isLoading = false;
      });

      _checkRouteCompletion();
    } catch (e) {
      debugPrint('Error loading ${widget.routeId} data: $e');
      setState(() => _isLoading = false);
    }
  }

  // ============================
  // ЛОГИКА УЗЛОВ
  // ============================
  T _findLastUnlockedNode(List<T> nodes, int steps) {
    T result = nodes.first;
    for (final node in nodes) {
      if (widget.config.getCumulativeSteps(node) <= steps) {
        result = node;
      } else {
        break;
      }
    }
    return result;
  }

  bool _isNodeUnlocked(T node) {
    return widget.config.getCumulativeSteps(node) <= _userSteps;
  }

  void _onNodeSelected(T node) {
    setState(() => _selectedNode = node);
  }

  // ============================
  // ЗАВЕРШЕНИЕ МАРШРУТА
  // ============================
  Future<void> _completeRoute() async {
    if (_nodes == null) return;

    if (_userSteps < _totalSteps) {
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Маршрут не пройден'),
          content: Text(
            'Вы прошли только $_userSteps из $_totalSteps шагов.\n\n'
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
          'Вы действительно хотите завершить маршрут?\n\n'
          '✅ Маршрут будет отмечен как пройденный\n'
          '❌ Это действие нельзя отменить',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );

    if (shouldComplete == true && mounted) {
      setState(() => _isLoading = true);

      try {
        await _routeRepo?.markRouteCompleted(widget.routeId);
        await _routeRepo?.clearActiveRoute();
        CurrentRouteManager.instance.stopRoute();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Поздравляем! Маршрут завершён! 🎉'),
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
  // ДЕТАЛИ СУЩЕСТВА
  // ============================
  void _showBlueprint(T node) {
    final creature = CreatureInfo(
      species: widget.config.getSpecies(node),
      imageUrl: widget.config.getImageUrl(node),
      lengthM: widget.config.getLength(node),
      heightM: widget.config.getHeight(node),
      weightKg: widget.config.getWeight(node),
      wingspanM: widget.config.getWingspan(node),
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
  // ВИДЖЕТЫ ОТОБРАЖЕНИЯ
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

  Widget _buildCreatureImage(T node) {
    final bool isUnlocked = _isNodeUnlocked(node);
    final baseImage = _buildSizedImage(
      widget.config.getImageUrl(node),
      isUnlocked,
    );

    if (!isUnlocked) return _buildLockedImage(baseImage);

    Widget creatureWidget = BouncingCreature(
      amplitude: 12,
      duration: const Duration(seconds: 4),
      shadowOffset: 40,
      showShadow: true,
      child: baseImage,
    );

    final nodes = _nodes!;
    if (widget.config.isFinalNode(node, nodes) && !_hasReachedFinal) {
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

  Widget _buildBackground(T node) {
    final bg = widget.config.getBackground(node);
    switch (bg) {
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
  // BUILD
  // ============================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return BreathingGradientBackground(
        colors: widget.config.backgroundColors,
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

    if (_nodes == null || _nodes!.isEmpty || _selectedNode == null) {
      return BreathingGradientBackground(
        colors: widget.config.backgroundColors,
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

    final node = _selectedNode as T;
    final isCompleted = _isRouteCompleted;
    final isFullyUnlocked = _userSteps >= _totalSteps;

    return BreathingGradientBackground(
      colors: widget.config.backgroundColors,
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
              if (widget.config.timelineBuilder != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.map_outlined,
                      color: Color(0xFF061B14),
                    ),
                    onPressed: () {
                      final nodes = _nodes!;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => widget.config.timelineBuilder!(
                            context,
                            nodes,
                            _userSteps,
                          ),
                        ),
                      );
                    },
                    tooltip: 'Таймлайна',
                  ),
                ),
            if (isFullyUnlocked && !isCompleted)
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.flag, color: Colors.white),
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
              // ВЕРХНЯЯ ПОЛОВИНА (существо + фон)
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

              // НИЖНЯЯ ПОЛОВИНА (информация + прогресс)
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
                          // Текст
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
                                    widget.config.getFunFact(node),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.4,
                                      color: Color(0xFF061B14),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    widget.config.getText(node),
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

                          // Прогресс-бар
                          Container(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                            color: Colors.white,
                            child: Column(
                              children: [
                                EvolutionProgressBar<T>(
                                  currentSteps: _userSteps,
                                  totalSteps: _totalSteps,
                                  nodes: _nodes!,
                                  stepsOf: widget.config.getCumulativeSteps,
                                  labelOf: widget.config.getSpecies,
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
                                      '$_userSteps / $_totalSteps шагов',
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

                    // Название существа
                    IgnorePointer(
                      child: Container(
                        height: 80,
                        alignment: Alignment.center,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            widget.config.getSpecies(node),
                            key: ValueKey(widget.config.getSpecies(node)),
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

              // НИЖНЕЕ МЕНЮ
              DarwinBottomBar(currentIndex: 0),
            ],
          ),
        ),
      ),
    );
  }
}