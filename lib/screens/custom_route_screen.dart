import 'package:flutter/material.dart';

class CustomRouteScreen extends StatelessWidget {
  const CustomRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройка маршрута')),
      body: const Center(
        child: Text('Здесь позже появится конструктор маршрута'),
      ),
    );
  }
}
