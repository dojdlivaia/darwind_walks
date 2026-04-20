// lib/screens/whale_vertical_timeline_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';

import '../models/whale.dart';
import '../widgets/lily_pad.dart';

class WhaleVerticalTimelineScreen extends StatelessWidget {
  final WhaleData data;
  final int userSteps;

  WhaleVerticalTimelineScreen({
    super.key,
    required this.data,
    required this.userSteps,
  }) : _bgIndex = Random().nextInt(3);

  final int _bgIndex;

  String get _backgroundPath =>
      'assets/images/whales/background0${_bgIndex + 1}.png';

  static const Color _background = Color(0xFF061B14);
  static const Color _textColor = Color(0xFFEEF8CC);

  @override
  Widget build(BuildContext context) {
    final nodes = data.nodes;

    const double pixelsPerStepY = 0.085;
    const double width = 300;
    const double horizontalScreenPadding = 8;

    int currentIndex = 0;
    if (nodes.isNotEmpty) {
      for (int i = nodes.length - 1; i >= 0; i--) {
        if (nodes[i].cumulativeSteps <= userSteps) {
          currentIndex = i;
          break;
        }
      }
    }

    final List<_DotPoint> points = [];
    double currentY = 40;

    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];

      if (i > 0) {
        final prev = nodes[i - 1];
        final diffSteps = node.cumulativeSteps - prev.cumulativeSteps;
        final double diff = diffSteps.clamp(200, 4000).toDouble();
        currentY += diff * pixelsPerStepY;
      }

      final double t = currentY / 140.0;
      const double amplitude = 42;
      final double xCenterBase = width / 2 + amplitude * sin(t);

      final double scale = 1.0 + 0.15 * sin(i * pi / 4);
      const double baseSize = 44;
      final double size = baseSize * scale;

      final wedgeAngle = 0.9 + (i % 3) * 0.1;
      final rotationAngle = (i * 1.5) % (2 * pi);

      points.add(
        _DotPoint(
          node: node,
          index: i,
          xCenter: xCenterBase,
          yCenter: currentY,
          size: size,
          wedgeAngle: wedgeAngle,
          rotationAngle: rotationAngle,
        ),
      );
    }

    final double totalHeight =
        (points.isNotEmpty ? points.last.yCenter : 0) + 260;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Эволюция китов', style: TextStyle(color: _textColor)),
        backgroundColor: _background,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textColor),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(_backgroundPath, fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: _background.withOpacity(0.85))),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              vertical: 24,
              horizontal: horizontalScreenPadding,
            ),
            child: Center(
              child: SizedBox(
                width: width,
                height: totalHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _TimelineLinePainter(
                          points: points,
                          lineColor: _textColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                    // 🔹 Анимированные узлы
                    ...points.asMap().entries.map((entry) {
                      final index = entry.key;
                      final p = entry.value;
                      final isUnlocked = p.node.cumulativeSteps <= userSteps;
                      final isCurrent = index == currentIndex;
                      final textOnLeft = p.xCenter > width / 2;

                      return Positioned(
                        left: p.xCenter - p.size / 2,
                        top: p.yCenter - p.size / 2,
                        child: _AnimatedNode(
                          point: p,
                          isUnlocked: isUnlocked,
                          isCurrent: isCurrent,
                          textOnLeft: textOnLeft,
                          timelineWidth: width,
                          textColor: _textColor,
                          delay: Duration(milliseconds: index * 150),
                          onTap: () => _onNodeTap(p.node),
                        ),
                      );
                    }),
                    // Подписи
                    ...points.map((p) => _buildLabels(p, width: width)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onNodeTap(WhaleNode node) {
    debugPrint('🐋 Выбран: ${node.species}');
  }

  Widget _buildLabels(_DotPoint p, {required double width}) {
    final bool textOnLeft = p.xCenter > width / 2;
    final isUnlocked = p.node.cumulativeSteps <= userSteps;

    final speciesText = Text(
      p.node.species,
      textAlign: textOnLeft ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isUnlocked ? _textColor : _textColor.withOpacity(0.5),
      ),
    );

    final funFactText = isUnlocked
        ? Text(
            p.node.funfact,
            textAlign: textOnLeft ? TextAlign.right : TextAlign.left,
            softWrap: true,
            style: TextStyle(
              fontSize: 9,
              height: 1.25,
              color: _textColor.withOpacity(0.7),
            ),
          )
        : const SizedBox.shrink();

    final textColumn = Column(
      crossAxisAlignment:
          textOnLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [speciesText, const SizedBox(height: 4), funFactText],
    );

    final double circleRadius = p.size / 2;
    const double gap = 6;
    final double top = p.yCenter - circleRadius;

    if (textOnLeft) {
      return Positioned(
        top: top,
        left: 0,
        right: width - (p.xCenter + circleRadius),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: gap),
                child: textColumn,
              ),
            ),
            SizedBox(width: p.size),
          ],
        ),
      );
    } else {
      return Positioned(
        top: top,
        left: p.xCenter - circleRadius,
        right: 0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: p.size),
            const SizedBox(width: gap),
            Expanded(child: textColumn),
          ],
        ),
      );
    }
  }
}

// 🎭 Анимированный узел
class _AnimatedNode extends StatefulWidget {
  final _DotPoint point;
  final bool isUnlocked;
  final bool isCurrent;
  final bool textOnLeft;
  final double timelineWidth;
  final Color textColor;
  final Duration delay;
  final VoidCallback onTap;

  const _AnimatedNode({
    required this.point,
    required this.isUnlocked,
    required this.isCurrent,
    required this.textOnLeft,
    required this.timelineWidth,
    required this.textColor,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_AnimatedNode> createState() => _AnimatedNodeState();
}

class _AnimatedNodeState extends State<_AnimatedNode>
    with TickerProviderStateMixin {
  late final AnimationController _appearCtrl;
  late final Animation<double> _appearAnim;
  
  late final AnimationController _tapCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _rippleScaleAnim;
  late final Animation<double> _rippleOpacityAnim;
  
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // 1️⃣ Анимация появления (масштабирование на месте)
    _appearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _appearAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _appearCtrl, curve: Curves.elasticOut),
    );

    // 2️⃣ Анимация нажатия
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOutBack),
    );
    _rippleScaleAnim = Tween<double>(begin: 0.6, end: 2.5).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut),
    );
    _rippleOpacityAnim = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut),
    );
    _tapCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _tapCtrl.reset();
    });

    // 3️⃣ Пульсация текущего узла
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // 🔹 Запуск с задержкой
    Future.delayed(widget.delay, () {
      if (mounted) _appearCtrl.forward();
    });
  }

  @override
  void dispose() {
    _appearCtrl.dispose();
    _tapCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _tapCtrl.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.point;
    final radius = p.size / 2;

    return AnimatedBuilder(
      animation: Listenable.merge([_appearAnim, _tapCtrl, _pulseAnim]),
      builder: (context, child) {
        // 🔹 Масштаб: появление (0→1) + нажатие/пульсация
        double scale = _appearAnim.value;
        
        if (_tapCtrl.isAnimating) {
          scale *= _scaleAnim.value;
        } else if (widget.isCurrent) {
          scale *= _pulseAnim.value;
        }

        return Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: widget.isUnlocked ? _handleTap : null,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 💧 ВОДЯНАЯ РЯБЬ (всегда в дереве, управляем прозрачностью)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Transform.scale(
                    scale: _rippleScaleAnim.value,
                    child: Container(
                      width: p.size,
                      height: p.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.textColor.withOpacity(
                            _tapCtrl.isAnimating 
                                ? _rippleOpacityAnim.value 
                                : 0.0, // 🔹 Скрываем, когда не анимируем
                          ),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),

                // 🍃 КУВШИНКА
                LilyPad(
                  size: p.size,
                  isUnlocked: widget.isUnlocked,
                  isCurrent: false, // Обводка только через рябь/пульсацию
                  wedgeAngle: p.wedgeAngle,
                  rotationAngle: p.rotationAngle,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DotPoint {
  final WhaleNode node;
  final int index;
  final double xCenter;
  final double yCenter;
  final double size;
  final double wedgeAngle;
  final double rotationAngle;

  _DotPoint({
    required this.node,
    required this.index,
    required this.xCenter,
    required this.yCenter,
    required this.size,
    required this.wedgeAngle,
    required this.rotationAngle,
  });
}

class _TimelineLinePainter extends CustomPainter {
  final List<_DotPoint> points;
  final Color lineColor;

  _TimelineLinePainter({required this.points, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final pt = Offset(p.xCenter, p.yCenter);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        final prev = points[i - 1];
        final prevPt = Offset(prev.xCenter, prev.yCenter);
        final midY = (prevPt.dy + pt.dy) / 2;
        final midX = size.width / 2 + 42 * sin(midY / 140.0);
        path.cubicTo(midX, prevPt.dy, midX, pt.dy, pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TimelineLinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.lineColor != lineColor;
}