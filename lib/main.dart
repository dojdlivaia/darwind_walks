// lib/main.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'data/daily_steps_repository.dart';
import 'screens/main_shell.dart';
import 'services/step_tracker_service.dart';

late final DailyStepsRepository dailyStepsRepository;
late final StepTrackerService stepTrackerService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 1. Запрос разрешений ПЕРЕД инициализацией шагомера
  await _requestPermissions();

  dailyStepsRepository = await DailyStepsRepository.init();
  stepTrackerService = StepTrackerService(dailyStepsRepository);

  // 🔹 2. Запускаем слушать шаги только после получения разрешений
  await stepTrackerService.start();

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