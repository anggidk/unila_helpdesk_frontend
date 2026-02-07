enum AdminDateFilter {
  all,
  today,
  last7Days,
  last30Days,
  last6Months,
  last1Year,
}

extension AdminDateFilterX on AdminDateFilter {
  String get label {
    switch (this) {
      case AdminDateFilter.today:
        return 'Hari ini';
      case AdminDateFilter.last7Days:
        return '7 hari';
      case AdminDateFilter.last30Days:
        return '30 hari';
      case AdminDateFilter.last6Months:
        return '6 bulan';
      case AdminDateFilter.last1Year:
        return '1 tahun';
      case AdminDateFilter.all:
        return 'Semua';
    }
  }
}

class DateRange {
  const DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

DateRange? adminDateRange(AdminDateFilter filter, DateTime now) {
  switch (filter) {
    case AdminDateFilter.today:
      final start = DateTime(now.year, now.month, now.day);
      return DateRange(start: start, end: start.add(const Duration(days: 1)));
    case AdminDateFilter.last7Days:
      return DateRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      );
    case AdminDateFilter.last30Days:
      return DateRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      );
    case AdminDateFilter.last6Months:
      return DateRange(
        start: _monthsAgo(now, 6),
        end: now,
      );
    case AdminDateFilter.last1Year:
      return DateRange(
        start: _monthsAgo(now, 12),
        end: now,
      );
    case AdminDateFilter.all:
      return null;
  }
}

DateTime _monthsAgo(DateTime now, int months) {
  var year = now.year;
  var month = now.month - months;
  while (month <= 0) {
    month += 12;
    year -= 1;
  }
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = now.day > lastDay ? lastDay : now.day;
  return DateTime(
    year,
    month,
    day,
    now.hour,
    now.minute,
    now.second,
    now.millisecond,
    now.microsecond,
  );
}
