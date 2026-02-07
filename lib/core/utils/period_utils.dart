import 'date_filters.dart';

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
