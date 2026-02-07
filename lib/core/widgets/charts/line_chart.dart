import 'package:flutter/material.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';

class LineSeries {
  const LineSeries({
    required this.label,
    required this.color,
    required this.values,
  });

  final String label;
  final Color color;
  final List<int> values;
}

class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.labels,
    required this.series,
  });

  final List<String> labels;
  final List<LineSeries> series;

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

  final List<LineSeries> series;

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

  List<Offset> _pointsForLine(LineSeries line, Rect rect, int maxValue) {
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

  int _maxValue(List<LineSeries> series) {
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

  final List<LineSeries> series;

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
