// lib/models/mammal.dart

/// Модель данных маршрута "Мир млекопитающих"
class MammalData {
  final String title;
  final int startMya;
  final int endMya;
  final int totalSteps;
  final List<MammalNode> nodes;

  const MammalData({
    required this.title,
    required this.startMya,
    required this.endMya,
    required this.totalSteps,
    required this.nodes,
  });

  factory MammalData.fromJson(Map<String, dynamic> json) {
    final nodesJson = json['nodes'] as List<dynamic>? ?? [];
    final nodes = nodesJson
        .map((e) => MammalNode.fromJson(e as Map<String, dynamic>))
        .toList();

    return MammalData(
      title: json['title'] as String? ?? 'Мир млекопитающих',
      startMya: (json['start_mya'] as num?)?.toInt() ?? 0,
      endMya: (json['end_mya'] as num?)?.toInt() ?? 0,
      totalSteps: (json['total_steps'] as num?)?.toInt() ?? 0,
      nodes: nodes,
    );
  }
}

/// Узел эволюции млекопитающих
class MammalNode {
  final String species;
  final int timeMya;
  final int cumulativeSteps;
  final String funfact;
  final String text;
  final String imageUrl;
  final String background;
  final double lengthM;
  final double? heightM;
  final double weightKg;
  final double? wingspanM;

  const MammalNode({
    required this.species,
    required this.timeMya,
    required this.cumulativeSteps,
    required this.funfact,
    required this.text,
    required this.imageUrl,
    required this.background,
    required this.lengthM,
    this.heightM,
    required this.weightKg,
    this.wingspanM,
  });

  factory MammalNode.fromJson(Map<String, dynamic> json) {
    return MammalNode(
      species: json['species'] as String? ?? '',
      timeMya: (json['time_mya'] as num?)?.toInt() ?? 0,
      cumulativeSteps: (json['cumulative_steps'] as num?)?.toInt() ?? 0,
      funfact: json['funfact'] as String? ?? '',
      text: json['text'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      background: json['background'] as String? ?? 'ForestLeavesBackground',
      lengthM: _toDouble(json['length_m']) ?? 0.0,
      heightM: _toDoubleOrNull(json['height_m']),
      weightKg: _toDouble(json['weight_kg']) ?? 0.0,
      wingspanM: _toDoubleOrNull(json['wingspan_m']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value);
    return null;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    return _toDouble(value);
  }

  String get lengthText => _formatLength(lengthM);
  String get heightText => heightM != null ? _formatLength(heightM!) : '—';
  String get weightText => _formatWeight(weightKg);
  String get wingspanText => wingspanM != null ? _formatLength(wingspanM!) : '—';

  String _formatLength(double meters) {
    if (meters < 1.0) {
      return '${(meters * 100).toInt()} см';
    } else if (meters == meters.floor()) {
      return '${meters.toInt()} м';
    } else {
      return '${meters.toStringAsFixed(1)} м';
    }
  }

  String _formatWeight(double kg) {
    if (kg < 1.0) {
      return '${(kg * 1000).toInt()} г';
    } else if (kg < 1000) {
      return '${kg.toStringAsFixed(kg == kg.floor() ? 0 : 1)} кг';
    } else {
      return '${(kg / 1000).toStringAsFixed(1)} т';
    }
  }
}