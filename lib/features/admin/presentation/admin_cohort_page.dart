import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/analytics_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/score_utils.dart';
import 'package:unila_helpdesk_frontend/core/widgets/period_dropdown.dart';

class AdminCohortPage extends ConsumerWidget {
  const AdminCohortPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(cohortPeriodProvider);
    final reportAsync = ref.watch(cohortReportProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analisis Cohort',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cohort dibentuk dari survei pertama pengguna. Fokus analisis pada retensi dan tren kepuasan.',
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                PeriodDropdown(
                  value: selectedPeriod,
                  enabled: true,
                  onChanged: (value) {
                    ref.read(cohortPeriodProvider.notifier).state = value;
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            reportAsync.when(
              data: (report) {
                if (report == null || report.overall.isEmpty) {
                  return _SectionCard(
                    title: 'Analisis Belum Tersedia',
                    subtitle:
                        'Belum ada data survei registered yang cukup untuk membentuk cohort pada periode ini.',
                    child: const Text(
                      'Coba gunakan periode lain atau tambahkan data survei.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OverviewSection(report: report),
                    const SizedBox(height: 20),
                    _RetentionHeatmapSection(report: report),
                    const SizedBox(height: 20),
                    _ComparisonSection(
                      title: 'Perbandingan Cohort per Layanan',
                      subtitle:
                          'Kelompok dibandingkan berdasarkan layanan pada survei pertama pengguna.',
                      rows: report.serviceComparisons,
                      bucketLabels: report.bucketLabels,
                      emptyMessage:
                          'Belum ada perbandingan layanan yang dapat ditampilkan.',
                    ),
                    const SizedBox(height: 20),
                    _ComparisonSection(
                      title: 'Perbandingan Cohort per Entitas',
                      subtitle:
                          'Kelompok dibandingkan berdasarkan entitas pengguna pada survei pertama.',
                      rows: report.entityComparisons,
                      bucketLabels: report.bucketLabels,
                      emptyMessage:
                          'Belum ada perbandingan entitas yang dapat ditampilkan.',
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _SectionCard(
                title: 'Gagal Memuat Cohort',
                subtitle: 'Terjadi masalah saat menghitung analisis cohort.',
                child: Text(
                  error.toString(),
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.report});

  final CohortAnalysisReport report;

  @override
  Widget build(BuildContext context) {
    final unitLabel = switch (report.period) {
      'daily' => 'hari',
      'weekly' => 'minggu',
      'yearly' => 'tahun',
      _ => 'bulan',
    };
    final summaryText =
        'Cohort diambil dari ${report.lookbackPeriods} $unitLabel terakhir dengan horizon ${report.bucketCount} bucket. Semua bucket dihitung relatif terhadap survei pertama pengguna.';

    return _SectionCard(
      title: 'Overview Diagnostik',
      subtitle: summaryText,
      child: report.insights.isEmpty
          ? const Text(
              'Belum ada insight diagnostik yang cukup untuk periode ini.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final columns = _overviewColumnCount(constraints.maxWidth);
                final cardWidth =
                    (constraints.maxWidth - (spacing * (columns - 1))) /
                    columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: report.insights
                      .map(
                        (insight) => SizedBox(
                          width: cardWidth,
                          child: _InsightCard(insight: insight),
                        ),
                      )
                      .toList(),
                );
              },
            ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final CohortDiagnosticInsight insight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            insight.value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            insight.detail,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

int _overviewColumnCount(double width) {
  if (width >= 1500) {
    return 5;
  }
  if (width >= 1180) {
    return 4;
  }
  if (width >= 860) {
    return 3;
  }
  if (width >= 560) {
    return 2;
  }
  return 1;
}

class _RetentionHeatmapSection extends StatelessWidget {
  const _RetentionHeatmapSection({required this.report});

  final CohortAnalysisReport report;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Heatmap Retensi Cohort',
      subtitle:
          'Baris menunjukkan cohort berdasarkan survei pertama. Kolom D/W/M/Y menunjukkan umur cohort relatif.',
      child: _HorizontalTableFrame(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F5F7)),
          dataTextStyle: _compactCellStyle,
          headingTextStyle: _compactHeaderStyle,
          columnSpacing: 10,
          horizontalMargin: 10,
          dividerThickness: 0.5,
          headingRowHeight: 36,
          dataRowMinHeight: 42,
          dataRowMaxHeight: 42,
          columns: [
            const DataColumn(
              label: _HeaderLabel(
                'Cohort',
                width: 112,
              ),
            ),
            const DataColumn(
              label: _HeaderLabel(
                'Users',
                width: 52,
              ),
            ),
            ...report.bucketLabels.map(
              (label) => DataColumn(
                label: _HeaderLabel(
                  label,
                  width: 58,
                ),
              ),
            ),
            const DataColumn(
              label: _HeaderLabel(
                'Δ Rating',
                width: 72,
              ),
            ),
          ],
          rows: report.overall.map((row) {
            return DataRow(
              cells: [
                DataCell(_TableCellLabel(row.label, width: 112, alignLeft: true)),
                DataCell(_TableCellLabel(row.users.toString(), width: 52)),
                ...row.buckets.map(
                  (bucket) => DataCell(_RetentionHeatCell(metric: bucket)),
                ),
                DataCell(
                  _TableCellLabel(_formatSignedScore(row.scoreDelta), width: 72),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ComparisonSection extends StatelessWidget {
  const _ComparisonSection({
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.bucketLabels,
    required this.emptyMessage,
  });

  final String title;
  final String subtitle;
  final List<CohortAnalysisRow> rows;
  final List<String> bucketLabels;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      subtitle: subtitle,
      child: rows.isEmpty
          ? Text(
              emptyMessage,
              style: const TextStyle(color: AppTheme.textMuted),
            )
          : _HorizontalTableFrame(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F5F7)),
                dataTextStyle: _compactCellStyle,
                headingTextStyle: _compactHeaderStyle,
                columnSpacing: 10,
                horizontalMargin: 10,
                dividerThickness: 0.5,
                headingRowHeight: 36,
                dataRowMinHeight: 42,
                dataRowMaxHeight: 42,
                columns: [
                  const DataColumn(
                    label: _HeaderLabel(
                      'Kelompok',
                      width: 112,
                    ),
                  ),
                  const DataColumn(
                    label: _HeaderLabel(
                      'Users',
                      width: 52,
                    ),
                  ),
                  ...bucketLabels.map(
                    (label) => DataColumn(
                      label: _HeaderLabel(
                        label,
                        width: 58,
                      ),
                    ),
                  ),
                  const DataColumn(
                    label: _HeaderLabel(
                      'Drop-off',
                      width: 78,
                    ),
                  ),
                  const DataColumn(
                    label: _HeaderLabel(
                      'Δ Rating',
                      width: 72,
                    ),
                  ),
                ],
                rows: rows.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(
                        _TableCellLabel(row.label, width: 112, alignLeft: true),
                      ),
                      DataCell(_TableCellLabel(row.users.toString(), width: 52)),
                      ...row.buckets.map(
                        (bucket) => DataCell(_RetentionHeatCell(metric: bucket)),
                      ),
                      DataCell(
                        _TableCellLabel(_formatDropOff(row.dropOff), width: 78),
                      ),
                      DataCell(
                        _TableCellLabel(
                          _formatSignedScore(row.scoreDelta),
                          width: 72,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }
}

class _HorizontalTableFrame extends StatefulWidget {
  const _HorizontalTableFrame({required this.child});

  final Widget child;

  @override
  State<_HorizontalTableFrame> createState() => _HorizontalTableFrameState();
}

class _HorizontalTableFrameState extends State<_HorizontalTableFrame> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        trackVisibility: true,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _RetentionHeatCell extends StatelessWidget {
  const _RetentionHeatCell({required this.metric});

  final CohortBucketMetric metric;

  @override
  Widget build(BuildContext context) {
    if (metric.retention == null) {
      return const Text(
        '-',
        style: TextStyle(color: AppTheme.textMuted),
      );
    }

    final retention = metric.retention!.clamp(0, 100).toDouble();
    final alpha = (0.15 + (retention / 100 * 0.75)).clamp(0.15, 0.9);
    final textColor =
        alpha > 0.45 ? Colors.white : AppTheme.textPrimary;
    final tooltip = [
      'Retensi: ${retention.toStringAsFixed(1)}%',
      if (metric.activeUsers != null && metric.eligibleUsers != null)
        'Aktif: ${metric.activeUsers}/${metric.eligibleUsers}',
      if (metric.avgScore != null)
        'Skor: ${formatScoreFive(metric.avgScore)}',
    ].join('\n');

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 58,
        height: 30,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.navy.withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${retention.toStringAsFixed(0)}%',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.text, {required this.width});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: _compactHeaderStyle,
        ),
      ),
    );
  }
}

class _TableCellLabel extends StatelessWidget {
  const _TableCellLabel(
    this.text, {
    required this.width,
    this.alignLeft = false,
  });

  final String text;
  final double width;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
        child: Text(
          text,
          textAlign: alignLeft ? TextAlign.left : TextAlign.center,
          style: _compactCellStyle,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

String _formatDropOff(double? value) {
  if (value == null) {
    return '-';
  }
  return '${value.toStringAsFixed(1)} poin';
}

String _formatSignedScore(double? value) {
  if (value == null) {
    return '-';
  }
  if (value > 0) {
    return '+${value.toStringAsFixed(2)}';
  }
  return value.toStringAsFixed(2);
}

const TextStyle _compactHeaderStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.2,
  color: AppTheme.textMuted,
);

const TextStyle _compactCellStyle = TextStyle(
  fontSize: 13,
  color: AppTheme.textPrimary,
);
