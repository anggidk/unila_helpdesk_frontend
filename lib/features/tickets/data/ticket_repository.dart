import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/api_endpoints.dart';
import 'package:unila_helpdesk_frontend/core/network/query_params.dart';

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
      extra: {'status': status?.trim().toUpperCase(), 'categoryId': categoryId},
    );
    final response = await _client.get(
      ApiEndpoints.ticketsPaged,
      query: params,
    );
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

  /// Mengonversi file ke base64 data URI dan menyimpannya langsung di DB
  /// tanpa perlu storage eksternal. Format: "{namafile}|data:{mime};base64,{data}"
  Future<String> uploadAttachment({
    required String filename,
    required Uint8List bytes,
  }) async {
    final mimeType = _mimeFromFilename(filename);
    final encoded = base64Encode(bytes);
    return '$filename|data:$mimeType;base64,$encoded';
  }

  static String _mimeFromFilename(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    const map = <String, String>{
      'pdf': 'application/pdf',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };
    return map[ext] ?? 'application/octet-stream';
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
