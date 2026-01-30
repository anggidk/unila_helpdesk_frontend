import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';

class HomeSummary {
  const HomeSummary({
    required this.user,
    required this.activeCount,
    required this.resolvedCount,
    required this.waitingCount,
    required this.recentTickets,
  });

  final UserProfile user;
  final int activeCount;
  final int resolvedCount;
  final int waitingCount;
  final List<Ticket> recentTickets;
}
