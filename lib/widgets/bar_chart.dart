// lib/widgets/bar_chart.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

// ✅ Добавляем недостающие импорты
import '../data/daily_steps_repository.dart';
import '../screens/statistics/statistics_models.dart';
import '../screens/statistics/stat_range.dart';

class BarChart extends StatelessWidget {
  final List<AggregatedStatsPoint> points;
  final StatsRange range;
  final bool animateBars;

  const BarChart({
    super.key,
    required this.points,
    required this.range,
    required this.animateBars,
  });

  // ✅ Выносим цвета как статические константы
  static const Color _colorPast = Color(0xFF4B5E09);
  static const Color _colorToday = Color(0xFF7FB83E);
  static const Color _colorFuture = Color(0xFF1A2A0A);
  static const Color _colorStump = Color(0xFF0F1A05);
  static const Color _accentLight = Color(0xFFEEF8CC);

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox();

    final maxSteps = points.map((p) => p.totalSteps).reduce(math.max).toDouble();
    final now = DateTime.now();

    // Для дня используем горизонтальную прокрутку
    if (range == StatsRange.day) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: points.asMap().entries.map((entry) {
              final point = entry.value;
              
              final currentHour = now.hour;
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
              
              final height = maxSteps > 0 ? (point.totalSteps / maxSteps) : 0.0;
              final calculatedHeight = height * 150.0;
              final barHeight = calculatedHeight < minHeight ? minHeight : calculatedHeight;
              final finalHeight = animateBars ? math.max(0.0, barHeight) : 0.0;
              
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

    // Для недели
    final screenWidth = MediaQuery.of(context).size.width;
    final barWidth = (screenWidth - 64) / points.length - 4;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          
          Color barColor;
          double minHeight = 4.0;
          
          final pointDate = DateTime(point.date.year, point.date.month, point.date.day);
          final today = DateTime(now.year, now.month, now.day);
          
          if (pointDate.isBefore(today)) {
            barColor = _colorPast;
          } else if (pointDate.day == today.day && pointDate.month == today.month) {
            barColor = _colorToday;
          } else {
            barColor = _colorStump;
            minHeight = 2.0;
          }
          
          final height = maxSteps > 0 ? (point.totalSteps / maxSteps) : 0.0;
          final calculatedHeight = height * 100.0;
          final barHeight = calculatedHeight < minHeight ? minHeight : calculatedHeight;
          final finalHeight = animateBars ? math.max(0.0, barHeight) : 0.0;
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