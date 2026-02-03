import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/features/home/domain/home_models.dart';

final homeSummaryProvider =
    FutureProvider.autoDispose.family<HomeSummary, UserProfile>((ref, user) async {
  final tickets = await ref.watch(ticketsProvider.future);
  final activeCount =
      tickets.where((ticket) => ticket.status == TicketStatus.inProgress).length;
  final resolvedCount =
      tickets.where((ticket) => ticket.status == TicketStatus.resolved).length;
  final waitingCount =
      tickets.where((ticket) => ticket.status == TicketStatus.waiting).length;
  final recentTickets = [...tickets]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return HomeSummary(
    user: user,
    activeCount: activeCount,
    resolvedCount: resolvedCount,
    waitingCount: waitingCount,
    recentTickets: recentTickets.take(3).toList(),
  );
});
