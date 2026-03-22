import 'dart:math' as math;
import 'package:flutter/material.dart';

class BouncingCreature extends StatefulWidget {
  final Widget child;
  final double amplitude; // амплитуда по Y в пикселях
  final Duration duration; // период полного цикла

  const BouncingCreature({
    super.key,
    required this.child,
    this.amplitude = 8,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<BouncingCreature> createState() => _BouncingCreatureState();
}

class _BouncingCreatureState extends State<BouncingCreature>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(); // бесконечная плавная анимация
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // value: 0..1 -> sin(0..2π)
        final t = _controller.value * 2 * math.pi;
        final dy = math.sin(t) * widget.amplitude;

        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: widget.child,
    );
  }
}
