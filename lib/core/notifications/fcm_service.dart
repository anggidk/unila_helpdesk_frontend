import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
    FirebaseMessaging.instance.onTokenRefresh.listen(_registerTokenFromStream);

    _initialized = true;
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
    await _localNotifications.initialize(initializationSettings);
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
    );
  }
}
