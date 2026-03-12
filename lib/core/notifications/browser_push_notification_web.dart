import 'dart:js_interop';

import 'package:web/web.dart' as web;

const _unilaLogoPath = 'assets/assets/logo/Logo_unila.png';

Future<void> showBrowserNotification({
  required String title,
  required String body,
  String? ticketId,
  void Function(String ticketId)? onTapTicket,
}) async {
  if (web.Notification.permission != 'granted') return;

  final notification = web.Notification(
    title,
    web.NotificationOptions(
      body: body,
      tag: ticketId ?? 'helpdesk-notification',
      icon: _unilaLogoPath,
      badge: _unilaLogoPath,
      requireInteraction: true,
    ),
  );

  notification.onclick = ((web.Event event) {
    event.preventDefault();
    notification.close();
    web.window.focus();
    final value = ticketId?.trim() ?? '';
    if (value.isNotEmpty) {
      onTapTicket?.call(value);
    }
  }).toJS;
}
