import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/widgets/info_banner.dart';
import 'package:unila_helpdesk_frontend/features/tickets/data/ticket_repository.dart';

final guestTrackingFoundTicketProvider = StateProvider.autoDispose<Ticket?>(
  (ref) => null,
);

class GuestTrackingPage extends ConsumerStatefulWidget {
  const GuestTrackingPage({super.key});

  @override
  ConsumerState<GuestTrackingPage> createState() => _GuestTrackingPageState();
}

class _GuestTrackingPageState extends ConsumerState<GuestTrackingPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _searchTicket() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final query = _controller.text.trim().toLowerCase();
    Ticket? ticket;
    try {
      final tickets = await TicketRepository().fetchTickets(query: query);
      for (final item in tickets) {
        if (item.id.toLowerCase() == query) {
          ticket = item;
          break;
        }
      }
    } catch (_) {
      ticket = null;
    }

    if (!mounted) return;
    if (ticket != null) {
      ref.read(guestTrackingFoundTicketProvider.notifier).state = ticket;
    } else {
      ref.read(guestTrackingFoundTicketProvider.notifier).state = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket tidak ditemukan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final foundTicket = ref.watch(guestTrackingFoundTicketProvider);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Lacak Tiket')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const InfoBanner(
            text: 'Masukkan nomor tiket untuk melacak status laporan.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 38,
                  backgroundColor: AppTheme.surface,
                  child: Icon(Icons.search, color: AppTheme.accentBlue, size: 36),
                ),
                const SizedBox(height: 12),
                Text('Cek Status Tiket',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  'Masukkan ID tiket dari email konfirmasi.',
                  style: textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: TextFormField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'ID Tiket',
                      hintText: 'contoh: UNILA-2026-001',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Masukkan nomor tiket';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _searchTicket,
                    icon: const Icon(Icons.search),
                    label: const Text('Cari Tiket'),
                  ),
                ),
              ],
            ),
          ),
          if (foundTicket != null) ...[
            const SizedBox(height: 24),
            Text('Hasil Pencarian',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _FoundTicketTile(
              ticket: foundTicket,
              onTap: () => context.pushNamed(AppRouteNames.ticketDetail, extra: foundTicket),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Lupa nomor tiket? Hubungi helpdesk.',
            style: textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
          if (foundTicket == null && _controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Tiket tidak ditemukan, pastikan ID benar.',
                style: textTheme.bodySmall?.copyWith(color: AppTheme.danger),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _FoundTicketTile extends StatelessWidget {
  const _FoundTicketTile({required this.ticket, required this.onTap});

  final Ticket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppTheme.surface,
              child: Icon(Icons.confirmation_number_outlined, color: AppTheme.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.id, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(ticket.title, style: const TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
