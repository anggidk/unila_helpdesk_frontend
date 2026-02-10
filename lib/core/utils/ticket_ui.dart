import 'package:flutter/material.dart';

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
      return const Color(0xFF1E88E5); // Internet
    case 'CAT002':
      return const Color(0xFF3949AB); // SIAKAD
    case 'CAT003':
      return const Color(0xFF00897B); // Website
    case 'CAT004':
      return const Color(0xFFEF6C00); // Sistem Informasi
    case 'CAT005':
      return const Color(0xFF546E7A); // Lainnya
    case 'GST001':
    case 'GST002':
      return const Color(0xFFC62828); // SSO/Akun
    case 'GST003':
      return const Color(0xFF00ACC1); // Registrasi Email
  }
  return const Color(0xFF607D8B);
}
