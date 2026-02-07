import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/features/tickets/data/ticket_repository.dart';

Future<bool> openTicketDetailById(String ticketId) async {
  final id = ticketId.trim();
  if (id.isEmpty) return false;
  try {
    final ticket = await TicketRepository().fetchTicketById(id);
    appRouter.pushNamed(
      AppRouteNames.ticketDetail,
      extra: ticket,
    );
    return true;
  } catch (_) {
    return false;
  }
}
