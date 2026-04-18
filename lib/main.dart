import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/firebase/firebase_module.dart';
import 'features/notifications/data/services/fcm_service.dart';
import 'features/notifications/data/services/local_notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseModule.initialise();
  await Hive.initFlutter();
  await Hive.openBox('settings');

  if (!kIsWeb) {
    await LocalNotificationService.init();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    unawaited(LocalNotificationService.rescheduleFromSaved());
  }

  runApp(const ProviderScope(child: App()));
}
