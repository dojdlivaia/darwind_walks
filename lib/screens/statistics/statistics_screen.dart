// lib/screens/statistics/statistics_screen.dart

import 'package:flutter/material.dart';

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
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика шагов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final now = DateTime.now();
              await widget.repository.addSteps(
                date: now,
                stepsDelta: 100,
                routeId: 'test_button',
              );
              await _loadStats();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorText != null
              ? Center(child: Text(_errorText!))
              : Column(
                  children: [
                    _buildRangeSelector(),
                    if (summary != null) _buildSummaryRow(summary),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildChartPlaceholder(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
    );
  }

  Widget _buildRangeSelector() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _rangeChip('День', StatsRange.day),
          _rangeChip('Неделя', StatsRange.week),
          _rangeChip('Месяц', StatsRange.month),
          GestureDetector(
            onTap: _pickCustomRange,
            child: Chip(
              label: Text(
                _customRange == null ? 'Диапазон' : 'Диапазон ✓',
              ),
              backgroundColor: _range == StatsRange.custom
                  ? Colors.black87
                  : Colors.grey.shade200,
              labelStyle: TextStyle(
                color: _range == StatsRange.custom
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeChip(String label, StatsRange value) {
    final isSelected = _range == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onRangeChanged(value),
    );
  }

  Widget _buildSummaryRow(PeriodSummary summary) {
    final bestDayStr = summary.bestDayDate != null
        ? '${summary.bestDayDate!.day}.${summary.bestDayDate!.month}'
        : '–';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Всего', summary.totalSteps.toString()),
          _summaryItem(
            'В день',
            summary.averagePerDay.toStringAsFixed(0),
          ),
          _summaryItem('Рекорд', '${summary.bestDaySteps}\n$bestDayStr'),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildChartPlaceholder() {
    if (_points.isEmpty) {
      return const Center(
        child: Text('Нет данных для выбранного периода'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _points.length,
      itemBuilder: (context, index) {
        final p = _points[index];
        return ListTile(
          dense: true,
          title: Text(
            '${p.date.day}.${p.date.month}.${p.date.year}',
          ),
          trailing: Text('${p.totalSteps} шагов'),
        );
      },
    );
  }
}