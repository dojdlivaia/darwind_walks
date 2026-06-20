// lib/screens/mammal_vertical_timeline_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';

import '../models/mammal_node.dart';
import '../widgets/mammal_timeline_point.dart';
import '../widgets/mammal_media_viewer.dart';
import '../services/data_loader.dart';

class MammalVerticalTimelineScreen extends StatefulWidget {
  final int userSteps;

  const MammalVerticalTimelineScreen({
    super.key,
    required this.userSteps,
  });

  @override
  State<MammalVerticalTimelineScreen> createState() =>
      _MammalVerticalTimelineScreenState();
}

class _MammalVerticalTimelineScreenState
    extends State<MammalVerticalTimelineScreen> {
  late Future<MammalTimelineData> _dataFuture;

  static const Color _background = Color(0xFF061B14);
  static const Color _textColor = Color(0xFFEEF8CC);
  static const Color _accentColor = Color(0xFF4B5E09);

  @override
  void initState() {
    super.initState();
    _dataFuture = DataLoader.loadMammalsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Мир млекопитающих',
          style: TextStyle(color: _textColor),
        ),
        backgroundColor: _background,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textColor),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _accentColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              'Шагов: ${widget.userSteps}',
              style: const TextStyle(
                color: _textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<MammalTimelineData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _accentColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки данных: ${snapshot.error}',
                style: const TextStyle(color: _textColor),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                'Данные не найдены',
                style: TextStyle(color: _textColor),
              ),
            );
          }

          final data = snapshot.data!;
          final nodes = data.nodes;

          const double pixelsPerStepY = 0.065;
          const double width = 320;
          const double horizontalScreenPadding = 8;

          // Находим текущий индекс
          int currentIndex = 0;
          if (nodes.isNotEmpty) {
            for (int i = nodes.length - 1; i >= 0; i--) {
              if (nodes[i].cumulativeSteps <= widget.userSteps) {
                currentIndex = i;
                break;
              }
            }
          }

          // Строим точки
          final List<_MammalDotPoint> points = [];
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
            const double amplitude = 50;
            final double xCenterBase = width / 2 + amplitude * sin(t);

            final double scale = 1.0 + 0.15 * sin(i * pi / 4);
            const double baseSize = 48;
            final double size = baseSize * scale;

            points.add(
              _MammalDotPoint(
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

          return Stack(
            children: [
              // Фон
              Positioned.fill(
                child: Image.asset(
                  'assets/images/mammals/timeline_bg.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF061B14),
                          const Color(0xFF0A2A1E),
                          const Color(0xFF061B14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(color: _background.withOpacity(0.85)),
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
                        // Линия таймлайна
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MammalTimelineLinePainter(
                              points: points,
                              lineColor: _textColor.withOpacity(0.3),
                            ),
                          ),
                        ),

                        // Анимированные узлы
                        ...points.asMap().entries.map((entry) {
                          final index = entry.key;
                          final p = entry.value;
                          final isUnlocked =
                              p.node.cumulativeSteps <= widget.userSteps;
                          final isCurrent = index == currentIndex;
                          final textOnLeft = p.xCenter > width / 2;

                          return Positioned(
                            left: p.xCenter - p.size / 2,
                            top: p.yCenter - p.size / 2,
                            child: _MammalAnimatedNode(
                              point: p,
                              isUnlocked: isUnlocked,
                              isCurrent: isCurrent,
                              textOnLeft: textOnLeft,
                              timelineWidth: width,
                              textColor: _textColor,
                              delay: Duration(milliseconds: index * 150),
                              onTap: () => _onNodeTap(context, p.node),
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
          );
        },
      ),
    );
  }

  void _onNodeTap(BuildContext context, MammalNode node) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MammalMediaViewer(
        node: node,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildLabels(_MammalDotPoint p, {required double width}) {
    final bool textOnLeft = p.xCenter > width / 2;
    final isUnlocked = p.node.cumulativeSteps <= widget.userSteps;

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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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

    const double gap = 6;
    final double top = p.yCenter - p.size / 2;

    if (textOnLeft) {
      return Positioned(
        top: top,
        left: 0,
        right: width - p.xCenter,
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
        left: p.xCenter,
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

// ============================================================
// 🔹 Вспомогательные классы
// ============================================================

class _MammalDotPoint {
  final MammalNode node;
  final int index;
  final double xCenter;
  final double yCenter;
  final double size;

  _MammalDotPoint({
    required this.node,
    required this.index,
    required this.xCenter,
    required this.yCenter,
    required this.size,
  });
}

// ============================================================
// 🔹 Анимированный узел
// ============================================================

class _MammalAnimatedNode extends StatefulWidget {
  final _MammalDotPoint point;
  final bool isUnlocked;
  final bool isCurrent;
  final bool textOnLeft;
  final double timelineWidth;
  final Color textColor;
  final Duration delay;
  final VoidCallback onTap;

  const _MammalAnimatedNode({
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
  State<_MammalAnimatedNode> createState() => _MammalAnimatedNodeState();
}

class _MammalAnimatedNodeState extends State<_MammalAnimatedNode>
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

    _appearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _appearAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _appearCtrl, curve: Curves.elasticOut),
    );

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

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

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

    return AnimatedBuilder(
      animation: Listenable.merge([_appearAnim, _tapCtrl, _pulseAnim]),
      builder: (context, child) {
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
                // Рябь при нажатии
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
                                : 0.0,
                          ),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),

                // Отпечаток лапы
                MammalTimelinePoint(
                  node: p.node,
                  isUnlocked: widget.isUnlocked,
                  isCurrent: widget.isCurrent,
                  onTap: widget.isUnlocked ? _handleTap : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// 🔹 Линия таймлайна
// ============================================================

class _MammalTimelineLinePainter extends CustomPainter {
  final List<_MammalDotPoint> points;
  final Color lineColor;

  _MammalTimelineLinePainter({required this.points, required this.lineColor});

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
        final midX = size.width / 2 + 50 * sin(midY / 140.0);
        path.cubicTo(midX, prevPt.dy, midX, pt.dy, pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MammalTimelineLinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.lineColor != lineColor;
}