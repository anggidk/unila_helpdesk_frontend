class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
}
