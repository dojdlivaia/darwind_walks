// lib/configs/whale_config.dart

import 'package:flutter/material.dart';
import '../models/whale.dart';
import '../screens/evolution_route_screen.dart';
import '../screens/whale_vertical_timeline_screen.dart';

class WhaleConfig {
  static RouteConfig<WhaleNode> get() {
    return RouteConfig<WhaleNode>(
      routeId: 'whale',
      jsonPath: 'assets/data/whale.json',
      backgroundColors: const [
        Color(0xFF1B2D3B),
        Color(0xFF1A4A5A),
        Color(0xFF2D6B7A),
        Color(0xFF1B2D3B),
      ],
      fromJson: (json) {
        final data = WhaleData.fromJson(json);
        return data.nodes;
      },
      getCumulativeSteps: (n) => n.cumulativeSteps,
      getSpecies: (n) => n.species,
      getFunFact: (n) => n.funfact,
      getText: (n) => n.text,
      getImageUrl: (n) => n.imageUrl,
      getBackground: (n) => 'BubblesBackground',
      getLength: (n) => n.lengthM,
      getHeight: (n) => n.heightM,
      getWeight: (n) => n.weightKg,
      getWingspan: (n) => n.wingspanM,
      isFinalNode: (node, nodes) =>
          node.species.contains('Современный кит') && node == nodes.last,
      timelineBuilder: (context, nodes, userSteps) {
        return WhaleVerticalTimelineScreen(
          data: WhaleData(
            theme: 'Whale Evolution',
            title: 'Назад в океан',
            startMya: 50,
            endMya: 0,
            totalSteps: 0,
            nodes: nodes,
          ),
          userSteps: userSteps,
        );
      },
    );
  }
}