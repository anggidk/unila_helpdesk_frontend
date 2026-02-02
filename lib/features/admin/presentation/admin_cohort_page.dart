import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';

class AdminCohortPage extends ConsumerWidget {
  const AdminCohortPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cohortRowsAsync = ref.watch(cohortRowsProvider);
    final cohortRows = cohortRowsAsync.value ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DropdownButton(label: 'Analisis', value: 'Retention'),
              const SizedBox(width: 12),
              _DropdownButton(label: 'Periode', value: 'Bulanan'),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text('Export'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (cohortRowsAsync.isLoading)
            const Center(child: CircularProgressIndicator()),
          if (cohortRowsAsync.hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Gagal memuat cohort: ${cohortRowsAsync.error}',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outline),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.surface),
              columns: const [
                DataColumn(label: Text('Cohort')),
                DataColumn(label: Text('Users')),
                DataColumn(label: Text('M0')),
                DataColumn(label: Text('M1')),
                DataColumn(label: Text('M2')),
                DataColumn(label: Text('M3')),
                DataColumn(label: Text('M4')),
              ],
              rows: cohortRows.map((row) {
                return DataRow(
                  cells: [
                    DataCell(Text(row.label)),
                    DataCell(Text(row.users.toString())),
                    ...List.generate(5, (index) {
                      final value = row.retention[index];
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
                const Text('Satisfaction Score by Cohort', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (cohortRows.isEmpty)
                  const Text('Belum ada data survey.', style: TextStyle(color: AppTheme.textMuted))
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
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DropdownButton extends StatelessWidget {
  const _DropdownButton({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.expand_more, size: 18),
      label: Text('$label: $value'),
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
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Expanded(child: Text('Avg Score: ${score.toStringAsFixed(2)}')),
          Expanded(child: Text('Response: ${responseRate.toStringAsFixed(0)}%')),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Icon(Icons.star, color: AppTheme.accentYellow, size: 18),
                Icon(Icons.star, color: AppTheme.accentYellow, size: 18),
                Icon(Icons.star, color: AppTheme.accentYellow, size: 18),
                Icon(Icons.star_half, color: AppTheme.accentYellow, size: 18),
                Icon(Icons.star_border, color: AppTheme.textMuted, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

