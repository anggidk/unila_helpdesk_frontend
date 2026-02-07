const Duration _wibOffset = Duration(hours: 7);

String formatDate(DateTime date) {
  final normalized = date.toUtc().add(_wibOffset);
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  final month = months[normalized.month - 1];
  return '${normalized.day} $month ${normalized.year}';
}

String formatTime(DateTime date) {
  final normalized = date.toUtc().add(_wibOffset);
  final hour = normalized.hour.toString().padLeft(2, '0');
  final minute = normalized.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatDateTime(DateTime date) => '${formatDate(date)}, ${formatTime(date)}';
