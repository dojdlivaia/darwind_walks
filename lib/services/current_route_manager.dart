// lib/services/current_route_manager.dart

class CurrentRouteManager {
  CurrentRouteManager._();

  static final CurrentRouteManager instance = CurrentRouteManager._();

  String? _currentRouteId;

  String? get currentRouteId => _currentRouteId;

  void startRoute(String routeId) {
    _currentRouteId = routeId;
  }

  void stopRoute() {
    _currentRouteId = null;
  }
}