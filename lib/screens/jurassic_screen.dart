// lib/screens/jurassic_screen.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pedometer/pedometer.dart';

import '../models/jurassic.dart';
import '../widgets/evolution_progress_bar.dart';
import '../widgets/bouncing_creature.dart';
import '../widgets/bubbles_background.dart';
import '../widgets/forest_leaves_background.dart';
import '../widgets/rain_background.dart';
import '../widgets/final_creature_intro.dart';
import '../widgets/simple_confetti.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/breathing_gradient_background.dart';
import 'jurassic_vertical_timeline_screen.dart';

class JurassicScreen extends StatefulWidget {
  const JurassicScreen({super.key});

  @override
  State<JurassicScreen> createState() => _JurassicScreenState();
}

class _JurassicScreenState extends State<JurassicScreen> {
  JurassicData? _data;
  bool _isLoading = true;

  bool _hasReachedFinal = false;
  bool _showFinalConfetti = false;

  int _userSteps = 0;
  JurassicNode? _selectedNode;

  StreamSubscription<StepCount>? _stepSub;

  // Константа цветов фона
  static const List<Color> _backgroundColors = [
    Color(0xFF0A1929),
    Color(0xFF1A365D),
    Color(0xFF2D4A6E),
    Color(0xFF0A1929),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _initPedometer();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/jurassic.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final data = JurassicData.fromJson(jsonMap);

      setState(() {
        _data = data;
        _selectedNode = data.nodes.first;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading jurassic data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initPedometer() async {
    try {
      _stepSub = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepError,
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Pedometer init error: $e');
    }
  }

  void _onStepCount(StepCount event) {
    final int newSteps = event.steps;

    if (_data == null) {
      setState(() {
        _userSteps = newSteps;
      });
      return;
    }

    setState(() {
      _userSteps = newSteps.clamp(0, _data!.totalSteps);

      final latestUnlockedNode = _findLastUnlockedNode(
        _data!.nodes,
        _userSteps,
      );

      if (latestUnlockedNode.cumulativeSteps >
          (_selectedNode?.cumulativeSteps ?? 0)) {
        _selectedNode = latestUnlockedNode;
      }

      if (_selectedNode!.species == 'Компсогнат' && !_hasReachedFinal) {
        _hasReachedFinal = true;
        _showFinalConfetti = true;

        Future.delayed(const Duration(seconds: 6), () {
          if (!mounted) return;
          setState(() {
            _showFinalConfetti = false;
          });
        });
      }
    });
  }

  void _onStepError(error) {
    debugPrint('Pedometer error: $error');
  }

  JurassicNode _findLastUnlockedNode(List<JurassicNode> nodes, int steps) {
    JurassicNode result = nodes.first;
    for (final node in nodes) {
      if (node.cumulativeSteps <= steps) {
        result = node;
      } else {
        break;
      }
    }
    return result;
  }

  bool _isNodeUnlocked(JurassicNode node) {
    return node.cumulativeSteps <= _userSteps;
  }

  void _onNodeSelected(JurassicNode node) {
    setState(() {
      _selectedNode = node;
    });
  }

  void _simulateSteps() {
    if (_data == null) return;

    setState(() {
      _userSteps += 500;
      if (_userSteps > _data!.totalSteps) {
        _userSteps = _data!.totalSteps;
      }

      final latestUnlockedNode = _findLastUnlockedNode(
        _data!.nodes,
        _userSteps,
      );

      if (latestUnlockedNode.cumulativeSteps >
          (_selectedNode?.cumulativeSteps ?? 0)) {
        _selectedNode = latestUnlockedNode;
      }

      if (_selectedNode!.species == 'Компсогнат' && !_hasReachedFinal) {
        _hasReachedFinal = true;
        _showFinalConfetti = true;

        Future.delayed(const Duration(seconds: 6), () {
          if (!mounted) return;
          setState(() {
            _showFinalConfetti = false;
          });
        });
      }
    });
  }

  Widget _buildBaseImage(JurassicNode node, bool isUnlocked) {
    final image = Image.asset(
      node.imageUrl,
      key: ValueKey('img_${node.imageUrl}_$isUnlocked'),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.image_not_supported,
          size: 80,
          color: Colors.white54,
        );
      },
    );

    if (isUnlocked) return image;

    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0xFF27301F), BlendMode.srcATop),
      child: Opacity(opacity: 0.6, child: image),
    );
  }

  Widget _buildDinoImage(JurassicNode node) {
    final bool isUnlocked = _isNodeUnlocked(node);
    final baseImage = _buildBaseImage(node, isUnlocked);

    if (node.species == 'Компсогнат') {
      if (!isUnlocked) return baseImage;

      return FinalCreatureIntro(
        play: !_hasReachedFinal,
        child: BouncingCreature(
          amplitude: 6,
          duration: const Duration(seconds: 5),
          child: baseImage,
        ),
      );
    }

    if (!isUnlocked) return baseImage;

    return BouncingCreature(
      amplitude: 8,
      duration: const Duration(seconds: 4),
      child: baseImage,
    );
  }

  Widget _buildBackground(JurassicNode node) {
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

  void _openTimeline() {
    if (_data == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            JurassicVerticalTimelineScreen(data: _data!, userSteps: _userSteps),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return BreathingGradientBackground(
        colors: _backgroundColors,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
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

    return BreathingGradientBackground(
      colors: _backgroundColors,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _simulateSteps,
          backgroundColor: Colors.black87,
          icon: const Icon(Icons.directions_walk, color: Colors.white),
          label: const Text(
            '+500 шагов',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Верх: фон + динозавр + конфетти
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
                        padding: const EdgeInsets.all(32.0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: _buildDinoImage(node),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black87,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.map_outlined,
                                color: Colors.black87,
                              ),
                              onPressed: _openTimeline,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.settings_outlined,
                                color: Colors.black87,
                              ),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                    SimpleConfetti(isActive: _showFinalConfetti),
                  ],
                ),
              ),

              // Низ: карточка с текстом, прогресс‑баром и счётчиком шагов
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    // Основной контейнер
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
                          // Область прокрутки текста
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
                                      color: Colors.black87,
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

                          // Фиксированная нижняя часть с прогресс-баром
                          Container(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                            color: Colors.white,
                            child: Column(
                              children: [
                                EvolutionProgressBar<JurassicNode>(
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
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_userSteps / ${_data!.totalSteps} шагов',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
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

                    // Заголовок поверх карточки
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
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Нижнее меню
              DarwinBottomBar(
                currentIndex: 0,
                onHomeTapped: (index) {},
                onInfoTapped: (index) {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
