// lib/models/whale.dart

class WhaleData {
  final String theme;
  final String title;
  final int totalSteps;
  final List<WhaleNode> nodes;

  WhaleData({
    required this.theme,
    required this.title,
    required this.totalSteps,
    required this.nodes,
  });

  factory WhaleData.fromJson(Map<String, dynamic> json) {
    return WhaleData(
      theme: json['theme'] ?? '',
      title: json['title'] ?? '',
      totalSteps: json['total_steps'] ?? 10000,
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((e) => WhaleNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <WhaleNode>[],
    );
  }
}

class WhaleNode {
  final String species;
  final int cumulativeSteps;
  final String funfact;
  final String text;
  final String imageUrl;

  WhaleNode({
    required this.species,
    required this.cumulativeSteps,
    required this.funfact,
    required this.text,
    required this.imageUrl,
  });

  factory WhaleNode.fromJson(Map<String, dynamic> json) {
    return WhaleNode(
      species: json['species'] ?? '',
      cumulativeSteps: json['cumulative_steps'] ?? 0,
      funfact: json['funfact'] ?? '',
      text: json['text'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}
