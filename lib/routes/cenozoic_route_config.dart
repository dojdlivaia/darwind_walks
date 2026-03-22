// lib/routes/cenozoic_route_config.dart

import 'package:flutter/material.dart';

import '../models/cenozoic.dart';
import '../routes/evolution_route_config.dart';
import '../widgets/bouncing_creature.dart';
import '../widgets/bubbles_background.dart';
import '../widgets/forest_leaves_background.dart';
import '../widgets/rain_background.dart';
import '../widgets/final_creature_intro.dart';
import '../widgets/evolution_progress_bar.dart';

EvolutionRouteConfig<CenozoicNode> buildCenozoicRouteConfig() {
  Widget buildBaseImage(CenozoicNode node, bool isUnlocked) {
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
      colorFilter: const ColorFilter.mode(
        Color(0xFF27301F),
        BlendMode.srcATop,
      ),
      child: Opacity(opacity: 0.6, child: image),
    );
  }

  Widget buildBackground(CenozoicNode node) {
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

  return EvolutionRouteConfig<CenozoicNode>(
    id: 'cenozoic',
    jsonAssetPath: 'assets/data/cenozoic.json',

    cumulativeStepsOf: (n) => n.cumulativeSteps,
    speciesOf: (n) => n.species,
    funFactOf: (n) => n.funfact,
    textOf: (n) => n.text,

    // финальным считаем последний узел списка
    isFinalNode: (node, nodes) => node == nodes.last,

    buildBackground: buildBackground,

    buildCreature: (node, isUnlocked, hasReachedFinal) {
      final baseImage = buildBaseImage(node, isUnlocked);

      // финальное существо — последний узел, анимация может зависеть от hasReachedFinal
      if (!isUnlocked) return baseImage;

      // пример: пока финал не был достигнут, проигрываем более «праздничную» анимацию
      if (!hasReachedFinal) {
        return FinalCreatureIntro(
          play: true,
          child: BouncingCreature(
            amplitude: 6,
            duration: const Duration(seconds: 5),
            child: baseImage,
          ),
        );
      }

      // после достижения финала — обычное покачивание
      return BouncingCreature(
        amplitude: 8,
        duration: const Duration(seconds: 4),
        child: baseImage,
      );
    },

    buildProgressBar: ({
      required int currentSteps,
      required int totalSteps,
      required List<CenozoicNode> nodes,
      required void Function(CenozoicNode) onNodeSelected,
    }) {
      return EvolutionProgressBar<CenozoicNode>(
        currentSteps: currentSteps,
        totalSteps: totalSteps,
        nodes: nodes,
        stepsOf: (n) => n.cumulativeSteps,
        labelOf: (n) => n.species,
        onNodeSelected: onNodeSelected,
      );
    },
  );
}
