// lib/main.dart

import 'package:flutter/material.dart';

import 'data/daily_steps_repository.dart';
import 'screens/main_shell.dart';
import 'services/step_tracker_service.dart';

late final DailyStepsRepository dailyStepsRepository;
late final StepTrackerService stepTrackerService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  dailyStepsRepository = await DailyStepsRepository.init();
  stepTrackerService = StepTrackerService(dailyStepsRepository);

  // запускаем слушать шаги
  await stepTrackerService.start();

  runApp(const DarwinApp());
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
    );
  }
}