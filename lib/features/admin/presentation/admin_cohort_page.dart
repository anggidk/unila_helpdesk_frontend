import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/analytics_models.dart';

class AdminCohortPage extends ConsumerWidget {
  const AdminCohortPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(cohortPeriodProvider);
    final analysis = ref.watch(cohortAnalysisProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AnalysisDropdown(
                value: analysis,
                onChanged: (value) {
                  ref.read(cohortAnalysisProvider.notifier).state = value;
                },
              ),
              const SizedBox(width: 12),
              _PeriodDropdown(
                value: selectedPeriod,
                enabled: true,
                onChanged: (value) {
                  ref.read(cohortPeriodProvider.notifier).state = value;
                },
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 20),
          if (analysis == 'retention')
            _CenteredSection(child: _RetentionSection(period: selectedPeriod)),
          if (analysis == 'usage') _CenteredSection(child: _UsageSection()),
          if (analysis == 'service')
            _CenteredSection(child: _ServiceUtilSection()),
          if (analysis == 'entity-service')
            _CenteredSection(child: _EntityServiceSection()),
        ],
      ),
    );
  }
}

class _RetentionCell extends StatelessWidget {
  const _RetentionCell({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final colorStrength = (value / 100).clamp(0.1, 0.9).toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.navy.withValues(alpha: colorStrength),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value%',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AnalysisDropdown extends StatelessWidget {
  const _AnalysisDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'retention', child: Text('Retention Cohort')),
        PopupMenuItem(value: 'usage', child: Text('Time-based Usage')),
        PopupMenuItem(value: 'service', child: Text('Service Utilization')),
        PopupMenuItem(
          value: 'entity-service',
          child: Text('User Group x Service'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.expand_more, size: 18),
            const SizedBox(width: 6),
            Text('Analisis: ${_analysisLabel(value)}'),
          ],
        ),
      ),
    );
  }
}

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: enabled ? onChanged : null,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'daily', child: Text('Harian')),
        PopupMenuItem(value: 'weekly', child: Text('Mingguan')),
        PopupMenuItem(value: 'monthly', child: Text('Bulanan')),
        PopupMenuItem(value: 'yearly', child: Text('Tahunan')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled
                ? AppTheme.outline
                : AppTheme.outline.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.expand_more,
              size: 18,
              color: enabled ? AppTheme.textPrimary : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              'Periode: ${_periodLabel(value)}',
              style: TextStyle(
                color: enabled ? AppTheme.textPrimary : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CohortScoreRow extends StatelessWidget {
  const _CohortScoreRow({
    required this.label,
    required this.score,
    required this.responseRate,
  });

  final String label;
  final double score;
  final double responseRate;

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 5);
    final fullStars = clamped.floor();
    final hasHalf = (clamped - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalf ? 1 : 0);
    final stars = <Widget>[];
    for (var i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, color: AppTheme.accentYellow, size: 18));
    }
    if (hasHalf) {
      stars.add(
        const Icon(Icons.star_half, color: AppTheme.accentYellow, size: 18),
      );
    }
    for (var i = 0; i < emptyStars; i++) {
      stars.add(
        const Icon(Icons.star_border, color: AppTheme.textMuted, size: 18),
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Expanded(child: Text('Avg Score: ${clamped.toStringAsFixed(2)}')),
          Expanded(
            child: Text('Response: ${responseRate.toStringAsFixed(0)}%'),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: stars,
            ),
          ),
        ],
      ),
    );
  }
}

class _DualBarData {
  const _DualBarData({
    required this.label,
    required this.primary,
    required this.secondary,
  });

  final String label;
  final int primary;
  final int secondary;
}


class _VerticalDualBarChart extends StatelessWidget {
  const _VerticalDualBarChart({
    required this.rows,
    required this.primaryLabel,
    required this.secondaryLabel,
  });

  final List<_DualBarData> rows;
  final String primaryLabel;
  final String secondaryLabel;

  @override
  Widget build(BuildContext context) {
    final maxValue = rows.fold<int>(
      1,
      (value, row) => _max(value, _max(row.primary, row.secondary)),
    );
    const chartHeight = 160.0;
    return Column(
      children: [
        _LegendRow(primaryLabel: primaryLabel, secondaryLabel: secondaryLabel),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: rows
                .map(
                  (row) => _VerticalBarGroup(
                    label: row.label,
                    primary: row.primary,
                    secondary: row.secondary,
                    maxValue: maxValue,
                    height: chartHeight,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _VerticalBarGroup extends StatelessWidget {
  const _VerticalBarGroup({
    required this.label,
    required this.primary,
    required this.secondary,
    required this.maxValue,
    required this.height,
  });

  final String label;
  final int primary;
  final int secondary;
  final int maxValue;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ColumnBar(
                  value: primary,
                  maxValue: maxValue,
                  color: AppTheme.navy,
                ),
                const SizedBox(width: 6),
                _ColumnBar(
                  value: secondary,
                  maxValue: maxValue,
                  color: AppTheme.accentYellow,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnBar extends StatelessWidget {
  const _ColumnBar({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0 ? 0 : value / maxValue;
    final barHeight = (ratio * 140).clamp(4.0, 140.0).toDouble();
    return SizedBox(
      width: 22,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 4),
          Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend({required this.maxValue});

  final int maxValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Rendah', style: TextStyle(color: AppTheme.textMuted)),
        const SizedBox(width: 8),
        Container(
          width: 160,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                AppTheme.navy.withValues(alpha: 0.15),
                AppTheme.navy.withValues(alpha: 0.9),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Tinggi (max $maxValue)',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
      ],
    );
  }
}

class _HeatmapTable extends StatelessWidget {
  const _HeatmapTable({
    required this.entities,
    required this.categories,
    required this.matrix,
    required this.maxValue,
  });

  final List<String> entities;
  final List<String> categories;
  final Map<String, Map<String, int>> matrix;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Align(
        alignment: Alignment.center,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.surface),
          columns: [
            const DataColumn(label: Text('Entitas')),
            ...categories.map((category) => DataColumn(label: Text(category))),
          ],
          rows: entities.map((entity) {
            final row = matrix[entity] ?? const <String, int>{};
            return DataRow(
              cells: [
                DataCell(Text(entity)),
                ...categories.map((category) {
                  final value = row[category] ?? 0;
                  return DataCell(
                    _HeatmapCell(value: value, maxValue: maxValue),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({required this.value, required this.maxValue});

  final int value;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0 ? 0 : (value / maxValue);
    final alpha = (0.15 + (0.75 * ratio)).clamp(0.15, 0.9);
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.navy.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value.toString(),
        style: TextStyle(
          color: alpha > 0.45 ? Colors.white : AppTheme.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Map<String, Map<String, int>> _buildEntityServiceMatrix(
  List<EntityServiceRow> rows,
) {
  final matrix = <String, Map<String, int>>{};
  for (final row in rows) {
    matrix.putIfAbsent(row.entity, () => <String, int>{});
    matrix[row.entity]![row.category] = row.tickets;
  }
  return matrix;
}

List<String> _sortedEntities(List<EntityServiceRow> rows) {
  final set = <String>{};
  for (final row in rows) {
    set.add(row.entity);
  }
  final list = set.toList()..sort();
  return list;
}

List<String> _sortedCategories(List<EntityServiceRow> rows) {
  final set = <String>{};
  for (final row in rows) {
    set.add(row.category);
  }
  final list = set.toList()..sort();
  return list;
}

int _maxMatrixValue(Map<String, Map<String, int>> matrix) {
  var maxValue = 0;
  for (final row in matrix.values) {
    for (final value in row.values) {
      if (value > maxValue) {
        maxValue = value;
      }
    }
  }
  return maxValue == 0 ? 1 : maxValue;
}

class _CenteredSection extends StatelessWidget {
  const _CenteredSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: child,
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.primaryLabel, required this.secondaryLabel});

  final String primaryLabel;
  final String secondaryLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendItem(label: primaryLabel, color: AppTheme.navy),
        const SizedBox(width: 12),
        _LegendItem(label: secondaryLabel, color: AppTheme.accentYellow),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppTheme.textMuted)),
      ],
    );
  }
}


int _max(int a, int b) => a > b ? a : b;

List<String> _retentionLabels(String period, int? length) {
  final count = length ?? 5;
  switch (period) {
    case 'daily':
      return List<String>.generate(count, (index) => 'D$index');
    case 'weekly':
      return List<String>.generate(count, (index) => 'W$index');
    case 'yearly':
      return List<String>.generate(count, (index) => 'Y$index');
    default:
      return List<String>.generate(count, (index) => 'M$index');
  }
}

String _periodLabel(String period) {
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

String _analysisLabel(String value) {
  switch (value) {
    case 'usage':
      return 'Time-based Usage';
    case 'service':
      return 'Service Utilization';
    case 'entity-service':
      return 'User Group x Service';
    default:
      return 'Retention Cohort';
  }
}

class _RetentionSection extends ConsumerWidget {
  const _RetentionSection({required this.period});

  final String period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cohortRowsAsync = ref.watch(cohortRowsProvider);
    final cohortRows = cohortRowsAsync.value ?? [];
    final retentionLabels = _retentionLabels(
      period,
      cohortRows.isNotEmpty ? cohortRows.first.retention.length : null,
    );
    if (cohortRowsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (cohortRowsAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          'Gagal memuat cohort: ${cohortRowsAsync.error}',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outline),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.surface),
            columns: [
              const DataColumn(label: Text('Cohort')),
              const DataColumn(label: Text('Users')),
              ...retentionLabels.map((label) => DataColumn(label: Text(label))),
            ],
            rows: cohortRows.map((row) {
              final retention = row.retention;
              return DataRow(
                cells: [
                  DataCell(Text(row.label)),
                  DataCell(Text(row.users.toString())),
                  ...List.generate(retention.length, (index) {
                    final value = retention[index];
                    return DataCell(_RetentionCell(value: value));
                  }),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Satisfaction Score by Cohort',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (cohortRows.isEmpty)
                const Text(
                  'Belum ada data survey.',
                  style: TextStyle(color: AppTheme.textMuted),
                )
              else
                ...cohortRows.map(
                  (row) => _CohortScoreRow(
                    label: row.label,
                    score: row.avgScore,
                    responseRate: row.responseRate,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UsageSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(usageCohortProvider);
    final usageRows = usageAsync.value ?? [];
    if (usageAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (usageAsync.hasError) {
      return Text(
        'Gagal memuat usage cohort: ${usageAsync.error}',
        style: const TextStyle(color: AppTheme.textMuted),
      );
    }
    if (usageRows.isEmpty) {
      return const Text(
        'Belum ada data usage.',
        style: TextStyle(color: AppTheme.textMuted),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time-based Usage Cohort',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Jumlah tiket & survey per periode.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          _VerticalDualBarChart(
            rows: usageRows
                .map(
                  (row) => _DualBarData(
                    label: row.label,
                    primary: row.tickets,
                    secondary: row.surveys,
                  ),
                )
                .toList(),
            primaryLabel: 'Tiket',
            secondaryLabel: 'Survey',
          ),
        ],
      ),
    );
  }
}

class _ServiceUtilSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceUtilAsync = ref.watch(serviceUtilizationProvider);
    final serviceUtilRows = serviceUtilAsync.value ?? [];
    if (serviceUtilAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (serviceUtilAsync.hasError) {
      return Text(
        'Gagal memuat service utilization: ${serviceUtilAsync.error}',
        style: const TextStyle(color: AppTheme.textMuted),
      );
    }
    if (serviceUtilRows.isEmpty) {
      return const Text(
        'Belum ada data layanan.',
        style: TextStyle(color: AppTheme.textMuted),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Utilization Cohort',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'First ticket vs first survey per layanan.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          _VerticalDualBarChart(
            rows: serviceUtilRows
                .map(
                  (row) => _DualBarData(
                    label: row.category,
                    primary: row.firstTicketUsers,
                    secondary: row.firstSurveyUsers,
                  ),
                )
                .toList(),
            primaryLabel: 'First Ticket',
            secondaryLabel: 'First Survey',
          ),
        ],
      ),
    );
  }
}

class _EntityServiceSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entityServiceAsync = ref.watch(entityServiceProvider);
    final entityServiceRows = entityServiceAsync.value ?? [];
    if (entityServiceAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (entityServiceAsync.hasError) {
      return Text(
        'Gagal memuat user group x service: ${entityServiceAsync.error}',
        style: const TextStyle(color: AppTheme.textMuted),
      );
    }
    if (entityServiceRows.isEmpty) {
      return const Text(
        'Belum ada data user group.',
        style: TextStyle(color: AppTheme.textMuted),
      );
    }
    final categories = _sortedCategories(entityServiceRows);
    final entities = _sortedEntities(entityServiceRows);
    final matrix = _buildEntityServiceMatrix(entityServiceRows);
    final maxValue = _maxMatrixValue(matrix);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Group x Service',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Heatmap penggunaan tiket per entitas & layanan.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: _HeatmapLegend(maxValue: maxValue),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: _HeatmapTable(
              entities: entities,
              categories: categories,
              matrix: matrix,
              maxValue: maxValue,
            ),
          ),
        ],
      ),
    );
  }
}
