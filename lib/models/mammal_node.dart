// lib/models/mammal_node.dart

/// Медиа-информация для изображения
class MediaItem {
  final String url;
  final String type; // ct_scan, fossil, microscope, reconstruction, xray, museum, field
  final String caption;
  final String credit;
  final String? license;

  MediaItem({
    required this.url,
    required this.type,
    required this.caption,
    required this.credit,
    this.license,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      url: json['url'],
      type: json['type'],
      caption: json['caption'],
      credit: json['credit'],
      license: json['license'],
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'type': type,
    'caption': caption,
    'credit': credit,
    'license': license,
  };
}

/// Коллекция медиа для вида
class MediaCollection {
  final MediaItem primary;
  final List<MediaItem> gallery;

  MediaCollection({
    required this.primary,
    this.gallery = const [],
  });

  factory MediaCollection.fromJson(Map<String, dynamic> json) {
    return MediaCollection(
      primary: MediaItem.fromJson(json['primary']),
      gallery: (json['gallery'] as List?)
          ?.map((e) => MediaItem.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'primary': primary.toJson(),
    'gallery': gallery.map((e) => e.toJson()).toList(),
  };
}

/// Узел эволюционного маршрута
class MammalNode {
  final String species;
  final double timeMya; // млн лет назад (отрицательное число)
  final int cumulativeSteps;
  final MediaCollection media;
  final String funfact;
  final String text;
  final double lengthM;
  final double? heightM;
  final double weightKg;
  final double? wingspanM;
  final String? background;

  MammalNode({
    required this.species,
    required this.timeMya,
    required this.cumulativeSteps,
    required this.media,
    required this.funfact,
    required this.text,
    required this.lengthM,
    this.heightM,
    required this.weightKg,
    this.wingspanM,
    this.background,
  });

  // 🔹 Вычисляемые поля для отображения
  String get formattedTime {
    final abs = timeMya.abs();
    if (abs >= 100) return '${abs.round()} млн лет';
    if (abs >= 1) return '${abs.toStringAsFixed(1)} млн лет';
    return '${(abs * 1000).round()} тыс. лет';
  }

  String get lengthText {
    if (lengthM < 0.1) return '${(lengthM * 1000).round()} мм';
    if (lengthM < 1) return '${(lengthM * 100).round()} см';
    if (lengthM < 10) return '${lengthM.toStringAsFixed(1)} м';
    return '${lengthM.round()} м';
  }

  String get heightText {
    if (heightM == null) return '—';
    if (heightM! < 0.1) return '${(heightM! * 1000).round()} мм';
    if (heightM! < 1) return '${(heightM! * 100).round()} см';
    if (heightM! < 10) return '${heightM!.toStringAsFixed(1)} м';
    return '${heightM!.round()} м';
  }

  String get weightText {
    if (weightKg < 0.01) return '${(weightKg * 1000).round()} г';
    if (weightKg < 1) return '${(weightKg * 1000).round()} г';
    if (weightKg < 1000) return '${weightKg.round()} кг';
    if (weightKg < 10000) return '${(weightKg / 1000).toStringAsFixed(1)} т';
    return '${(weightKg / 1000).round()} т';
  }

  String get wingspanText {
    if (wingspanM == null) return '—';
    if (wingspanM! < 1) return '${(wingspanM! * 100).round()} см';
    if (wingspanM! < 10) return '${wingspanM!.toStringAsFixed(1)} м';
    return '${wingspanM!.round()} м';
  }

  // 🔹 Статус
  bool isUnlocked(int userSteps) => cumulativeSteps <= userSteps;
  bool isCurrent(int userSteps) {
    // Проверяем, что этот узел — последний пройденный
    // (в реальной реализации нужно передавать список всех узлов)
    return false; // будет переопределено в таймлайне
  }

  factory MammalNode.fromJson(Map<String, dynamic> json) {
    return MammalNode(
      species: json['species'],
      timeMya: json['time_mya'].toDouble(),
      cumulativeSteps: json['cumulative_steps'],
      media: MediaCollection.fromJson(json['media']),
      funfact: json['funfact'],
      text: json['text'],
      lengthM: json['length_m'].toDouble(),
      heightM: json['height_m']?.toDouble(),
      weightKg: json['weight_kg'].toDouble(),
      wingspanM: json['wingspan_m']?.toDouble(),
      background: json['background'],
    );
  }

  Map<String, dynamic> toJson() => {
    'species': species,
    'time_mya': timeMya,
    'cumulative_steps': cumulativeSteps,
    'media': media.toJson(),
    'funfact': funfact,
    'text': text,
    'length_m': lengthM,
    'height_m': heightM,
    'weight_kg': weightKg,
    'wingspan_m': wingspanM,
    'background': background,
  };
}

/// Корневой объект маршрута
class MammalTimelineData {
  final String period;
  final double startMya;
  final double endMya;
  final int totalSteps;
  final String description;
  final List<MammalNode> nodes;

  MammalTimelineData({
    required this.period,
    required this.startMya,
    required this.endMya,
    required this.totalSteps,
    required this.description,
    required this.nodes,
  });

  factory MammalTimelineData.fromJson(Map<String, dynamic> json) {
    return MammalTimelineData(
      period: json['period'],
      startMya: json['start_mya'].toDouble(),
      endMya: json['end_mya'].toDouble(),
      totalSteps: json['total_steps'],
      description: json['description'] ?? '',
      nodes: (json['nodes'] as List)
          .map((e) => MammalNode.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'period': period,
    'start_mya': startMya,
    'end_mya': endMya,
    'total_steps': totalSteps,
    'description': description,
    'nodes': nodes.map((e) => e.toJson()).toList(),
  };
}