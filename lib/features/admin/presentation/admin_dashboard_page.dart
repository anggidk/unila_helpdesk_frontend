import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/analytics_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/score_utils.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceTrendsAsync = ref.watch(serviceTrendsProvider);
    final serviceTrends = serviceTrendsAsync.value ?? [];
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final usageAsync = ref.watch(dashboardUsageProvider);
    final satisfactionAsync = ref.watch(dashboardSatisfactionProvider);
    final summary = summaryAsync.value;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dasbor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (summaryAsync.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (summaryAsync.hasError)
            Text(
              'Gagal memuat ringkasan: ${summaryAsync.error}',
              style: const TextStyle(color: AppTheme.textMuted),
            )
          else
            Row(
              children: [
                _StatCard(
                  label: 'Total Tiket',
                  value: _formatCount(summary?.totalTickets),
                  icon: Icons.folder_open,
                  color: AppTheme.accentBlue,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  label: 'Tiket Terbuka',
                  value: _formatCount(summary?.openTickets),
                  icon: Icons.warning_amber,
                  color: AppTheme.warning,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  label: 'Tiket Selesai Bulan Ini',
                  value: _formatCount(summary?.resolvedThisPeriod),
                  icon: Icons.check_circle,
                  color: AppTheme.success,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  label: 'Rata-rata Penilaian',
                  value: '${_formatScore(summary?.avgRating)} / 5.0',
                  icon: Icons.star,
                  color: AppTheme.accentYellow,
                ),
              ],
            ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: _dashboardCardHeight,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tiket per Kategori', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        if (serviceTrendsAsync.isLoading)
                          const Expanded(child: Center(child: CircularProgressIndicator()))
                        else if (serviceTrendsAsync.hasError)
                          Expanded(
                            child: Text(
                              'Gagal memuat kategori: ${serviceTrendsAsync.error}',
                              style: const TextStyle(color: AppTheme.textMuted),
                            ),
                          )
                        else if (serviceTrends.isEmpty)
                          const Expanded(
                            child: Text('Belum ada data kategori.', style: TextStyle(color: AppTheme.textMuted)),
                          )
                        else
                          Expanded(
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 180,
                                  child: _PieChart(
                                    sections: _trendSections(serviceTrends),
                                    centerText: '${_formatCount(summary?.totalTickets)}\nTOTAL',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: _trendLegend(serviceTrends),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: _dashboardCardHeight,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tren Bulanan', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text('Volume tiket masuk tahun ini', style: TextStyle(color: AppTheme.textMuted)),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.outline),
                            ),
                            child: usageAsync.when(
                              data: (rows) {
                                if (rows.isEmpty) {
                                  return const Center(
                                    child: Text('Belum ada data.', style: TextStyle(color: AppTheme.textMuted)),
                                  );
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
                              error: (error, _) => Center(
                                child: Text(
                                  'Gagal memuat tren: $error',
                                  style: const TextStyle(color: AppTheme.textMuted),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kepuasan per Layanan (Hasil Survei)', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                satisfactionAsync.when(
                  data: (rows) {
                    if (rows.isEmpty) {
                      return const Text(
                        'Belum ada data survei.',
                        style: TextStyle(color: AppTheme.textMuted),
                      );
                    }
                    return Column(
                      children: rows.map((row) => _SatisfactionBarRow(row: row)).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text(
                    'Gagal memuat kepuasan: $error',
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.outline),
    );
  }
}

const double _dashboardCardHeight = 420;

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SatisfactionBarRow extends StatelessWidget {
  const _SatisfactionBarRow({required this.row});

  final ServiceSatisfaction row;

  @override
  Widget build(BuildContext context) {
    final normalizedScore = scoreToFive(row.avgScore);
    final ratio = (normalizedScore / 5).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${normalizedScore.toStringAsFixed(2)} / 5 • ${row.responses} respon',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: ratio,
            color: AppTheme.navy,
            backgroundColor: AppTheme.surface,
          ),
        ],
      ),
    );
  }
}

class _PieSection {
  const _PieSection({
    required this.value,
    required this.color,
  });

  final double value;
  final Color color;
}

class _PieChart extends StatelessWidget {
  const _PieChart({
    required this.sections,
    required this.centerText,
  });

  final List<_PieSection> sections;
  final String centerText;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(180, 180),
          painter: _PieChartPainter(sections),
        ),
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.outline),
          ),
          alignment: Alignment.center,
          child: Text(
            centerText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter(this.sections);

  final List<_PieSection> sections;

  @override
  void paint(Canvas canvas, Size size) {
    final total = sections.fold<double>(0, (sum, item) => sum + item.value);
    if (total <= 0) {
      final paint = Paint()
        ..color = AppTheme.surface
        ..style = PaintingStyle.fill;
      canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);
      return;
    }
    var startAngle = -90.0;
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: radius);
    for (final section in sections) {
      final sweep = (section.value / total) * 360;
      final paint = Paint()
        ..color = section.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, _degToRad(startAngle), _degToRad(sweep), true, paint);
      startAngle += sweep;
    }
  }

  double _degToRad(double degree) => degree * (3.141592653589793 / 180);

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.sections != sections;
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

String _formatCount(int? value) => value == null ? '-' : value.toString();

String _formatScore(double? value) {
  if (value == null) {
    return '-';
  }
  return scoreToFive(value).toStringAsFixed(2);
}

List<_LegendRow> _trendLegend(List<ServiceTrend> rows) {
  final colors = _palette(rows.length);
  return List.generate(rows.length, (index) {
    final row = rows[index];
    return _LegendRow(
      label: row.label,
      value: '${row.percentage.toStringAsFixed(1)}%',
      color: colors[index],
    );
  });
}

List<_PieSection> _trendSections(List<ServiceTrend> rows) {
  final colors = _palette(rows.length);
  return List.generate(rows.length, (index) {
    final row = rows[index];
    return _PieSection(value: row.percentage, color: colors[index]);
  });
}

List<Color> _palette(int count) {
  const base = [
    AppTheme.navy,
    AppTheme.accentBlue,
    AppTheme.accentYellow,
    AppTheme.success,
    AppTheme.warning,
    AppTheme.danger,
    AppTheme.textMuted,
  ];
  if (count <= base.length) {
    return base.take(count).toList();
  }
  return List.generate(count, (index) => base[index % base.length]);
}

