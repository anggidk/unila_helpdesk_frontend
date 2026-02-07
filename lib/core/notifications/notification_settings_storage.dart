import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationSettingsStorage {
  NotificationSettingsStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _pushEnabledKey = 'push_notifications_enabled';
  final FlutterSecureStorage _storage;

  Future<bool> readPushEnabled() async {
    final value = await _storage.read(key: _pushEnabledKey);
    if (value == null || value.isEmpty) return true;
    return value == 'true';
  }

  Future<void> savePushEnabled(bool enabled) {
    return _storage.write(
      key: _pushEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }
}
