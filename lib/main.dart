import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/app/app.dart';

void main() {
  // Wrap app dengan ProviderScope untuk mengaktifkan Riverpod
  runApp(
    const ProviderScope(
      child: HelpdeskApp(),
    ),
  );
}
