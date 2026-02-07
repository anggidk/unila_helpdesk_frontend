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

DateRange periodRangeFor(String period, DateTime now) {
  final current = now.toUtc();
  final normalized = period.trim().toLowerCase();
  final periods = periodsFor(normalized);

  switch (normalized) {
    case 'daily':
      return DateRange(
        start: current.subtract(Duration(days: periods)),
        end: current,
      );
    case 'weekly':
      return DateRange(
        start: current.subtract(Duration(days: periods * 7)),
        end: current,
      );
    case 'yearly':
      return DateRange(
        start: DateTime(current.year - periods, current.month, current.day),
        end: current,
      );
    default:
      return DateRange(
        start: DateTime(current.year, current.month - periods, current.day),
        end: current,
      );
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
