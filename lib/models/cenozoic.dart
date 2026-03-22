// lib/models/cenozoic.dart

class CenozoicData {
  final String period;
  final int startMya;
  final int endMya;

  /// Общее количество шагов для прохождения периода.
  final int totalSteps;

  /// Список узлов эволюции.
  final List<CenozoicNode> nodes;

  const CenozoicData({
    required this.period,
    required this.startMya,
    required this.endMya,
    required this.totalSteps,
    required this.nodes,
  });

  factory CenozoicData.fromJson(Map<String, dynamic> json) {
    final nodesJson = json['nodes'] as List<dynamic>? ?? <dynamic>[];

    return CenozoicData(
      period: json['period'] as String? ?? 'Cenozoic',
      startMya: (json['start_mya'] as num?)?.toInt() ?? 0,
      endMya: (json['end_mya'] as num?)?.toInt() ?? 0,
      totalSteps: (json['total_steps'] as num?)?.toInt() ?? 0,
      nodes: nodesJson
          .map((e) => CenozoicNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'start_mya': startMya,
      'end_mya': endMya,
      'total_steps': totalSteps,
      'nodes': nodes.map((n) => n.toJson()).toList(),
    };
  }
}

class CenozoicNode {
  /// Название вида/этапа.
  final String species;

  /// Время (миллионы лет назад).
  final int timeMya;

  /// Накопленные шаги до этого узла (как в JurassicNode.cumulativeSteps).
  final int cumulativeSteps;

  /// Короткий забавный факт.
  final String funfact;

  /// Основной текст описания.
  final String text;

  /// Путь к картинке в ассетах.
  final String imageUrl;

  /// Имя виджета фона (ForestLeavesBackground / RainBackground / BubblesBackground).
  final String background;

  const CenozoicNode({
    required this.species,
    required this.timeMya,
    required this.cumulativeSteps,
    required this.funfact,
    required this.text,
    required this.imageUrl,
    required this.background,
  });

  factory CenozoicNode.fromJson(Map<String, dynamic> json) {
    return CenozoicNode(
      species: json['species'] as String? ?? '',
      timeMya: (json['time_mya'] as num?)?.toInt() ?? 0,
      cumulativeSteps: (json['cumulative_steps'] as num?)?.toInt() ?? 0,
      funfact: json['funfact'] as String? ?? '',
      text: json['text'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      background: json['background'] as String? ?? 'BubblesBackground',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'species': species,
      'time_mya': timeMya,
      'cumulative_steps': cumulativeSteps,
      'funfact': funfact,
      'text': text,
      'image_url': imageUrl,
      'background': background,
    };
  }
}
