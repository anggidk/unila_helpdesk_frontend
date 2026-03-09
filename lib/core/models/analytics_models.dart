class CohortBucketMetric {
  const CohortBucketMetric({
    required this.eligibleUsers,
    required this.activeUsers,
    required this.retention,
    required this.avgScore,
  });

  final int? eligibleUsers;
  final int? activeUsers;
  final double? retention;
  final double? avgScore;

  factory CohortBucketMetric.fromJson(Map<String, dynamic> json) {
    return CohortBucketMetric(
      eligibleUsers: int.tryParse(json['eligibleUsers']?.toString() ?? ''),
      activeUsers: int.tryParse(json['activeUsers']?.toString() ?? ''),
      retention: double.tryParse(json['retention']?.toString() ?? ''),
      avgScore: double.tryParse(json['avgScore']?.toString() ?? ''),
    );
  }
}

class CohortAnalysisRow {
  const CohortAnalysisRow({
    required this.label,
    required this.users,
    required this.buckets,
    required this.dropOff,
    required this.scoreDelta,
  });

  final String label;
  final int users;
  final List<CohortBucketMetric> buckets;
  final double? dropOff;
  final double? scoreDelta;

  factory CohortAnalysisRow.fromJson(Map<String, dynamic> json) {
    final buckets = (json['buckets'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CohortBucketMetric.fromJson)
        .toList();
    return CohortAnalysisRow(
      label: json['label']?.toString() ?? '',
      users: int.tryParse(json['users']?.toString() ?? '') ?? 0,
      buckets: buckets,
      dropOff: double.tryParse(json['dropOff']?.toString() ?? ''),
      scoreDelta: double.tryParse(json['scoreDelta']?.toString() ?? ''),
    );
  }
}

class CohortDiagnosticInsight {
  const CohortDiagnosticInsight({
    required this.title,
    required this.detail,
    required this.value,
  });

  final String title;
  final String detail;
  final String value;

  factory CohortDiagnosticInsight.fromJson(Map<String, dynamic> json) {
    return CohortDiagnosticInsight(
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }
}

class CohortAnalysisReport {
  const CohortAnalysisReport({
    required this.period,
    required this.lookbackPeriods,
    required this.bucketCount,
    required this.start,
    required this.end,
    required this.bucketLabels,
    required this.satisfactionOverview,
    required this.overall,
    required this.serviceComparisons,
    required this.entityComparisons,
    required this.insights,
  });

  final String period;
  final int lookbackPeriods;
  final int bucketCount;
  final DateTime start;
  final DateTime end;
  final List<String> bucketLabels;
  final SatisfactionOverviewReport? satisfactionOverview;
  final List<CohortAnalysisRow> overall;
  final List<CohortAnalysisRow> serviceComparisons;
  final List<CohortAnalysisRow> entityComparisons;
  final List<CohortDiagnosticInsight> insights;

  factory CohortAnalysisReport.fromJson(Map<String, dynamic> json) {
    final bucketLabels = (json['bucketLabels'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .toList();
    final overall = (json['overall'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CohortAnalysisRow.fromJson)
        .toList();
    final serviceComparisons =
        (json['serviceComparisons'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CohortAnalysisRow.fromJson)
            .toList();
    final entityComparisons = (json['entityComparisons'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CohortAnalysisRow.fromJson)
        .toList();
    final insights = (json['insights'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CohortDiagnosticInsight.fromJson)
        .toList();

    return CohortAnalysisReport(
      period: json['period']?.toString() ?? '',
      lookbackPeriods:
          int.tryParse(json['lookbackPeriods']?.toString() ?? '') ?? 0,
      bucketCount: int.tryParse(json['bucketCount']?.toString() ?? '') ?? 0,
      start:
          DateTime.tryParse(json['start']?.toString() ?? '') ?? DateTime.now(),
      end: DateTime.tryParse(json['end']?.toString() ?? '') ?? DateTime.now(),
      bucketLabels: bucketLabels,
      satisfactionOverview: json['satisfactionOverview']
              is Map<String, dynamic>
          ? SatisfactionOverviewReport.fromJson(
              json['satisfactionOverview'] as Map<String, dynamic>,
            )
          : null,
      overall: overall,
      serviceComparisons: serviceComparisons,
      entityComparisons: entityComparisons,
      insights: insights,
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

class SatisfactionOverviewItem {
  const SatisfactionOverviewItem({
    required this.label,
    required this.avgScore,
    required this.responses,
  });

  final String label;
  final double avgScore;
  final int responses;

  factory SatisfactionOverviewItem.fromJson(Map<String, dynamic> json) {
    return SatisfactionOverviewItem(
      label: json['label']?.toString() ?? '',
      avgScore: double.tryParse(json['avgScore']?.toString() ?? '') ?? 0,
      responses: int.tryParse(json['responses']?.toString() ?? '') ?? 0,
    );
  }
}

class SatisfactionEntityPreference {
  const SatisfactionEntityPreference({
    required this.entity,
    required this.category,
    required this.responses,
    required this.share,
  });

  final String entity;
  final String category;
  final int responses;
  final double share;

  factory SatisfactionEntityPreference.fromJson(Map<String, dynamic> json) {
    return SatisfactionEntityPreference(
      entity: json['entity']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      responses: int.tryParse(json['responses']?.toString() ?? '') ?? 0,
      share: double.tryParse(json['share']?.toString() ?? '') ?? 0,
    );
  }
}

class SatisfactionOverviewReport {
  const SatisfactionOverviewReport({
    required this.period,
    required this.start,
    required this.end,
    required this.categoryHighest,
    required this.categoryLowest,
    required this.entityHighest,
    required this.entityLowest,
    required this.entityPreferences,
  });

  final String period;
  final DateTime start;
  final DateTime end;
  final SatisfactionOverviewItem? categoryHighest;
  final SatisfactionOverviewItem? categoryLowest;
  final SatisfactionOverviewItem? entityHighest;
  final SatisfactionOverviewItem? entityLowest;
  final List<SatisfactionEntityPreference> entityPreferences;

  factory SatisfactionOverviewReport.fromJson(Map<String, dynamic> json) {
    SatisfactionOverviewItem? readItem(String key) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return SatisfactionOverviewItem.fromJson(value);
      }
      return null;
    }

    return SatisfactionOverviewReport(
      period: json['period']?.toString() ?? '',
      start:
          DateTime.tryParse(json['start']?.toString() ?? '') ?? DateTime.now(),
      end: DateTime.tryParse(json['end']?.toString() ?? '') ?? DateTime.now(),
      categoryHighest: readItem('categoryHighest'),
      categoryLowest: readItem('categoryLowest'),
      entityHighest: readItem('entityHighest'),
      entityLowest: readItem('entityLowest'),
      entityPreferences: (json['entityPreferences'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SatisfactionEntityPreference.fromJson)
          .toList(),
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
