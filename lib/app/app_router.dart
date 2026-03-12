import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/core/models/survey_models.dart';
import 'package:unila_helpdesk_frontend/core/models/ticket_models.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/token_storage.dart';
import 'package:unila_helpdesk_frontend/features/admin/presentation/admin_shell.dart';
import 'package:unila_helpdesk_frontend/features/auth/presentation/boot_page.dart';
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
  static const boot = '/';
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
  static const boot = 'boot';
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

enum _RouteAccess {
  public,
  loggedOutOnly,
  registeredOnly,
  adminOnly,
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.boot,
  routes: [
    GoRoute(
      path: AppRoutes.boot,
      name: AppRouteNames.boot,
      builder: (context, state) => const BootPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: AppRouteNames.login,
      builder: (context, state) => const _RouteGuard(
        access: _RouteAccess.loggedOutOnly,
        child: LoginPage(),
      ),
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
      builder: (context, state) => const _RouteGuard(
        access: _RouteAccess.registeredOnly,
        child: UserShell(),
      ),
    ),
    GoRoute(
      path: AppRoutes.admin,
      name: AppRouteNames.admin,
      builder: (context, state) => const _RouteGuard(
        access: _RouteAccess.adminOnly,
        child: AdminShell(),
      ),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      name: AppRouteNames.notifications,
      builder: (context, state) => _RouteGuard(
        access: _RouteAccess.registeredOnly,
        child: NotificationsPage(
          initialTicketId: state.uri.queryParameters['ticketId'],
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.tickets,
      name: AppRouteNames.tickets,
      builder: (context, state) => const _RouteGuard(
        access: _RouteAccess.registeredOnly,
        child: TicketListPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.ticketForm,
      name: AppRouteNames.ticketForm,
      builder: (context, state) {
        final existing = state.extra is Ticket ? state.extra as Ticket : null;
        return _RouteGuard(
          access: _RouteAccess.registeredOnly,
          child: TicketFormPage(existing: existing),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.ticketDetail,
      name: AppRouteNames.ticketDetail,
      builder: (context, state) {
        final ticket = state.extra is Ticket ? state.extra as Ticket : null;
        if (ticket == null) {
          return const _MissingDataPage(message: 'Data tiket tidak ditemukan.');
        }
        return _RouteGuard(
          access: _RouteAccess.registeredOnly,
          child: TicketDetailPage(ticket: ticket),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.survey,
      name: AppRouteNames.survey,
      builder: (context, state) {
        final payload = state.extra is SurveyPayload
            ? state.extra as SurveyPayload
            : null;
        if (payload == null) {
          return const _MissingDataPage(
            message: 'Data survey tidak ditemukan.',
          );
        }
        return _RouteGuard(
          access: _RouteAccess.registeredOnly,
          child: SurveyPage(ticket: payload.ticket, template: payload.template),
        );
      },
    ),
  ],
);

class _RouteGuard extends StatefulWidget {
  const _RouteGuard({required this.access, required this.child});

  final _RouteAccess access;
  final Widget child;

  @override
  State<_RouteGuard> createState() => _RouteGuardState();
}

class _RouteGuardState extends State<_RouteGuard> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveAccess());
  }

  Future<void> _resolveAccess() async {
    final hasSession = await TokenStorage().hasActiveSession(
      requireStoredExpiry: kIsWeb,
    );
    final token = await TokenStorage().readToken();
    final user = await TokenStorage().readUser();
    if (!mounted) return;

    final hasResolvedSession =
        hasSession && token != null && token.isNotEmpty && user != null;
    sharedApiClient.setAuthToken(hasResolvedSession ? token : null);

    final redirectName = _redirectFor(user, hasResolvedSession);
    if (redirectName != null) {
      context.goNamed(redirectName);
      return;
    }

    setState(() => _checking = false);
  }

  String? _redirectFor(UserProfile? user, bool hasSession) {
    switch (widget.access) {
      case _RouteAccess.public:
        return null;
      case _RouteAccess.loggedOutOnly:
        if (!hasSession || user == null) return null;
        return user.role == UserRole.admin
            ? AppRouteNames.admin
            : AppRouteNames.userShell;
      case _RouteAccess.registeredOnly:
        if (!hasSession || user == null) {
          return AppRouteNames.login;
        }
        if (user.role == UserRole.admin) {
          return AppRouteNames.admin;
        }
        return null;
      case _RouteAccess.adminOnly:
        if (!hasSession || user == null) {
          return AppRouteNames.login;
        }
        if (user.role != UserRole.admin) {
          return AppRouteNames.userShell;
        }
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.child;
  }
}

class _MissingDataPage extends StatelessWidget {
  const _MissingDataPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kesalahan')),
      body: Center(child: Text(message)),
    );
  }
}
