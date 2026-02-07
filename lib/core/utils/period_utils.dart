import 'date_filters.dart';
import 'timezone_utils.dart';

int periodsFor(String period) {
  switch (period) {
    case 'daily':
      return 7;
    case 'weekly':
      return 4;
    case 'yearly':
      return 5;
    default:
      return 6;
  }
}

int reportPeriodsFor(String period) {
  return 1;
}

DateRange reportWindowRangeFor(String period, DateTime now) {
  final currentWib = toWib(now);
  final normalized = period.trim().toLowerCase();
  final dayStart = wibMidnightUtc(
    currentWib.year,
    currentWib.month,
    currentWib.day,
  );
  final dayEnd = dayStart.add(const Duration(days: 1));

  switch (normalized) {
    case 'daily':
      return DateRange(start: dayStart, end: dayEnd);
    case 'weekly':
      return DateRange(
        start: dayStart.subtract(const Duration(days: 6)),
        end: dayEnd,
      );
    case 'yearly':
      final yearStart = wibMidnightUtc(currentWib.year, 1, 1);
      final yearEnd = wibMidnightUtc(currentWib.year + 1, 1, 1);
      return DateRange(start: yearStart, end: yearEnd);
    default:
      final monthStart = wibMidnightUtc(currentWib.year, currentWib.month, 1);
      final monthEnd = wibMidnightUtc(currentWib.year, currentWib.month + 1, 1);
      return DateRange(start: monthStart, end: monthEnd);
  }
}

String periodLabel(String period) {
  switch (period) {
    case 'daily':
      return 'Harian';
    case 'weekly':
      return 'Mingguan';
    case 'yearly':
      return 'Tahunan';
    default:
      return 'Bulanan';
  }
}
