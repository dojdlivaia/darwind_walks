// lib/services/step_tracker_service.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/daily_steps_repository.dart';
import '../data/repositories/route_state_repository.dart';
import 'current_route_manager.dart';
import 'achievement_service.dart';

class StepTrackerService {
  StepTrackerService(this._repository);

  final DailyStepsRepository _repository;

  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;

  int? _lastRawSteps;
  DateTime? _lastEventDate;
  
  // Ключи для SharedPreferences
  static const _keyLastRawSteps = 'step_tracker_last_raw';
  static const _keyLastDate = 'step_tracker_last_date';
  static const _keyDailyBase = 'step_tracker_daily_base';

  bool _isStarted = false;
  bool get isStarted => _isStarted;

  // Для периодической проверки достижений (не каждый шаг)
  int _stepsSinceLastAchievementCheck = 0;
  static const int _achievementCheckInterval = 100; // проверять каждые 100 шагов

  /// Запуск отслеживания шагов
  Future<void> start() async {
    if (_isStarted) return;

    try {
      final permissionStatus = await Permission.activityRecognition.status;
      debugPrint('🔐 StepTrackerService: Permission = $permissionStatus');

      // Загружаем сохранённые значения
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

  /// Загружаем последнее сохранённое состояние
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

  /// Сохраняем состояние для следующего запуска
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastRawSteps, _lastRawSteps ?? 0);
      await prefs.setString(_keyLastDate, _getTodayKey());
    } catch (e) {
      debugPrint('⚠️ Failed to save state: $e');
    }
  }

  /// Ключ даты в формате "YYYY-MM-DD"
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> stop() async {
    await _stepSub?.cancel();
    await _statusSub?.cancel();
    await _saveState();
    _stepSub = null;
    _statusSub = null;
    _isStarted = false;
  }

  void _onStepCount(StepCount event) {
    final raw = event.steps;
    final timestamp = event.timeStamp;
    final eventDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    debugPrint('👟 onStepCount: raw=$raw, last=$_lastRawSteps');

    // Первое событие: инициализируем
    if (_lastRawSteps == null) {
      _lastRawSteps = raw;
      _lastEventDate = eventDate;
      _saveState();
      debugPrint('📝 Initialized with raw=$raw');
      return;
    }

    // Смена дня: сбрасываем счётчик
    if (_lastEventDate != null && !_isSameDay(_lastEventDate!, eventDate)) {
      debugPrint('📅 Day changed, resetting counter');
      _lastRawSteps = raw;
      _lastEventDate = eventDate;
      _saveState();
      _stepsSinceLastAchievementCheck = 0;
      return;
    }

    // Вычисляем дельту
    final delta = raw - _lastRawSteps!;
    _lastRawSteps = raw;
    _lastEventDate = eventDate;
    _saveState();

    debugPrint('📊 delta=$delta');
    if (delta <= 0) return;

    // Обрабатываем null
    final currentRouteId = CurrentRouteManager.instance.currentRouteId;
    final routeId = currentRouteId ?? 'free_walk';
    
    debugPrint('📍 СОХРАНЕНИЕ ШАГОВ:');
    debugPrint('   routeId из CurrentRouteManager: $currentRouteId');
    debugPrint('   итоговый routeId: $routeId');
    debugPrint('   delta: $delta');
    
    _repository.addSteps(
      date: timestamp,
      stepsDelta: delta,
      routeId: routeId,
    );
    
    // Проверка достижений (каждые N шагов)
    _stepsSinceLastAchievementCheck += delta;
    if (_stepsSinceLastAchievementCheck >= _achievementCheckInterval) {
      _stepsSinceLastAchievementCheck = 0;
      _checkAchievements();
    }
  }

  /// Проверка достижений
  Future<void> _checkAchievements() async {
    try {
      debugPrint('🏆 Checking achievements...');
      
      // Получаем общее количество шагов
      final totalSteps = await _repository.getTotalStepsForRoute('jurassic');
      
      // Получаем шаги за сегодня
      final today = DateTime.now();
      final todayStats = await _repository.getForDate(today);
      final dailySteps = todayStats?.totalSteps ?? 0;
      
      // Получаем завершённые маршруты
      final routeRepo = await RouteStateRepository.getInstance();
      final completedRoutes = await routeRepo.getCompletedRouteIds();
      
      // Получаем количество открытых существ (из SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      final creaturesOpened = prefs.getInt('creatures_opened') ?? 0;
      
      // Получаем количество дней подряд
      final consecutiveDays = await _getConsecutiveDays();
      
      final achievementService = AchievementService();
      await achievementService.checkAchievements(
        totalSteps: totalSteps,
        dailySteps: dailySteps,
        completedRoutes: completedRoutes.length,
        completedRouteIds: completedRoutes,
        creaturesOpened: creaturesOpened,
        consecutiveDays: consecutiveDays,
      );
      
      debugPrint('🏆 Achievement check completed');
    } catch (e) {
      debugPrint('❌ Error checking achievements: $e');
    }
  }

  /// Подсчёт дней подряд
  Future<int> _getConsecutiveDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDate = prefs.getString('last_activity_date');
      final streak = prefs.getInt('streak') ?? 0;
      
      final today = _getTodayKey();
      
      if (lastDate == null) {
        // Первый день
        await prefs.setString('last_activity_date', today);
        await prefs.setInt('streak', 1);
        return 1;
      }
      
      if (lastDate == today) {
        return streak;
      }
      
      // Проверяем, был ли вчера
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey = _getDateKey(yesterday);
      
      if (lastDate == yesterdayKey) {
        // Продолжаем streak
        final newStreak = streak + 1;
        await prefs.setString('last_activity_date', today);
        await prefs.setInt('streak', newStreak);
        return newStreak;
      } else {
        // Сбрасываем streak
        await prefs.setString('last_activity_date', today);
        await prefs.setInt('streak', 1);
        return 1;
      }
    } catch (e) {
      debugPrint('⚠️ Error calculating consecutive days: $e');
      return 0;
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _onPedestrianStatus(PedestrianStatus status) {
    debugPrint('🚶 pedestrian status = $status');
  }

  void _onStepError(Object error) {
    debugPrint('❌ pedometer error: $error');
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Публичный метод для тестовых шагов
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
    
    // Проверяем достижения после добавления тестовых шагов
    _stepsSinceLastAchievementCheck += steps;
    if (_stepsSinceLastAchievementCheck >= _achievementCheckInterval) {
      _stepsSinceLastAchievementCheck = 0;
      _checkAchievements();
    }
  }

  /// Диагностика
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