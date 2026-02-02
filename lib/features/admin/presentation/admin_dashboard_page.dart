import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceTrendsAsync = ref.watch(serviceTrendsProvider);
    final serviceTrends = serviceTrendsAsync.value ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              _StatCard(label: 'Total Ticket', value: '156', icon: Icons.folder_open, color: AppTheme.accentBlue),
              SizedBox(width: 16),
              _StatCard(label: 'Open Ticket', value: '42', icon: Icons.warning_amber, color: AppTheme.warning),
              SizedBox(width: 16),
              _StatCard(label: 'Resolved Bulan Ini', value: '89', icon: Icons.check_circle, color: AppTheme.success),
              SizedBox(width: 16),
              _StatCard(label: 'Avg. Rating', value: '4.2 / 5.0', icon: Icons.star, color: AppTheme.accentYellow),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tiket per Kategori', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: Center(
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.surface,
                              border: Border.all(color: AppTheme.outline),
                            ),
                            child: const Center(
                              child: Text('156\nTOTAL', textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LegendRow(label: 'Internet', value: '45%', color: AppTheme.accentBlue),
                      _LegendRow(label: 'SIAKAD', value: '30%', color: AppTheme.navy),
                      _LegendRow(label: 'Email', value: '15%', color: AppTheme.accentYellow),
                      _LegendRow(label: 'Lainnya', value: '10%', color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trend Bulanan', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text('Volume tiket masuk tahun ini', style: TextStyle(color: AppTheme.textMuted)),
                      const SizedBox(height: 12),
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: const Center(
                          child: Text('Grafik Trend (Mock)'),
                        ),
                      ),
                    ],
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
                const Text('Kepuasan per Layanan (Survey Results)', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (serviceTrendsAsync.isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (serviceTrendsAsync.hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Gagal memuat tren layanan: ${serviceTrendsAsync.error}',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                ...serviceTrends.map(
                  (trend) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(trend.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('${trend.percentage.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: trend.percentage / 100,
                          color: AppTheme.navy,
                          backgroundColor: AppTheme.surface,
                        ),
                        const SizedBox(height: 4),
                        Text(trend.note, style: const TextStyle(color: AppTheme.textMuted)),
                      ],
                    ),
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
                  Text(label, style: const TextStyle(color: AppTheme.textMuted)),
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

