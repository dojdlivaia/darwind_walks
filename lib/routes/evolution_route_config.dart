// lib/routes/evolution_route_config.dart

import 'package:flutter/widgets.dart';

class EvolutionRouteConfig<TNode> {
  final String id; // 'jurassic', 'whale', 'cenozoic'
  final String jsonAssetPath;

  final int Function(TNode) cumulativeStepsOf;
  final String Function(TNode) speciesOf;
  final String Function(TNode) funFactOf;
  final String Function(TNode) textOf;

  final bool Function(TNode node, List<TNode> allNodes) isFinalNode;

  final Widget Function(TNode node, bool isUnlocked, bool hasReachedFinal)
      buildCreature;

  final Widget Function(TNode node) buildBackground;

  final Widget Function({
    required int currentSteps,
    required int totalSteps,
    required List<TNode> nodes,
    required void Function(TNode) onNodeSelected,
  }) buildProgressBar;

  /// Коллбек, который экран вызывает при нажатии на иконку карты.
  /// Если null — иконку не показываем.
  final void Function(BuildContext context, List<TNode> nodes, int userSteps)?
      onOpenTimeline;

  const EvolutionRouteConfig({
    required this.id,
    required this.jsonAssetPath,
    required this.cumulativeStepsOf,
    required this.speciesOf,
    required this.funFactOf,
    required this.textOf,
    required this.isFinalNode,
    required this.buildCreature,
    required this.buildBackground,
    required this.buildProgressBar,
    this.onOpenTimeline,
  });
}
