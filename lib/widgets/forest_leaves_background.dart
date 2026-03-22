import 'dart:math';
import 'package:flutter/material.dart';

class ForestLeavesBackground extends StatefulWidget {
  final int leavesCount;

  const ForestLeavesBackground({super.key, this.leavesCount = 18});

  @override
  State<ForestLeavesBackground> createState() => _ForestLeavesBackgroundState();
}

class _ForestLeavesBackgroundState extends State<ForestLeavesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Leaf> _leaves;
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(_tick)
          ..repeat();

    _leaves = List.generate(
      widget.leavesCount,
      (index) => _createLeaf(index, widget.leavesCount),
    );
  }

  _Leaf _createLeaf(int index, int total) {
    final baseX = (index + 0.5) / total;
    final xJitter = (_rnd.nextDouble() - 0.5) * (1.0 / total);
    final x = (baseX + xJitter).clamp(0.05, 0.95);

    const startY = 0.12;
    const endY = 1.05;

    // первые 5–7 листьев появляются сразу, остальные с задержкой до 5 сек
    final spawnDelay = index < 6 ? 0.0 : _rnd.nextDouble() * 5.0;

    // начальная позиция где‑то между верхом и низом, чтобы не было линии
    final initialProgress = _rnd.nextDouble(); // 0..1
    final initialY = startY + initialProgress * (endY - startY);

    return _Leaf(
      index: index,
      x: x,
      startY: startY,
      endY: endY,
      y: initialY,
      size: 10 + _rnd.nextDouble() * 10,
      speed: 0.03 + _rnd.nextDouble() * 0.03,
      wobbleAmplitude: 0.012 + _rnd.nextDouble() * 0.02,
      wobbleSpeed: 0.7 + _rnd.nextDouble() * 1.0,
      rotationSpeed: -0.3 + _rnd.nextDouble() * 0.6,
      spawnDelay: spawnDelay,
    );
  }

  void _resetLeaf(int i) {
    _leaves[i] = _createLeaf(i, widget.leavesCount);
  }

  void _tick() {
    final elapsedMs = _controller.lastElapsedDuration?.inMilliseconds ?? 0;
    final t = elapsedMs / 1000.0; // секунды с момента старта

    for (var i = 0; i < _leaves.length; i++) {
      final leaf = _leaves[i];

      // ещё не настало время этого листа появляться
      if (t < leaf.spawnDelay) continue;

      final newY = leaf.y + leaf.speed * 0.01;
      if (newY > leaf.endY) {
        _resetLeaf(i);
      } else {
        _leaves[i] = leaf.copyWith(y: newY);
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
      painter: _LeavesPainter(
        leaves: _leaves,
        time: (_controller.value * 2 * pi),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _Leaf {
  final int index;
  final double x;
  final double startY;
  final double endY;
  final double size;
  final double speed;
  final double wobbleAmplitude;
  final double wobbleSpeed;
  final double rotationSpeed;
  final double y;
  final double spawnDelay;

  _Leaf({
    required this.index,
    required this.x,
    required this.startY,
    required this.endY,
    required this.size,
    required this.speed,
    required this.wobbleAmplitude,
    required this.wobbleSpeed,
    required this.rotationSpeed,
    required this.y,
    required this.spawnDelay,
  });

  _Leaf copyWith({double? y}) {
    return _Leaf(
      index: index,
      x: x,
      startY: startY,
      endY: endY,
      size: size,
      speed: speed,
      wobbleAmplitude: wobbleAmplitude,
      wobbleSpeed: wobbleSpeed,
      rotationSpeed: rotationSpeed,
      y: y ?? this.y,
      spawnDelay: spawnDelay,
    );
  }
}

class _LeavesPainter extends CustomPainter {
  final List<_Leaf> leaves;
  final double time;

  _LeavesPainter({required this.leaves, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final leaf in leaves) {
      final travel = (leaf.y - leaf.startY) / (leaf.endY - leaf.startY);
      final progress = travel.clamp(0.0, 1.0);
      final fadeBottom = (1 - progress * 1.1).clamp(0.0, 1.0);

      final wobble =
          leaf.wobbleAmplitude * sin(time * leaf.wobbleSpeed + leaf.x * 10);
      final dx = (leaf.x + wobble) * size.width;
      final dy = leaf.y * size.height;

      final baseColor = Color.lerp(
        Colors.green.shade700,
        Colors.green.shade200,
        progress,
      )!;

      strokePaint.color = baseColor.withValues(alpha: 0.18 + 0.25 * fadeBottom);

      final angle = time * leaf.rotationSpeed + leaf.x * pi;
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(
          leaf.size * 0.3,
          -leaf.size * 0.4,
          leaf.size * 0.8,
          leaf.size * 0.1,
        )
        ..lineTo(leaf.size, leaf.size * 0.3)
        ..lineTo(leaf.size * 0.7, leaf.size * 0.5)
        ..lineTo(0, leaf.size * 0.2)
        ..close();

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(angle);
      canvas.drawPath(path, strokePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LeavesPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.leaves != leaves;
  }
}
