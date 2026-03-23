// lib/services/step_tracker_service.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ← Добавляем

import '../data/daily_steps_repository.dart';
import 'current_route_manager.dart';

class StepTrackerService {
  StepTrackerService(this._repository);

  final DailyStepsRepository _repository;

  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;

  int? _lastRawSteps;
  DateTime? _lastEventDate;
  
  // 🔹 Ключи для SharedPreferences
  static const _keyLastRawSteps = 'step_tracker_last_raw';
  static const _keyLastDate = 'step_tracker_last_date';
  static const _keyDailyBase = 'step_tracker_daily_base';

  bool _isStarted = false;
  bool get isStarted => _isStarted;

  /// Запуск отслеживания шагов
  Future<void> start() async {
    if (_isStarted) return;

    try {
      final permissionStatus = await Permission.activityRecognition.status;
      debugPrint('🔐 StepTrackerService: Permission = $permissionStatus');

      // 🔹 Загружаем сохранённые значения
      await _loadSavedState();

      _isStarted = true;
      debugPrint('🚀 StepTrackerService: subscribing to stream');

      _stepSub = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepError,
        cancelOnError: false,
      );

      _statusSub = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatus,
        onError: (e) => debugPrint('❌ Status error: $e'),
      );

    } catch (e, stack) {
      debugPrint('❌ StepTrackerService exception: $e\n$stack');
      _isStarted = false;
    }
  }

  /// 🔹 Загружаем последнее сохранённое состояние
  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final savedDate = prefs.getString(_keyLastDate);
      final savedBase = prefs.getInt(_keyDailyBase);
      final savedRaw = prefs.getInt(_keyLastRawSteps);

      final today = _getTodayKey();
      
      // Если день сменился — сбрасываем базовое значение
      if (savedDate != today) {
        debugPrint('📅 New day detected ($savedDate → $today), resetting base');
        await prefs.setString(_keyLastDate, today);
        await prefs.setInt(_keyDailyBase, 0);
        _lastRawSteps = null;
      } else {
        // Тот же день — восстанавливаем базовое значение
        _lastRawSteps = savedRaw;
        debugPrint('📦 Restored: lastRaw=$_lastRawSteps, base=$savedBase');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load saved state: $e');
    }
  }

  /// 🔹 Сохраняем состояние для следующего запуска
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastRawSteps, _lastRawSteps ?? 0);
      await prefs.setString(_keyLastDate, _getTodayKey());
    } catch (e) {
      debugPrint('⚠️ Failed to save state: $e');
    }
  }

  /// 🔹 Ключ даты в формате "YYYY-MM-DD"
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> stop() async {
    await _stepSub?.cancel();
    await _statusSub?.cancel();
    await _saveState(); // 🔹 Сохраняем перед остановкой
    _stepSub = null;
    _statusSub = null;
    _isStarted = false;
  }

  void _onStepCount(StepCount event) {
    final raw = event.steps;
    final timestamp = event.timeStamp;
    final eventDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    debugPrint('👟 onStepCount: raw=$raw, last=$_lastRawSteps');

    // 🔹 Первое событие: инициализируем
    if (_lastRawSteps == null) {
      _lastRawSteps = raw;
      _lastEventDate = eventDate;
      _saveState();
      debugPrint('📝 Initialized with raw=$raw');
      return;
    }

    // 🔹 Смена дня: сбрасываем счётчик
    if (_lastEventDate != null && !_isSameDay(_lastEventDate!, eventDate)) {
      debugPrint('📅 Day changed, resetting counter');
      _lastRawSteps = raw;
      _lastEventDate = eventDate;
      _saveState();
      return;
    }

    // 🔹 Вычисляем дельту
    final delta = raw - _lastRawSteps!;
    _lastRawSteps = raw;
    _lastEventDate = eventDate;
    
    // 🔹 Сохраняем после каждого события (на случай краша)
    _saveState();

    debugPrint('📊 delta=$delta');
    if (delta <= 0) return;

    final currentRouteId = CurrentRouteManager.instance.currentRouteId ?? 'free_walk';
    
    _repository.addSteps(
      date: timestamp,
      stepsDelta: delta,
      routeId: currentRouteId,
    );
  }

  void _onPedestrianStatus(PedestrianStatus status) {
    debugPrint('🚶 pedestrian status = $status');
  }

  void _onStepError(Object error) {
    debugPrint('❌ pedometer error: $error');
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 🔹 Публичный метод для тестовых шагов
  Future<void> addTestSteps(int steps) async {
    if (steps <= 0) return;
    final now = DateTime.now();
    final routeId = CurrentRouteManager.instance.currentRouteId ?? 'free_walk';

    await _repository.addSteps(
      date: now,
      stepsDelta: steps,
      routeId: routeId,
    );
    
    // Для отладки: обновляем кэш
    _lastRawSteps = (_lastRawSteps ?? 0) + steps;
    await _saveState();
    
    debugPrint('✅ Added $steps test steps');
  }

  /// 🔹 Диагностика
  Future<Map<String, dynamic>> getDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isStarted': _isStarted,
      'lastRawSteps': _lastRawSteps,
      'savedBase': prefs.getInt(_keyDailyBase),
      'savedDate': prefs.getString(_keyLastDate),
      'todayKey': _getTodayKey(),
    };
  }
}