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

    cumulativeStepsOf: (n) => n.cumulativeSteps,
    speciesOf: (n) => n.species,
    funFactOf: (n) => n.funfact,
    textOf: (n) => n.text,

    isFinalNode: (node, nodes) =>
        node.species == 'Голубой кит' || node.species == 'Blue Whale',

    buildBackground: (_) => const BubblesBackground(bubblesCount: 17),

    buildCreature: (node, isUnlocked, hasReachedFinal) {
      final baseImage = buildBaseImage(node, isUnlocked);

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

      if (!isUnlocked) return baseImage;

      return BouncingCreature(
        amplitude: 8,
        duration: const Duration(seconds: 4),
        child: baseImage,
      );
    },

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

    onOpenTimeline: (context, nodes, userSteps) {
      final totalSteps = nodes.isNotEmpty ? nodes.last.cumulativeSteps : 30000;
      
      final data = WhaleData(
        theme: 'Whale Evolution',
        title: 'Назад в океан: Как олень стал китом',
        startMya: 50,
        endMya: 0,
        totalSteps: totalSteps,
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