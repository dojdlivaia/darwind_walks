// lib/screens/whale_screen.dart

import 'package:flutter/material.dart';

import '../models/whale.dart';
import 'evolution_route_screen.dart';
import '../routes/whale_route_config.dart';
import '../services/current_route_manager.dart';

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
          // initialSteps по умолчанию 0, но EvolutionRouteScreen сам загрузит из репозитория
        ),
      ),
    );
  }
}