import 'package:flutter/material.dart';

import '../models/cenozoic.dart';
import 'evolution_route_screen.dart';
import '../routes/cenozoic_route_config.dart';

class CenozoicScreen extends StatelessWidget {
  const CenozoicScreen({super.key});

  (List<CenozoicNode>, int) _decodeCenozoicData(
    Map<String, dynamic> jsonMap,
  ) {
    final data = CenozoicData.fromJson(jsonMap);
    return (data.nodes, data.totalSteps);
  }

  static const List<Color> _backgroundColors = [
    Color(0xFF39452B),
    Color(0xFF2F3A21),
    Color(0xFF4C5A35),
    Color(0xFF39452B),
  ];

  @override
  Widget build(BuildContext context) {
    return EvolutionRouteScreen<CenozoicNode>(
      config: buildCenozoicRouteConfig(),
      decodeData: _decodeCenozoicData,
      showBottomIcons: false,
      backgroundColors: _backgroundColors,
    );
  }
}
