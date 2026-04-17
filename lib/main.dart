import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/firebase/firebase_module.dart';
import 'features/notifications/data/services/fcm_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseModule.initialise();
  await Hive.initFlutter();
  await Hive.openBox('settings');

  // Register the background message handler before the app starts.
  // This is a top-level requirement of firebase_messaging.
  // The actual initialisation (permissions, token storage, foreground handler)
  // is deferred to FcmService.initialise(), which is called after the user
  // signs in so we have a uid to store the token against.
  // We still register it here to satisfy the plugin's early-setup contract.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: App()));
}
