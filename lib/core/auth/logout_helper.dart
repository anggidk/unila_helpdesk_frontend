import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/features/auth/data/auth_repository.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/token_storage.dart';
import 'package:unila_helpdesk_frontend/core/notifications/fcm_service.dart';

Future<void> performLogout(WidgetRef ref) async {
  final refreshToken = await TokenStorage().readRefreshToken();
  if (refreshToken != null && refreshToken.isNotEmpty) {
    try {
      await AuthRepository().logout(refreshToken: refreshToken);
    } catch (_) {
      // Ignore revoke failure and continue local logout.
    }
  }
  await FcmService.unregisterCurrentToken();
  FcmService.markNavigationUnavailable();
  await TokenStorage().clearToken();
  sharedApiClient.setAuthToken(null);
  ref.read(adminUserProvider.notifier).state = null;
  ref.read(currentUserProvider.notifier).state = null;
  ref.invalidate(ticketsProvider);
  ref.invalidate(notificationsProvider);
}
