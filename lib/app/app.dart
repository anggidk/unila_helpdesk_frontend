import 'package:flutter/material.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';

class HelpdeskApp extends StatelessWidget {
  const HelpdeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Helpdesk Unila',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
