import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;

class SimpleConfetti extends StatefulWidget {
  final bool isActive;
  final Duration duration;

  const SimpleConfetti({
    super.key,
    required this.isActive,
    this.duration = const Duration(seconds: 6),
  });

  @override
  State<SimpleConfetti> createState() => _SimpleConfettiState();
}

class _SimpleConfettiState extends State<SimpleConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_Particle> _particles;
  final _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        // когда волна закончилась и всё ещё активно – запускаем следующую
        if (status == AnimationStatus.completed && widget.isActive) {
          _particles = List.generate(140, (_) => _randomParticle());
          _controller.forward(from: 0);
        }
      });

    _particles = List.generate(140, (_) => _randomParticle());
    if (widget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant SimpleConfetti oldWidget) {
    super.didUpdateWidget(oldWidget);

    // включили конфетти
    if (widget.isActive && !oldWidget.isActive) {
      _particles = List.generate(140, (_) => _randomParticle());
      _controller.forward(from: 0);
    }

    // выключили конфетти
    if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  _Particle _randomParticle() {
    return _Particle(
      // x: 0..1
      x: _rnd.nextDouble(),
      // старт чуть выше центра (чтобы они были и над китом)
      startY: -0.4 + _rnd.nextDouble() * 0.4,
      // летит ниже низа экрана
      endY: 1.4,
      size: 3 + _rnd.nextDouble() * 4,
      angle: _rnd.nextDouble() * 2 * pi,
      angularVelocity: -2 + _rnd.nextDouble() * 4,
      // индивидуальная скорость падения
      verticalSpeedFactor: 0.7 + _rnd.nextDouble() * 0.6, // 0.7..1.3
      color: [
        Colors.white,
        Colors.yellowAccent,
        Colors.lightBlueAccent,
        Colors.pinkAccent,
        Colors.cyanAccent,
      ][_rnd.nextInt(5)],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive && !_controller.isAnimating) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(
              particles: _particles,
              t: _controller.value,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double x;
  final double startY;
  final double endY;
  final double size;
  final double angle;
  final double angularVelocity;
  final double verticalSpeedFactor;
  final Color color;

  _Particle({
    required this.x,
    required this.startY,
    required this.endY,
    required this.size,
    required this.angle,
    required this.angularVelocity,
    required this.verticalSpeedFactor,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;

  _ConfettiPainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final localT = (t * p.verticalSpeedFactor).clamp(0.0, 1.0);
      final yNorm = lerpDouble(p.startY, p.endY, localT)!;
      final y = yNorm * size.height;
      final x = p.x * size.width;

      final fade = (1 - localT).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withOpacity(fade)
        ..style = PaintingStyle.fill;

      final angle = p.angle + p.angularVelocity * t;
      final rect = Rect.fromCenter(
        center: Offset(x, y),
        width: p.size * 2,
        height: p.size,
      );

      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(angle);
      canvas.translate(-rect.center.dx, -rect.center.dy);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.particles != particles;
  }
}
