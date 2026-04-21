// lib/models/creature_info.dart

class CreatureInfo {
  final String species;
  final String imageUrl;
  final double lengthM;
  final double? heightM;
  final double weightKg;
  final double? wingspanM;

  const CreatureInfo({
    required this.species,
    required this.imageUrl,
    required this.lengthM,
    this.heightM,
    required this.weightKg,
    this.wingspanM,
  });

  // Фабричный конструктор для WhaleNode
  factory CreatureInfo.fromWhale(dynamic node) {
    if (node is Map<String, dynamic>) {
      return CreatureInfo(
        species: node['species'] as String? ?? '',
        imageUrl: node['image_url'] as String? ?? '',
        lengthM: _toDouble(node['length_m']) ?? 0.0,
        heightM: _toDouble(node['height_m']),
        weightKg: _toDouble(node['weight_kg']) ?? 0.0,
        wingspanM: _toDouble(node['wingspan_m']),
      );
    }
    throw ArgumentError('Unsupported type for CreatureInfo.fromWhale');
  }

  // Фабричный конструктор для JurassicNode
  factory CreatureInfo.fromJurassic(dynamic node) {
    if (node is Map<String, dynamic>) {
      return CreatureInfo(
        species: node['species'] as String? ?? '',
        imageUrl: node['image_url'] as String? ?? '',
        lengthM: _toDouble(node['length_m']) ?? 0.0,
        heightM: _toDouble(node['height_m']),
        weightKg: _toDouble(node['weight_kg']) ?? 0.0,
        wingspanM: _toDouble(node['wingspan_m']),
      );
    }
    throw ArgumentError('Unsupported type for CreatureInfo.fromJurassic');
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Геттеры для форматирования
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