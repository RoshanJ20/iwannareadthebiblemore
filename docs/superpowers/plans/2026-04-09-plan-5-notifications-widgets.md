# Notifications & Widgets — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement FCM push notifications (foreground + background), local reminder scheduling, deep-link routing from notifications, and home/lock screen widgets for streak + verse.

**Architecture:** Notification concerns live in `lib/core/notifications/` (FCM service, local notification service, notification router, widget update service) and are wired into `lib/main.dart` at boot time. Feature-layer code (`lib/features/notifications/presentation/`) handles user-facing settings only. Deep-link routing extends the existing `lib/core/navigation/app_router.dart` and `lib/core/navigation/routes.dart` without changing the auth redirect logic.

**Tech Stack:** Flutter/Dart, Riverpod, firebase_messaging, flutter_local_notifications, home_widget, go_router

---

## Prerequisites / codebase state

- Plan 1 is merged; 17 tests pass; `flutter test` is green.
- `pubspec.yaml` already contains `home_widget: ^0.4.1`, `firebase_messaging: ^15.0.0`, `flutter_local_notifications` is NOT yet listed (add in Task 1).
- Existing placeholder: `lib/features/notifications/notifications_placeholder.dart`
- Existing router: `lib/core/navigation/app_router.dart` (StatefulShellRoute with 5 branches)
- Existing routes: `lib/core/navigation/routes.dart` (login, home, read, groups, plans, profile)
- `lib/main.dart`: calls `FirebaseModule.initialise()`, then `runApp`.
- App Group identifier: `group.com.iwannareadthebiblemore`
- Bundle ID (inferred from App Group): `com.iwannareadthebiblemore`

---

## Task 1 — Add flutter_local_notifications + tz to pubspec

**Files:** `pubspec.yaml`

`home_widget: ^0.4.1` is already present. Add the two missing packages.

### Steps

- [ ] Open `pubspec.yaml` and add to the `dependencies` block (after `home_widget`):
  ```yaml
  flutter_local_notifications: ^18.0.0
  timezone: ^0.9.4
  ```
- [ ] Run:
  ```bash
  flutter pub get
  ```
- [ ] Verify output contains no version conflicts. If `flutter_local_notifications` publishes a newer minor, use the latest `^18.x.x`.
- [ ] Run `flutter test` — all 17 tests must still pass.

### Commit

```
git add pubspec.yaml pubspec.lock
git commit -m "chore: add flutter_local_notifications and timezone packages"
```

---

## Task 2 — FCM Service

**Files:**
- `lib/core/notifications/fcm_service.dart` (create)
- `test/core/notifications/fcm_service_test.dart` (create)

### Implementation

`lib/core/notifications/fcm_service.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'local_notification_service.dart';

// IMPORTANT: background handler MUST be a top-level function — not a class method.
// Firebase invokes it in an isolate before Flutter/Riverpod is fully initialised.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Minimal work only — no UI, no Riverpod reads, no Navigator.
  // Data is available in message.data if needed for analytics/logging.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class FCMService {
  FCMService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    LocalNotificationService? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _localNotifications =
            localNotifications ?? LocalNotificationService.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocalNotificationService _localNotifications;

  /// Call once after Firebase.initializeApp() in main().
  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Request notification permission from the OS.
  /// Returns true if granted (or already granted on Android < 13).
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Get the FCM token and persist it to Firestore users/{uid}.fcmToken.
  Future<String?> getTokenAndSave() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(uid, token);
    }
    return token;
  }

  /// Listen for token refreshes (called once during app lifetime).
  void setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((newToken) {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        _saveToken(uid, newToken);
      }
    });
  }

  /// Show a local notification for foreground FCM messages.
  void setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.showImmediateNotification(
          title: notification.title ?? '',
          body: notification.body ?? '',
          payload: _encodePayload(message.data),
        );
      }
    });
  }

  Future<void> _saveToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update({'fcmToken': token});
  }

  String _encodePayload(Map<String, dynamic> data) {
    // Simple key=value encoding; notification_router decodes this.
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }
}
```

### Tests

`test/core/notifications/fcm_service_test.dart`:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/core/notifications/fcm_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}
class MockLocalNotificationService extends Mock
    implements LocalNotificationService {}

void main() {
  late MockFirebaseMessaging mockMessaging;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late FCMService service;

  setUp(() {
    mockMessaging = MockFirebaseMessaging();
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'user-123'),
    );
    service = FCMService(
      messaging: mockMessaging,
      firestore: fakeFirestore,
      auth: mockAuth,
    );
  });

  group('FCMService.getTokenAndSave', () {
    test('saves token to Firestore when user is signed in', () async {
      when(() => mockMessaging.getToken()).thenAnswer((_) async => 'test-token');

      await service.getTokenAndSave();

      final doc =
          await fakeFirestore.collection('users').doc('user-123').get();
      expect(doc.data()?['fcmToken'], equals('test-token'));
    });

    test('returns null when no user is signed in', () async {
      final noAuthService = FCMService(
        messaging: mockMessaging,
        firestore: fakeFirestore,
        auth: MockFirebaseAuth(signedIn: false),
      );

      final result = await noAuthService.getTokenAndSave();

      expect(result, isNull);
    });
  });

  group('FCMService.requestPermission', () {
    test('returns true when authorization granted', () async {
      when(() => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
          )).thenAnswer((_) async => const NotificationSettings(
            authorizationStatus: AuthorizationStatus.authorized,
            alert: AppleNotificationSetting.enabled,
            announcement: AppleNotificationSetting.disabled,
            badge: AppleNotificationSetting.enabled,
            carPlay: AppleNotificationSetting.disabled,
            lockScreen: AppleNotificationSetting.enabled,
            notificationCenter: AppleNotificationSetting.enabled,
            showPreviews: AppleShowPreviewSetting.always,
            sound: AppleNotificationSetting.enabled,
            timeSensitive: AppleNotificationSetting.disabled,
            criticalAlert: AppleNotificationSetting.disabled,
          ));

      final result = await service.requestPermission();

      expect(result, isTrue);
    });

    test('returns false when authorization denied', () async {
      when(() => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
          )).thenAnswer((_) async => const NotificationSettings(
            authorizationStatus: AuthorizationStatus.denied,
            alert: AppleNotificationSetting.disabled,
            announcement: AppleNotificationSetting.disabled,
            badge: AppleNotificationSetting.disabled,
            carPlay: AppleNotificationSetting.disabled,
            lockScreen: AppleNotificationSetting.disabled,
            notificationCenter: AppleNotificationSetting.disabled,
            showPreviews: AppleShowPreviewSetting.never,
            sound: AppleNotificationSetting.disabled,
            timeSensitive: AppleNotificationSetting.disabled,
            criticalAlert: AppleNotificationSetting.disabled,
          ));

      final result = await service.requestPermission();

      expect(result, isFalse);
    });
  });
}
```

### Steps

- [ ] Create directory `lib/core/notifications/`.
- [ ] Create `lib/core/notifications/fcm_service.dart` with the code above.
- [ ] Create `test/core/notifications/` directory.
- [ ] Create `test/core/notifications/fcm_service_test.dart` with the tests above.
- [ ] Run `flutter test test/core/notifications/fcm_service_test.dart` — tests must pass.

### Commit

```
git add lib/core/notifications/fcm_service.dart test/core/notifications/fcm_service_test.dart
git commit -m "feat: add FCMService with token save, permission request, foreground handler"
```

---

## Task 3 — Notification Router

**Files:**
- `lib/core/notifications/notification_router.dart` (create)
- `test/core/notifications/notification_router_test.dart` (create)

### Implementation

`lib/core/notifications/notification_router.dart`:

```dart
import 'package:go_router/go_router.dart';
import '../navigation/routes.dart';

enum NotificationRoute {
  todayReading,
  groupDetail,
  achievements,
  planComplete,
  groupLeaderboard,
}

class NotificationPayload {
  const NotificationPayload({
    required this.route,
    this.groupId,
    this.userPlanId,
  });

  final NotificationRoute route;
  final String? groupId;
  final String? userPlanId;
}

class NotificationRouter {
  /// Parse a raw FCM data map into a typed [NotificationPayload].
  /// Returns null if the payload cannot be interpreted.
  static NotificationPayload? parseNotificationPayload(
      Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == null) return null;

    switch (type) {
      case 'daily_reminder':
      case 'streak_at_risk':
        return const NotificationPayload(route: NotificationRoute.todayReading);
      case 'friend_nudge':
      case 'group_activity':
      case 'plan_completion':
        final groupId = data['groupId'] as String?;
        return NotificationPayload(
          route: NotificationRoute.groupDetail,
          groupId: groupId,
        );
      case 'milestone':
        return const NotificationPayload(
            route: NotificationRoute.achievements);
      case 'plan_complete':
        final userPlanId = data['userPlanId'] as String?;
        return NotificationPayload(
          route: NotificationRoute.planComplete,
          userPlanId: userPlanId,
        );
      case 'weekly_leaderboard':
        final groupId = data['groupId'] as String?;
        return NotificationPayload(
          route: NotificationRoute.groupLeaderboard,
          groupId: groupId,
        );
      default:
        return null;
    }
  }

  /// Navigate to the screen appropriate for [payload] using [router].
  static void handleNotificationTap(
      NotificationPayload payload, GoRouter router) {
    switch (payload.route) {
      case NotificationRoute.todayReading:
        router.go(Routes.todayReading);
      case NotificationRoute.groupDetail:
        final groupId = payload.groupId;
        if (groupId != null) {
          router.go(Routes.groupDetail(groupId));
        } else {
          router.go(Routes.groups);
        }
      case NotificationRoute.achievements:
        router.go(Routes.achievements);
      case NotificationRoute.planComplete:
        final userPlanId = payload.userPlanId;
        if (userPlanId != null) {
          router.go(Routes.planComplete(userPlanId));
        } else {
          router.go(Routes.plans);
        }
      case NotificationRoute.groupLeaderboard:
        final groupId = payload.groupId;
        if (groupId != null) {
          router.go(Routes.groupLeaderboard(groupId));
        } else {
          router.go(Routes.groups);
        }
    }
  }
}
```

### Tests

`test/core/notifications/notification_router_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/core/notifications/notification_router.dart';

void main() {
  group('NotificationRouter.parseNotificationPayload', () {
    test('daily_reminder maps to todayReading', () {
      final result = NotificationRouter.parseNotificationPayload(
          {'type': 'daily_reminder'});
      expect(result?.route, equals(NotificationRoute.todayReading));
    });

    test('streak_at_risk maps to todayReading', () {
      final result = NotificationRouter.parseNotificationPayload(
          {'type': 'streak_at_risk'});
      expect(result?.route, equals(NotificationRoute.todayReading));
    });

    test('friend_nudge maps to groupDetail with groupId', () {
      final result = NotificationRouter.parseNotificationPayload(
          {'type': 'friend_nudge', 'groupId': 'group-abc'});
      expect(result?.route, equals(NotificationRoute.groupDetail));
      expect(result?.groupId, equals('group-abc'));
    });

    test('group_activity maps to groupDetail', () {
      final result = NotificationRouter.parseNotificationPayload(
          {'type': 'group_activity', 'groupId': 'group-xyz'});
      expect(result?.route, equals(NotificationRoute.groupDetail));
    });

    test('milestone maps to achievements', () {
      final result = NotificationRouter.parseNotificationPayload(
          {'type': 'milestone'});
      expect(result?.route, equals(NotificationRoute.achievements));
    });

    test('plan_complete maps to planComplete with userPlanId', () {
      final result = NotificationRouter.parseNotificationPayload(
          {'type': 'plan_complete', 'userPlanId': 'plan-99'});
      expect(result?.route, equals(NotificationRoute.planComplete));
      expect(result?.userPlanId, equals('plan-99'));
    });

    test('weekly_leaderboard maps to groupLeaderboard with groupId', () {
      final result = NotificationRouter.parseNotificationPayload(
          {'type': 'weekly_leaderboard', 'groupId': 'group-abc'});
      expect(result?.route, equals(NotificationRoute.groupLeaderboard));
      expect(result?.groupId, equals('group-abc'));
    });

    test('unknown type returns null', () {
      final result = NotificationRouter.parseNotificationPayload(
          {'type': 'totally_unknown'});
      expect(result, isNull);
    });

    test('missing type returns null', () {
      final result =
          NotificationRouter.parseNotificationPayload({'foo': 'bar'});
      expect(result, isNull);
    });
  });
}
```

### Steps

- [ ] Create `lib/core/notifications/notification_router.dart`.
- [ ] Create `test/core/notifications/notification_router_test.dart`.
- [ ] Run `flutter test test/core/notifications/notification_router_test.dart` — all tests pass.

### Commit

```
git add lib/core/notifications/notification_router.dart test/core/notifications/notification_router_test.dart
git commit -m "feat: add NotificationRouter with payload parsing and deep-link dispatch"
```

---

## Task 4 — Local Notification Service

**Files:**
- `lib/core/notifications/local_notification_service.dart` (create)

> Note: `flutter_local_notifications` callbacks run in a background isolate; unit-testing the scheduler requires integration tests on a real device/emulator. Provide manual smoke-test instructions instead.

### Implementation

`lib/core/notifications/local_notification_service.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance =
      LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Notification channel IDs
  static const String _remindersChannelId = 'reminders';
  static const String _streakAlertsChannelId = 'streak_alerts';

  // Notification IDs (stable, so rescheduling cancels the previous one)
  static const int _dailyReminderId = 100;
  static const int _immediateNotificationId = 101;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Initialise timezone data (required for scheduled notifications)
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // we request via FCMService.requestPermission()
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    await _createAndroidChannels();
  }

  Future<void> _createAndroidChannels() async {
    const remindersChannel = AndroidNotificationChannel(
      _remindersChannelId,
      'Reminders',
      description: 'Daily Bible reading reminders',
      importance: Importance.high,
    );

    const streakAlertsChannel = AndroidNotificationChannel(
      _streakAlertsChannelId,
      'Streak Alerts',
      description: 'Alerts when your reading streak is at risk',
      importance: Importance.high,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(remindersChannel);
    await androidPlugin?.createNotificationChannel(streakAlertsChannel);
  }

  /// Schedule (or reschedule) the daily reading reminder.
  /// [time] is in the user's local timezone.
  /// [ianaTimezone] should match the user's Firestore `timezone` field.
  Future<void> scheduleReminder(
    TimeOfDay time, {
    String ianaTimezone = 'UTC',
  }) async {
    await cancelReminder();

    final location = _safeGetLocation(ianaTimezone);
    final now = tz.TZDateTime.now(location);
    var scheduled = tz.TZDateTime(
        location, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      "Time to read",
      "Open the Bible and keep your streak alive!",
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _remindersChannelId,
          'Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'type=daily_reminder',
    );
  }

  Future<void> cancelReminder() async {
    await _plugin.cancel(_dailyReminderId);
  }

  /// Show a notification immediately (used for foreground FCM messages).
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      _immediateNotificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _remindersChannelId,
          'Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  tz.Location _safeGetLocation(String ianaTimezone) {
    try {
      return tz.getLocation(ianaTimezone);
    } catch (_) {
      return tz.UTC;
    }
  }
}

// Top-level callbacks required by flutter_local_notifications

void _onNotificationResponse(NotificationResponse response) {
  // Taps while app is in foreground/background — handled by NotificationRouter
  // in the UI layer. The payload string is available as response.payload.
  debugPrint('[LocalNotifications] onResponse: ${response.payload}');
}

@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  debugPrint(
      '[LocalNotifications] onBackgroundResponse: ${response.payload}');
}
```

### Manual smoke-test checklist (device/emulator)

After implementing:
1. Call `LocalNotificationService.instance.initialize()` at app start.
2. Call `scheduleReminder(TimeOfDay(hour: 9, minute: 0))`.
3. Advance device clock to 09:00 (or use Android ADB `date` command).
4. Confirm notification appears in the notification shade.
5. Tap notification — confirm app opens (deep link handled in Task 6).

### Steps

- [ ] Create `lib/core/notifications/local_notification_service.dart` with code above.
- [ ] Run `flutter analyze lib/core/notifications/local_notification_service.dart` — no errors.

### Commit

```
git add lib/core/notifications/local_notification_service.dart
git commit -m "feat: add LocalNotificationService with daily reminder scheduling and channels"
```

---

## Task 5 — Notification Settings Screen

**Files:**
- `lib/features/notifications/presentation/notification_settings_screen.dart` (create)
- `lib/features/notifications/notifications_placeholder.dart` (replace — was empty)

### Implementation

`lib/features/notifications/presentation/notification_settings_screen.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/notifications/local_notification_service.dart';

/// Notification preferences stored in Firestore users/{uid}:
///   reminderTime: "HH:mm"          — local time for daily reminder
///   notifyStreakAlerts: bool
///   notifyGroupActivity: bool
///   notifyMilestones: bool
///   timezone: string (IANA)        — written by other logic; read here

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 30);
  bool _streakAlerts = true;
  bool _groupActivity = true;
  bool _milestones = true;
  bool _loading = true;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    final data = doc.data() ?? {};
    final rawTime = data['reminderTime'] as String? ?? '07:30';
    final parts = rawTime.split(':');

    setState(() {
      _reminderTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 7,
          minute: int.tryParse(parts[1]) ?? 30);
      _streakAlerts = data['notifyStreakAlerts'] as bool? ?? true;
      _groupActivity = data['notifyGroupActivity'] as bool? ?? true;
      _milestones = data['notifyMilestones'] as bool? ?? true;
      _loading = false;
    });
  }

  Future<void> _savePreferences() async {
    final timeString =
        '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';

    await FirebaseFirestore.instance.collection('users').doc(_uid).update({
      'reminderTime': timeString,
      'notifyStreakAlerts': _streakAlerts,
      'notifyGroupActivity': _groupActivity,
      'notifyMilestones': _milestones,
    });

    // Reschedule local reminder to match the new time.
    await LocalNotificationService.instance.scheduleReminder(_reminderTime);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      await _savePreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Daily Reminder'),
            subtitle: Text(_reminderTime.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: _pickReminderTime,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Streak Alerts'),
            subtitle: const Text(
                'Get notified 2 hours before midnight if you haven\'t read today'),
            value: _streakAlerts,
            onChanged: (v) {
              setState(() => _streakAlerts = v);
              _savePreferences();
            },
          ),
          SwitchListTile(
            title: const Text('Group Activity'),
            subtitle: const Text('When friends finish reading or send nudges'),
            value: _groupActivity,
            onChanged: (v) {
              setState(() => _groupActivity = v);
              _savePreferences();
            },
          ),
          SwitchListTile(
            title: const Text('Milestones'),
            subtitle: const Text('Streak milestones and plan completions'),
            value: _milestones,
            onChanged: (v) {
              setState(() => _milestones = v);
              _savePreferences();
            },
          ),
        ],
      ),
    );
  }
}
```

### Update placeholder

Replace the empty `lib/features/notifications/notifications_placeholder.dart`:

```dart
// Notifications feature — see presentation/notification_settings_screen.dart
export 'presentation/notification_settings_screen.dart';
```

### Wire into Profile screen

In `lib/features/profile/presentation/screens/profile_screen.dart`, add a "Notifications" ListTile that navigates to `Routes.notificationSettings` (added in Task 6). Example addition inside the profile screen's build method:

```dart
ListTile(
  leading: const Icon(Icons.notifications_outlined),
  title: const Text('Notifications'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.go(Routes.notificationSettings),
),
```

### Steps

- [ ] Create `lib/features/notifications/presentation/` directory.
- [ ] Create `lib/features/notifications/presentation/notification_settings_screen.dart`.
- [ ] Replace contents of `lib/features/notifications/notifications_placeholder.dart`.
- [ ] Run `flutter analyze lib/features/notifications/` — no errors.

### Commit

```
git add lib/features/notifications/
git commit -m "feat: add NotificationSettingsScreen with reminder time picker and toggles"
```

---

## Task 6 — Deep Link Integration (Routes + AppRouter update)

**Files:**
- `lib/core/navigation/routes.dart` (edit)
- `lib/core/navigation/app_router.dart` (edit)
- `lib/features/bible/presentation/screens/today_reading_screen.dart` (create — stub)
- `lib/features/profile/presentation/screens/achievements_screen.dart` (create — stub)
- `lib/features/groups/presentation/screens/plan_complete_screen.dart` (create — stub)
- `lib/features/groups/presentation/screens/group_leaderboard_screen.dart` (create — stub)
- `lib/features/notifications/presentation/notification_settings_screen.dart` — already created (Task 5)

### Routes update

`lib/core/navigation/routes.dart` — replace with:

```dart
abstract class Routes {
  static const login = '/login';
  static const home = '/home';
  static const read = '/read';
  static const groups = '/groups';
  static const plans = '/plans';
  static const profile = '/profile';

  // Notification deep-link routes (Plan 5)
  static const todayReading = '/bible/today';
  static const achievements = '/profile/achievements';
  static const notificationSettings = '/profile/settings/notifications';

  static String groupDetail(String groupId) => '/groups/$groupId';
  static String planComplete(String userPlanId) =>
      '/plans/complete/$userPlanId';
  static String groupLeaderboard(String groupId) =>
      '/groups/$groupId/leaderboard';
}
```

### AppRouter update

Edit `lib/core/navigation/app_router.dart`. Key changes:
1. Add a `notificationRoute` parameter that provides the cold-start initial location.
2. Add new `GoRoute` entries for all deep-link paths.
3. Handle `getInitialMessage()` cold-start routing.

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../../features/shell/presentation/shell_screen.dart';
import '../../features/shell/presentation/home_screen.dart';
import '../../features/shell/presentation/login_screen.dart';
import '../../features/bible/presentation/screens/bible_screen.dart';
import '../../features/bible/presentation/screens/today_reading_screen.dart';
import '../../features/groups/presentation/screens/groups_screen.dart';
import '../../features/groups/presentation/screens/plans_screen.dart';
import '../../features/groups/presentation/screens/plan_complete_screen.dart';
import '../../features/groups/presentation/screens/group_leaderboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/achievements_screen.dart';
import '../../features/notifications/presentation/notification_settings_screen.dart';
import '../notifications/notification_router.dart';
import 'routes.dart';

class AppRouter {
  /// [coldStartRoute] is non-null when the app was opened via a notification tap
  /// (determined by calling FirebaseMessaging.instance.getInitialMessage() before
  /// creating the router — see main.dart).
  static GoRouter create(
    ProviderContainer container, {
    String? coldStartRoute,
  }) {
    final authListenable = _AuthListenable(container);

    return GoRouter(
      initialLocation: coldStartRoute ?? Routes.home,
      refreshListenable: authListenable,
      redirect: (context, state) {
        final authState = container.read(authNotifierProvider);
        if (authState.isLoading) return null;

        final user = authState.valueOrNull;
        final isLoggingIn = state.matchedLocation == Routes.login;

        if (user == null && !isLoggingIn) return Routes.login;
        if (user != null && isLoggingIn) return Routes.home;
        return null;
      },
      routes: [
        GoRoute(
          path: Routes.login,
          builder: (_, __) => const LoginScreen(),
        ),

        // Notification deep-link routes — outside the shell so they can push
        // on top of the authenticated stack cleanly.
        GoRoute(
          path: Routes.todayReading,
          builder: (_, __) => const TodayReadingScreen(),
        ),
        GoRoute(
          path: Routes.achievements,
          builder: (_, __) => const AchievementsScreen(),
        ),
        GoRoute(
          path: Routes.notificationSettings,
          builder: (_, __) => const NotificationSettingsScreen(),
        ),
        GoRoute(
          path: '/plans/complete/:userPlanId',
          builder: (_, state) => PlanCompleteScreen(
            userPlanId: state.pathParameters['userPlanId']!,
          ),
        ),
        GoRoute(
          path: '/groups/:groupId/leaderboard',
          builder: (_, state) => GroupLeaderboardScreen(
            groupId: state.pathParameters['groupId']!,
          ),
        ),
        GoRoute(
          path: '/groups/:groupId',
          builder: (_, state) => GroupsScreen(
            groupId: state.pathParameters['groupId'],
          ),
        ),

        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => ShellScreen(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: Routes.home, builder: (_, __) => const HomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: Routes.read, builder: (_, __) => const BibleScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: Routes.groups,
                  builder: (_, __) => const GroupsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: Routes.plans,
                  builder: (_, __) => const PlansScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: Routes.profile,
                  builder: (_, __) => const ProfileScreen()),
            ]),
          ],
        ),
      ],
    );
  }
}

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(ProviderContainer container) {
    _sub = container.listen(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<User?>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
```

### Stub screens

Create minimal stubs for the new routes (flesh them out in later plans):

`lib/features/bible/presentation/screens/today_reading_screen.dart`:
```dart
import 'package:flutter/material.dart';

class TodayReadingScreen extends StatelessWidget {
  const TodayReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Reading")),
      body: const Center(child: Text("Today's chapter — coming in Plan 7")),
    );
  }
}
```

`lib/features/profile/presentation/screens/achievements_screen.dart`:
```dart
import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: const Center(child: Text('Milestones — coming in Plan 4')),
    );
  }
}
```

`lib/features/groups/presentation/screens/plan_complete_screen.dart`:
```dart
import 'package:flutter/material.dart';

class PlanCompleteScreen extends StatelessWidget {
  const PlanCompleteScreen({super.key, required this.userPlanId});

  final String userPlanId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan Complete')),
      body: Center(child: Text('Plan $userPlanId complete — coming in Plan 7')),
    );
  }
}
```

`lib/features/groups/presentation/screens/group_leaderboard_screen.dart`:
```dart
import 'package:flutter/material.dart';

class GroupLeaderboardScreen extends StatelessWidget {
  const GroupLeaderboardScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Center(child: Text('Leaderboard for $groupId — coming in Plan 3')),
    );
  }
}
```

Also update `GroupsScreen` to accept an optional `groupId` parameter:

In `lib/features/groups/presentation/screens/groups_screen.dart`, change the constructor:
```dart
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key, this.groupId});
  final String? groupId;
  // ...
}
```

### Steps

- [ ] Replace `lib/core/navigation/routes.dart` with the new version above.
- [ ] Replace `lib/core/navigation/app_router.dart` with the new version above.
- [ ] Create each stub screen file listed.
- [ ] Update `GroupsScreen` constructor to accept optional `groupId`.
- [ ] Run `flutter analyze lib/` — no errors.
- [ ] Run `flutter test` — all tests pass.

### Commit

```
git add lib/core/navigation/ lib/features/bible/presentation/screens/today_reading_screen.dart lib/features/profile/presentation/screens/achievements_screen.dart lib/features/groups/presentation/screens/plan_complete_screen.dart lib/features/groups/presentation/screens/group_leaderboard_screen.dart lib/features/groups/presentation/screens/groups_screen.dart
git commit -m "feat: add deep-link routes for notification taps (today, achievements, plan complete, leaderboard)"
```

---

## Task 7 — iOS Widget Extension

> **This task requires manual steps in Xcode.** The Flutter code in Task 9 handles data delivery; this task creates the native Widget extension that reads and displays that data.

### Manual Xcode steps (developer must perform these)

1. Open `ios/Runner.xcworkspace` in Xcode (never `.xcodeproj` when using CocoaPods).
2. In the Project Navigator, select the top-level `Runner` project (not the target).
3. Click the `+` button at the bottom of the Targets list → choose **Widget Extension**.
4. Configure:
   - **Product Name:** `BibleWidget`
   - **Team:** your Apple Developer team
   - **Bundle Identifier:** `com.iwannareadthebiblemore.BibleWidget`
   - Uncheck "Include Configuration Intent" (we use static configuration)
5. Click **Finish**. Xcode will create `ios/BibleWidget/` and prompt to activate the scheme — click **Activate**.
6. Select the `BibleWidget` target → **Signing & Capabilities** → **+ Capability** → **App Groups**.
   - Add group: `group.com.iwannareadthebiblemore`
7. Select the `Runner` target → **Signing & Capabilities** → **App Groups**.
   - Add the same group: `group.com.iwannareadthebiblemore`
8. Both targets must share the same App Group — this is how Flutter writes data and the widget reads it.

### Swift widget code

Replace the generated `ios/BibleWidget/BibleWidget.swift` with:

```swift
import WidgetKit
import SwiftUI

// MARK: - Shared data keys (must match home_widget package keys used in Dart)
private enum WidgetKeys {
    static let streak = "streak"
    static let verseText = "verseText"
    static let verseRef = "verseRef"
    static let appGroupId = "group.com.iwannareadthebiblemore"
}

// MARK: - Timeline entry
struct BibleEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let verseText: String
    let verseRef: String
}

// MARK: - Timeline provider
struct BibleProvider: TimelineProvider {
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: WidgetKeys.appGroupId)
    }

    func placeholder(in context: Context) -> BibleEntry {
        BibleEntry(date: .now, streak: 7, verseText: "Your word is a lamp to my feet…", verseRef: "Psalm 119:105")
    }

    func getSnapshot(in context: Context, completion: @escaping (BibleEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BibleEntry>) -> Void) {
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry()], policy: .after(nextUpdate)))
    }

    private func entry() -> BibleEntry {
        let defaults = sharedDefaults
        return BibleEntry(
            date: .now,
            streak: defaults?.integer(forKey: WidgetKeys.streak) ?? 0,
            verseText: defaults?.string(forKey: WidgetKeys.verseText) ?? "Open the Bible today",
            verseRef: defaults?.string(forKey: WidgetKeys.verseRef) ?? ""
        )
    }
}

// MARK: - Home screen widget view
struct BibleWidgetEntryView: View {
    var entry: BibleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            // Lock screen circular (iOS 16+)
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(entry.streak)")
                    .font(.headline.bold())
            }
        case .accessoryRectangular:
            // Lock screen rectangular (iOS 16+)
            HStack {
                Image(systemName: "flame.fill").foregroundColor(.orange)
                Text("\(entry.streak) day streak")
                    .font(.caption.bold())
            }
        default:
            // Home screen small/medium
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").foregroundColor(.orange)
                    Text("\(entry.streak)")
                        .font(.title2.bold())
                    Text("day streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(entry.verseText)
                    .font(.caption)
                    .lineLimit(3)
                    .foregroundColor(.primary)
                Text(entry.verseRef)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Link(destination: URL(string: "iwannareadthebiblemore://bible/today")!) {
                    Label("Read", systemImage: "book.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

// MARK: - Widget definition
@main
struct BibleWidget: Widget {
    let kind = "BibleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BibleProvider()) { entry in
            BibleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Bible Streak")
        .description("Streak count, today's verse, and a Read button.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
        ])
    }
}
```

### iOS deep link (URL scheme)

In Xcode, select the **Runner** target → **Info** tab → **URL Types** → add:
- Identifier: `com.iwannareadthebiblemore`
- URL Schemes: `iwannareadthebiblemore`

This allows the "Read" button `Link` in the widget to open the app at `/bible/today`.

In `lib/app.dart` (or `lib/main.dart`), ensure go_router handles the incoming URL scheme via `GoRouter`'s `onException` or a dedicated redirect — this is handled by `go_router`'s built-in URL handling when the `initialLocation` is set from `getInitialMessage()`.

### Steps

- [ ] Perform manual Xcode steps 1–8 above.
- [ ] Replace generated `ios/BibleWidget/BibleWidget.swift` with the Swift code above.
- [ ] Add URL scheme to Runner target (Xcode → Runner target → Info → URL Types).
- [ ] Build and run on iOS simulator — widget should appear in widget gallery.
- [ ] Add widget to home screen — verify it shows streak and verse from shared UserDefaults.

### Commit

```
git add ios/BibleWidget/ ios/Runner/
git commit -m "feat: add iOS BibleWidget extension with streak, verse, and Read CTA"
```

---

## Task 8 — Android Widget

**Files:**
- `android/app/src/main/kotlin/com/iwannareadthebiblemore/BibleWidget.kt` (create)
- `android/app/src/main/res/layout/bible_widget.xml` (create)
- `android/app/src/main/res/xml/bible_widget_info.xml` (create)
- `android/app/src/main/AndroidManifest.xml` (edit — add `<receiver>`)

### Widget layout

`android/app/src/main/res/layout/bible_widget.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="12dp"
    android:background="@drawable/widget_background"
    android:gravity="start">

    <!-- Streak row -->
    <LinearLayout
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center_vertical">

        <TextView
            android:id="@+id/streak_emoji"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="🔥"
            android:textSize="18sp" />

        <TextView
            android:id="@+id/streak_count"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="0"
            android:textSize="22sp"
            android:textStyle="bold"
            android:paddingStart="4dp"
            android:paddingEnd="2dp" />

        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text=" day streak"
            android:textSize="12sp"
            android:textColor="#88FFFFFF" />
    </LinearLayout>

    <!-- Verse text -->
    <TextView
        android:id="@+id/verse_text"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:text="Open the Bible today"
        android:textSize="12sp"
        android:maxLines="3"
        android:ellipsize="end"
        android:paddingTop="6dp" />

    <!-- Verse reference -->
    <TextView
        android:id="@+id/verse_ref"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text=""
        android:textSize="10sp"
        android:textColor="#88FFFFFF"
        android:paddingBottom="6dp" />

    <!-- Read button -->
    <Button
        android:id="@+id/read_button"
        android:layout_width="wrap_content"
        android:layout_height="32dp"
        android:text="Read"
        android:textSize="12sp"
        android:paddingStart="12dp"
        android:paddingEnd="12dp" />

</LinearLayout>
```

> Note: Create a simple `android/app/src/main/res/drawable/widget_background.xml` rounded-rect drawable to give the widget a card appearance. Use `@android:color/black` or a dark color for dark-mode compatibility.

### Widget info XML

`android/app/src/main/res/xml/bible_widget_info.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="110dp"
    android:updatePeriodMillis="3600000"
    android:initialLayout="@layout/bible_widget"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen"
    android:description="@string/app_name" />
```

### Kotlin AppWidget

`android/app/src/main/kotlin/com/iwannareadthebiblemore/BibleWidget.kt`:

```kotlin
package com.iwannareadthebiblemore

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class BibleWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // Read data written by Flutter via home_widget package.
            // home_widget uses SharedPreferences with the app's default prefs.
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )
            val streak = prefs.getLong("flutter.streak", 0).toInt()
            val verseText = prefs.getString("flutter.verseText", "Open the Bible today") ?: ""
            val verseRef = prefs.getString("flutter.verseRef", "") ?: ""

            val views = RemoteViews(context.packageName, R.layout.bible_widget)
            views.setTextViewText(R.id.streak_count, streak.toString())
            views.setTextViewText(R.id.verse_text, verseText)
            views.setTextViewText(R.id.verse_ref, verseRef)

            // "Read" button — deep link into the app at /bible/today
            val intent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("iwannareadthebiblemore://bible/today")
                setPackage(context.packageName)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.read_button, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
```

### AndroidManifest.xml addition

In `android/app/src/main/AndroidManifest.xml`, add inside the `<application>` block:

```xml
<receiver
    android:name=".BibleWidget"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/bible_widget_info" />
</receiver>
```

Also add the deep link intent filter to the `<activity>` element (the `MainActivity`) if not present:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="iwannareadthebiblemore" />
</intent-filter>
```

### Steps

- [ ] Determine the exact Kotlin package directory by checking `android/app/src/main/kotlin/` — use the real package path.
- [ ] Create `BibleWidget.kt` at the correct path.
- [ ] Create `android/app/src/main/res/layout/bible_widget.xml`.
- [ ] Create `android/app/src/main/res/xml/` directory and `bible_widget_info.xml`.
- [ ] Create a simple `android/app/src/main/res/drawable/widget_background.xml` shape drawable.
- [ ] Edit `AndroidManifest.xml` to add the `<receiver>` and deep link intent filter.
- [ ] Run `flutter build apk --debug` — build must succeed.
- [ ] Install on Android emulator, add widget to home screen — verify it appears.

### Commit

```
git add android/
git commit -m "feat: add Android BibleWidget with streak, verse, and Read button deep link"
```

---

## Task 9 — Widget Update Service

**Files:**
- `lib/core/notifications/widget_update_service.dart` (create)

### Implementation

`lib/core/notifications/widget_update_service.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class WidgetUpdateService {
  WidgetUpdateService._();
  static final WidgetUpdateService instance = WidgetUpdateService._();

  // Must match the app group used in the iOS Widget Extension.
  static const String _appGroupId = 'group.com.iwannareadthebiblemore';

  // Widget name constants (match the `kind` in Swift and the Kotlin receiver name)
  static const String _iOSWidgetName = 'BibleWidget';
  static const String _androidWidgetName = 'BibleWidget';

  /// Call this when HomeScreen loads and after marking today's reading as done.
  Future<void> updateWidget({
    required int streak,
    required String verseText,
    required String verseRef,
  }) async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);

      await Future.wait([
        HomeWidget.saveWidgetData<int>('streak', streak),
        HomeWidget.saveWidgetData<String>('verseText', verseText),
        HomeWidget.saveWidgetData<String>('verseRef', verseRef),
      ]);

      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e, st) {
      // Widget update failures are non-fatal — log and continue.
      debugPrint('[WidgetUpdateService] Failed to update widget: $e\n$st');
    }
  }
}
```

### Wiring into HomeScreen

In `lib/features/shell/presentation/home_screen.dart`, call `WidgetUpdateService.instance.updateWidget(...)` after loading streak and verse data:

```dart
// Example call site — adapt to actual data providers in Plan 7
WidgetUpdateService.instance.updateWidget(
  streak: currentStreak,
  verseText: todayVerse.text,
  verseRef: todayVerse.reference,
);
```

### Steps

- [ ] Create `lib/core/notifications/widget_update_service.dart`.
- [ ] Add a call in `HomeScreen` (or relevant provider listener) once streak and verse data is available.
- [ ] Run `flutter analyze lib/core/notifications/` — no errors.

### Commit

```
git add lib/core/notifications/widget_update_service.dart lib/features/shell/presentation/home_screen.dart
git commit -m "feat: add WidgetUpdateService to push streak and verse data to home/lock screen widgets"
```

---

## Task 10 — Integration: FCM init on app start + cold-start routing

**Files:**
- `lib/main.dart` (edit)
- `lib/core/firebase/firebase_module.dart` (edit)
- `lib/app.dart` (edit)

This task wires everything together: background handler registration, FCM init, cold-start notification routing, and `LocalNotificationService` init.

### Updated `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/firebase/firebase_module.dart';
import 'core/notifications/fcm_service.dart';
import 'core/notifications/local_notification_service.dart';
import 'core/notifications/notification_router.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register background FCM handler BEFORE Firebase.initializeApp().
  // Must be a top-level function — see fcm_service.dart.
  FCMService.registerBackgroundHandler();

  await FirebaseModule.initialise();

  // Initialise local notification channels.
  await LocalNotificationService.instance.initialize();

  // Check whether the app was opened by tapping a notification (cold start).
  final coldStartRoute = await _resolveColdStartRoute();

  runApp(ProviderScope(child: App(coldStartRoute: coldStartRoute)));
}

/// Returns the route path to open if the app was cold-started from a notification,
/// or null to use the default initial location.
Future<String?> _resolveColdStartRoute() async {
  try {
    // firebase_messaging: returns the RemoteMessage if app opened from terminated state.
    // Returns null if app was opened normally.
    final message =
        await FirebaseMessaging.instance.getInitialMessage();  // ignore: unused_import
    if (message == null) return null;

    final payload = NotificationRouter.parseNotificationPayload(message.data);
    if (payload == null) return null;

    // Convert payload to a route string without a GoRouter instance.
    // GoRouter is created in App — we just need the path string here.
    return _payloadToPath(payload);
  } catch (_) {
    return null;
  }
}

String? _payloadToPath(NotificationPayload payload) {
  switch (payload.route) {
    case NotificationRoute.todayReading:
      return '/bible/today';
    case NotificationRoute.achievements:
      return '/profile/achievements';
    case NotificationRoute.groupDetail:
      final g = payload.groupId;
      return g != null ? '/groups/$g' : '/groups';
    case NotificationRoute.planComplete:
      final p = payload.userPlanId;
      return p != null ? '/plans/complete/$p' : '/plans';
    case NotificationRoute.groupLeaderboard:
      final g = payload.groupId;
      return g != null ? '/groups/$g/leaderboard' : '/groups';
  }
}
```

> Note: Add `import 'package:firebase_messaging/firebase_messaging.dart';` to `main.dart` — the `ignore` comment above is a placeholder reminder; remove it and add the real import.

### Updated `lib/app.dart`

Add a `coldStartRoute` parameter so `AppRouter.create` receives it:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/design_system/app_theme.dart';
import 'core/navigation/app_router.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key, this.coldStartRoute});

  final String? coldStartRoute;

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= AppRouter.create(
      ProviderScope.containerOf(context),
      coldStartRoute: widget.coldStartRoute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'iwannareadthebiblemore',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: _router!,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### FCM post-login init

In `lib/core/auth/auth_notifier.dart` (or a provider that watches auth state), after the user signs in call:

```dart
final fcmService = FCMService();
await fcmService.getTokenAndSave();
fcmService.setupTokenRefreshListener();
fcmService.setupForegroundHandler();
```

This is best done in an `AuthNotifier` listener or a dedicated `FCMInitNotifier` that watches `authNotifierProvider` — implement whichever pattern fits the existing auth code.

### Updated `lib/core/firebase/firebase_module.dart`

No changes needed to `FirebaseModule.initialise()` itself. The background handler registration and FCM init happen in `main.dart` as shown above.

### Steps

- [ ] Edit `lib/main.dart` to register the background handler, init `LocalNotificationService`, call `_resolveColdStartRoute()`, and pass `coldStartRoute` to `App`.
- [ ] Add the `firebase_messaging` import to `main.dart`.
- [ ] Edit `lib/app.dart` to accept and pass `coldStartRoute` to `AppRouter.create`.
- [ ] Add FCM `getTokenAndSave()` + listeners call in auth sign-in flow.
- [ ] Run `flutter analyze lib/` — no errors.
- [ ] Run `flutter test` — all tests pass (target: 17 + new tests from Tasks 2 and 3).

### Commit

```
git add lib/main.dart lib/app.dart lib/core/auth/ lib/core/notifications/
git commit -m "feat: wire FCM init, cold-start notification routing, and LocalNotification init into app startup"
```

---

## Final verification

```bash
flutter test
# Expected: all tests pass (17 original + new notification tests)

flutter analyze
# Expected: no errors, no warnings

flutter build ios --no-codesign
flutter build apk --debug
# Expected: both build successfully
```

## Summary of new files

| File | Purpose |
|---|---|
| `lib/core/notifications/fcm_service.dart` | FCM token, permission, foreground handler |
| `lib/core/notifications/local_notification_service.dart` | Notification channels, scheduled reminders |
| `lib/core/notifications/notification_router.dart` | Payload parsing + GoRouter dispatch |
| `lib/core/notifications/widget_update_service.dart` | home_widget data write + refresh trigger |
| `lib/features/notifications/presentation/notification_settings_screen.dart` | Settings UI |
| `lib/features/bible/presentation/screens/today_reading_screen.dart` | Stub for /bible/today |
| `lib/features/profile/presentation/screens/achievements_screen.dart` | Stub for /profile/achievements |
| `lib/features/groups/presentation/screens/plan_complete_screen.dart` | Stub for /plans/complete/:id |
| `lib/features/groups/presentation/screens/group_leaderboard_screen.dart` | Stub for /groups/:id/leaderboard |
| `ios/BibleWidget/BibleWidget.swift` | iOS WidgetKit extension |
| `android/app/src/main/.../BibleWidget.kt` | Android AppWidget |
| `android/app/src/main/res/layout/bible_widget.xml` | Android widget layout |
| `android/app/src/main/res/xml/bible_widget_info.xml` | Android widget metadata |
| `test/core/notifications/fcm_service_test.dart` | FCMService unit tests |
| `test/core/notifications/notification_router_test.dart` | NotificationRouter unit tests |

## Modified files

| File | Change |
|---|---|
| `pubspec.yaml` | Add `flutter_local_notifications`, `timezone` |
| `lib/main.dart` | Background handler, local notif init, cold-start route |
| `lib/app.dart` | Accept and pass `coldStartRoute` |
| `lib/core/navigation/routes.dart` | New deep-link route constants and helpers |
| `lib/core/navigation/app_router.dart` | New GoRoute entries, `coldStartRoute` param |
| `lib/features/notifications/notifications_placeholder.dart` | Export settings screen |
| `lib/features/groups/presentation/screens/groups_screen.dart` | Optional `groupId` param |
| `android/app/src/main/AndroidManifest.xml` | Widget receiver + deep link intent filter |
