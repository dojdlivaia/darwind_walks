import 'package:flutter/material.dart';
import 'ready_routes_screen.dart';
import 'custom_route_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // верхняя панель с иконкой настроек слева
      appBar: AppBar(
        title: const Text('Прогулка Дарвина'),
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // здесь потом сделаем экран настроек
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Экран настроек скоро будет :)')),
            );
          },
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Выбери, как гуляем сегодня:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Кнопка "Готовые маршруты"
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReadyRoutesScreen()),
                );
              },
              child: const Text(
                'Готовые маршруты',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 16),

            // Кнопка "Настройка маршрута"
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CustomRouteScreen()),
                );
              },
              child: const Text(
                'Настройка маршрута',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
