import 'package:flutter/material.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';

List<Widget> buildStarIcons(double score, {double size = 24}) {
  final clamped = score.clamp(0, 5).toDouble();
  final fullStars = clamped.floor();
  final hasHalf = (clamped - fullStars) >= 0.5;
  final emptyStars = 5 - fullStars - (hasHalf ? 1 : 0);
  final stars = <Widget>[];

  for (var i = 0; i < fullStars; i++) {
    stars.add(Icon(Icons.star, color: AppTheme.accentYellow, size: size));
  }
  if (hasHalf) {
    stars.add(Icon(Icons.star_half, color: AppTheme.accentYellow, size: size));
  }
  for (var i = 0; i < emptyStars; i++) {
    stars.add(Icon(Icons.star_border, color: AppTheme.textMuted, size: size));
  }

  return stars;
}
