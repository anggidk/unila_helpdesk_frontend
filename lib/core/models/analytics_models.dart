class CohortRow {
  const CohortRow({
    required this.label,
    required this.users,
    required this.retention,
  });

  final String label;
  final int users;
  final List<int> retention;
}

class ServiceTrend {
  const ServiceTrend({
    required this.label,
    required this.percentage,
    required this.note,
  });

  final String label;
  final double percentage;
  final String note;
}
