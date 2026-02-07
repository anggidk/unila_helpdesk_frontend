import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/analytics_models.dart';
import 'package:unila_helpdesk_frontend/core/widgets/charts/line_chart.dart';

List<LineSeries> buildUsageLineSeries(List<UsageCohortRow> rows) {
  return [
    LineSeries(
      label: 'Tiket',
      color: AppTheme.navy,
      values: rows.map((row) => row.tickets).toList(),
    ),
    LineSeries(
      label: 'Survei',
      color: AppTheme.accentYellow,
      values: rows.map((row) => row.surveys).toList(),
    ),
  ];
}
