import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
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
    apiKey: 'AIzaSyA6tGmED8Kj-H9S4bgMBxL_baORWMmyNUE',
    authDomain: 'iwannareadthebiblemore.firebaseapp.com',
    projectId: 'iwannareadthebiblemore',
    storageBucket: 'iwannareadthebiblemore.firebasestorage.app',
    messagingSenderId: '115353396036',
    appId: '1:115353396036:web:c5c9773dfad45e1bbb6d11',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA6tGmED8Kj-H9S4bgMBxL_baORWMmyNUE',
    appId: '1:115353396036:android:c5c9773dfad45e1bbb6d11',
    messagingSenderId: '115353396036',
    projectId: 'iwannareadthebiblemore',
    storageBucket: 'iwannareadthebiblemore.firebasestorage.app',
  );

  // STUB VALUES — replace by running `flutterfire configure`

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDAh8wKkifARD9YTZIxHAtVPqtxWvkryVs',
    appId: '1:115353396036:ios:527edb0844a5ac2ebb6d11',
    messagingSenderId: '115353396036',
    projectId: 'iwannareadthebiblemore',
    storageBucket: 'iwannareadthebiblemore.firebasestorage.app',
    androidClientId: '115353396036-2j3bau7hpals07kg5vdieovb787kirfs.apps.googleusercontent.com',
    iosClientId: '115353396036-i8oasfrm5adus5pmkkgoo1uc752qt75i.apps.googleusercontent.com',
    iosBundleId: 'com.iwannareadthebiblemore.iwannareadthebiblemore',
  );

}