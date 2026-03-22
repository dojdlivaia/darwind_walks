// lib/screens/whale_vertical_timeline_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';

import '../models/whale.dart';

class WhaleVerticalTimelineScreen extends StatelessWidget {
  final WhaleData data;
  final int userSteps;

  WhaleVerticalTimelineScreen({
    super.key,
    required this.data,
    required this.userSteps,
  }) : _bgIndex = Random().nextInt(3); // 0,1,2

  final int _bgIndex;

  String get _backgroundPath =>
      'assets/images/whales/background0${_bgIndex + 1}.png';
  // если файлы называются background01/02/03 — используй:
  // 'assets/images/whales/background0${_bgIndex + 1}.png';

  static const Color _seaGreen = Color.fromARGB(255, 156, 228, 244);

  @override
  Widget build(BuildContext context) {
    final nodes = data.nodes;

    const double pixelsPerStepY = 0.085;
    const double width = 300;
    const double horizontalScreenPadding = 8;

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

      points.add(
        _DotPoint(
          node: node,
          index: i,
          xCenter: xCenterBase,
          yCenter: currentY,
          size: size,
        ),
      );
    }

    final double totalHeight =
        (points.isNotEmpty ? points.last.yCenter : 0) + 260;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Эволюция китов',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          // фон, если есть отдельная картинка — подставь сюда свой путь
          Positioned.fill(
            child: Image.asset(_backgroundPath, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.15)),
          ),
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
                        painter: _TimelineLinePainter(points: points),
                      ),
                    ),
                    // круги
                    ...points.map(
                      (p) => Positioned(
                        left: p.xCenter - p.size / 2,
                        top: p.yCenter - p.size / 2,
                        child: _buildCircle(p),
                      ),
                    ),
                    // подписи
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

  Widget _buildCircle(_DotPoint p) {
    final isUnlocked = p.node.cumulativeSteps <= userSteps;
    final Color circleColor = isUnlocked ? _seaGreen : Colors.grey.shade400;

    return Container(
      width: p.size,
      height: p.size,
      decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '${p.index + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
        color: isUnlocked ? Colors.white : Colors.white70,
      ),
    );

    final funFactText = isUnlocked
        ? Text(
            p.node.funfact,
            textAlign: textOnLeft ? TextAlign.right : TextAlign.left,
            softWrap: true,
            style: const TextStyle(
              fontSize: 9,
              height: 1.25,
              color: Colors.white70,
            ),
          )
        : const SizedBox.shrink();

    final textColumn = Column(
      crossAxisAlignment: textOnLeft
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [speciesText, const SizedBox(height: 4), funFactText],
    );

    final double circleRadius = p.size / 2;
    const double gap = 6;
    final double top = p.yCenter - circleRadius;

    if (textOnLeft) {
      // [ТЕКСТ]  gap  [КРУГ]
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
      // [КРУГ]  gap  [ТЕКСТ]
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

class _DotPoint {
  final WhaleNode node;
  final int index;
  final double xCenter;
  final double yCenter;
  final double size;

  _DotPoint({
    required this.node,
    required this.index,
    required this.xCenter,
    required this.yCenter,
    required this.size,
  });
}

class _TimelineLinePainter extends CustomPainter {
  final List<_DotPoint> points;

  _TimelineLinePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final Offset pt = Offset(p.xCenter, p.yCenter);

      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        final prev = points[i - 1];
        final Offset prevPt = Offset(prev.xCenter, prev.yCenter);

        final double midY = (prevPt.dy + pt.dy) / 2;
        final double t = midY / 140.0;
        const double amplitude = 42;
        final double midX = size.width / 2 + amplitude * sin(t);

        path.cubicTo(midX, prevPt.dy, midX, pt.dy, pt.dx, pt.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TimelineLinePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
