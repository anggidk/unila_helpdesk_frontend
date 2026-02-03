import 'package:flutter/material.dart';

IconData iconForTicketCategory(String category) {
  final value = category.toLowerCase();

  if (value.contains('internet') || value.contains('jaringan')) {
    return Icons.wifi;
  }
  if (value.contains('website') || value.contains('web')) {
    return Icons.language;
  }
  if (value.contains('siakad')) {
    return Icons.school_outlined;
  }
  if (value.contains('sistem informasi') || value.contains('sistem') || value.contains('aplikasi')) {
    return Icons.apps_outlined;
  }
  if (value.contains('email')) {
    return Icons.email_outlined;
  }
  if (value.contains('sso') ||
      value.contains('akun') ||
      value.contains('keanggotaan') ||
      value.contains('password')) {
    return Icons.verified_user_outlined;
  }

  return Icons.support_agent_outlined;
}
