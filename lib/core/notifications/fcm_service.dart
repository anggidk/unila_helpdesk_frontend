import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:unila_helpdesk_frontend/core/navigation/ticket_navigation.dart';
import 'package:unila_helpdesk_frontend/core/notifications/notification_settings_storage.dart';
import 'package:unila_helpdesk_frontend/features/notifications/data/notification_repository.dart';

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
  static bool _pushEnabled = true;
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
    await _loadPushSetting();
    if (_pushEnabled) {
      await _registerToken();
    } else {
      await FirebaseMessaging.instance.setAutoInitEnabled(false);
    }

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

  static void markNavigationUnavailable() {
    _navigationReady = false;
  }

  static Future<bool> isPushEnabled() async {
    if (!_initialized) {
      await initialize();
    }
    return _pushEnabled;
  }

  static Future<void> setPushEnabled(bool enabled) async {
    if (!_initialized) {
      await initialize();
    }
    _pushEnabled = enabled;
    await NotificationSettingsStorage().savePushEnabled(enabled);
    await FirebaseMessaging.instance.setAutoInitEnabled(enabled);
    if (enabled) {
      await _requestPermissions();
      await syncToken();
      return;
    }
    await unregisterCurrentToken();
  }

  static Future<void> syncToken() async {
    if (!_initialized) {
      await initialize();
      return;
    }
    if (!_pushEnabled) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    await _sendToken(token);
  }

  static Future<void> unregisterCurrentToken() async {
    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await NotificationRepository().unregisterFcmToken(token);
      }
    } catch (_) {
      // Ignore unregister failure during logout.
    } finally {
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {
        // Ignore local token delete failure during logout.
      }
    }
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
    if (!_pushEnabled) return;
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
    if (!_pushEnabled) return;
    final notification = message.notification;
    final ticketId = message.data['ticket_id']?.toString();
    final title = notification?.title ?? message.data['title']?.toString() ?? 'Helpdesk';
    final body =
        notification?.body ??
        message.data['body']?.toString() ??
        (ticketId == null || ticketId.isEmpty
            ? 'Ada pembaruan notifikasi.'
            : 'Ada pembaruan pada tiket $ticketId.');

    const androidDetails = AndroidNotificationDetails(
      fcmChannelId,
      fcmChannelName,
      channelDescription: fcmChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      message.hashCode,
      title,
      body,
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
    await openTicketDetailById(ticketId);
  }

  static Future<void> _loadPushSetting() async {
    _pushEnabled = await NotificationSettingsStorage().readPushEnabled();
  }
}
