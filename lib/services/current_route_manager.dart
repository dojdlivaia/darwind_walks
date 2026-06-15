// lib/services/current_route_manager.dart

import 'package:flutter/foundation.dart';

class CurrentRouteManager {
  CurrentRouteManager._();

  static final CurrentRouteManager instance = CurrentRouteManager._();

  String? _currentRouteId;

  String? get currentRouteId => _currentRouteId;

  void startRoute(String routeId) {
    _currentRouteId = routeId;
    debugPrint('📍 CurrentRouteManager: started route "$routeId"');
  }

  void stopRoute() {
    debugPrint('📍 CurrentRouteManager: stopped route "$_currentRouteId"');
    _currentRouteId = null;
  }
  
  // ✅ Новый метод: синхронизация с репозиторием
  void syncWithRepository(String? routeId) {
    if (routeId == null) {
      _currentRouteId = null;
      debugPrint('📍 CurrentRouteManager: synced to null');
    } else if (_currentRouteId != routeId) {
      _currentRouteId = routeId;
      debugPrint('📍 CurrentRouteManager: synced to route "$routeId"');
    }
  }
  
  // ✅ Новый метод: проверка, активен ли маршрут
  bool isActiveRoute(String routeId) {
    return _currentRouteId == routeId;
  }
}