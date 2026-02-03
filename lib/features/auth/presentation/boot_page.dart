import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/token_storage.dart';
import 'package:unila_helpdesk_frontend/core/notifications/fcm_service.dart';

class BootPage extends ConsumerStatefulWidget {
  const BootPage({super.key});

  @override
  ConsumerState<BootPage> createState() => _BootPageState();
}

class _BootPageState extends ConsumerState<BootPage> {
  bool _booting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_booting) return;
    _booting = true;
    final token = await TokenStorage().readToken();
    final user = await TokenStorage().readUser();
    if (token == null || token.isEmpty || user == null) {
      if (!mounted) return;
      context.goNamed(AppRouteNames.login);
      return;
    }

    sharedApiClient.setAuthToken(token);
    if (user.role == UserRole.admin) {
      ref.read(adminUserProvider.notifier).state = user;
    } else {
      ref.read(adminUserProvider.notifier).state = null;
    }
    await FcmService.syncToken();
    ref.invalidate(ticketsProvider);
    ref.invalidate(notificationsProvider);
    if (!mounted) return;
    if (user.role == UserRole.admin) {
      context.goNamed(AppRouteNames.admin);
    } else {
      context.goNamed(AppRouteNames.userShell, extra: user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
