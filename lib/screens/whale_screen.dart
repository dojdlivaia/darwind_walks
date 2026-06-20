// lib/screens/whale_screen.dart

import 'package:flutter/material.dart';
import '../models/whale.dart';
import '../configs/whale_config.dart';
import 'evolution_route_screen.dart';

class WhaleScreen extends StatelessWidget {
  const WhaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EvolutionRouteScreen<WhaleNode>(
      config: WhaleConfig.get(),
      routeId: 'whale',
    );
  }
}