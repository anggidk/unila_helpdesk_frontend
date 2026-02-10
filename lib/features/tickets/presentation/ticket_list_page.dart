import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/widgets/user_top_app_bar.dart';
import 'package:unila_helpdesk_frontend/features/tickets/data/ticket_repository.dart';
import 'package:unila_helpdesk_frontend/features/tickets/presentation/widgets/ticket_card.dart';
import 'package:unila_helpdesk_frontend/features/user/presentation/style_15_bottom_nav_bar.widget.dart';

final ticketListSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');
final ticketListFilterProvider =
    StateProvider.autoDispose<TicketFilter>((ref) => TicketFilter.all);

class TicketListPage extends ConsumerStatefulWidget {
  const TicketListPage({super.key});

  @override
  ConsumerState<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends ConsumerState<TicketListPage> {
  late final TextEditingController _searchController;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: ref.read(ticketListSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(ticketListSearchQueryProvider);
    final selectedFilter = ref.watch(ticketListFilterProvider);
    final ticketsAsync = ref.watch(ticketsProvider);
    if (_searchController.text != searchQuery) {
      _searchController.text = searchQuery;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    }
    final tickets = (ticketsAsync.value ?? []).where((ticket) {
      if (selectedFilter == TicketFilter.open) {
        if (ticket.status == TicketStatus.resolved) {
          return false;
        }
      } else if (selectedFilter == TicketFilter.inProgress) {
        if (ticket.status != TicketStatus.inProgress) {
          return false;
        }
      } else if (selectedFilter == TicketFilter.resolved) {
        if (ticket.status != TicketStatus.resolved) {
          return false;
        }
      }

      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return ticket.displayNumber.toLowerCase().contains(query) ||
            ticket.title.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: UserTopAppBar(titleText: 'Tiket'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + Style15BottomNavBar.heightFor(context),
        ),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) =>
                ref.read(ticketListSearchQueryProvider.notifier).state = value,
            decoration: InputDecoration(
              hintText: 'Cari nomor tiket atau kata kunci',
              prefixIcon: Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        ref.read(ticketListSearchQueryProvider.notifier).state =
                            '';
                        _searchController.clear();
                      },
                      icon: const Icon(Icons.close),
                      tooltip: 'Hapus',
                    ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TicketFilter.values.map((filter) {
                final isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter.label),
                    selected: isSelected,
                    onSelected: (_) => ref.read(ticketListFilterProvider.notifier).state = filter,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (ticketsAsync.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (ticketsAsync.hasError)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Text(
                'Gagal memuat tiket: ${ticketsAsync.error}',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
          if (!ticketsAsync.isLoading && tickets.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outline),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 32, color: AppTheme.textMuted),
                  SizedBox(height: 8),
                  Text('Belum ada tiket untuk filter ini.'),
                ],
              ),
            ),
          ...tickets.map(
            (ticket) => TicketCard(
              ticket: ticket,
              onTap: () {
                context.pushNamed(AppRouteNames.ticketDetail, extra: ticket);
              },
              onEdit: () async {
                final updated = await context.pushNamed<bool>(
                  AppRouteNames.ticketForm,
                  extra: ticket,
                );
                if (updated == true) {
                  ref.invalidate(ticketsProvider);
                }
              },
              onDelete: () => _confirmDelete(ticket),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Ticket ticket) async {
    if (_isDeleting) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Tiket'),
        content: Text(
          'Apakah Anda yakin ingin menghapus tiket ${ticket.displayNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _isDeleting
                ? null
                : () async {
                    setState(() => _isDeleting = true);
                    final response = await TicketRepository().deleteTicket(
                      ticket.id,
                    );
                    if (!mounted) return;
                    if (!response.isSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            response.error?.message ?? 'Gagal menghapus tiket.',
                          ),
                        ),
                      );
                      setState(() => _isDeleting = false);
                      return;
                    }
                    ref.invalidate(ticketsProvider);
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tiket berhasil dihapus.')),
                    );
                    setState(() => _isDeleting = false);
                  },
            child: _isDeleting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

enum TicketFilter { all, open, inProgress, resolved }

extension TicketFilterX on TicketFilter {
  String get label {
    switch (this) {
      case TicketFilter.all:
        return 'Semua';
      case TicketFilter.open:
        return 'Terbuka';
      case TicketFilter.inProgress:
        return 'Diproses';
      case TicketFilter.resolved:
        return 'Selesai';
    }
  }
}
