// lib/models/whale.dart

class WhaleData {
  final String theme;
  final String title;
  final int startMya;
  final int endMya;
  final int totalSteps;
  final List<WhaleNode> nodes;

  WhaleData({
    required this.theme,
    required this.title,
    required this.startMya,
    required this.endMya,
    required this.totalSteps,
    required this.nodes,
  });

  factory WhaleData.fromJson(Map<String, dynamic> json) {
    final nodesJson = json['nodes'] as List<dynamic>? ?? [];
    final nodes = nodesJson
        .map((e) => WhaleNode.fromJson(e as Map<String, dynamic>))
        .toList();

    return WhaleData(
      theme: json['theme'] as String? ?? 'Whale Evolution',
      title: json['title'] as String? ?? 'Назад в океан',
      startMya: _toInt(json['start_mya']) ?? 50,
      endMya: _toInt(json['end_mya']) ?? 0,
      totalSteps: _toInt(json['total_steps']) ?? 30000,
      nodes: nodes,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class WhaleNode {
  final String species;
  final int timeMya;
  final int cumulativeSteps;
  final String funfact;
  final String text;
  final String imageUrl;
  final double lengthM;
  final double? heightM;
  final double weightKg;
  final double? wingspanM;

  WhaleNode({
    required this.species,
    required this.timeMya,
    required this.cumulativeSteps,
    required this.funfact,
    required this.text,
    required this.imageUrl,
    required this.lengthM,
    this.heightM,
    required this.weightKg,
    this.wingspanM,
  });

  factory WhaleNode.fromJson(Map<String, dynamic> json) {
    return WhaleNode(
      species: json['species'] as String? ?? '',
      timeMya: _toInt(json['time_mya']) ?? 0,
      cumulativeSteps: _toInt(json['cumulative_steps']) ?? 0,
      funfact: json['funfact'] as String? ?? '',
      text: json['text'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      lengthM: _toDouble(json['length_m']) ?? 0.0,
      heightM: _toDoubleOrNull(json['height_m']),
      weightKg: _toDouble(json['weight_kg']) ?? 0.0,
      wingspanM: _toDoubleOrNull(json['wingspan_m']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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