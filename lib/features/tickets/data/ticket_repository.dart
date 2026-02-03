import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/api_endpoints.dart';

class TicketRepository {
  TicketRepository({ApiClient? client})
      : _client = client ?? sharedApiClient;

  final ApiClient _client;

  Future<List<Ticket>> fetchTickets({String? query}) async {
    final trimmed = query?.trim() ?? '';
    final response = await _client.get(
      trimmed.isEmpty ? ApiEndpoints.tickets : ApiEndpoints.ticketSearch,
      query: trimmed.isEmpty ? null : {'q': trimmed},
    );
    final items = response.data?['data'];
    if (response.isSuccess && items is List) {
      return items
          .whereType<Map<String, dynamic>>()
          .map(Ticket.fromJson)
          .toList();
    }
    return [];
  }

  Future<Ticket> fetchTicketById(String id) async {
    final response = await _client.get(ApiEndpoints.ticketById(id));
    final data = response.data?['data'];
    if (response.isSuccess && data is Map<String, dynamic>) {
      return Ticket.fromJson(data);
    }
    throw Exception(response.error?.message ?? 'Ticket tidak ditemukan');
  }

  Future<ApiResponse<Map<String, dynamic>>> createTicket(TicketDraft draft) {
    return _client.post(ApiEndpoints.tickets, body: draft.toJson());
  }

  Future<ApiResponse<Map<String, dynamic>>> createGuestTicket({
    required TicketDraft draft,
    required String reporterName,
  }) {
    return _client.post(ApiEndpoints.guestTickets, body: {
      ...draft.toJson(),
      'reporter_name': reporterName,
    });
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

  Future<ApiResponse<Map<String, dynamic>>> addComment({
    required String id,
    required String message,
  }) {
    return _client.post(
      '${ApiEndpoints.ticketById(id)}/comments',
      body: {'message': message},
    );
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
