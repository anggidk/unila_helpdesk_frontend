import 'date_filters.dart';

const Duration _wibOffset = Duration(hours: 7);

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
  final currentUtc = now.toUtc();
  final currentWib = currentUtc.add(_wibOffset);
  final normalized = period.trim().toLowerCase();
  final dayStart = DateTime.utc(
    currentWib.year,
    currentWib.month,
    currentWib.day,
  ).subtract(_wibOffset);
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
      final yearStart = DateTime.utc(currentWib.year, 1, 1).subtract(_wibOffset);
      final yearEnd = DateTime.utc(currentWib.year + 1, 1, 1).subtract(_wibOffset);
      return DateRange(start: yearStart, end: yearEnd);
    default:
      final monthStart = DateTime.utc(currentWib.year, currentWib.month, 1).subtract(_wibOffset);
      final monthEnd = DateTime.utc(currentWib.year, currentWib.month + 1, 1).subtract(_wibOffset);
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
