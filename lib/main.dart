// lib/main.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'data/daily_steps_repository.dart';
import 'data/repositories/route_state_repository.dart';
import 'screens/main_shell.dart';
import 'services/step_tracker_service.dart';

// Глобальные сервисы (теперь через геттеры)
StepTrackerService? _stepTrackerService;

// Геттеры для доступа к сервисам
Future<StepTrackerService> getStepTrackerService() async {
  if (_stepTrackerService == null) {
    final stepsRepo = await DailyStepsRepository.getInstance();
    _stepTrackerService = StepTrackerService(stepsRepo);
    await _stepTrackerService!.start();
  }
  return _stepTrackerService!;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 1. Запрос разрешений
  await _requestPermissions();

  // 🔹 2. Инициализация репозиториев (Singleton)
  await DailyStepsRepository.getInstance();
  await RouteStateRepository.getInstance();
  debugPrint('✅ Репозитории инициализированы');

  // 🔹 3. Инициализация шагомера
  _stepTrackerService = StepTrackerService(
    await DailyStepsRepository.getInstance(),
  );
  await _stepTrackerService!.start();
  debugPrint('✅ StepTrackerService запущен');

  runApp(const DarwinApp());
}

/// Запрашивает необходимые разрешения для работы шагомера
Future<void> _requestPermissions() async {
  try {
    // Для Android 10+ (API 29+)
    final activityStatus = await Permission.activityRecognition.request();
    debugPrint('🔐 Permission.activityRecognition: $activityStatus');

    // Для iOS (если понадобится доступ к другим сенсорам)
    final sensorsStatus = await Permission.sensors.request();
    debugPrint('🔐 Permission.sensors: $sensorsStatus'); 

    // Для Android 12+ (API 31+)
    if (await Permission.notification.isDenied) {
      final notificationStatus = await Permission.notification.request();
      debugPrint('🔐 Permission.notification: $notificationStatus');
    }

    // Проверка для отладки
    if (!activityStatus.isGranted) {
      debugPrint('⚠️ ACTIVITY_RECOGNITION not granted - pedometer may not work!');
      debugPrint('💡 Попросите пользователя включить разрешение в настройках приложения');
    }
  } catch (e) {
    debugPrint('❌ Error requesting permissions: $e');
  }
}

class DarwinApp extends StatelessWidget {
  const DarwinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Прогулка Дарвина',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}