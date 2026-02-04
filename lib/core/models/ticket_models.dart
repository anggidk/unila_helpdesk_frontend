enum TicketStatus { waiting, processing, inProgress, resolved }

extension TicketStatusX on TicketStatus {
  String get label {
    switch (this) {
      case TicketStatus.waiting:
        return 'Menunggu';
      case TicketStatus.processing:
        return 'Diproses';
      case TicketStatus.inProgress:
        return 'Progres';
      case TicketStatus.resolved:
        return 'Selesai';
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

  factory TicketUpdate.fromJson(Map<String, dynamic> json) {
    return TicketUpdate(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
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

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    return TicketComment(
      author: json['author']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      isStaff: json['isStaff'] == true,
    );
  }
}

class Ticket {
  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.categoryId,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.reporter,
    required this.isGuest,
    required this.history,
    required this.comments,
    required this.surveyRequired,
    required this.surveyScore,
    this.assignee,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String categoryId;
  final TicketStatus status;
  final TicketPriority priority;
  final DateTime createdAt;
  final String reporter;
  final bool isGuest;
  final String? assignee;
  final List<TicketUpdate> history;
  final List<TicketComment> comments;
  final bool surveyRequired;
  final double surveyScore;

  bool get isResolved => status == TicketStatus.resolved;

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final history = (json['history'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(TicketUpdate.fromJson)
        .toList();
    final comments = (json['comments'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(TicketComment.fromJson)
        .toList();
    return Ticket(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      status: _statusFromString(json['status']?.toString() ?? ''),
      priority: _priorityFromString(json['priority']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      reporter: json['reporter']?.toString() ?? '',
      isGuest: json['isGuest'] == true,
      assignee: json['assignee']?.toString(),
      history: history,
      comments: comments,
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

TicketStatus _statusFromString(String value) {
  switch (value) {
    case 'processing':
      return TicketStatus.processing;
    case 'inProgress':
      return TicketStatus.inProgress;
    case 'resolved':
      return TicketStatus.resolved;
    default:
      return TicketStatus.waiting;
  }
}

TicketPriority _priorityFromString(String value) {
  switch (value) {
    case 'high':
      return TicketPriority.high;
    case 'low':
      return TicketPriority.low;
    default:
      return TicketPriority.medium;
  }
}
