import 'package:unila_helpdesk_frontend/core/config/api_config.dart';
import 'package:unila_helpdesk_frontend/core/mock/mock_data.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/api_endpoints.dart';

class TicketRepository {
  TicketRepository({ApiClient? client})
      : _client = client ?? MockApiClient(baseUrl: ApiConfig.baseUrl);

  final ApiClient _client;

  Future<List<Ticket>> fetchTickets({String? query}) async {
    // TODO: Replace with API call:
    // final response = await _client.get(ApiEndpoints.tickets, query: {'q': query ?? ''});
    // return response.data?['data'] as List<Ticket>;
    final tickets = MockData.tickets;
    if (query == null || query.trim().isEmpty) {
      return tickets;
    }
    final lowerQuery = query.toLowerCase();
    return tickets
        .where(
          (ticket) =>
              ticket.id.toLowerCase().contains(lowerQuery) ||
              ticket.title.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  Future<Ticket> fetchTicketById(String id) async {
    // TODO: Replace with API call:
    // final response = await _client.get(ApiEndpoints.ticketById(id));
    // return Ticket.fromJson(response.data?['data']);
    return MockData.tickets.firstWhere((ticket) => ticket.id == id);
  }

  Future<ApiResponse<Map<String, dynamic>>> createTicket(TicketDraft draft) {
    return _client.post(ApiEndpoints.tickets, body: draft.toJson());
  }

  Future<ApiResponse<Map<String, dynamic>>> updateTicket({
    required String id,
    required TicketDraft draft,
  }) {
    return _client.post(ApiEndpoints.ticketById(id), body: draft.toJson());
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteTicket(String id) {
    return _client.post('${ApiEndpoints.ticketById(id)}/delete');
  }
}

class TicketDraft {
  TicketDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    this.attachments = const [],
  });

  final String title;
  final String description;
  final String category;
  final TicketPriority priority;
  final List<String> attachments;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority.name,
      'attachments': attachments,
    };
  }
}
