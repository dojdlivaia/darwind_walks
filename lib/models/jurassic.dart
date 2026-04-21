// lib/models/jurassic.dart

import 'package:flutter/foundation.dart';

class JurassicData {
  final String period;
  final int startMya;
  final int endMya;
  final int totalSteps;
  final List<JurassicNode> nodes;

  const JurassicData({
    required this.period,
    required this.startMya,
    required this.endMya,
    required this.totalSteps,
    required this.nodes,
  });

  factory JurassicData.fromJson(Map<String, dynamic> json) {
    final nodesJson = json['nodes'] as List<dynamic>;
    final nodes = nodesJson
        .map((e) => JurassicNode.fromJson(e as Map<String, dynamic>))
        .toList();

    return JurassicData(
      period: json['period'] as String? ?? 'Jurassic',
      startMya: json['start_mya'] as int? ?? 200,
      endMya: json['end_mya'] as int? ?? 145,
      totalSteps: json['total_steps'] as int,
      nodes: nodes,
    );
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
  final String background;
  
  // 🔹 Новые поля: размеры и вес
  final double lengthM;         // длина в метрах
  final double? heightM;        // высота в метрах (может быть null)
  final double weightKg;        // вес в килограммах
  final double? wingspanM;      // размах крыльев (может быть null)

  const JurassicNode({
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

  factory JurassicNode.fromJson(Map<String, dynamic> json) {
    return JurassicNode(
      species: json['species'] as String,
      timeMya: json['time_mya'] as int,
      cumulativeSteps: json['cumulative_steps'] as int,
      funfact: json['funfact'] as String,
      text: json['text'] as String,
      imageUrl: json['image_url'] as String,
      background: json['background'] as String? ?? 'ForestLeavesBackground',
      lengthM: _toDouble(json['length_m']),
      heightM: _toDoubleOrNull(json['height_m']),
      weightKg: _toDouble(json['weight_kg']),
      wingspanM: _toDoubleOrNull(json['wingspan_m']),
    );
  }

  // 🔹 Вспомогательные методы для конвертации
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return 0.0;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return null;
  }

  // 🔹 Методы для форматирования
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