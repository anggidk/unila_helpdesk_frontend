import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unila_helpdesk_frontend/core/platform/browser_info.dart';

class AppTheme {
  static const Color unilaBlue = Color(0xFF1E90FF);
  static const Color unilaGold = Color(0xFFFFD700);
  static const Color unilaRed = Color(0xFFFF0000);
  static const Color unilaGreen = Color(0xFF008000);
  static const Color unilaBlack = Color(0xFF000000);

  // Backward-compatible aliases used across existing widgets.
  static const Color navy = unilaBlue;
  static const Color deepBlue = unilaBlack;
  static const Color accentYellow = Color(0xFFFFD700);
  static const Color accentBlue = unilaBlue;
  static const Color birutua = Color(0xFF00008B);
  static const Color surface = Color(0xFFF6F8FB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color outline = Color(0xFFE2E8F0);
  static const Color success = unilaGreen;
  static const Color warning = Color(0xFFFFA500);
  static const Color danger = unilaRed;

  static const PageTransitionsTheme _noWebRouteTransitions =
      PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.iOS: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _NoAnimationPageTransitionsBuilder(),
        },
      );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: unilaBlue,
      secondary: unilaGold,
      surface: surface,
      error: danger,
    ),
    scaffoldBackgroundColor: surface,
    textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: outline),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: navy, width: 1.4),
      ),
      labelStyle: const TextStyle(color: textMuted),
      hintStyle: const TextStyle(color: textMuted),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: accentBlue.withValues(alpha: 0.15),
      secondarySelectedColor: accentBlue.withValues(alpha: 0.15),
      labelStyle: const TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: outline),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: navy,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        side: const BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: const Color(0xFF0C4A6E),
      contentTextStyle: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    // Safari iOS (web) melaporkan transisi route tampil ganda.
    // Menonaktifkan page transition hanya untuk Safari iOS.
    pageTransitionsTheme: isSafariIOSWeb
        ? _noWebRouteTransitions
        : const PageTransitionsTheme(),
  );
}

class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
