// lib/screens/statistics/statistics_screen.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../data/daily_steps_repository.dart';
import 'stat_range.dart';
import 'statistics_models.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    super.key,
    required this.repository,
  });

  final DailyStepsRepository repository;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatsRange _range = StatsRange.week;
  DateTimeRange? _customRange;

  List<AggregatedStatsPoint> _points = [];
  PeriodSummary? _summary;
  bool _isLoading = true;
  String? _errorText;

  // 🎨 Цветовая палитра
  static const Color _primaryGreen = Color(0xFF4B5E09);
  static const Color _backgroundDark = Color(0xFF061B14);
  static const Color _accentLight = Color(0xFFEEF8CC);
  static const Color _secondaryDark = Color(0xFF2E3A05);
  static const Color _textWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final now = DateTime.now();
      late DateTime from;
      late DateTime to;

      switch (_range) {
        case StatsRange.day:
          from = DateTime(now.year, now.month, now.day);
          to = from;
          break;
        case StatsRange.week:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          from = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          to = DateTime(now.year, now.month, now.day);
          break;
        case StatsRange.month:
          from = DateTime(now.year, now.month, 1);
          to = DateTime(now.year, now.month + 1, 0);
          break;
        case StatsRange.custom:
          if (_customRange == null) {
            setState(() => _isLoading = false);
            return;
          }
          from = _customRange!.start;
          to = _customRange!.end;
          break;
      }

      final raw = await widget.repository.getRange(from: from, to: to);
      final aggregated = _aggregate(raw);
      final summary = _buildSummary(aggregated);

      setState(() {
        _points = aggregated;
        _summary = summary;
        _isLoading = false;
        _errorText = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _points = [];
        _summary = null;
        _errorText = 'Ошибка при загрузке статистики: $e';
      });
    }
  }

  List<AggregatedStatsPoint> _aggregate(List<DailyStepsStat> stats) {
    return stats
        .map(
          (s) => AggregatedStatsPoint(
            date: s.date,
            totalSteps: s.totalSteps,
          ),
        )
        .toList();
  }

  PeriodSummary _buildSummary(List<AggregatedStatsPoint> points) {
    if (points.isEmpty) {
      return PeriodSummary(
        totalSteps: 0,
        averagePerDay: 0,
        bestDaySteps: 0,
        bestDayDate: null,
      );
    }

    final total = points.fold<int>(0, (sum, p) => sum + p.totalSteps);
    final best = points.reduce(
      (a, b) => a.totalSteps >= b.totalSteps ? a : b,
    );
    final avg = total / points.length;

    return PeriodSummary(
      totalSteps: total,
      averagePerDay: avg,
      bestDaySteps: best.totalSteps,
      bestDayDate: best.date,
    );
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, now.day - 6),
            end: DateTime(now.year, now.month, now.day),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _primaryGreen,
              onPrimary: _textWhite,
              surface: _secondaryDark,
              onSurface: _textWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (result == null) return;

    setState(() {
      _customRange = result;
      _range = StatsRange.custom;
    });
    await _loadStats();
  }

  void _onRangeChanged(StatsRange range) {
    setState(() {
      _range = range;
      if (range != StatsRange.custom) {
        _customRange = null;
      }
    });
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        backgroundColor: _secondaryDark,
        elevation: 0,
        title: Text(
          '📊 Статистика',
          style: TextStyle(
            color: _textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: _primaryGreen,
                backgroundColor: _secondaryDark,
              ),
            )
          : _errorText != null
              ? Center(
                  child: Text(
                    _errorText!,
                    style: TextStyle(color: _accentLight),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  children: [
                    _buildRangeSelector(),
                    if (_summary != null) _buildSummaryCards(_summary!),
                    const SizedBox(height: 12),
                    Expanded(child: _buildChart()),
                  ],
                ),
    );
  }

  // 🎯 Селектор диапазона с новой стилизацией
  Widget _buildRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: _secondaryDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _rangeChip('День', StatsRange.day),
          _rangeChip('Неделя', StatsRange.week),
          _rangeChip('Месяц', StatsRange.month),
          GestureDetector(
            onTap: _pickCustomRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _range == StatsRange.custom ? _primaryGreen : _accentLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _range == StatsRange.custom ? _accentLight : _primaryGreen,
                  width: 1.5,
                ),
              ),
              child: Text(
                _customRange == null ? '📅 Диапазон' : '✓',
                style: TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeChip(String label, StatsRange value) {
    final isSelected = _range == value;
    return GestureDetector(
      onTap: () => _onRangeChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _accentLight : _accentLight.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _textWhite : _accentLight,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // 📈 Карточки с итоговой статистикой
  Widget _buildSummaryCards(PeriodSummary summary) {
    final bestDayStr = summary.bestDayDate != null
        ? '${summary.bestDayDate!.day}.${summary.bestDayDate!.month}'
        : '–';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _expandedSummaryCard('👣 Всего', summary.totalSteps.toString(), _primaryGreen),
          const SizedBox(width: 10),
          _expandedSummaryCard('📅 В день', summary.averagePerDay.toStringAsFixed(0), _secondaryDark),
          const SizedBox(width: 10),
          _expandedSummaryCard('🏆 Рекорд', '${summary.bestDaySteps}\n$bestDayStr', _accentLight.withOpacity(0.3)),
        ],
      ),
    );
  }

  Widget _expandedSummaryCard(String label, String value, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withOpacity(0.4),
              accentColor.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withOpacity(0.6), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: _accentLight.withOpacity(0.9),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 📊 Визуальный график шагов
  Widget _buildChart() {
    if (_points.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: _accentLight.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет данных для периода',
              style: TextStyle(
                color: _accentLight.withOpacity(0.7),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 📈 Мини-график (бар-чарт)
        Expanded(
          flex: 3,
          child: _buildBarChart(),
        ),
        // 📋 Список дней
        Expanded(
          flex: 2,
          child: _buildStepsList(),
        ),
      ],
    );
  }

  // 📊 Горизонтальный бар-чарт
  Widget _buildBarChart() {
    if (_points.isEmpty) return const SizedBox();

    final maxSteps = _points.map((p) => p.totalSteps).reduce(math.max).toDouble();
    final barWidth = (MediaQuery.of(context).size.width - 40) / _points.length - 4;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _points.map((point) {
          final height = maxSteps > 0 ? (point.totalSteps / maxSteps) : 0;
          final dayLabel = '${point.date.day}.${point.date.month}';
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Бар
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: math.max(barWidth, 8),
                height: math.max(height * 100, 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      _primaryGreen,
                      _primaryGreen.withOpacity(0.7),
                      _accentLight.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryGreen.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Подпись дня
              Text(
                dayLabel,
                style: TextStyle(
                  color: _accentLight.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // 📋 Список дней с шагами
  Widget _buildStepsList() {
    return Container(
      decoration: BoxDecoration(
        color: _secondaryDark.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _points.length,
        separatorBuilder: (_, __) => Divider(color: _accentLight.withOpacity(0.1), height: 1),
        itemBuilder: (context, index) {
          final p = _points[index];
          final dayName = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][p.date.weekday - 1];
          final dateStr = '${p.date.day}.${p.date.month}';
          
          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  dayName,
                  style: TextStyle(
                    color: _accentLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              dateStr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accentLight.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentLight.withOpacity(0.3)),
              ),
              child: Text(
                '${p.totalSteps}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}