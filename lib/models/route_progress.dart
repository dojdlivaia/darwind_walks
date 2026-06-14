class ActiveRoute {
  final String routeId;
  final DateTime startedAt;
  
  ActiveRoute({
    required this.routeId,
    required this.startedAt,
  });
  
  // ✅ toMap — для сохранения в БД
  Map<String, dynamic> toMap() => {
    'routeId': routeId,
    'startedAt': startedAt.toIso8601String(),
  };
  
  // ✅ fromMap — фабричный конструктор для чтения из БД
  factory ActiveRoute.fromMap(Map<String, dynamic> map) {
    return ActiveRoute(
      routeId: map['routeId'] as String,
      startedAt: DateTime.parse(map['startedAt'] as String),
    );
  }
  
  // ✅ Альтернатива: именованный конструктор
  ActiveRoute.fromJson(Map<String, dynamic> json)
      : routeId = json['routeId'] as String,
        startedAt = DateTime.parse(json['startedAt'] as String);
}