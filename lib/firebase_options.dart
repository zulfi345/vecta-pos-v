// File konfigurasi Firebase otomatis untuk build APK
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForBuild123456789',
    appId: '1:123456789:android:123456789',
    messagingSenderId: '123456789',
    projectId: 'vecta-pos',
    storageBucket: 'vecta-pos.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForBuild123456789',
    appId: '1:123456789:ios:123456789',
    messagingSenderId: '123456789',
    projectId: 'vecta-pos',
    storageBucket: 'vecta-pos.appspot.com',
  );
}
