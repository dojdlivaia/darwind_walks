// lib/screens/statistics/statistics_screen.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../data/daily_steps_repository.dart';
import 'stat_range.dart';
import 'statistics_models.dart';
import '../../widgets/bar_chart.dart';
import '../../widgets/month_heatmap.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    super.key,
    required this.repository,
  });

  final DailyStepsRepository repository;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  StatsRange _range = StatsRange.week;
  DateTimeRange? _customRange;
  int _periodOffset = 0;

  List<AggregatedStatsPoint> _points = [];
  PeriodSummary? _summary;
  bool _isLoading = true;
  String? _errorText;

  late AnimationController _animationController;
  bool _animateBars = false;

  static const Color _primaryGreen = Color(0xFF4B5E09);
  static const Color _backgroundDark = Color(0xFF061B14);
  static const Color _accentLight = Color(0xFFEEF8CC);
  static const Color _secondaryDark = Color(0xFF2E3A05);
  static const Color _textWhite = Colors.white;

  static const Color _colorPast = Color(0xFF4B5E09);
  static const Color _colorToday = Color(0xFF7FB83E);
  static const Color _colorFuture = Color(0xFF1A2A0A);
  static const Color _colorStump = Color(0xFF0F1A05);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
      _animateBars = false;
    });

    try {
      final now = DateTime.now();
      late DateTime from;
      late DateTime to;

      switch (_range) {
        case StatsRange.day:
          from = DateTime(now.year, now.month, now.day).add(Duration(days: _periodOffset));
          to = from;
          break;
        case StatsRange.week:
          final baseStart = now.subtract(Duration(days: now.weekday - 1));
          final startOfWeek = baseStart.add(Duration(days: _periodOffset * 7));
          from = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          to = from.add(const Duration(days: 6));
          break;
        case StatsRange.month:
          var targetMonth = now.month + _periodOffset;
          var targetYear = now.year;
          while (targetMonth > 12) { targetMonth -= 12; targetYear++; }
          while (targetMonth < 1) { targetMonth += 12; targetYear--; }
          from = DateTime(targetYear, targetMonth, 1);
          to = DateTime(targetYear, targetMonth + 1, 0);
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
      
      final aggregated = _range == StatsRange.week 
          ? _padWeekData(_aggregate(raw), from) 
          : _aggregate(raw);
          
      final summary = _buildSummary(aggregated);

      setState(() {
        _points = aggregated;
        _summary = summary;
        _isLoading = false;
        _errorText = null;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _animateBars = true);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _points = [];
        _summary = null;
        _errorText = 'Ошибка: $e';
      });
    }
  }

  List<AggregatedStatsPoint> _padWeekData(
    List<AggregatedStatsPoint> points, 
    DateTime weekStart
  ) {
    final result = <AggregatedStatsPoint>[];
    final pointMap = {for (var p in points) _dayKey(p.date): p};
    
    for (var i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final key = _dayKey(date);
      result.add(pointMap[key] ?? AggregatedStatsPoint(date: date, totalSteps: 0));
    }
    return result;
  }

  int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  void _previousPeriod() {
    setState(() => _periodOffset--);
    _loadStats();
  }

  void _nextPeriod() {
    setState(() => _periodOffset++);
    _loadStats();
  }

  List<AggregatedStatsPoint> _aggregate(List<DailyStepsStat> stats) {
    if (_range == StatsRange.day && stats.isNotEmpty) {
      final firstDay = stats.first;
      return List.generate(24, (hour) {
        final steps = firstDay.hourlySteps[hour] ?? 0;
        return AggregatedStatsPoint(
          date: DateTime(firstDay.date.year, firstDay.date.month, firstDay.date.day, hour),
          totalSteps: steps,
        );
      });
    }
    
    return stats.map((s) => AggregatedStatsPoint(
      date: s.date,
      totalSteps: s.totalSteps,
    )).toList();
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
    final best = points.reduce((a, b) => a.totalSteps >= b.totalSteps ? a : b);
    final avg = total / points.length;

    return PeriodSummary(
      totalSteps: total,
      averagePerDay: avg,
      bestDaySteps: best.totalSteps,
      bestDayDate: best.date,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        backgroundColor: _secondaryDark,
        elevation: 0,
        title: const Text(
          'Статистика',
          style: TextStyle(
            color: _textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.12,
                child: Image.asset(
                  'assets/images/plants/plant01.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.12,
                child: Image.asset(
                  'assets/images/plants/plant02.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomLeft,
                ),
              ),
            ),
          ),
          _buildBodyContent(),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: _primaryGreen,
          backgroundColor: _secondaryDark,
        ),
      );
    }
    
    if (_errorText != null) {
      return Center(
        child: Text(
          _errorText!,
          style: TextStyle(color: _accentLight),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        _buildRangeSelector(),
        if (_summary != null) _buildSummaryCards(_summary!),
        const SizedBox(height: 12),
        Expanded(child: _buildChart()),
      ],
    );
  }

  Widget _buildRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: _secondaryDark,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: _accentLight),
                onPressed: _previousPeriod,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              Expanded(
                child: Text(
                  _getPeriodLabel(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _accentLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: _accentLight),
                onPressed: _nextPeriod,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
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
                    _customRange == null ? 'Диапазон' : '✓',
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
        ],
      ),
    );
  }

  String _getPeriodLabel() {
    final now = DateTime.now();
    switch (_range) {
      case StatsRange.day:
        final targetDate = DateTime(now.year, now.month, now.day).add(Duration(days: _periodOffset));
        return '${targetDate.day}.${targetDate.month}.${targetDate.year}';
      case StatsRange.week:
        final start = now.subtract(Duration(days: now.weekday - 1)).add(Duration(days: _periodOffset * 7));
        final end = start.add(const Duration(days: 6));
        return '${start.day}.${start.month} – ${end.day}.${end.month}';
      case StatsRange.month:
        var month = now.month + _periodOffset;
        var year = now.year;
        while (month > 12) { month -= 12; year++; }
        while (month < 1) { month += 12; year--; }
        final monthNames = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 
                           'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];
        return '${monthNames[month - 1]} $year';
      case StatsRange.custom:
        return 'Выбранный период';
    }
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

  Widget _buildSummaryCards(PeriodSummary summary) {
    final bestDayStr = summary.bestDayDate != null
        ? '${summary.bestDayDate!.day}.${summary.bestDayDate!.month}'
        : '–';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _expandedSummaryCard('Всего', summary.totalSteps.toString(), _primaryGreen),
          const SizedBox(width: 10),
          _expandedSummaryCard('В день', summary.averagePerDay.toStringAsFixed(0), _secondaryDark),
          const SizedBox(width: 10),
          _expandedSummaryCard('Рекорд', '${summary.bestDaySteps}\n$bestDayStr', _accentLight.withOpacity(0.3)),
        ],
      ),
    );
  }

  Widget _expandedSummaryCard(String label, String value, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.2),
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
                color: _accentLight,
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

  Widget _buildChart() {
  if (_points.isEmpty) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64,
            color: _accentLight,
          ),
          SizedBox(height: 16),
          Text(
            'Нет данных для периода',
            style: TextStyle(
              color: _accentLight,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  if (_range == StatsRange.month) {
    return MonthHeatmap(
      points: _points,
      animateBars: _animateBars,
    );
  }

  return Column(
    children: [
      Expanded(flex: 3, child: BarChart(
        points: _points,
        range: _range,
        animateBars: _animateBars,
      )),
      Expanded(flex: 2, child: _buildStepsList()), // ✅ Оставляем старый метод
    ],
  );
}

  Widget _buildStepsList() {
    return Container(
      decoration: BoxDecoration(
        color: _secondaryDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _points.length,
        separatorBuilder: (_, __) => Divider(color: _accentLight.withOpacity(0.1), height: 1),
        itemBuilder: (context, index) {
          final p = _points[index];
          final dayName = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][p.date.weekday - 1];
          final dateStr = _range == StatsRange.day 
              ? '${p.date.hour}:00–${(p.date.hour + 1) % 24}:00'
              : '${p.date.day}.${p.date.month}';
          
          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _primaryGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _range == StatsRange.day ? '${p.date.hour}' : dayName,
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
      _periodOffset = 0;
    });
    await _loadStats();
  }

  void _onRangeChanged(StatsRange range) {
    setState(() {
      _range = range;
      _periodOffset = 0;
      if (range != StatsRange.custom) {
        _customRange = null;
      }
    });
    _loadStats();
  }
}