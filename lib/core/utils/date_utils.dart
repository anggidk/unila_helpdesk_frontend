import 'timezone_utils.dart';

String formatDate(DateTime date) {
  final normalized = toWib(date);
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
  final normalized = toWib(date);
  final hour = normalized.hour.toString().padLeft(2, '0');
  final minute = normalized.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatDateTime(DateTime date) => '${formatDate(date)}, ${formatTime(date)}';
