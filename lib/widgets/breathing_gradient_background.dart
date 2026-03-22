// lib/widgets/breathing_gradient_background.dart
import 'package:flutter/material.dart';

class BreathingGradientBackground extends StatefulWidget {
  final List<Color> colors;
  final Widget child;
  final Duration duration;
  final Curve curve;

  const BreathingGradientBackground({
    super.key,
    required this.colors,
    required this.child,
    this.duration = const Duration(seconds: 4),
    this.curve = Curves.easeInOut,
  });

  @override
  State<BreathingGradientBackground> createState() =>
      _BreathingGradientBackgroundState();
}

class _BreathingGradientBackgroundState
    extends State<BreathingGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 1.5 * t, -1.0),
              end: Alignment(1.0 + 1.5 * t, 1.0),
              colors: widget.colors,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
