// lib/services/step_tracker_service.dart

import 'dart:async';

import 'package:pedometer_2/pedometer_2.dart';

import '../data/daily_steps_repository.dart';
import 'current_route_manager.dart';

class StepTrackerService {
  StepTrackerService(this._repository);

  final DailyStepsRepository _repository;

  StreamSubscription<int>? _stepSub;

  int? _lastRawSteps;
  DateTime? _lastEventDate;

  bool _isStarted = false;

  bool get isStarted => _isStarted;

  Future<void> start() async {
    if (_isStarted) return;
    _isStarted = true;

    try {
      final pedometer = Pedometer();

      // Реальный стрим шагов c момента последней перезагрузки.
      // Возвращает просто int — количество шагов.
      _stepSub = pedometer.stepCountStream().listen(
        _onStepCount,
        onError: _onStepError,
      );
    } catch (e) {
      _isStarted = false;
    }
  }

  Future<void> stop() async {
    await _stepSub?.cancel();
    _stepSub = null;
    _isStarted = false;
  }

  void _onStepCount(int raw) {
    final timestamp = DateTime.now();
    final eventDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (_lastRawSteps == null) {
      _lastRawSteps = raw;
      _lastEventDate = eventDate;
      return;
    }

    if (_lastEventDate != null && !_isSameDay(_lastEventDate!, eventDate)) {
      _lastRawSteps = raw;
      _lastEventDate = eventDate;
      return;
    }

    final delta = raw - (_lastRawSteps ?? raw);
    _lastRawSteps = raw;
    _lastEventDate = eventDate;

    if (delta <= 0) return;

    final currentRouteId =
        CurrentRouteManager.instance.currentRouteId ?? 'free_walk';

    _repository.addSteps(
      date: timestamp,
      stepsDelta: delta,
      routeId: currentRouteId,
    );
  }

  void _onStepError(Object error) {
    // при необходимости можно добавить обработку ошибок при ошибке стрима
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> addTestSteps(int steps) async {
    if (steps <= 0) return;
    final now = DateTime.now();
    final currentRouteId =
        CurrentRouteManager.instance.currentRouteId ?? 'free_walk';

    await _repository.addSteps(
      date: now,
      stepsDelta: steps,
      routeId: currentRouteId,
    );
  }
}