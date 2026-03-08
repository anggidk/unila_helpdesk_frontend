import 'package:flutter/material.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';

IconData iconForTicketCategory(String categoryId) {
  switch (categoryId) {
    case '1':
    case '2':
    case '3':
      return Icons.verified_user_outlined;
    case '4':
      return Icons.wifi;
    case '5':
      return Icons.language;
    case '6':
      return Icons.apps_outlined;
    case '7':
      return Icons.school_outlined;
    case '99':
      return Icons.support_agent_outlined;
  }
  return Icons.support_agent_outlined;
}

Color colorForTicketCategory(String categoryId) {
  switch (categoryId) {
    case '1':
    case '2':
    case '3':
      return AppTheme.unilaBlack;
    case '4':
      return AppTheme.accentBlue;
    case '5':
      return AppTheme.warning;
    case '6':
      return AppTheme.success;
    case '7':
      return AppTheme.danger;
    case '99':
      return AppTheme.textMuted;
  }
  return AppTheme.textMuted;
}
