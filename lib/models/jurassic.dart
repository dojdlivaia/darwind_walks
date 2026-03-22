import 'package:flutter/foundation.dart';

class JurassicData {
  final int totalSteps;
  final List<JurassicNode> nodes;

  const JurassicData({required this.totalSteps, required this.nodes});

  factory JurassicData.fromJson(Map<String, dynamic> json) {
    final nodesJson = json['nodes'] as List<dynamic>;
    final nodes = nodesJson
        .map((e) => JurassicNode.fromJson(e as Map<String, dynamic>))
        .toList();

    return JurassicData(totalSteps: json['total_steps'] as int, nodes: nodes);
  }
}

@immutable
class JurassicNode {
  final String species;
  final int timeMya;
  final int cumulativeSteps;
  final String funfact;
  final String text;
  final String imageUrl;
  final String
  background; // 'ForestLeavesBackground' | 'RainBackground' | 'BubblesBackground'

  const JurassicNode({
    required this.species,
    required this.timeMya,
    required this.cumulativeSteps,
    required this.funfact,
    required this.text,
    required this.imageUrl,
    required this.background,
  });

  factory JurassicNode.fromJson(Map<String, dynamic> json) {
    return JurassicNode(
      species: json['species'] as String,
      timeMya: json['time_mya'] as int,
      cumulativeSteps: json['cumulative_steps'] as int,
      funfact: json['funfact'] as String,
      text: json['text'] as String,
      imageUrl: json['image_url'] as String,
      background: json['background'] as String? ?? 'ForestLeavesBackground',
    );
  }
}
