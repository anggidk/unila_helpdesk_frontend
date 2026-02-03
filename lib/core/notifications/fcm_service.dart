import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/features/notifications/data/notification_repository.dart';
import 'package:unila_helpdesk_frontend/features/tickets/data/ticket_repository.dart';

const String fcmChannelId = 'helpdesk_updates';
const String fcmChannelName = 'Helpdesk Updates';
const String fcmChannelDescription = 'Notifikasi status tiket dan survey';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

class FcmService {
  static bool _initialized = false;
  static bool _navigationReady = false;
  static String? _pendingTicketId;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (_) {
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _setupLocalNotifications();
    await _requestPermissions();
    await _registerToken();

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    FirebaseMessaging.instance.onTokenRefresh.listen(_registerTokenFromStream);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    _initialized = true;
  }

  static void markNavigationReady() {
    _navigationReady = true;
    final pending = _pendingTicketId;
    if (pending != null && pending.isNotEmpty) {
      _pendingTicketId = null;
      _handleTicketNavigation(pending);
    }
  }

  static Future<void> syncToken() async {
    if (!_initialized) {
      await initialize();
      return;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    await _sendToken(token);
  }

  static Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> _setupLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        _handleTicketNavigation(payload);
      },
    );
    const channel = AndroidNotificationChannel(
      fcmChannelId,
      fcmChannelName,
      description: fcmChannelDescription,
      importance: Importance.high,
    );
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  static Future<void> _registerToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    await _sendToken(token);
  }

  static Future<void> _registerTokenFromStream(String token) async {
    if (token.isEmpty) return;
    await _sendToken(token);
  }

  static Future<void> _sendToken(String token) async {
    try {
      await NotificationRepository().registerFcmToken(token);
    } catch (_) {
      // Ignore registration failure (e.g. user not logged in).
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if (title == null && body == null) return;
    final ticketId = message.data['ticket_id']?.toString();

    const androidDetails = AndroidNotificationDetails(
      fcmChannelId,
      fcmChannelName,
      channelDescription: fcmChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      message.hashCode,
      title ?? 'Helpdesk',
      body ?? '',
      details,
      payload: ticketId,
    );
  }

  static void _handleMessageTap(RemoteMessage message) {
    final ticketId = message.data['ticket_id']?.toString();
    if (ticketId == null || ticketId.isEmpty) return;
    _handleTicketNavigation(ticketId);
  }

  static void _handleTicketNavigation(String ticketId) {
    if (!_navigationReady) {
      _pendingTicketId = ticketId;
      return;
    }
    _openTicketById(ticketId);
  }

  static Future<void> _openTicketById(String ticketId) async {
    try {
      final ticket = await TicketRepository().fetchTicketById(ticketId);
      appRouter.pushNamed(
        AppRouteNames.ticketDetail,
        extra: ticket,
      );
    } catch (_) {
      // Ignore if user is not authenticated or ticket is missing.
    }
  }
}
