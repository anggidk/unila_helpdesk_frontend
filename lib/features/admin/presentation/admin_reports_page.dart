import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';

const _reportRows = [
  {
    'dimension': 'Responsiveness',
    'score': '4.20',
    'target': '4.00',
    'gap': '+0.20',
    'status': 'Optimal',
  },
  {
    'dimension': 'Reliability',
    'score': '3.80',
    'target': '4.00',
    'gap': '-0.20',
    'status': 'Underperform',
  },
  {
    'dimension': 'Assurance',
    'score': '4.50',
    'target': '4.00',
    'gap': '+0.50',
    'status': 'Excellent',
  },
  {
    'dimension': 'Empathy',
    'score': '3.90',
    'target': '4.00',
    'gap': '-0.10',
    'status': 'Warning',
  },
  {
    'dimension': 'Tangibles',
    'score': '4.10',
    'target': '4.00',
    'gap': '+0.10',
    'status': 'Optimal',
  },
];

final adminReportRowsProvider = Provider<List<Map<String, String>>>((ref) => _reportRows);

class AdminReportsPage extends ConsumerWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(adminReportRowsProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DropdownFilter(label: 'Layanan', value: 'Internet & Jaringan'),
              const SizedBox(width: 12),
              _DropdownFilter(label: 'Framework', value: 'ISO 9001'),
              const SizedBox(width: 12),
              _DropdownFilter(label: 'Periode', value: 'Q3 2026'),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text('Export CSV'),
              ),
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
                const Text('Hasil Survey - Internet (ISO 9001)', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                DataTable(
                  headingRowColor: WidgetStateProperty.all(AppTheme.surface),
                  columns: const [
                    DataColumn(label: Text('Dimensi')),
                    DataColumn(label: Text('Skor (AVG)')),
                    DataColumn(label: Text('Target')),
                    DataColumn(label: Text('Gap')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: rows.map((row) {
                    return DataRow(
                      cells: [
                        DataCell(Text(row['dimension']!)),
                        DataCell(Text(row['score']!)),
                        DataCell(Text(row['target']!)),
                        DataCell(Text(row['gap']!)),
                        DataCell(_StatusPill(label: row['status']!)),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _CardPlaceholder(
                  title: 'Trend per Dimensi',
                  description: 'Grafik radar kepuasan (mock).',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CardPlaceholder(
                  title: 'Detail Response (Top 5 Issues)',
                  description: 'Daftar isu dengan skor tertinggi (mock).',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  const _DropdownFilter({required this.label, required this.value});

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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    Color color = AppTheme.success;
    if (label.toLowerCase().contains('under') || label.toLowerCase().contains('warning')) {
      color = AppTheme.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder({required this.title, required this.description});

  final String title;
  final String description;

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
            height: 150,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outline),
            ),
            child: const Center(child: Text('Grafik / List (Mock)')),
          ),
        ],
      ),
    );
  }
}

