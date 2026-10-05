import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Sannidhi application.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD9eAhIGCkp6WjXhClE2ivJTVYiFS0xPgk',
    appId: '1:482970667835:android:653b196caffdf42aa2851e',
    messagingSenderId: '482970667835',
    projectId: 'sannidhi-79ea7',
    authDomain: 'sannidhi-79ea7.firebaseapp.com',
    storageBucket: 'sannidhi-79ea7.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD9eAhIGCkp6WjXhClE2ivJTVYiFS0xPgk',
    appId: '1:482970667835:android:653b196caffdf42aa2851e',
    messagingSenderId: '482970667835',
    projectId: 'sannidhi-79ea7',
    storageBucket: 'sannidhi-79ea7.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyClr7Q4CJpxaKI5OJEu2CRwop-Z5v-tO8s',
    appId: '1:482970667835:ios:848ab0122c4fdb43a2851e',
    messagingSenderId: '482970667835',
    projectId: 'sannidhi-79ea7',
    storageBucket: 'sannidhi-79ea7.firebasestorage.app',
    iosClientId:
        '482970667835-vht8l6snubsj8fb1c0vbvk1mao31iimr.apps.googleusercontent.com',
    iosBundleId: 'com.company.sannidhi',
  );
}
