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

  // STUB VALUES — replace by running `flutterfire configure`
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_REAL_KEY',
    appId: 'REPLACE_WITH_REAL_APP_ID',
    messagingSenderId: 'REPLACE_WITH_REAL_SENDER_ID',
    projectId: 'iwannareadthebiblemore',
    storageBucket: 'iwannareadthebiblemore.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_REAL_KEY',
    appId: 'REPLACE_WITH_REAL_APP_ID',
    messagingSenderId: 'REPLACE_WITH_REAL_SENDER_ID',
    projectId: 'iwannareadthebiblemore',
    storageBucket: 'iwannareadthebiblemore.appspot.com',
    iosClientId: 'REPLACE_WITH_REAL_IOS_CLIENT_ID',
    iosBundleId: 'com.iwannareadthebiblemore.app',
  );
}
