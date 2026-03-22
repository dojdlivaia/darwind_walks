// lib/screens/statistics/statistics_models.dart

class AggregatedStatsPoint {
  final DateTime date;
  final int totalSteps;

  AggregatedStatsPoint({
    required this.date,
    required this.totalSteps,
  });
}

class PeriodSummary {
  final int totalSteps;
  final double averagePerDay;
  final int bestDaySteps;
  final DateTime? bestDayDate;

  PeriodSummary({
    required this.totalSteps,
    required this.averagePerDay,
    required this.bestDaySteps,
    required this.bestDayDate,
  });
}
