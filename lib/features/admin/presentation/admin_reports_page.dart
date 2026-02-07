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
import 'package:unila_helpdesk_frontend/core/widgets/charts/line_chart.dart';
import 'package:unila_helpdesk_frontend/core/widgets/charts/usage_series.dart';
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
    final periods = periodsFor(period);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export CSV berhasil.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export: $error')),
      );
    }
  }

  void _syncCategory(List<ServiceCategory> categories) {
    final filtered = categories.where((category) => !category.guestAllowed).toList();
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
    ref.listen<AsyncValue<List<ServiceCategory>>>(
      serviceCategoriesProvider,
      (_, next) {
        final list = next.value ?? [];
        _syncCategory(list);
      },
    );
    ref.listen<String?>(
      reportsCategoryIdProvider,
      (_, next) {
        final categories = ref.read(serviceCategoriesProvider).value ?? [];
        final selected = categories
            .where((item) => item.id == next)
            .toList();
        if (next != null && next != _lastCategoryId) {
          _lastCategoryId = next;
          _syncTemplateFromCategory(selected.isNotEmpty ? selected.first : null);
        }
      },
    );

    final period = ref.watch(reportsPeriodProvider);
    final chartPeriod = ref.watch(reportsChartPeriodProvider);
    final usageAsync = ref.watch(reportsChartUsageProvider);
    final trendsAsync = ref.watch(reportsChartServiceTrendsProvider);
    final satisfactionAsync = ref.watch(surveySatisfactionProvider);
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final templatesAsync = ref.watch(reportsTemplatesProvider);
    final selectedCategoryId = ref.watch(reportsCategoryIdProvider);
    final selectedTemplateId = ref.watch(reportsTemplateIdProvider);

    final categories = (categoriesAsync.value ?? [])
        .where((category) => !category.guestAllowed)
        .toList();
    final templates = templatesAsync.value ?? [];
    final hasSelected = selectedTemplateId != null &&
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
                    const Text('Hasil Kepuasan Survei', style: TextStyle(fontWeight: FontWeight.w700)),
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
                      return const Text('Belum ada data survei.', style: TextStyle(color: AppTheme.textMuted));
                    }
                    return _SatisfactionTable(report: report);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text(
                    'Gagal memuat hasil survei: $error',
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Grafik',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
              PeriodDropdown(
                value: chartPeriod,
                onChanged: (value) {
                  ref.read(reportsChartPeriodProvider.notifier).state = value;
                },
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CardPlaceholder(
                  title: 'Tren Tiket & Survei',
                  description: 'Jumlah tiket dan survei per periode.',
                  child: usageAsync.when(
                    data: (rows) {
                      if (rows.isEmpty) {
                        return const Text('Belum ada data.', style: TextStyle(color: AppTheme.textMuted));
                      }
                      return LineChart(
                        labels: rows.map((row) => row.label).toList(),
                        series: buildUsageLineSeries(rows),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text(
                      'Gagal memuat tren: $error',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CardPlaceholder(
                  title: 'Top Isu per Layanan',
                  description: 'Persentase tiket per kategori layanan.',
                  child: trendsAsync.when(
                    data: (rows) {
                      if (rows.isEmpty) {
                        return const Text('Belum ada data.', style: TextStyle(color: AppTheme.textMuted));
                      }
                      return _TopIssuesBarChart(rows: rows);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text(
                      'Gagal memuat top isu: $error',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 12),
          Container(
            height: 300,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outline),
            ),
            child: child,
          ),
        ],
      ),
    );
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
          border: Border.all(color: enabled ? AppTheme.outline : AppTheme.outline.withValues(alpha: 0.4)),
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

class _TopIssuesBarChart extends StatelessWidget {
  const _TopIssuesBarChart({required this.rows});

  final List<ServiceTrend> rows;

  @override
  Widget build(BuildContext context) {
    final sorted = [...rows]..sort((a, b) => b.percentage.compareTo(a.percentage));
    final visible = sorted.take(6).toList();
    final maxValue = visible.fold<double>(0, (max, row) => row.percentage > max ? row.percentage : max);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: visible
          .map(
            (row) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${row.percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: _barHeight(row.percentage, maxValue),
                      decoration: BoxDecoration(
                        color: AppTheme.navy,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      row.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  double _barHeight(double value, double maxValue) {
    if (maxValue <= 0) {
      return 0;
    }
    final ratio = value / maxValue;
    return (ratio * 120).clamp(8.0, 120.0).toDouble();
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
              final supportsScore = row.type != 'text' && row.type != 'multipleChoice';
              final avgText =
                  !supportsScore || row.responses == 0 ? '-' : formatScoreFive(row.avgScore);
              return DataRow(
                cells: [
                  DataCell(SizedBox(
                    width: 360,
                    child: Text(row.question, maxLines: 2, overflow: TextOverflow.ellipsis),
                  )),
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
    case 'likert4':
      return 'Likert 1-4 (Baik)';
    case 'likert4Puas':
      return 'Likert 1-4 (Puas)';
    case 'likert3':
      return 'Likert 1-3 (Baik)';
    case 'likert3Puas':
      return 'Likert 1-3 (Puas)';
    case 'likertQuality':
      return 'Likert 1-5 (Baik)';
    case 'multipleChoice':
      return 'Pilihan Ganda';
    case 'text':
      return 'Teks';
    default:
      return 'Likert 1-5 (Puas)';
  }
}

