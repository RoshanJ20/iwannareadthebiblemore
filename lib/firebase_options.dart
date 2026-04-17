// GENERATED FILE — DO NOT EDIT
// Replace this file by running: flutterfire configure
// See: https://firebase.flutter.dev/docs/overview
//
// This stub exists to allow the project to compile.
// Run `flutterfire configure` to generate the real version.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // ignore: dead_code
    if (kIsWeb) throw UnsupportedError('Web not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions not configured for ${defaultTargetPlatform.name}. '
          'Run `flutterfire configure` to generate the real firebase_options.dart.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'FIREBASE_ANDROID_API_KEY',
    appId: '1:115353396036:android:c5c9773dfad45e1bbb6d11',
    messagingSenderId: '115353396036',
    projectId: 'iwannareadthebiblemore',
    storageBucket: 'iwannareadthebiblemore.firebasestorage.app',
  );

  // STUB VALUES — replace by running `flutterfire configure`

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'FIREBASE_IOS_API_KEY',
    appId: '1:115353396036:ios:527edb0844a5ac2ebb6d11',
    messagingSenderId: '115353396036',
    projectId: 'iwannareadthebiblemore',
    storageBucket: 'iwannareadthebiblemore.firebasestorage.app',
    androidClientId: '115353396036-2j3bau7hpals07kg5vdieovb787kirfs.apps.googleusercontent.com',
    iosClientId: '115353396036-i8oasfrm5adus5pmkkgoo1uc752qt75i.apps.googleusercontent.com',
    iosBundleId: 'com.iwannareadthebiblemore.iwannareadthebiblemore',
  );

}