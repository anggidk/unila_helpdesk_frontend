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
                      'Indeks Kepuasan Layanan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    PeriodDropdown(
                      value: indexPeriod,
                      onChanged: (value) {
                        ref
                                .read(
                                  reportsSatisfactionIndexPeriodProvider
                                      .notifier,
                                )
                                .state =
                            value;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nilai kepuasan tiap kategori dinormalisasi ke skala 100.',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 12),
                satisfactionSummaryAsync.when(
                  data: (rows) {
                    if (rows.isEmpty) {
                      return const Text(
                        'Belum ada data kepuasan per kategori.',
                        style: TextStyle(color: AppTheme.textMuted),
                      );
                    }
                    return _SatisfactionIndexTable(rows: rows);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text(
                    'Gagal memuat indeks kepuasan: $error',
                    style: const TextStyle(color: AppTheme.textMuted),
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

class _SatisfactionIndexTable extends StatelessWidget {
  const _SatisfactionIndexTable({required this.rows});

  final List<ServiceSatisfaction> rows;

  @override
  Widget build(BuildContext context) {
    final totalResponses = rows.fold<int>(0, (sum, row) => sum + row.responses);
    final totalWeightedScore = rows.fold<double>(
      0,
      (sum, row) => sum + (row.avgScore * row.responses),
    );
    final totalAverage = totalResponses == 0
        ? 0.0
        : totalWeightedScore / totalResponses;
    final totalIndex = _toIndex100(totalAverage);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.surface),
            columns: const [
              DataColumn(label: Text('Kategori Layanan')),
              DataColumn(label: Text('Respon')),
              DataColumn(label: Text('Nilai Kepuasan')),
              DataColumn(label: Text('Indeks (100)')),
            ],
            rows: [
              ...rows.map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text(row.label)),
                    DataCell(Text(row.responses.toString())),
                    DataCell(Text(formatScoreFive(row.avgScore))),
                    DataCell(Text(_formatIndex(_toIndex100(row.avgScore)))),
                  ],
                ),
              ),
              DataRow(
                color: WidgetStateProperty.all(
                  AppTheme.surface.withValues(alpha: 0.75),
                ),
                cells: [
                  const DataCell(
                    Text(
                      'Indeks Kepuasan Total',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataCell(
                    Text(
                      totalResponses.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataCell(
                    Text(
                      formatScoreFive(totalAverage),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatIndex(totalIndex),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _toIndex100(double score) {
    if (score <= 0) {
      return 0;
    }
    return (score * 20).clamp(0, 100).toDouble();
  }

  String _formatIndex(double score) {
    return score.toStringAsFixed(2);
  }
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
              DataColumn(label: Text('Pertanyaan')),
              DataColumn(label: Text('Tipe')),
              DataColumn(label: Text('Skor (AVG)')),
              DataColumn(label: Text('Respon')),
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
                    SizedBox(
                      width: 360,
                      child: Text(
                        row.question,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(_questionTypeLabel(row.type))),
                  DataCell(Text(avgText)),
                  DataCell(Text(row.responses.toString())),
                ],
              );
            }).toList(),
          ),
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
