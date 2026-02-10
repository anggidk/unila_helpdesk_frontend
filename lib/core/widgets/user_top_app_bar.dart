import 'package:flutter/material.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';

class UserTopAppBar extends AppBar {
  UserTopAppBar({
    super.key,
    required String titleText,
    super.leading,
    super.actions,
    super.bottom,
    bool centerTitle = true,
    bool automaticallyImplyLeading = true,
  }) : super(
         title: Text(titleText),
         centerTitle: centerTitle,
         automaticallyImplyLeading: automaticallyImplyLeading,
         foregroundColor: AppTheme.textPrimary,
         backgroundColor: Colors.white,
         surfaceTintColor: Colors.transparent,
         elevation: 0,
         scrolledUnderElevation: 0,
         flexibleSpace: DecoratedBox(
           decoration: BoxDecoration(
             color: Colors.white,
             border: Border(
               bottom: BorderSide(
                 color: AppTheme.outline.withValues(alpha: 0.85),
               ),
             ),
           ),
         ),
       );
}
