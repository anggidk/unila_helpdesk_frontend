import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/analytics_models.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/csv_exporter.dart';
import 'package:unila_helpdesk_frontend/core/utils/period_utils.dart';
import 'package:unila_helpdesk_frontend/core/utils/score_utils.dart';
import 'package:unila_helpdesk_frontend/core/widgets/period_dropdown.dart';
import 'package:unila_helpdesk_frontend/features/admin/data/report_repository.dart';

class AdminReportsPage extends ConsumerStatefulWidget {
  const AdminReportsPage({super.key});

  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  String? _lastCategoryId;

  Future<void> _exportSurveyCsv({
    required BuildContext context,
    required String period,
    required String? categoryId,
    required String? templateId,
  }) async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export CSV hanya tersedia di web.')),
      );
      return;
    }
    if (categoryId == null || categoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu.')),
      );
      return;
    }
    final periods = reportPeriodsFor(period);
    try {
      final csv = await ReportRepository().exportSurveySatisfactionCsv(
        categoryId: categoryId,
        templateId: templateId,
        period: period,
        periods: periods,
      );
      final filename = 'survey_${categoryId}_$period.csv';
      await downloadCsv(filename: filename, content: csv);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Export CSV berhasil.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal export: $error')));
    }
  }

  void _syncCategory(List<ServiceCategory> categories) {
    final filtered = categories
        .where((category) => !category.guestAllowed)
        .toList();
    if (filtered.isEmpty) {
      return;
    }
    final selected = ref.read(reportsCategoryIdProvider);
    if (selected == null || !filtered.any((item) => item.id == selected)) {
      ref.read(reportsCategoryIdProvider.notifier).state = filtered.first.id;
    }
  }

  void _syncTemplateFromCategory(ServiceCategory? category) {
    final templateId = category?.surveyTemplateId;
    ref.read(reportsTemplateIdProvider.notifier).state =
        (templateId == null || templateId.isEmpty) ? null : templateId;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<ServiceCategory>>>(reportsCategoriesProvider, (
      _,
      next,
    ) {
      final list = next.value ?? [];
      _syncCategory(list);
    });
    ref.listen<String?>(reportsCategoryIdProvider, (_, next) {
      final categories = ref.read(reportsCategoriesProvider).value ?? [];
      final selected = categories.where((item) => item.id == next).toList();
      if (next != null && next != _lastCategoryId) {
        _lastCategoryId = next;
        _syncTemplateFromCategory(selected.isNotEmpty ? selected.first : null);
      }
    });

    final period = ref.watch(reportsPeriodProvider);
    final indexPeriod = ref.watch(reportsSatisfactionIndexPeriodProvider);
    final satisfactionSummaryAsync = ref.watch(
      reportsSatisfactionSummaryProvider,
    );
    final satisfactionAsync = ref.watch(surveySatisfactionProvider);
    final categoriesAsync = ref.watch(reportsCategoriesProvider);
    final templatesAsync = ref.watch(reportsTemplatesProvider);
    final selectedCategoryId = ref.watch(reportsCategoryIdProvider);
    final selectedTemplateId = ref.watch(reportsTemplateIdProvider);

    final categories = categoriesAsync.value ?? [];
    final templates = templatesAsync.value ?? [];
    final hasSelected =
        selectedTemplateId != null &&
        templates.any((template) => template.id == selectedTemplateId);
    if (!hasSelected && templates.isEmpty && selectedTemplateId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(reportsTemplateIdProvider.notifier).state = null;
      });
    }
    if (!hasSelected && templates.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(reportsTemplateIdProvider.notifier).state = templates.first.id;
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SelectDropdown(
                label: 'Kategori',
                value: selectedCategoryId,
                enabled: categories.isNotEmpty,
                options: {
                  for (final category in categories) category.id: category.name,
                },
                onChanged: (value) {
                  ref.read(reportsCategoryIdProvider.notifier).state = value;
                },
              ),
              const SizedBox(width: 12),
              _SelectDropdown(
                label: 'Template',
                value: selectedTemplateId,
                enabled: templates.isNotEmpty,
                options: {
                  for (final template in templates) template.id: template.title,
                },
                onChanged: (value) {
                  ref.read(reportsTemplateIdProvider.notifier).state = value;
                },
              ),
              const SizedBox(width: 12),
              PeriodDropdown(
                value: period,
                onChanged: (value) {
                  ref.read(reportsPeriodProvider.notifier).state = value;
                },
              ),
              const Spacer(),
            ],
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
                Row(
                  children: [
                    const Text(
                      'Hasil Kepuasan Survei',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: kIsWeb
                          ? () => _exportSurveyCsv(
                              context: context,
                              period: period,
                              categoryId: selectedCategoryId,
                              templateId: selectedTemplateId,
                            )
                          : null,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Export CSV'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Filter berdasarkan kategori, template, dan periode.',
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 12),
                satisfactionAsync.when(
                  data: (report) {
                    if (report == null || report.rows.isEmpty) {
                      return const Text(
                        'Belum ada data survei.',
                        style: TextStyle(color: AppTheme.textMuted),
                      );
                    }
                    return _SatisfactionTable(report: report);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text(
                    'Gagal memuat hasil survei: $error',
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          satisfactionSummaryAsync.when(
            data: (rows) {
              if (rows.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: const Text(
                    'Belum ada data kepuasan per kategori.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                );
              }
              return _SatisfactionIndexSection(
                rows: rows,
                period: indexPeriod,
                onPeriodChanged: (value) {
                  ref
                          .read(
                            reportsSatisfactionIndexPeriodProvider.notifier,
                          )
                          .state =
                      value;
                },
              );
            },
            loading: () => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outline),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Text(
                'Gagal memuat indeks kepuasan: $error',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SatisfactionIndexSection extends StatelessWidget {
  const _SatisfactionIndexSection({
    required this.rows,
    required this.period,
    required this.onPeriodChanged,
  });

  final List<ServiceSatisfaction> rows;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final summary = _SatisfactionIndexSummary.fromRows(rows);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 980;
        final sharedHeight = _satisfactionIndexPanelHeight(rows.length);

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SatisfactionIndexOverviewCard(summary: summary),
              const SizedBox(height: 16),
              _SatisfactionIndexTableCard(
                rows: rows,
                period: period,
                onPeriodChanged: onPeriodChanged,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 250,
              height: sharedHeight,
              child: _SatisfactionIndexOverviewCard(
                summary: summary,
                fillHeight: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: sharedHeight,
                child: _SatisfactionIndexTableCard(
                  rows: rows,
                  period: period,
                  onPeriodChanged: onPeriodChanged,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SatisfactionIndexTable extends StatelessWidget {
  const _SatisfactionIndexTable({required this.rows});

  final List<ServiceSatisfaction> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.surface),
            headingRowHeight: _satisfactionIndexHeadingRowHeight,
            dataRowMinHeight: _satisfactionIndexDataRowHeight,
            dataRowMaxHeight: _satisfactionIndexDataRowHeight,
            columns: const [
              DataColumn(
                label: _ReportHeaderLabel('Kategori Layanan', width: 220),
              ),
              DataColumn(label: _ReportHeaderLabel('Respon', width: 80)),
              DataColumn(
                label: _ReportHeaderLabel('Nilai Kepuasan', width: 120),
              ),
              DataColumn(label: _ReportHeaderLabel('Indeks (100)', width: 120)),
            ],
            rows: [
              ...rows.map(
                (row) => DataRow(
                  cells: [
                    DataCell(
                      _ReportCellLabel(row.label, width: 220, alignLeft: true),
                    ),
                    DataCell(
                      _ReportCellLabel(row.responses.toString(), width: 80),
                    ),
                    DataCell(
                      _ReportCellLabel(
                        formatScoreFive(row.avgScore),
                        width: 120,
                      ),
                    ),
                    DataCell(
                      _ReportCellLabel(
                        _formatIndex(_reportIndexTo100(row.avgScore)),
                        width: 120,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SatisfactionIndexOverviewCard extends StatelessWidget {
  const _SatisfactionIndexOverviewCard({
    required this.summary,
    this.fillHeight = false,
  });

  final _SatisfactionIndexSummary summary;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ringkasan Indeks Global',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          if (fillHeight) const Spacer() else const SizedBox(height: 18),
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 128,
                  height: 128,
                  child: CircularProgressIndicator(
                    value: summary.index / 100,
                    strokeWidth: 9,
                    backgroundColor: AppTheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      summary.statusColor,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      summary.indexLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.qualityLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: summary.statusColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (fillHeight) const Spacer() else const SizedBox(height: 14),
          Text(
            summary.caption,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (fillHeight) const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _SatisfactionIndexTableCard extends StatelessWidget {
  const _SatisfactionIndexTableCard({
    required this.rows,
    required this.period,
    required this.onPeriodChanged,
  });

  final List<ServiceSatisfaction> rows;
  final String period;
  final ValueChanged<String> onPeriodChanged;

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
          Row(
            children: [
              const Text(
                'Evaluasi Berdasarkan Kategori',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              PeriodDropdown(
                value: period,
                onChanged: onPeriodChanged,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Nilai kepuasan tiap kategori dinormalisasi ke skala 100.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          _SatisfactionIndexTable(rows: rows),
        ],
      ),
    );
  }
}

class _SatisfactionIndexSummary {
  const _SatisfactionIndexSummary({
    required this.index,
    required this.responses,
  });

  final double index;
  final int responses;

  String get indexLabel => index.toStringAsFixed(2);

  String get serviceGrade {
    if (index >= 88.31) {
      return 'A';
    }
    if (index >= 76.61) {
      return 'B';
    }
    if (index >= 65.00) {
      return 'C';
    }
    return 'D';
  }

  String get qualityLabel {
    if (index >= 88.31) {
      return 'SANGAT BAIK';
    }
    if (index >= 76.61) {
      return 'BAIK';
    }
    if (index >= 65.00) {
      return 'KURANG BAIK';
    }
    return 'TIDAK BAIK';
  }

  Color get statusColor {
    if (index >= 88.31) {
      return AppTheme.success;
    }
    if (index >= 76.61) {
      return AppTheme.navy;
    }
    if (index >= 65.00) {
      return AppTheme.warning;
    }
    return AppTheme.danger;
  }

  String get caption {
    return 'Indeks ini menunjukkan mutu pelayanan $serviceGrade dengan kategori $qualityLabel.\nTotal responden: $responses.';
  }

  factory _SatisfactionIndexSummary.fromRows(List<ServiceSatisfaction> rows) {
    final totalResponses = rows.fold<int>(0, (sum, row) => sum + row.responses);
    final totalWeightedScore = rows.fold<double>(
      0,
      (sum, row) => sum + (row.avgScore * row.responses),
    );
    final totalAverage = totalResponses == 0
        ? 0.0
        : totalWeightedScore / totalResponses;
    return _SatisfactionIndexSummary(
      index: _reportIndexTo100(totalAverage),
      responses: totalResponses,
    );
  }
}

const double _satisfactionIndexHeadingRowHeight = 52.0;
const double _satisfactionIndexDataRowHeight = 48.0;
const double _satisfactionIndexCardVerticalPadding = 32.0;
const double _satisfactionIndexCardHeaderHeight = 36.0;
const double _satisfactionIndexCardDescriptionHeight = 20.0;
const double _satisfactionIndexCardSpacing = 20.0;
const double _satisfactionIndexCardSafetyBuffer = 12.0;

double _satisfactionIndexPanelHeight(int rowCount) {
  return _satisfactionIndexCardVerticalPadding +
      _satisfactionIndexCardHeaderHeight +
      _satisfactionIndexCardDescriptionHeight +
      _satisfactionIndexCardSpacing +
      _satisfactionIndexHeadingRowHeight +
      (rowCount * _satisfactionIndexDataRowHeight) +
      _satisfactionIndexCardSafetyBuffer;
}

class _SelectDropdown extends StatelessWidget {
  const _SelectDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.enabled,
  });

  final String label;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = value != null ? options[value] ?? '-' : '-';
    return PopupMenuButton<String>(
      onSelected: enabled ? onChanged : null,
      itemBuilder: (context) => options.entries
          .map(
            (entry) => PopupMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
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
              '$label: $selectedLabel',
              style: TextStyle(
                color: enabled ? AppTheme.textPrimary : AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SatisfactionTable extends StatelessWidget {
  const _SatisfactionTable({required this.report});

  final SurveySatisfactionReport report;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.surface),
            columns: const [
              DataColumn(label: _ReportHeaderLabel('Pertanyaan', width: 360)),
              DataColumn(label: _ReportHeaderLabel('Tipe', width: 100)),
              DataColumn(label: _ReportHeaderLabel('Skor (AVG)', width: 100)),
              DataColumn(label: _ReportHeaderLabel('Respon', width: 80)),
            ],
            rows: report.rows.map((row) {
              final supportsScore =
                  row.type != 'text' && row.type != 'multipleChoice';
              final avgText = !supportsScore || row.responses == 0
                  ? '-'
                  : formatScoreFive(row.avgScore);
              return DataRow(
                cells: [
                  DataCell(
                    _ReportCellLabel(
                      row.question,
                      width: 360,
                      alignLeft: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    _ReportCellLabel(_questionTypeLabel(row.type), width: 100),
                  ),
                  DataCell(_ReportCellLabel(avgText, width: 100)),
                  DataCell(
                    _ReportCellLabel(row.responses.toString(), width: 80),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ReportHeaderLabel extends StatelessWidget {
  const _ReportHeaderLabel(this.text, {required this.width});

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
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ReportCellLabel extends StatelessWidget {
  const _ReportCellLabel(
    this.text, {
    required this.width,
    this.alignLeft = false,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final double width;
  final bool alignLeft;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
        child: Text(
          text,
          textAlign: alignLeft ? TextAlign.left : TextAlign.center,
          maxLines: maxLines,
          overflow: overflow,
          style: const TextStyle(fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}

String _questionTypeLabel(String type) {
  switch (type) {
    case 'yesNo':
      return 'Ya/Tidak';
    case 'likert5':
      return 'Likert 1-5';
    case 'likert4':
      return 'Likert 1-4';
    case 'likert3':
      return 'Likert 1-3';
    case 'multipleChoice':
      return 'Pilihan Ganda';
    case 'text':
      return 'Teks';
    default:
      return 'Likert';
  }
}

double _reportIndexTo100(double score) {
  if (score <= 0) {
    return 0;
  }
  return (score * 20).clamp(0, 100).toDouble();
}

String _formatIndex(double score) {
  return score.toStringAsFixed(2);
}
