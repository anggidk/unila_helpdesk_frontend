enum TicketStatus { waiting, assign, done, reject }

extension TicketStatusX on TicketStatus {
  String get label {
    switch (this) {
      case TicketStatus.waiting:
        return 'Menunggu';
      case TicketStatus.assign:
        return 'Ditugaskan';
      case TicketStatus.done:
        return 'Selesai';
      case TicketStatus.reject:
        return 'Ditolak';
    }
  }

  String get apiValue {
    switch (this) {
      case TicketStatus.waiting:
        return 'WAITING';
      case TicketStatus.assign:
        return 'ASSIGN';
      case TicketStatus.done:
        return 'DONE';
      case TicketStatus.reject:
        return 'REJECT';
    }
  }
}

enum TicketPriority { low, medium, high }

extension TicketPriorityX on TicketPriority {
  String get label {
    switch (this) {
      case TicketPriority.low:
        return 'Rendah';
      case TicketPriority.medium:
        return 'Normal';
      case TicketPriority.high:
        return 'Tinggi';
    }
  }

  String get apiValue {
    switch (this) {
      case TicketPriority.low:
        return 'LOW';
      case TicketPriority.medium:
        return 'MEDIUM';
      case TicketPriority.high:
        return 'HIGH';
    }
  }
}

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.guestAllowed,
    this.surveyTemplateId,
  });

  final String id;
  final String name;
  final bool guestAllowed;
  final String? surveyTemplateId;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      guestAllowed: json['guestAllowed'] == true,
      surveyTemplateId: json['templateId']?.toString(),
    );
  }
}

class TicketUpdate {
  const TicketUpdate({
    required this.title,
    required this.description,
    required this.timestamp,
  });

  final String title;
  final String description;
  final DateTime timestamp;
}

class TicketComment {
  const TicketComment({
    required this.author,
    required this.message,
    required this.timestamp,
    required this.isStaff,
  });

  final String author;
  final String message;
  final DateTime timestamp;
  final bool isStaff;
}

class Ticket {
  const Ticket({
    required this.id,
    required this.ticketNumber,
    required this.ticketDate,
    required this.username,
    required this.numberId,
    required this.name,
    required this.email,
    required this.entity,
    required this.serviceId,
    required this.serviceName,
    required this.notes,
    required this.staffNotes,
    required this.priority,
    required this.status,
    required this.isReject,
    required this.isAssign,
    required this.isDone,
    required this.idStaff,
    required this.lamp1,
    required this.lamp2,
    required this.surveyRequired,
    required this.surveyScore,
  });

  final String id;
  final String ticketNumber;
  final DateTime ticketDate;
  final String username;
  final String numberId;
  final String name;
  final String email;
  final String entity;
  final String serviceId;
  final String serviceName;
  final String notes;
  final String staffNotes;
  final TicketPriority priority;
  final TicketStatus status;
  final bool isReject;
  final bool isAssign;
  final bool isDone;
  final String idStaff;
  final String lamp1;
  final String lamp2;
  final bool surveyRequired;
  final double surveyScore;

  DateTime get createdAt => ticketDate;
  String get category => serviceName;
  String get categoryId => serviceId;
  String get title => _firstLine(notes).isEmpty ? serviceName : _firstLine(notes);
  String get description => notes;
  String get reporter => name;
  bool get isGuest => username.trim().isEmpty;
  String? get assignee => idStaff.trim().isEmpty ? null : idStaff;
  List<String> get attachments => [lamp1, lamp2]
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);
  List<TicketUpdate> get history => const <TicketUpdate>[];
  List<TicketComment> get comments {
    if (staffNotes.trim().isEmpty) {
      return const <TicketComment>[];
    }
    return <TicketComment>[
      TicketComment(
        author: assignee ?? 'Staff',
        message: staffNotes,
        timestamp: ticketDate,
        isStaff: true,
      ),
    ];
  }

  bool get isResolved => status == TicketStatus.done;
  String get displayNumber => ticketNumber.isEmpty ? id : ticketNumber;

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final fallbackAttachments = (json['attachments'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .where((value) => value.trim().isNotEmpty)
        .toList();
    final parsedTicketDate =
        DateTime.tryParse(json['ticketDate']?.toString() ?? '') ??
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now();

    final rawServiceId =
        json['serviceId']?.toString() ?? json['categoryId']?.toString() ?? '';
    final rawServiceName =
        json['serviceName']?.toString() ?? json['category']?.toString() ?? '';
    final lamp1 = json['lamp1']?.toString() ?? (fallbackAttachments.isNotEmpty ? fallbackAttachments.first : '');
    final lamp2 = json['lamp2']?.toString() ?? (fallbackAttachments.length > 1 ? fallbackAttachments[1] : '');

    return Ticket(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticketNumber']?.toString() ?? '',
      ticketDate: parsedTicketDate,
      username: json['username']?.toString() ?? '',
      numberId: json['numberId']?.toString() ?? '',
      name:
          json['name']?.toString() ??
          json['reporterName']?.toString() ??
          '',
      email: json['email']?.toString() ?? '',
      entity: json['entity']?.toString() ?? '',
      serviceId: rawServiceId,
      serviceName: rawServiceName,
      notes:
          json['notes']?.toString() ??
          json['description']?.toString() ??
          '',
      staffNotes: json['staffNotes']?.toString() ?? '',
      priority: _priorityFromString(json['priority']?.toString() ?? ''),
      status: _statusFromString(json['status']?.toString() ?? ''),
      isReject: json['isReject'] == true,
      isAssign: json['isAssign'] == true,
      isDone: json['isDone'] == true,
      idStaff:
          json['idStaff']?.toString() ??
          json['assigneeId']?.toString() ??
          '',
      lamp1: lamp1,
      lamp2: lamp2,
      surveyRequired: json['surveyRequired'] == true,
      surveyScore: (json['surveyScore'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TicketPage {
  const TicketPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<Ticket> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasNext => page < totalPages;
  bool get hasPrev => page > 1;

  factory TicketPage.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Ticket.fromJson)
        .toList();
    return TicketPage(
      items: items,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? items.length,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

String _firstLine(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  return trimmed.split('\n').first.trim();
}

TicketStatus _statusFromString(String value) {
  switch (value.trim().toUpperCase()) {
    case 'ASSIGN':
      return TicketStatus.assign;
    case 'DONE':
      return TicketStatus.done;
    case 'REJECT':
      return TicketStatus.reject;
    default:
      return TicketStatus.waiting;
  }
}

TicketPriority _priorityFromString(String value) {
  switch (value.trim().toUpperCase()) {
    case 'LOW':
      return TicketPriority.low;
    case 'HIGH':
      return TicketPriority.high;
    default:
      return TicketPriority.medium;
  }
}
