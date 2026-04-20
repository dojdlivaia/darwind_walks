// lib/widgets/lily_pad.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

class LilyPad extends StatefulWidget {
  final double size;
  final bool isUnlocked;
  final bool isCurrent;
  final VoidCallback? onTap;
  final double? wedgeAngle; // угол выреза (опционально)
  final double? rotationAngle; // угол поворота выреза (опционально)
  final Duration delay;

  // 🎨 Цветовая палитра
  static const Color darkLeaf = Color(0xFF2E3A05);
  static const Color mediumLeaf = Color(0xFF4B5E09);
  static const Color brightLeaf = Color(0xFF6B8E23);
  static const Color flower = Color(0xFFEEF8CC);
  static const Color veinColor = Color(0xFF061B14);

  const LilyPad({
    super.key,
    this.size = 48,
    this.isUnlocked = false,
    this.isCurrent = false,
    this.onTap,
    this.wedgeAngle,
    this.rotationAngle,
    this.delay = Duration.zero,
  });

  @override
  State<LilyPad> createState() => _LilyPadState();
}

class _LilyPadState extends State<LilyPad>
    with TickerProviderStateMixin {
  late AnimationController _appearController;
  late Animation<double> _appearAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 🔹 Меньший разброс угла выреза: от 0.9 до 1.1 радиан (~51° до ~63°)
  late final double _wedgeAngle;
  // 🔹 Случайный угол поворота выреза: от 0 до 2π
  late final double _rotationAngle;
  late final double _sizeVariation;

  @override
  void initState() {
    super.initState();

    // 🔹 Генерируем случайные параметры
    _wedgeAngle = widget.wedgeAngle ??
        (0.9 + math.Random().nextDouble() * 0.2); // от 0.9 до 1.1 радиан (~51° до ~63°)
    
    _rotationAngle = widget.rotationAngle ??
        (math.Random().nextDouble() * 2 * math.pi); // от 0 до 360°
    
    _sizeVariation = 0.9 + math.Random().nextDouble() * 0.2; // от 0.9 до 1.1

    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _appearAnimation = CurvedAnimation(
      parent: _appearController,
      curve: Curves.elasticOut,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _appearController.forward();
        if (widget.isCurrent) {
          _pulseController.repeat(reverse: true);
        }
      }
    });
  }

  @override
  void didUpdateWidget(LilyPad oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isCurrent && !oldWidget.isCurrent) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isCurrent && oldWidget.isCurrent) {
      _pulseController.stop();
      _pulseController.reset();
    }

    if (widget.isUnlocked && !oldWidget.isUnlocked) {
      _appearController.reset();
      Future.delayed(widget.delay, () {
        if (mounted) {
          _appearController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _appearController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actualSize = widget.size * _sizeVariation;

    return AnimatedBuilder(
      animation: Listenable.merge([_appearAnimation, _pulseAnimation]),
      builder: (context, child) {
        double scale = _appearAnimation.value;

        if (widget.isCurrent) {
          scale *= _pulseAnimation.value;
        }

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: widget.isUnlocked ? widget.onTap : null,
            child: Container(
              width: actualSize,
              height: actualSize,
              decoration: widget.isCurrent
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: LilyPad.flower,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: LilyPad.flower.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    )
                  : null,
              child: CustomPaint(
                painter: _LilyPadPainter(
                  isUnlocked: widget.isUnlocked,
                  isCurrent: widget.isCurrent,
                  wedgeAngle: _wedgeAngle,
                  rotationAngle: _rotationAngle, // 🔹 Передаём угол поворота
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LilyPadPainter extends CustomPainter {
  final bool isUnlocked;
  final bool isCurrent;
  final double wedgeAngle;
  final double rotationAngle; // 🔹 Новый параметр

  _LilyPadPainter({
    required this.isUnlocked,
    required this.isCurrent,
    required this.wedgeAngle,
    required this.rotationAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.92;

    final leafColor = _getLeafColor();
    final veinColor = LilyPad.veinColor.withOpacity(
      isUnlocked ? 0.6 : 0.8,
    );
    final outlineColor = isCurrent
        ? LilyPad.flower.withOpacity(0.9)
        : leafColor.withOpacity(0.4);

    final leafPaint = Paint()
      ..color = leafColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final veinPaint = Paint()
      ..color = veinColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final outlinePaint = Paint()
      ..color = outlineColor
      ..strokeWidth = isCurrent ? 2 : 1
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // 🔹 Рисуем кувшинку с поворотом выреза
    // startAngle = rotationAngle + wedgeAngle/2 (чтобы вырез был симметричен относительно rotationAngle)
    final startAngle = rotationAngle + wedgeAngle / 2;
    
    final path = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, // начало дуги (с поворотом)
        2 * math.pi - wedgeAngle, // длина дуги
      )
      ..lineTo(center.dx, center.dy)
      ..close();

    canvas.drawPath(path, leafPaint);

    // 🔹 Прожилки с учётом поворота
    final veinCount = 7;
    for (var i = 0; i < veinCount; i++) {
      final angle = startAngle + (i / veinCount) * (2 * math.pi - wedgeAngle);
      final endX = center.dx + math.cos(angle) * radius * 0.85;
      final endY = center.dy + math.sin(angle) * radius * 0.85;
      canvas.drawLine(center, Offset(endX, endY), veinPaint);
    }

    canvas.drawPath(path, outlinePaint);

    if (isUnlocked) {
      final flowerPaint = Paint()
        ..color = LilyPad.flower
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final petalCount = 5;
      final petalRadius = radius * 0.25;
      for (var i = 0; i < petalCount; i++) {
        final angle = rotationAngle + (i / petalCount) * 2 * math.pi;
        final petalCenter = Offset(
          center.dx + math.cos(angle) * petalRadius * 0.6,
          center.dy + math.sin(angle) * petalRadius * 0.6,
        );
        canvas.drawCircle(petalCenter, petalRadius, flowerPaint);
      }

      canvas.drawCircle(
        center,
        radius * 0.15,
        Paint()
          ..color = LilyPad.mediumLeaf
          ..style = PaintingStyle.fill,
      );
    }
  }

  Color _getLeafColor() {
    if (isCurrent) {
      return LilyPad.brightLeaf;
    } else if (isUnlocked) {
      return LilyPad.mediumLeaf;
    } else {
      return LilyPad.darkLeaf;
    }
  }

  @override
  bool shouldRepaint(covariant _LilyPadPainter oldDelegate) {
    return oldDelegate.isUnlocked != isUnlocked ||
        oldDelegate.isCurrent != isCurrent ||
        oldDelegate.wedgeAngle != wedgeAngle ||
        oldDelegate.rotationAngle != rotationAngle;
  }
}