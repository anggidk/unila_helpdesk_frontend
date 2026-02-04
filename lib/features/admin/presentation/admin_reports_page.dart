import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/analytics_models.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';

class AdminReportsPage extends ConsumerStatefulWidget {
  const AdminReportsPage({super.key});

  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  String? _lastCategoryId;

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
              _PeriodDropdown(
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
                const Text('Hasil Kepuasan Survei', style: TextStyle(fontWeight: FontWeight.w700)),
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
              _PeriodDropdown(
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
                      return _LineChart(
                        labels: rows.map((row) => row.label).toList(),
                        series: [
                          _LineSeries(
                            label: 'Tiket',
                            color: AppTheme.navy,
                            values: rows.map((row) => row.tickets).toList(),
                          ),
                          _LineSeries(
                            label: 'Survei',
                            color: AppTheme.accentYellow,
                            values: rows.map((row) => row.surveys).toList(),
                          ),
                        ],
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

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'daily', child: Text('Harian')),
        PopupMenuItem(value: 'weekly', child: Text('Mingguan')),
        PopupMenuItem(value: 'monthly', child: Text('Bulanan')),
        PopupMenuItem(value: 'yearly', child: Text('Tahunan')),
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
            Text(
              'Periode: ${_periodLabel(value)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
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

class _LineSeries {
  const _LineSeries({
    required this.label,
    required this.color,
    required this.values,
  });

  final String label;
  final Color color;
  final List<int> values;
}

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.labels,
    required this.series,
  });

  final List<String> labels;
  final List<_LineSeries> series;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChartLegend(series: series),
        const SizedBox(height: 8),
        Expanded(
          child: CustomPaint(
            painter: _LineChartPainter(series: series),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map(
                (label) => Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.series});

  final List<_LineSeries> series;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = _maxValue(series);
    if (maxValue <= 0) {
      return;
    }
    final axisStep = _axisStepFor(maxValue);
    final axisMax = axisStep * 5;
    const axisPadding = 36.0;
    final chartRect = Rect.fromLTWH(
      axisPadding,
      4,
      size.width - axisPadding,
      size.height - 8,
    );
    final gridPaint = Paint()
      ..color = AppTheme.outline
      ..strokeWidth = 1;
    final labelStyle = const TextStyle(fontSize: 10, color: AppTheme.textMuted);
    for (var i = 0; i <= 5; i++) {
      final ratio = i / 5;
      final dy = chartRect.bottom - (chartRect.height * ratio);
      canvas.drawLine(
        Offset(chartRect.left, dy),
        Offset(chartRect.right, dy),
        gridPaint,
      );
      final value = axisStep * i;
      final textPainter = TextPainter(
        text: TextSpan(text: value.toString(), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(chartRect.left - 6 - textPainter.width, dy - textPainter.height / 2),
      );
    }

    for (final line in series) {
      final linePaint = Paint()
        ..color = line.color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final points = _pointsForLine(line, chartRect, axisMax);
      if (points.isEmpty) continue;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);

      final pointPaint = Paint()..color = line.color;
      for (final point in points) {
        canvas.drawCircle(point, 3, pointPaint);
      }
    }
  }

  List<Offset> _pointsForLine(_LineSeries line, Rect rect, int maxValue) {
    final count = line.values.length;
    if (count == 0) return [];
    final points = <Offset>[];
    for (var i = 0; i < count; i++) {
      final ratioX = count == 1 ? 0.5 : i / (count - 1);
      final value = line.values[i];
      final ratioY = value / maxValue;
      final x = rect.left + rect.width * ratioX;
      final y = rect.bottom - rect.height * ratioY;
      points.add(Offset(x, y));
    }
    return points;
  }

  int _maxValue(List<_LineSeries> series) {
    var maxValue = 0;
    for (final line in series) {
      for (final value in line.values) {
        if (value > maxValue) {
          maxValue = value;
        }
      }
    }
    return maxValue == 0 ? 1 : maxValue;
  }

  int _axisStepFor(int maxValue) {
    var step = 10;
    while (maxValue > step * 5) {
      step *= 2;
    }
    return step;
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.series != series;
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.series});

  final List<_LineSeries> series;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: series
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(item.label, style: const TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            ),
          )
          .toList(),
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
                  !supportsScore || row.responses == 0 ? '-' : row.avgScore.toStringAsFixed(2);
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
    case 'likert7':
      return 'Likert 1-7';
    case 'likert6':
      return 'Likert 1-6';
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

