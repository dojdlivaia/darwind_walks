import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class BouncingCreature extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration duration;
  final bool showShadow;
  final double shadowOffset;

  const BouncingCreature({
    super.key,
    required this.child,
    this.amplitude = 8,
    this.duration = const Duration(seconds: 3),
    this.showShadow = true,
    this.shadowOffset = 30,
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
      ..repeat();
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
        final t = _controller.value * 2 * math.pi;
        final dy = math.sin(t) * widget.amplitude;
        final normalizedHeight = dy / widget.amplitude;

        // Параметры эллиптической тени
        final shadowScaleX = 1.0 + (1 - normalizedHeight) * 0.5;
        final shadowScaleY = 0.12;
        final shadowOpacity = 0.4 - (normalizedHeight + 1) * 0.2;
        final shadowBlur = 15 + (1 - normalizedHeight) * 25;

        // 🔹 УМЕНЬШЕНЫ отступы чтобы не обрезали картинку
        final extraPadding = widget.shadowOffset + 20;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 30,   // было 60
            vertical: extraPadding,
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Эллиптическая тень
              if (widget.showShadow)
                Positioned(
                  bottom: -widget.shadowOffset + dy,
                  child: Transform.scale(
                    scaleX: shadowScaleX,
                    scaleY: shadowScaleY,
                    child: CustomPaint(
                      size: const Size(80, 20),
                      painter: _ShadowPainter(
                        opacity: shadowOpacity.clamp(0.0, 0.4),
                        blurRadius: shadowBlur,
                      ),
                    ),
                  ),
                ),

              // Персонаж
              Transform.translate(
                offset: Offset(0, dy),
                child: child,
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _ShadowPainter extends CustomPainter {
  final double opacity;
  final double blurRadius;

  _ShadowPainter({required this.opacity, required this.blurRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.black.withOpacity(opacity),
          Colors.black.withOpacity(opacity * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2,
      ));
    canvas.drawOval(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShadowPainter old) =>
      old.opacity != opacity || old.blurRadius != blurRadius;
}