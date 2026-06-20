// lib/screens/mammal_screen.dart

import 'package:flutter/material.dart';
import '../models/mammal_node.dart';  // ✅ полная модель
import '../configs/mammal_config.dart';
import 'evolution_route_screen.dart';

class MammalScreen extends StatelessWidget {
  const MammalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EvolutionRouteScreen<MammalNode>(
      config: MammalConfig.get(),  // ✅ теперь возвращает RouteConfig<MammalNode>
      routeId: 'mammals',
    );
  }
}