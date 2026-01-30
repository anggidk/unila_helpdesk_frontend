import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/core/mock/mock_data.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/features/admin/presentation/admin_shell.dart';
import 'package:unila_helpdesk_frontend/features/auth/presentation/login_page.dart';
import 'package:unila_helpdesk_frontend/features/feedback/presentation/survey_page.dart';
import 'package:unila_helpdesk_frontend/features/guest/presentation/guest_ticket_form_page.dart';
import 'package:unila_helpdesk_frontend/features/guest/presentation/guest_tracking_page.dart';
import 'package:unila_helpdesk_frontend/features/notifications/presentation/notifications_page.dart';
import 'package:unila_helpdesk_frontend/features/tickets/presentation/ticket_detail_page.dart';
import 'package:unila_helpdesk_frontend/features/tickets/presentation/ticket_list_page.dart';
import 'package:unila_helpdesk_frontend/features/tickets/presentation/ticket_form_page.dart';
import 'package:unila_helpdesk_frontend/features/user/presentation/user_shell.dart';

class AppRoutes {
  static const login = '/login';
  static const guestTracking = '/guest-tracking';
  static const guestTicket = '/guest-ticket';
  static const userShell = '/user';
  static const admin = '/admin';
  static const notifications = '/notifications';
  static const tickets = '/tickets';
  static const ticketForm = '/ticket-form';
  static const ticketDetail = '/ticket-detail';
  static const survey = '/survey';
}

class AppRouteNames {
  static const login = 'login';
  static const guestTracking = 'guestTracking';
  static const guestTicket = 'guestTicket';
  static const userShell = 'userShell';
  static const admin = 'admin';
  static const notifications = 'notifications';
  static const tickets = 'tickets';
  static const ticketForm = 'ticketForm';
  static const ticketDetail = 'ticketDetail';
  static const survey = 'survey';
}

class SurveyPayload {
  const SurveyPayload({required this.ticket, required this.template});

  final Ticket ticket;
  final SurveyTemplate template;
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      name: AppRouteNames.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.guestTracking,
      name: AppRouteNames.guestTracking,
      builder: (context, state) => const GuestTrackingPage(),
    ),
    GoRoute(
      path: AppRoutes.guestTicket,
      name: AppRouteNames.guestTicket,
      builder: (context, state) => const GuestTicketFormPage(),
    ),
    GoRoute(
      path: AppRoutes.userShell,
      name: AppRouteNames.userShell,
      builder: (context, state) {
        final user = state.extra is UserProfile ? state.extra as UserProfile : MockData.registeredUser;
        return UserShell(user: user);
      },
    ),
    GoRoute(
      path: AppRoutes.admin,
      name: AppRouteNames.admin,
      builder: (context, state) => const AdminShell(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      name: AppRouteNames.notifications,
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: AppRoutes.tickets,
      name: AppRouteNames.tickets,
      builder: (context, state) {
        final user = state.extra is UserProfile ? state.extra as UserProfile : MockData.registeredUser;
        return TicketListPage(user: user);
      },
    ),
    GoRoute(
      path: AppRoutes.ticketForm,
      name: AppRouteNames.ticketForm,
      builder: (context, state) {
        final existing = state.extra is Ticket ? state.extra as Ticket : null;
        return TicketFormPage(existing: existing);
      },
    ),
    GoRoute(
      path: AppRoutes.ticketDetail,
      name: AppRouteNames.ticketDetail,
      builder: (context, state) {
        final ticket = state.extra is Ticket ? state.extra as Ticket : MockData.tickets.first;
        return TicketDetailPage(ticket: ticket);
      },
    ),
    GoRoute(
      path: AppRoutes.survey,
      name: AppRouteNames.survey,
      builder: (context, state) {
        final payload = state.extra as SurveyPayload;
        return SurveyPage(ticket: payload.ticket, template: payload.template);
      },
    ),
  ],
);
