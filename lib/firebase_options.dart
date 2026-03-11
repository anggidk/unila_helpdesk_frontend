import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'FirebaseOptions belum dikonfigurasi untuk platform ini.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBy4sE8Xy26wvZZfiSRwPmwgpNAGWWOzNM',
    appId: '1:1063618731673:web:e9871b789bba454efba208',
    messagingSenderId: '1063618731673',
    projectId: 'helpdesk-unila',
    authDomain: 'helpdesk-unila.firebaseapp.com',
    storageBucket: 'helpdesk-unila.firebasestorage.app',
    measurementId: 'G-KKWL63MHFC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCgt4F07aqqN0_Io9RJyytoteHKt0W9KTE',
    appId: '1:1063618731673:android:3d16d93ae5fc2adafba208',
    messagingSenderId: '1063618731673',
    projectId: 'helpdesk-unila',
    storageBucket: 'helpdesk-unila.firebasestorage.app',
  );
}
