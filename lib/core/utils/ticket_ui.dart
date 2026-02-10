import 'package:flutter/material.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';

IconData iconForTicketCategory(String categoryId) {
  switch (categoryId) {
    case 'CAT001':
      return Icons.wifi;
    case 'CAT002':
      return Icons.school_outlined;
    case 'CAT003':
      return Icons.language;
    case 'CAT004':
      return Icons.apps_outlined;
    case 'CAT005':
      return Icons.support_agent_outlined;
    case 'GST001':
    case 'GST002':
      return Icons.verified_user_outlined;
    case 'GST003':
      return Icons.person_add_alt_1_outlined;
  }
  return Icons.support_agent_outlined;
}

Color colorForTicketCategory(String categoryId) {
  switch (categoryId) {
    case 'CAT001':
      return AppTheme.accentBlue;
    case 'CAT002':
      return AppTheme.warning;
    case 'CAT003':
      return AppTheme.success;
    case 'CAT004':
      return AppTheme.danger;
    case 'CAT005':
      return AppTheme.textMuted;
    case 'GST001':
    case 'GST002':
      return AppTheme.unilaBlack;
    case 'GST003':
      return AppTheme.accentYellow;
  }
  return AppTheme.textMuted;
}
