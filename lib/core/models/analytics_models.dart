class CohortRow {
  const CohortRow({
    required this.label,
    required this.users,
    required this.retention,
    required this.avgScore,
    required this.responseRate,
  });

  final String label;
  final int users;
  final List<int> retention;
  final double avgScore;
  final double responseRate;

  factory CohortRow.fromJson(Map<String, dynamic> json) {
    final retention = (json['retention'] as List<dynamic>? ?? [])
        .map((value) => int.tryParse(value.toString()) ?? 0)
        .toList();
    return CohortRow(
      label: json['label']?.toString() ?? '',
      users: int.tryParse(json['users']?.toString() ?? '') ?? 0,
      retention: retention,
      avgScore: double.tryParse(json['avgScore']?.toString() ?? '') ?? 0,
      responseRate:
          double.tryParse(json['responseRate']?.toString() ?? '') ?? 0,
    );
  }
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

  factory ServiceTrend.fromJson(Map<String, dynamic> json) {
    return ServiceTrend(
      label: json['label']?.toString() ?? '',
      percentage: double.tryParse(json['percentage']?.toString() ?? '') ?? 0,
      note: json['note']?.toString() ?? '',
    );
  }
}
