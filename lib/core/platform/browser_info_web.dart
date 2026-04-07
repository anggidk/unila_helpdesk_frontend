// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

bool get isSafariIOSWeb {
  final ua = html.window.navigator.userAgent.toLowerCase();
  final isIOS =
      ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
  final isSafari = ua.contains('safari');
  final isOtherIOSBrowser =
      ua.contains('crios') ||
      ua.contains('fxios') ||
      ua.contains('edgios') ||
      ua.contains('opios');

  return isIOS && isSafari && !isOtherIOSBrowser;
}
