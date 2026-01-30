import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/features/tickets/presentation/widgets/ticket_card.dart';

final ticketListSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final ticketListFilterProvider = StateProvider.autoDispose<TicketFilter>((ref) => TicketFilter.all);

class TicketListPage extends ConsumerWidget {
  const TicketListPage({super.key, required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(ticketListSearchQueryProvider);
    final selectedFilter = ref.watch(ticketListFilterProvider);
    final tickets = ref.watch(ticketsProvider).where((ticket) {
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
        return ticket.id.toLowerCase().contains(query) ||
            ticket.title.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tickets')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            onChanged: (value) => ref.read(ticketListSearchQueryProvider.notifier).state = value,
            decoration: const InputDecoration(
              hintText: 'Cari ID atau kata kunci',
              prefixIcon: Icon(Icons.search),
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
          if (tickets.isEmpty)
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
            ),
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
        return 'Open';
      case TicketFilter.inProgress:
        return 'Progres';
      case TicketFilter.resolved:
        return 'Selesai';
    }
  }
}
