import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
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
      FcmService.markNavigationUnavailable();
      if (!mounted) return;
      context.goNamed(AppRouteNames.login);
      return;
    }

    sharedApiClient.setAuthToken(token);
    if (user.role == UserRole.admin) {
      ref.read(adminUserProvider.notifier).state = user;
      ref.read(currentUserProvider.notifier).state = null;
    } else {
      ref.read(adminUserProvider.notifier).state = null;
      ref.read(currentUserProvider.notifier).state = user;
    }
    await FcmService.syncToken();
    ref.invalidate(ticketsProvider);
    ref.invalidate(notificationsProvider);
    if (!mounted) return;
    if (user.role == UserRole.admin) {
      context.goNamed(AppRouteNames.admin);
    } else {
      context.goNamed(AppRouteNames.userShell);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo/Logo_unila.png',
                width: 110,
                height: 110,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.surface,
                    child: Icon(Icons.school, size: 48, color: AppTheme.navy),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'HELPDESK UNILA',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Layanan Bantuan TI Unila',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
