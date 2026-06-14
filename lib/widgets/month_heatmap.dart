// lib/widgets/month_heatmap.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../data/daily_steps_repository.dart';
import '../screens/statistics/statistics_models.dart';

class MonthHeatmap extends StatefulWidget {
  final List<AggregatedStatsPoint> points;
  final bool animateBars;

  const MonthHeatmap({
    super.key,
    required this.points,
    required this.animateBars,
  });

  @override
  State<MonthHeatmap> createState() => _MonthHeatmapState();
}

class _MonthHeatmapState extends State<MonthHeatmap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const Color _colorPast = Color(0xFF4B5E09);
  static const Color _colorToday = Color(0xFF7FB83E);
  static const Color _colorFuture = Color(0xFF1A2A0A);
  static const Color _colorStump = Color(0xFF0F1A05);
  static const Color _accentLight = Color(0xFFEEF8CC);
  static const Color _textWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    // ✅ Увеличиваем длительность: 42 ячейки × 40мс задержка + 300мс на анимацию каждой
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    if (widget.animateBars) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(MonthHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateBars && !oldWidget.animateBars) {
      _controller.forward(from: 0);
    } else if (!widget.animateBars) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) return const SizedBox();

    final maxSteps = widget.points.map((p) => p.totalSteps).reduce(math.max).toDouble();
    final now = DateTime.now();
    
    final firstPoint = widget.points.first;
    final lastPoint = widget.points.last;
    
    final firstDayOfMonth = DateTime(firstPoint.date.year, firstPoint.date.month, 1);
    final lastDayOfMonth = DateTime(lastPoint.date.year, lastPoint.date.month + 1, 0);
    final startingWeekday = firstDayOfMonth.weekday;
    final totalDaysInMonth = lastDayOfMonth.day;

    final pointMap = {for (var p in widget.points) p.date.day: p};

    Color getColorForSteps(int steps) {
      if (steps == 0) return _colorStump;
      final ratio = steps / maxSteps;
      if (ratio < 0.25) return _colorFuture;
      if (ratio < 0.5) return _colorPast;
      if (ratio < 0.75) return _colorPast.withOpacity(0.8);
      return _colorToday;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
                .map((day) => SizedBox(
                      width: 40,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _accentLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final dayIndex = index - startingWeekday + 2;
                
                if (dayIndex < 1 || dayIndex > totalDaysInMonth) {
                  return const SizedBox();
                }

                final day = dayIndex;
                final point = pointMap[day];
                final steps = point?.totalSteps ?? 0;
                
                final isToday = day == now.day && 
                               firstPoint.date.month == now.month && 
                               firstPoint.date.year == now.year;
                
                final color = getColorForSteps(steps);
                
                // ✅ Простая и надёжная формула задержки
                final staggerDelay = (dayIndex - 1) * 30; // 40мс на ячейку
                final animationStart = staggerDelay / 2200.0; // Нормализуем к длительности контроллера
                final animationDuration = 0.3; // 30% времени на рост каждой ячейки
                
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final progress = _controller.value;
                    // Вычисляем прогресс для конкретной ячейки
                    final rawProgress = (progress - animationStart) / animationDuration;
                    final cellProgress = rawProgress.clamp(0.0, 1.0);
                    
                    if (cellProgress <= 0) {
                      return const SizedBox();
                    }

                    return Transform.scale(
                      scale: Curves.easeOutBack.transform(cellProgress),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday 
                              ? Border.all(color: _accentLight, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: const TextStyle(
                                color: _textWhite,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (steps > 0)
                              Text(
                                '$steps',
                                style: TextStyle(
                                  color: _accentLight,
                                  fontSize: 9,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}