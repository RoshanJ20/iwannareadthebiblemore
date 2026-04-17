import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/notification_type.dart';
import '../../domain/entities/app_notification.dart';
import '../repositories/firestore_notification_repository.dart';

/// Top-level background message handler — must be a top-level function,
/// not a class member, as required by `firebase_messaging`.
///
/// Registered in `main.dart` before `runApp()`. Do NOT call from
/// [FcmService.initialise] because the platform channel is unavailable in
/// test environments.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] background message: ${message.messageId}');
}

/// Service that owns the FCM lifecycle:
/// - requests permissions
/// - registers / refreshes the device token in Firestore
/// - routes foreground messages to an in-app banner
/// - routes notification-tap events to the correct screen
class FcmService {
  FcmService({
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
    /// Optional: injectable message streams for testing.
    Stream<RemoteMessage>? onMessageStream,
    Stream<RemoteMessage>? onMessageOpenedAppStream,
  })  : _messaging = messaging,
        _firestore = firestore,
        _notificationRepo = FirestoreNotificationRepository(firestore),
        _onMessageStream =
            onMessageStream ?? FirebaseMessaging.onMessage,
        _onMessageOpenedAppStream =
            onMessageOpenedAppStream ?? FirebaseMessaging.onMessageOpenedApp;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirestoreNotificationRepository _notificationRepo;
  final Stream<RemoteMessage> _onMessageStream;
  final Stream<RemoteMessage> _onMessageOpenedAppStream;

  /// Callback invoked when a foreground message arrives, so the UI layer can
  /// display a banner.  Set this before calling [initialise].
  void Function(RemoteMessage message)? onForegroundMessage;

  /// GoRouter navigator key used for programmatic navigation on notification
  /// tap.
  GlobalKey<NavigatorState>? navigatorKey;

  // ─── Initialisation ──────────────────────────────────────────────────────

  /// Call once, after Firebase.initializeApp().
  ///
  /// Note: [FirebaseMessaging.onBackgroundMessage] is registered in
  /// `main.dart` before `runApp()`, not here, because it must be a top-level
  /// call made before the isolate starts. Calling it here in tests would
  /// require a running platform channel.
  Future<void> initialise(String userId) async {
    // Request permissions (iOS + Android 13+).
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] permission: ${settings.authorizationStatus}');

    // Persist initial token.
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(userId, token);
    }

    // Refresh token automatically.
    _messaging.onTokenRefresh.listen((newToken) {
      _saveToken(userId, newToken);
    });

    // Foreground messages.
    _onMessageStream.listen((message) {
      debugPrint('[FCM] foreground: ${message.notification?.title}');
      onForegroundMessage?.call(message);
      _persistNotification(userId, message);
    });

    // App opened from background via notification tap.
    _onMessageOpenedAppStream.listen((message) {
      debugPrint('[FCM] opened from background: ${message.notification?.title}');
      _handleNavigationForMessage(message);
    });

    // App opened from terminated state via notification tap.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
          '[FCM] opened from terminated: ${initialMessage.notification?.title}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNavigationForMessage(initialMessage);
      });
    }
  }

  // ─── Topic subscriptions ─────────────────────────────────────────────────

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('[FCM] subscribed to $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('[FCM] unsubscribed from $topic');
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  Future<void> _saveToken(String userId, String token) async {
    await _firestore.collection('users').doc(userId).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
    debugPrint('[FCM] token saved for $userId');
  }

  Future<void> _persistNotification(
    String userId,
    RemoteMessage message,
  ) async {
    final typeStr = message.data['type'] as String?;
    final type = NotificationType.fromValue(typeStr ?? '') ??
        NotificationType.dailyReminder;

    final notification = AppNotification(
      id: message.messageId ?? '',
      type: type,
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      data: Map<String, String>.from(message.data),
      receivedAt: DateTime.now(),
      isRead: false,
    );

    try {
      await _notificationRepo.saveNotification(userId, notification);
    } catch (e) {
      debugPrint('[FCM] failed to persist notification: $e');
    }
  }

  void _handleNavigationForMessage(RemoteMessage message) {
    final context = navigatorKey?.currentContext;
    if (context == null) return;

    final typeStr = message.data['type'] as String?;
    final type = NotificationType.fromValue(typeStr ?? '');
    final groupId = message.data['groupId'] as String?;

    switch (type) {
      case NotificationType.dailyReminder:
      case NotificationType.streakAtRisk:
      case NotificationType.friendNudge:
        GoRouter.of(context).go('/read');
      case NotificationType.groupActivity:
        if (groupId != null) {
          GoRouter.of(context).go('/groups/$groupId');
        } else {
          GoRouter.of(context).go('/groups');
        }
      case NotificationType.milestone:
      case NotificationType.planCompletion:
        GoRouter.of(context).go('/profile');
      case NotificationType.weeklyLeaderboard:
        if (groupId != null) {
          GoRouter.of(context).go('/groups/$groupId');
        } else {
          GoRouter.of(context).go('/groups');
        }
      case null:
        break;
    }
  }
}
