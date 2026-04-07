import 'browser_info_stub.dart'
    if (dart.library.html) 'browser_info_web.dart' as impl;

bool get isSafariIOSWeb => impl.isSafariIOSWeb;
