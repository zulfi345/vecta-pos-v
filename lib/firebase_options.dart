import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Platform tidak didukung');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCBcF3tLcNiQX9rpFMqw7lBKEQ6UAgWLVQ',
    appId: '1:278717955661:android:98eebc382580800416e604',
    messagingSenderId: '278717955661',
    projectId: 'vecta-pos',
    storageBucket: 'vecta-pos.firebasestorage.app',
  );
}
