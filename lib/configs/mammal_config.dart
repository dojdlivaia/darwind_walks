// lib/configs/mammal_config.dart

import 'package:flutter/material.dart';
import '../models/mammal.dart' as simple;  // ✅ псевдоним для простой модели
import '../models/mammal_node.dart';       // ✅ полная модель (без псевдонима)
import '../screens/evolution_route_screen.dart';
import '../screens/mammal_vertical_timeline_screen.dart';

class MammalConfig {
  static RouteConfig<MammalNode> get() {  // ✅ MammalNode из mammal_node.dart
    return RouteConfig<MammalNode>(
      routeId: 'mammals',
      jsonPath: 'assets/data/mammals.json',
      backgroundColors: const [
        Color(0xFF2D1B3D),
        Color(0xFF4A2B5A),
        Color(0xFF6B3F7A),
        Color(0xFF2D1B3D),
      ],
      fromJson: (json) {
        // ✅ Используем простую модель для парсинга
        final data = simple.MammalData.fromJson(json);
        // ✅ Преобразуем simple.MammalNode в MammalNode (из mammal_node.dart)
        return data.nodes.map((simpleNode) {
          return MammalNode(
            species: simpleNode.species,
            timeMya: simpleNode.timeMya.toDouble(),
            cumulativeSteps: simpleNode.cumulativeSteps,
            media: MediaCollection(
              primary: MediaItem(
                url: simpleNode.imageUrl,
                type: 'reconstruction',
                caption: simpleNode.species,
                credit: 'Darwin Walk',
              ),
              gallery: [],
            ),
            funfact: simpleNode.funfact,
            text: simpleNode.text,
            lengthM: simpleNode.lengthM,
            heightM: simpleNode.heightM,
            weightKg: simpleNode.weightKg,
            wingspanM: simpleNode.wingspanM,
            background: simpleNode.background,
          );
        }).toList();
      },
      getCumulativeSteps: (n) => n.cumulativeSteps,
      getSpecies: (n) => n.species,
      getFunFact: (n) => n.funfact,
      getText: (n) => n.text,
      getImageUrl: (n) => n.media.primary.url,
      getBackground: (n) => n.background ?? 'ForestLeavesBackground',
      getLength: (n) => n.lengthM,
      getHeight: (n) => n.heightM,
      getWeight: (n) => n.weightKg,
      getWingspan: (n) => n.wingspanM ?? 0,
      isFinalNode: (node, nodes) =>
          node.species.contains('Человек') && node == nodes.last,
      timelineBuilder: (context, nodes, userSteps) {
        return MammalVerticalTimelineScreen(
          userSteps: userSteps,
        );
      },
    );
  }
}