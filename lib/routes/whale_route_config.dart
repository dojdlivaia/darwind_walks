// lib/routes/whale_route_config.dart

import 'package:flutter/material.dart';

import '../models/whale.dart';
import '../routes/evolution_route_config.dart';
import '../widgets/bouncing_creature.dart';
import '../widgets/bubbles_background.dart';
import '../widgets/final_creature_intro.dart';
import '../widgets/whale_progress_bar.dart';
import '../screens/whale_vertical_timeline_screen.dart';

EvolutionRouteConfig<WhaleNode> buildWhaleRouteConfig() {
  Widget buildBaseImage(WhaleNode node, bool isUnlocked) {
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

    // Силуэт для закрытого узла
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Color.fromARGB(255, 30, 49, 52),
        BlendMode.srcATop,
      ),
      child: Opacity(opacity: 0.6, child: image),
    );
  }

  return EvolutionRouteConfig<WhaleNode>(
    id: 'whale',
    jsonAssetPath: 'assets/data/whale.json',

    // Мапперы данных
    cumulativeStepsOf: (n) => n.cumulativeSteps,
    speciesOf: (n) => n.species,
    funFactOf: (n) => n.funfact,
    textOf: (n) => n.text,

    // Финальный узел — голубой кит
    isFinalNode: (node, nodes) =>
        node.species == 'Голубой кит' || node.species == 'Blue Whale',

    // Фоновая анимация (пузыри)
    buildBackground: (_) => const BubblesBackground(bubblesCount: 17),

    // Существо + анимации
    buildCreature: (node, isUnlocked, hasReachedFinal) {
      final baseImage = buildBaseImage(node, isUnlocked);

      // Голубой кит – финальная анимация только когда открыт
      if (node.species == 'Blue Whale' || node.species == 'Голубой кит') {
        if (!isUnlocked) return baseImage;

        return FinalCreatureIntro(
          play: !hasReachedFinal,
          child: BouncingCreature(
            amplitude: 6,
            duration: const Duration(seconds: 5),
            child: baseImage,
          ),
        );
      }

      // Остальные – покачивание только когда открыты
      if (!isUnlocked) return baseImage;

      return BouncingCreature(
        amplitude: 8,
        duration: const Duration(seconds: 4),
        child: baseImage,
      );
    },

    // Прогресс‑бар маршрута
    buildProgressBar: ({
      required int currentSteps,
      required int totalSteps,
      required List<WhaleNode> nodes,
      required void Function(WhaleNode) onNodeSelected,
    }) {
      return WhaleProgressBar(
        currentSteps: currentSteps,
        totalSteps: totalSteps,
        nodes: nodes,
        onNodeSelected: onNodeSelected,
      );
    },

    // Кнопка карты/таймлайна
    onOpenTimeline: (context, nodes, userSteps) {
      final data = WhaleData(
        theme: '', // можно подставить реальные значения, если нужны в таймлайне
        title: 'Эволюция китов',
        totalSteps: nodes.isNotEmpty ? nodes.last.cumulativeSteps : 0,
        nodes: nodes,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WhaleVerticalTimelineScreen(
            data: data,
            userSteps: userSteps,
          ),
        ),
      );
    },
  );
}
