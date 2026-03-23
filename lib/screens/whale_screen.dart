// lib/screens/whale_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/whale.dart';
import 'evolution_route_screen.dart';
import '../routes/whale_route_config.dart';
import '../services/current_route_manager.dart';
import '../main.dart';

class WhaleScreen extends StatelessWidget {
  const WhaleScreen({super.key});

  (List<WhaleNode>, int) _decodeWhaleData(Map<String, dynamic> jsonMap) {
    final data = WhaleData.fromJson(jsonMap);
    return (data.nodes, data.totalSteps);
  }

  static const List<Color> _backgroundColors = [
    Color(0xFF344651),
    Color(0xFF1A365D),
    Color(0xFF2D4A6E),
    Color(0xFF344651),
  ];

  /// 🔹 Временная панель отладки
  Widget _buildDebugPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Кнопка: добавить тестовые шаги
              ElevatedButton.icon(
                onPressed: () async {
                  await stepTrackerService.addTestSteps(50);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ +50 тестовых шагов')),
                    );
                  }
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+50 шагов'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              
              // Кнопка: диагностика
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final info = await stepTrackerService.getDebugInfo();
                    
                    // 🔹 Безопасная обработка nullable значений
                    final isStarted = info['isStarted'] as bool? ?? false;
                    final permissionGranted = info['permissionGranted'] as bool? ?? false;
                    final lastRawSteps = info['lastRawSteps'] as int?;
                    final savedBase = info['savedBase'] as int?;
                    final savedDate = info['savedDate'] as String?;
                    final todayKey = info['todayKey'] as String?;
                    
                    final message = '''
📊 Статус шагомера:
• Запущен: ${isStarted ? '✅' : '❌'}
• Разрешение: ${permissionGranted ? '✅' : '❌'}
• Последние шаги: ${lastRawSteps?.toString() ?? '—'}
• Сохранено (база): ${savedBase?.toString() ?? '—'}
• Дата сохранения: ${savedDate ?? '—'}
• Сегодня: ${todayKey ?? '—'}
                    ''';
                    
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('🔍 Диагностика'),
                          content: SelectableText(message),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('❌ Debug panel error: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка диагностики: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.info, size: 16),
                label: const Text('Диагностика'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              
              // Кнопка: настройки
              ElevatedButton.icon(
                onPressed: () async {
                  await openAppSettings();
                },
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('Настройки'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    CurrentRouteManager.instance.startRoute('whale');

    return WillPopScope(
      onWillPop: () async {
        CurrentRouteManager.instance.stopRoute();
        return true;
      },
      child: Scaffold(
        body: EvolutionRouteScreen<WhaleNode>(
          config: buildWhaleRouteConfig(),
          decodeData: _decodeWhaleData,
          showBottomIcons: false,
          backgroundColors: _backgroundColors,
        ),

        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'addSteps',
              onPressed: () async {
                await stepTrackerService.addTestSteps(50);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ +50 шагов добавлено')),
                  );
                }
              },
              tooltip: 'Добавить 50 шагов',
              child: const Icon(Icons.directions_walk),
            ),
            const SizedBox(height: 12),
            
            FloatingActionButton.small(
              heroTag: 'debug',
              onPressed: () => _buildDebugPanel(context),
              tooltip: 'Диагностика шагомера',
              backgroundColor: Colors.blue,
              child: const Icon(Icons.bug_report),
            ),
          ],
        ),
        
        bottomSheet: kDebugMode ? _buildDebugPanel(context) : null,
      ),
    );
  }
}