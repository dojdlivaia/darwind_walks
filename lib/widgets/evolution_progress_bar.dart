// lib/widgets/evolution_progress_bar.dart

import 'package:flutter/material.dart';

class EvolutionProgressBar<T> extends StatefulWidget {
  final int currentSteps;
  final int totalSteps;
  final List<T> nodes;

  /// Как получить cumulativeSteps из ноды
  final int Function(T node) stepsOf;

  /// Какой текст показывать под точкой (название существа)
  final String Function(T node) labelOf;

  /// Колбэк при выборе подписи (теперь вызывается и для закрытых узлов)
  final void Function(T node) onNodeSelected;

  const EvolutionProgressBar({
    super.key,
    required this.currentSteps,
    required this.totalSteps,
    required this.nodes,
    required this.stepsOf,
    required this.labelOf,
    required this.onNodeSelected,
  });

  @override
  State<EvolutionProgressBar<T>> createState() =>
      _EvolutionProgressBarState<T>();
}

class _EvolutionProgressBarState<T> extends State<EvolutionProgressBar<T>> {
  late final ScrollController _scrollController;
  final double _pixelsPerStep = 0.2;
  final double _nodeRadius = 8.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _springToCurrentPosition();
    });
  }

  @override
  void didUpdateWidget(covariant EvolutionProgressBar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSteps != widget.currentSteps ||
        oldWidget.totalSteps != widget.totalSteps) {
      _springToCurrentPosition();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _springToCurrentPosition() {
    if (!_scrollController.hasClients) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final totalWidth = (widget.totalSteps * _pixelsPerStep) + 100.0;
    final maxScroll = (totalWidth - screenWidth).clamp(0.0, double.infinity);

    final currentX = widget.currentSteps * _pixelsPerStep;

    if (widget.currentSteps == 0) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
      return;
    }

    double targetOffset = currentX - screenWidth / 2;
    targetOffset = targetOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth = (widget.totalSteps * _pixelsPerStep) + 100.0;

    return SizedBox(
      height: 120,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: totalWidth,
          height: 120,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              CustomPaint(
                size: Size(totalWidth, 120),
                painter: _TimelinePainter<T>(
                  currentSteps: widget.currentSteps,
                  totalSteps: widget.totalSteps,
                  pixelsPerStep: _pixelsPerStep,
                  nodes: widget.nodes,
                  stepsOf: widget.stepsOf,
                  nodeRadius: _nodeRadius,
                ),
              ),
              ...widget.nodes.map((node) {
                final cumulative = widget.stepsOf(node);
                final leftPosition = cumulative * _pixelsPerStep;
                final isUnlocked = cumulative <= widget.currentSteps;

                return Positioned(
                  left: leftPosition - 40,
                  top: 60 + _nodeRadius + 5,
                  child: GestureDetector(
                    // теперь тап доступен для любого узла
                    onTap: () => widget.onNodeSelected(node),
                    child: SizedBox(
                      width: 80,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.labelOf(node),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? Colors.black87 : Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$cumulative',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelinePainter<T> extends CustomPainter {
  final int currentSteps;
  final int totalSteps;
  final double pixelsPerStep;
  final List<T> nodes;
  final int Function(T node) stepsOf;
  final double nodeRadius;

  _TimelinePainter({
    required this.currentSteps,
    required this.totalSteps,
    required this.pixelsPerStep,
    required this.nodes,
    required this.stepsOf,
    required this.nodeRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double centerY = 60.0;
    final double currentX = currentSteps * pixelsPerStep;

    final Paint greyLinePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const Offset(0, centerY),
      Offset(totalSteps * pixelsPerStep, centerY),
      greyLinePaint,
    );

    final Paint greenLinePaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const Offset(0, centerY),
      Offset(currentX, centerY),
      greenLinePaint,
    );

    final lastPassedIndex = nodes.lastIndexWhere(
      (n) => stepsOf(n) <= currentSteps,
    );

    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final cumulative = stepsOf(node);

      final double nodeX = cumulative * pixelsPerStep;
      final bool isPassed = cumulative <= currentSteps;
      final bool isLastPassed = i == lastPassedIndex && isPassed;

      final Offset center = Offset(nodeX, centerY);

      final Paint circlePaint = Paint()
        ..color = isPassed ? const Color(0xFF4CAF50) : Colors.grey.shade400
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, nodeRadius, circlePaint);

      if (!isPassed) {
        final Paint borderPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(center, nodeRadius - 1, borderPaint);
      } else if (isLastPassed) {
        final Paint ringPaint = Paint()
          ..color = const Color(0xFF4CAF50)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

        final Paint innerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        canvas.drawCircle(center, nodeRadius, ringPaint);
        canvas.drawCircle(center, nodeRadius - 3, innerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
