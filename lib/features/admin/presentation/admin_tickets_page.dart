import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/utils/date_utils.dart';

class AdminTicketsPage extends ConsumerWidget {
  const AdminTicketsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsProvider);
    final tickets = ticketsAsync.value ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by ticket ID or title...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _FilterButton(label: 'Status: All', icon: Icons.filter_list),
              const SizedBox(width: 12),
              _FilterButton(
                label: 'Kategori: All',
                icon: Icons.category_outlined,
              ),
              const SizedBox(width: 12),
              _FilterButton(
                label: 'Tanggal: All',
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(width: 12),
            ],
          ),
          const SizedBox(height: 20),
          if (ticketsAsync.isLoading)
            const Center(child: CircularProgressIndicator()),
          if (ticketsAsync.hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Gagal memuat tiket: ${ticketsAsync.error}',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outline),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.surface),
              columns: const [
                DataColumn(label: Text('Ticket ID')),
                DataColumn(label: Text('Judul')),
                DataColumn(label: Text('Kategori')),
                DataColumn(label: Text('Tanggal')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Action')),
              ],
              rows: tickets.map((ticket) {
                return DataRow(
                  cells: [
                    DataCell(Text(ticket.id)),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ticket.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Reported by: ${ticket.reporter}',
                            style: const TextStyle(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(ticket.category)),
                    DataCell(Text(formatDate(ticket.createdAt))),
                    DataCell(_StatusChip(label: ticket.status.label)),
                    DataCell(
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_horiz),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    Color color = AppTheme.accentBlue;
    if (label.toLowerCase().contains('selesai')) {
      color = AppTheme.success;
    } else if (label.toLowerCase().contains('menunggu')) {
      color = AppTheme.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
