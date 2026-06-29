// lib/widgets/bar_chart.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../screens/statistics/statistics_models.dart';
import '../screens/statistics/stat_range.dart';

class BarChart extends StatefulWidget {
  final List<AggregatedStatsPoint> points;
  final StatsRange range;
  final bool animateBars;

  const BarChart({
    super.key,
    required this.points,
    required this.range,
    required this.animateBars,
  });

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart> {
  final ScrollController _scrollController = ScrollController();

  static const Color _colorPast = Color(0xFF4B5E09);
  static const Color _colorToday = Color(0xFF7FB83E);
  static const Color _colorStump = Color(0xFF0F1A05);
  static const Color _accentLight = Color(0xFFEEF8CC);

  @override
  void initState() {
    super.initState();
    if (widget.range == StatsRange.day && widget.points.isNotEmpty) {
      final hasData = widget.points.any((p) => p.totalSteps > 0);
      if (hasData) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToRelevantTime();
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _getTargetHour() {
    final now = DateTime.now().hour;
    if (now < 8) return 0;
    if (now < 16) return 7;
    return 13;
  }

  void _scrollToRelevantTime() {
    if (!_scrollController.hasClients) return;
    final targetHour = _getTargetHour();
    final index = widget.points.indexWhere((p) => p.date.hour == targetHour);
    if (index == -1) return;

    const itemWidth = 34.0;
    const padding = 16.0;
    final offset = (index * itemWidth) + padding;

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Если нет точек — показываем заглушку
    if (widget.points.isEmpty) {
      return const Center(
        child: Text(
          'Нет данных',
          style: TextStyle(color: _accentLight),
        ),
      );
    }

    // ✅ Защита от пустых данных — вычисляем maxSteps
    final maxSteps = widget.points
        .map((p) => p.totalSteps)
        .fold<int>(0, (max, value) => value > max ? value : max)
        .toDouble();

    // ✅ Если maxSteps == 0 — все столбцы нулевые
    if (maxSteps <= 0) {
      return const Center(
        child: Text(
          'Нет шагов в этом периоде',
          style: TextStyle(color: _accentLight),
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 📅 Вкладка "День"
    if (widget.range == StatsRange.day) {
      final selectedDate = widget.points.isNotEmpty
          ? DateTime(
              widget.points.first.date.year,
              widget.points.first.date.month,
              widget.points.first.date.day,
            )
          : today;

      final isToday = selectedDate.year == today.year &&
          selectedDate.month == today.month &&
          selectedDate.day == today.day;
      final currentHour = isToday ? now.hour : 23;

      return SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: widget.points.asMap().entries.map((entry) {
              final point = entry.value;
              final pointHour = point.date.hour;

              Color barColor;
              double minHeight = 4.0;

              if (pointHour < currentHour) {
                barColor = _colorPast;
              } else if (pointHour == currentHour) {
                barColor = _colorToday;
              } else {
                barColor = _colorStump;
                minHeight = 2.0;
              }

              // ✅ Высота столбца: от 0 до 150
              final heightRatio = maxSteps > 0 ? (point.totalSteps / maxSteps) : 0.0;
              final calculatedHeight = heightRatio * 150.0;
              final barHeight = calculatedHeight < minHeight ? minHeight : calculatedHeight;
              final finalHeight = widget.animateBars 
                  ? barHeight.clamp(0.0, 150.0) 
                  : 0.0;

              return Container(
                width: 30,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      width: 20,
                      height: finalHeight,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${point.date.hour}',
                      style: const TextStyle(
                        color: _accentLight,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    // 📅 Вкладки "Неделя", "Месяц", "Диапазон"
    final screenWidth = MediaQuery.of(context).size.width;
    final barWidth = (screenWidth - 64) / widget.points.length - 4;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: widget.points.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;

          Color barColor;
          double minHeight = 4.0;

          final pointDate = DateTime(point.date.year, point.date.month, point.date.day);

          if (pointDate.isBefore(today)) {
            barColor = _colorPast;
          } else if (pointDate.day == today.day && pointDate.month == today.month) {
            barColor = _colorToday;
          } else {
            barColor = _colorStump;
            minHeight = 2.0;
          }

          // ✅ Высота столбца: от 0 до 100
          final heightRatio = maxSteps > 0 ? (point.totalSteps / maxSteps) : 0.0;
          final calculatedHeight = heightRatio * 100.0;
          final barHeight = calculatedHeight < minHeight ? minHeight : calculatedHeight;
          final finalHeight = widget.animateBars 
              ? barHeight.clamp(0.0, 100.0) 
              : 0.0;
          final dayLabel = '${point.date.day}.${point.date.month}';

          return Container(
            width: math.max(barWidth, 20.0),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 400 + index * 80),
                  curve: Curves.easeOutBack,
                  width: double.infinity,
                  height: finalHeight,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dayLabel,
                  style: const TextStyle(
                    color: _accentLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}