import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/api_endpoints.dart';
import 'package:unila_helpdesk_frontend/features/home/domain/home_models.dart';

class HomeRepository {
  HomeRepository({ApiClient? client})
      : _client = client ?? sharedApiClient;

  final ApiClient _client;

  Future<HomeSummary> fetchHomeSummary({required UserProfile user}) async {
    final response = await _client.get(ApiEndpoints.tickets);
    final items = response.data?['data'];
    final tickets = <Ticket>[];
    if (response.isSuccess && items is List) {
      tickets.addAll(
        items
            .whereType<Map<String, dynamic>>()
            .map(Ticket.fromJson),
      );
      tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final activeCount =
        tickets.where((ticket) => ticket.status == TicketStatus.inProgress).length;
    final resolvedCount =
        tickets.where((ticket) => ticket.status == TicketStatus.resolved).length;
    final waitingCount =
        tickets.where((ticket) => ticket.status == TicketStatus.waiting).length;

    return HomeSummary(
      user: user,
      activeCount: activeCount,
      resolvedCount: resolvedCount,
      waitingCount: waitingCount,
      recentTickets: tickets.take(3).toList(),
    );
  }
}
