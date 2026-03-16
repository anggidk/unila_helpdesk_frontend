import 'package:flutter/material.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';

enum AppFeedbackTone { success, error, info, warning }

void showAppFeedbackSnackBar(
  BuildContext context, {
  required String message,
  AppFeedbackTone tone = AppFeedbackTone.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      duration: duration,
      margin: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      content: _AppFeedbackSnackBarContent(message: message, tone: tone),
    ),
  );
}

class _AppFeedbackSnackBarContent extends StatelessWidget {
  const _AppFeedbackSnackBarContent({
    required this.message,
    required this.tone,
  });

  final String message;
  final AppFeedbackTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = _feedbackScheme(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(scheme.icon, color: scheme.foreground, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: scheme.foreground,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

_AppFeedbackScheme _feedbackScheme(AppFeedbackTone tone) {
  switch (tone) {
    case AppFeedbackTone.success:
      return const _AppFeedbackScheme(
        background: Color(0xFF0F5132),
        border: Color(0xFF198754),
        foreground: Colors.white,
        icon: Icons.check_circle_rounded,
      );
    case AppFeedbackTone.error:
      return const _AppFeedbackScheme(
        background: Color(0xFF7A1321),
        border: AppTheme.danger,
        foreground: Colors.white,
        icon: Icons.error_rounded,
      );
    case AppFeedbackTone.warning:
      return const _AppFeedbackScheme(
        background: Color(0xFF744210),
        border: Color(0xFFD97706),
        foreground: Colors.white,
        icon: Icons.warning_amber_rounded,
      );
    case AppFeedbackTone.info:
      return const _AppFeedbackScheme(
        background: Color(0xFF0C4A6E),
        border: AppTheme.navy,
        foreground: Colors.white,
        icon: Icons.info_rounded,
      );
  }
}

class _AppFeedbackScheme {
  const _AppFeedbackScheme({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
}
