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

int cohortBucketCountFor(String period) {
  switch (period) {
    case 'daily':
      return 10;
    case 'weekly':
      return 8;
    case 'yearly':
      return 5;
    default:
      return 6;
  }
}

int cohortLookbackPeriodsFor(String period) {
  switch (period) {
    case 'daily':
      return 30;
    case 'weekly':
      return 12;
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
      return DateRange(
        start: dayStart.subtract(const Duration(days: 364)),
        end: dayEnd,
      );
    default:
      return DateRange(
        start: dayStart.subtract(const Duration(days: 29)),
        end: dayEnd,
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
