import 'package:unila_helpdesk_frontend/core/config/api_config.dart';
import 'package:unila_helpdesk_frontend/core/mock/mock_data.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/features/home/domain/home_models.dart';

class HomeRepository {
  HomeRepository({ApiClient? client})
      : _client = client ?? MockApiClient(baseUrl: ApiConfig.baseUrl);

  final ApiClient _client;

  Future<HomeSummary> fetchHomeSummary({required UserProfile user}) async {
    // TODO: Replace with API call.
    // final response = await _client.get(ApiEndpoints.homeSummary);
    // Map response to HomeSummary.

    final tickets = List<Ticket>.from(MockData.tickets);
    tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
