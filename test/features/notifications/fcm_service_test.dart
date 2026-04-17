import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/notifications/data/services/fcm_service.dart';
import 'package:mocktail/mocktail.dart';

// Alias firebase_messaging's NotificationSettings to avoid name clash with
// our app's NotificationSettings class if it were imported here.
import 'package:firebase_messaging/firebase_messaging.dart' as fm
    show NotificationSettings;

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

fm.NotificationSettings _authorizedSettings() {
  return const fm.NotificationSettings(
    authorizationStatus: AuthorizationStatus.authorized,
    alert: AppleNotificationSetting.enabled,
    announcement: AppleNotificationSetting.disabled,
    badge: AppleNotificationSetting.enabled,
    carPlay: AppleNotificationSetting.disabled,
    lockScreen: AppleNotificationSetting.enabled,
    notificationCenter: AppleNotificationSetting.enabled,
    showPreviews: AppleShowPreviewSetting.always,
    timeSensitive: AppleNotificationSetting.disabled,
    criticalAlert: AppleNotificationSetting.disabled,
    sound: AppleNotificationSetting.enabled,
  );
}

/// Builds an [FcmService] with controlled/empty streams so no platform
/// channel is invoked in tests.
FcmService _buildService({
  required MockFirebaseMessaging messaging,
  required FakeFirebaseFirestore firestore,
  Stream<RemoteMessage>? onMessage,
  Stream<RemoteMessage>? onMessageOpenedApp,
}) {
  return FcmService(
    messaging: messaging,
    firestore: firestore,
    onMessageStream: onMessage ?? const Stream.empty(),
    onMessageOpenedAppStream: onMessageOpenedApp ?? const Stream.empty(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseMessaging mockMessaging;
  late FakeFirebaseFirestore fakeFirestore;
  late FcmService fcmService;

  setUp(() {
    mockMessaging = MockFirebaseMessaging();
    fakeFirestore = FakeFirebaseFirestore();
    fcmService = _buildService(
      messaging: mockMessaging,
      firestore: fakeFirestore,
    );
  });

  group('FcmService', () {
    test('requestPermission is called on initialise', () async {
      when(() => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
          )).thenAnswer((_) async => _authorizedSettings());

      when(() => mockMessaging.getToken())
          .thenAnswer((_) async => 'test-fcm-token-abc123');

      when(() => mockMessaging.onTokenRefresh)
          .thenAnswer((_) => const Stream.empty());

      when(() => mockMessaging.getInitialMessage())
          .thenAnswer((_) async => null);

      await fcmService.initialise('user-123');

      verify(() => mockMessaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          )).called(1);
    });

    test('FCM token is saved to Firestore /users/{uid}.fcmToken', () async {
      when(() => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
          )).thenAnswer((_) async => _authorizedSettings());

      when(() => mockMessaging.getToken())
          .thenAnswer((_) async => 'saved-token-xyz');

      when(() => mockMessaging.onTokenRefresh)
          .thenAnswer((_) => const Stream.empty());

      when(() => mockMessaging.getInitialMessage())
          .thenAnswer((_) async => null);

      await fcmService.initialise('user-456');

      final doc =
          await fakeFirestore.collection('users').doc('user-456').get();
      expect(doc.data()?['fcmToken'], equals('saved-token-xyz'));
    });

    test('foreground handler is invoked when a message arrives on the stream',
        () async {
      final controller = StreamController<RemoteMessage>.broadcast();
      final service = _buildService(
        messaging: mockMessaging,
        firestore: fakeFirestore,
        onMessage: controller.stream,
      );

      when(() => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
          )).thenAnswer((_) async => _authorizedSettings());
      when(() => mockMessaging.getToken()).thenAnswer((_) async => null);
      when(() => mockMessaging.onTokenRefresh)
          .thenAnswer((_) => const Stream.empty());
      when(() => mockMessaging.getInitialMessage())
          .thenAnswer((_) async => null);

      var invokedWith;
      service.onForegroundMessage = (msg) => invokedWith = msg;

      await service.initialise('user-789');

      final testMessage = RemoteMessage(
        notification:
            const RemoteNotification(title: 'Hello', body: 'World'),
        data: {'type': 'daily_reminder'},
      );
      controller.add(testMessage);
      await Future.delayed(Duration.zero);

      expect(invokedWith, equals(testMessage));
      await controller.close();
    });

    test('onForegroundMessage callback can be set and called directly', () {
      var called = false;
      fcmService.onForegroundMessage = (_) => called = true;

      fcmService.onForegroundMessage!(
        RemoteMessage(
          notification: const RemoteNotification(title: 'T', body: 'B'),
          data: {'type': 'milestone'},
        ),
      );
      expect(called, isTrue);
    });

    test('navigatorKey can be set and retrieved', () {
      final key = GlobalKey<NavigatorState>();
      fcmService.navigatorKey = key;
      expect(fcmService.navigatorKey, equals(key));
    });

    test('FcmService can be constructed with real dependencies', () {
      expect(fcmService, isNotNull);
      expect(fcmService.onForegroundMessage, isNull);
      expect(fcmService.navigatorKey, isNull);
    });
  });
}
