import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/api_endpoints.dart';
import 'package:unila_helpdesk_frontend/core/network/query_params.dart';
import 'package:unila_helpdesk_frontend/core/network/token_storage.dart';

class TicketRepository {
  TicketRepository({ApiClient? client}) : _client = client ?? sharedApiClient;

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

  Future<TicketPage> fetchTicketsPaged({
    String? query,
    String? status,
    String? categoryId,
    DateTime? start,
    DateTime? end,
    int page = 1,
    int limit = 50,
  }) async {
    final params = buildPagedQueryParams(
      page: page,
      limit: limit,
      query: query,
      start: start,
      end: end,
      extra: {
        'status': status?.trim().toUpperCase(),
        'categoryId': categoryId,
      },
    );
    final response = await _client.get(ApiEndpoints.ticketsPaged, query: params);
    final data = response.data?['data'];
    if (response.isSuccess && data is Map<String, dynamic>) {
      return TicketPage.fromJson(data);
    }
    return const TicketPage(
      items: [],
      page: 1,
      limit: 50,
      total: 0,
      totalPages: 1,
    );
  }

  Future<Ticket> fetchTicketById(String id) async {
    final response = await _client.get(ApiEndpoints.ticketById(id));
    final data = response.data?['data'];
    if (response.isSuccess && data is Map<String, dynamic>) {
      return Ticket.fromJson(data);
    }
    throw Exception(response.error?.message ?? 'Tiket tidak ditemukan');
  }

  Future<ApiResponse<Map<String, dynamic>>> createTicket(TicketDraft draft) {
    return _client.post(ApiEndpoints.tickets, body: draft.toJson());
  }

  Future<ApiResponse<Map<String, dynamic>>> createGuestTicket({
    required GuestTicketDraft draft,
  }) {
    return _client.post(ApiEndpoints.guestTickets, body: draft.toJson());
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

  Future<String> uploadAttachment({
    required String filename,
    required Uint8List bytes,
  }) async {
    final uri = _client.buildUri(ApiEndpoints.uploads);
    final request = http.MultipartRequest('POST', uri);
    final headers = <String, String>{
      'X-Client-Type': kIsWeb ? 'web' : 'mobile',
    };
    final token = await TokenStorage().readToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    request.headers.addAll(headers);
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Upload gagal (${streamed.statusCode})');
    }
    final decoded = jsonDecode(body);
    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      final path = data['path']?.toString() ?? '';
      if (path.isNotEmpty) {
        return path;
      }
      final url = data['url']?.toString() ?? '';
      if (url.isNotEmpty) {
        return url;
      }
    }
    throw Exception('Upload gagal: respons tidak valid');
  }
}

class TicketDraft {
  TicketDraft({
    required this.serviceId,
    required this.notes,
    required this.priority,
    this.lamp1,
  });

  final String serviceId;
  final String notes;
  final TicketPriority priority;
  final String? lamp1;

  Map<String, dynamic> toJson() {
    return {
      'serviceId': int.tryParse(serviceId),
      'notes': notes,
      'priority': priority.apiValue,
      if (lamp1 != null && lamp1!.trim().isNotEmpty) 'lamp1': lamp1,
    };
  }
}

class GuestTicketDraft {
  GuestTicketDraft({
    required this.name,
    required this.numberId,
    required this.email,
    required this.entity,
    required this.serviceId,
    required this.notes,
    required this.priority,
    required this.lamp1,
    required this.lamp2,
  });

  final String name;
  final String numberId;
  final String email;
  final String entity;
  final String serviceId;
  final String notes;
  final TicketPriority priority;
  final String lamp1;
  final String lamp2;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'numberId': numberId,
      'email': email,
      'entity': entity,
      'serviceId': int.tryParse(serviceId),
      'notes': notes,
      'priority': priority.apiValue,
      'lamp1': lamp1,
      'lamp2': lamp2,
    };
  }
}
