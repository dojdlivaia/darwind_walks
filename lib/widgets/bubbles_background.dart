import 'dart:math';
import 'package:flutter/material.dart';

class BubblesBackground extends StatefulWidget {
  final int bubblesCount;

  const BubblesBackground({super.key, this.bubblesCount = 20});

  @override
  State<BubblesBackground> createState() => _BubblesBackgroundState();
}

class _BubblesBackgroundState extends State<BubblesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Bubble> _bubbles;
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(_tick)
          ..repeat();

    _bubbles = List.generate(widget.bubblesCount, (_) => _createBubble());
  }

  _Bubble _createBubble() {
    // создаём пузырёк чуть ниже низа экрана
    return _Bubble(
      x: _rnd.nextDouble(), // 0..1 по ширине
      y: 1.1 + _rnd.nextDouble() * 0.4, // старт ниже низа
      radius: 6 + _rnd.nextDouble() * 10,
      speed: (0.02 + _rnd.nextDouble() * 0.06) / 30, // «шаг» по Y за один тик
      wobbleAmplitude: 0.22 + _rnd.nextDouble() * 0.03,
      wobbleSpeed: 1 + _rnd.nextDouble() * 2,
      opacity: 0.3 + _rnd.nextDouble() * 0.5,
    );
  }

  void _tick() {
    // обновляем позиции пузырьков
    for (var i = 0; i < _bubbles.length; i++) {
      final b = _bubbles[i];
      // двигаем вверх
      final newY = b.y - b.speed;
      if (newY < -0.1) {
        // «лопнул» выше, создаём новый снизу
        _bubbles[i] = _createBubble();
      } else {
        _bubbles[i] = b.copyWith(y: newY);
      }
    }
    // перерисовываем
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblesPainter(
        bubbles: _bubbles,
        time: _controller.value * 2 * pi,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _Bubble {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double wobbleAmplitude;
  final double wobbleSpeed;
  final double opacity;

  _Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.wobbleAmplitude,
    required this.wobbleSpeed,
    required this.opacity,
  });

  _Bubble copyWith({double? x, double? y}) {
    return _Bubble(
      x: x ?? this.x,
      y: y ?? this.y,
      radius: radius,
      speed: speed,
      wobbleAmplitude: wobbleAmplitude,
      wobbleSpeed: wobbleSpeed,
      opacity: opacity,
    );
  }
}

class _BubblesPainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double time; // 0..2π

  _BubblesPainter({required this.bubbles, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final bubble in bubbles) {
      // лёгкое покачивание по X (sin)
      final wobble =
          bubble.wobbleAmplitude * sin(time * bubble.wobbleSpeed + bubble.x);

      final dx = (bubble.x + wobble) * size.width;
      final dy = bubble.y * size.height;

      final center = Offset(dx, dy);

      strokePaint.color = Colors.white.withOpacity(bubble.opacity);

      canvas.drawCircle(center, bubble.radius, strokePaint);

      // небольшой внутренний блик
      canvas.drawCircle(
        center.translate(-bubble.radius / 3, -bubble.radius / 3),
        bubble.radius / 3,
        strokePaint..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) {
    return true;
  }
}
