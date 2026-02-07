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
  const ServiceTrend({required this.label, required this.percentage});

  final String label;
  final double percentage;

  factory ServiceTrend.fromJson(Map<String, dynamic> json) {
    return ServiceTrend(
      label: json['label']?.toString() ?? '',
      percentage: double.tryParse(json['percentage']?.toString() ?? '') ?? 0,
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.totalTickets,
    required this.openTickets,
    required this.resolvedThisPeriod,
    required this.avgRating,
  });

  final int totalTickets;
  final int openTickets;
  final int resolvedThisPeriod;
  final double avgRating;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalTickets: int.tryParse(json['totalTickets']?.toString() ?? '') ?? 0,
      openTickets: int.tryParse(json['openTickets']?.toString() ?? '') ?? 0,
      resolvedThisPeriod:
          int.tryParse(json['resolvedThisPeriod']?.toString() ?? '') ?? 0,
      avgRating: double.tryParse(json['avgRating']?.toString() ?? '') ?? 0,
    );
  }
}

class ServiceSatisfaction {
  const ServiceSatisfaction({
    required this.categoryId,
    required this.label,
    required this.avgScore,
    required this.responses,
    required this.percentage,
  });

  final String categoryId;
  final String label;
  final double avgScore;
  final int responses;
  final double percentage;

  factory ServiceSatisfaction.fromJson(Map<String, dynamic> json) {
    return ServiceSatisfaction(
      categoryId: json['categoryId']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      avgScore: double.tryParse(json['avgScore']?.toString() ?? '') ?? 0,
      responses: int.tryParse(json['responses']?.toString() ?? '') ?? 0,
      percentage: double.tryParse(json['percentage']?.toString() ?? '') ?? 0,
    );
  }
}

class UsageCohortRow {
  const UsageCohortRow({
    required this.label,
    required this.tickets,
    required this.surveys,
  });

  final String label;
  final int tickets;
  final int surveys;

  factory UsageCohortRow.fromJson(Map<String, dynamic> json) {
    return UsageCohortRow(
      label: json['label']?.toString() ?? '',
      tickets: int.tryParse(json['tickets']?.toString() ?? '') ?? 0,
      surveys: int.tryParse(json['surveys']?.toString() ?? '') ?? 0,
    );
  }
}

class SurveySatisfactionRow {
  const SurveySatisfactionRow({
    required this.question,
    required this.type,
    required this.avgScore,
    required this.responses,
  });

  final String question;
  final String type;
  final double avgScore;
  final int responses;

  factory SurveySatisfactionRow.fromJson(Map<String, dynamic> json) {
    return SurveySatisfactionRow(
      question: json['question']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      avgScore: double.tryParse(json['avgScore']?.toString() ?? '') ?? 0,
      responses: int.tryParse(json['responses']?.toString() ?? '') ?? 0,
    );
  }
}

class SurveySatisfactionReport {
  const SurveySatisfactionReport({
    required this.templateId,
    required this.template,
    required this.categoryId,
    required this.category,
    required this.period,
    required this.start,
    required this.end,
    required this.rows,
  });

  final String templateId;
  final String template;
  final String categoryId;
  final String category;
  final String period;
  final DateTime start;
  final DateTime end;
  final List<SurveySatisfactionRow> rows;

  factory SurveySatisfactionReport.fromJson(Map<String, dynamic> json) {
    final rows = (json['rows'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SurveySatisfactionRow.fromJson)
        .toList();
    return SurveySatisfactionReport(
      templateId: json['templateId']?.toString() ?? '',
      template: json['template']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      period: json['period']?.toString() ?? '',
      start:
          DateTime.tryParse(json['start']?.toString() ?? '') ?? DateTime.now(),
      end: DateTime.tryParse(json['end']?.toString() ?? '') ?? DateTime.now(),
      rows: rows,
    );
  }
}

class EntityServiceRow {
  const EntityServiceRow({
    required this.entity,
    required this.categoryId,
    required this.category,
    required this.tickets,
    required this.surveys,
  });

  final String entity;
  final String categoryId;
  final String category;
  final int tickets;
  final int surveys;

  factory EntityServiceRow.fromJson(Map<String, dynamic> json) {
    return EntityServiceRow(
      entity: json['entity']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      tickets: int.tryParse(json['tickets']?.toString() ?? '') ?? 0,
      surveys: int.tryParse(json['surveys']?.toString() ?? '') ?? 0,
    );
  }
}
