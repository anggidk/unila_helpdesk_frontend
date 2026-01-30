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
  });

  final String id;
  final String name;
  final bool guestAllowed;
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
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.reporter,
    required this.isGuest,
    required this.history,
    required this.comments,
    this.assignee,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final TicketStatus status;
  final TicketPriority priority;
  final DateTime createdAt;
  final String reporter;
  final bool isGuest;
  final String? assignee;
  final List<TicketUpdate> history;
  final List<TicketComment> comments;

  bool get isResolved => status == TicketStatus.resolved;
}
