import 'dart:math';
import 'package:flutter/material.dart';

class RainBackground extends StatefulWidget {
  final int dropsCount;

  const RainBackground({super.key, this.dropsCount = 18});

  @override
  State<RainBackground> createState() => _RainBackgroundState();
}

class _RainBackgroundState extends State<RainBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_RainDrop> _drops;
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..addListener(_tick)
          ..repeat();

    _drops = List.generate(
      widget.dropsCount,
      (index) => _createDrop(index, widget.dropsCount),
    );
  }

  _RainDrop _createDrop(int index, int total) {
    final baseX = (index + 0.5) / total;
    final xJitter = (_rnd.nextDouble() - 0.5) * (1.0 / total);
    final x = (baseX + xJitter).clamp(0.03, 0.97);

    final startY = -0.3;
    const endY = 1.02;

    // первые ~5 капель сразу, остальные — постепенно до 4 сек
    final spawnDelay = index < 5 ? 0.0 : _rnd.nextDouble() * 4.0;

    // начальная позиция на всём пути, чтобы не было линии
    final initialProgress = _rnd.nextDouble();
    final initialY = startY + initialProgress * (endY - startY);

    return _RainDrop(
      index: index,
      x: x,
      startY: startY,
      endY: endY,
      y: initialY,
      length: 10 + _rnd.nextDouble() * 16,
      speed: 0.08 + _rnd.nextDouble() * 0.09,
      angle: -pi / 8 + _rnd.nextDouble() * (pi / 24),
      opacity: 0.22 + _rnd.nextDouble() * 0.25,
      spawnDelay: spawnDelay,
    );
  }

  void _resetDrop(int i) {
    _drops[i] = _createDrop(i, widget.dropsCount);
  }

  void _tick() {
    final elapsedMs = _controller.lastElapsedDuration?.inMilliseconds ?? 0;
    final t = elapsedMs / 1000.0;

    for (var i = 0; i < _drops.length; i++) {
      final drop = _drops[i];

      if (t < drop.spawnDelay) continue;

      var newY = drop.y + drop.speed * 0.012;

      if (newY > drop.endY) {
        _resetDrop(i);
      } else {
        _drops[i] = drop.copyWith(y: newY);
      }
    }

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
      painter: _RainPainter(drops: _drops),
      child: const SizedBox.expand(),
    );
  }
}

class _RainDrop {
  final int index;
  final double x;
  final double startY;
  final double endY;
  final double length;
  final double speed;
  final double angle;
  final double opacity;
  final double spawnDelay;
  final double y;

  _RainDrop({
    required this.index,
    required this.x,
    required this.startY,
    required this.endY,
    required this.length,
    required this.speed,
    required this.angle,
    required this.opacity,
    required this.spawnDelay,
    required this.y,
  });

  _RainDrop copyWith({double? y}) {
    return _RainDrop(
      index: index,
      x: x,
      startY: startY,
      endY: endY,
      length: length,
      speed: speed,
      angle: angle,
      opacity: opacity,
      spawnDelay: spawnDelay,
      y: y ?? this.y,
    );
  }
}

class _RainPainter extends CustomPainter {
  final List<_RainDrop> drops;

  _RainPainter({required this.drops});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (final drop in drops) {
      final dx = drop.x * size.width;
      final dy = drop.y * size.height;
      final endDx = dx + drop.length * sin(drop.angle);
      final endDy = dy + drop.length * cos(drop.angle);

      paint.color = const Color(
        0xFFB3D9FF,
      ).withValues(alpha: (drop.opacity * 0.7).clamp(0.0, 0.6));

      canvas.drawLine(Offset(dx, dy), Offset(endDx, endDy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) {
    return oldDelegate.drops != drops;
  }
}
