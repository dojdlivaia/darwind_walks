// lib/screens/evolution_route_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../routes/evolution_route_config.dart';
import '../widgets/simple_confetti.dart';
import '../widgets/breathing_gradient_background.dart';
import '../main.dart'; // global dailyStepsRepository
import 'statistics/statistics_screen.dart';

class EvolutionRouteScreen<TNode> extends StatefulWidget {
  const EvolutionRouteScreen({
    super.key,
    required this.config,
    required this.decodeData,
    this.showBottomIcons = true,
    this.backgroundColors,
  });

  final EvolutionRouteConfig<TNode> config;

  /// Функция, которая из jsonMap делает (nodes, totalSteps).
  final (List<TNode>, int) Function(Map<String, dynamic> jsonMap) decodeData;

  /// Показать ли три иконки внизу (домик/профиль/инфо) — для Whale/Cenozoic.
  final bool showBottomIcons;

  /// Цвета для "дышащего" градиента фона.
  /// Если null — градиент не используется.
  final List<Color>? backgroundColors;

  @override
  State<EvolutionRouteScreen<TNode>> createState() =>
      _EvolutionRouteScreenState<TNode>();
}

class _EvolutionRouteScreenState<TNode>
    extends State<EvolutionRouteScreen<TNode>> {
  List<TNode>? _nodes;
  int _totalSteps = 0;
  bool _isLoading = true;

  bool _hasReachedFinal = false;
  bool _showFinalConfetti = false;

  int _userSteps = 0;
  TNode? _selectedNode;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final jsonString = await rootBundle.loadString(
        widget.config.jsonAssetPath,
      );
      final jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;
      final (nodes, totalSteps) = widget.decodeData(jsonMap);

      setState(() {
        _nodes = nodes;
        _totalSteps = totalSteps;
        _selectedNode = nodes.isNotEmpty ? nodes.first : null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading route data: $e');
      setState(() => _isLoading = false);
    }
  }

  TNode _findLastUnlockedNode(List<TNode> nodes, int steps) {
    TNode result = nodes.first;
    for (final node in nodes) {
      if (widget.config.cumulativeStepsOf(node) <= steps) {
        result = node;
      } else {
        break;
      }
    }
    return result;
  }

  bool _isNodeUnlocked(TNode node) {
    return widget.config.cumulativeStepsOf(node) <= _userSteps;
  }

  void _onNodeSelected(TNode node) {
    setState(() {
      _selectedNode = node;
    });
  }

  void _simulateSteps() {
    if (_nodes == null) return;

    setState(() {
      _userSteps += 500;
      if (_userSteps > _totalSteps) {
        _userSteps = _totalSteps;
      }

      final latestUnlockedNode = _findLastUnlockedNode(
        _nodes!,
        _userSteps,
      );

      if (widget.config.cumulativeStepsOf(latestUnlockedNode) >
          (_selectedNode != null
              ? widget.config.cumulativeStepsOf(_selectedNode as TNode)
              : 0)) {
        _selectedNode = latestUnlockedNode;
      }

      final nodes = _nodes!;
      final current = _selectedNode;
      if (current != null &&
          widget.config.isFinalNode(current, nodes) &&
          !_hasReachedFinal) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      if (widget.backgroundColors == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return BreathingGradientBackground(
        colors: widget.backgroundColors!,
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (_nodes == null || _nodes!.isEmpty || _selectedNode == null) {
      if (widget.backgroundColors == null) {
        return const Scaffold(
          body: Center(child: Text('Ошибка загрузки данных')),
        );
      }

      return BreathingGradientBackground(
        colors: widget.backgroundColors!,
        child: const Scaffold(
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

    final node = _selectedNode as TNode;

    final scaffold = Scaffold(
      backgroundColor:
          widget.backgroundColors == null ? Colors.white : Colors.transparent,
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
            // Верх
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.transparent,
                    child: widget.config.buildBackground(node),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: widget.config.buildCreature(
                          node,
                          _isNodeUnlocked(node),
                          _hasReachedFinal,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.black87,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.config.onOpenTimeline != null)
                          IconButton(
                            icon: const Icon(
                              Icons.map_outlined,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              final nodes = _nodes!;
                              widget.config.onOpenTimeline!(
                                context,
                                nodes,
                                _userSteps,
                              );
                            },
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Colors.black54,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  SimpleConfetti(isActive: _showFinalConfetti),
                ],
              ),
            ),

            // Низ: карточка как в Jurassic
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
                                  widget.config.funFactOf(node),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.4,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.config.textOf(node),
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

                        // Фиксированная нижняя часть с прогресс‑баром и иконками
                        Container(
                          padding:
                              const EdgeInsets.fromLTRB(24, 16, 24, 16),
                          color: Colors.white,
                          child: Column(
                            children: [
                              widget.config.buildProgressBar(
                                currentSteps: _userSteps,
                                totalSteps: _totalSteps,
                                nodes: _nodes!,
                                onNodeSelected: _onNodeSelected,
                              ),
                              if (widget.showBottomIcons) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.home_outlined,
                                        size: 28,
                                        color: Colors.black87,
                                      ),
                                      onPressed: () {
                                        Navigator.of(context)
                                            .popUntil((route) => route.isFirst);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.person_outline,
                                        size: 28,
                                        color: Colors.black87,
                                      ),
                                      onPressed: () {
                                        // TODO: профиль
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.info_outline,
                                        size: 28,
                                        color: Colors.black87,
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => StatisticsScreen(
                                              repository: dailyStepsRepository,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
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
                          widget.config.speciesOf(node),
                          key: ValueKey(widget.config.speciesOf(node)),
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
          ],
        ),
      ),
    );

    if (widget.backgroundColors == null) return scaffold;

    return BreathingGradientBackground(
      colors: widget.backgroundColors!,
      child: scaffold,
    );
  }
}