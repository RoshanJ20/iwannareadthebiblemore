import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/repositories/firestore_notification_repository.dart';
import '../../data/services/fcm_service.dart';
import '../../data/services/local_notification_service.dart';
import '../../domain/entities/notification_type.dart';
import '../../domain/repositories/notification_repository.dart';

// ─── Repository ──────────────────────────────────────────────────────────────

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirestoreNotificationRepository(FirebaseFirestore.instance);
});

// ─── FCM Service ─────────────────────────────────────────────────────────────

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(
    messaging: FirebaseMessaging.instance,
    firestore: FirebaseFirestore.instance,
  );
});

// ─── Local Notification Service ──────────────────────────────────────────────

// LocalNotificationService is fully static; no provider instance needed.

// ─── Notification Settings ───────────────────────────────────────────────────

/// Per-type enabled/disabled state + daily reminder time.
class NotificationSettings {
  const NotificationSettings({
    required this.enabledTypes,
    required this.reminderTime,
  });

  /// Default: all types enabled, reminder at 08:00.
  factory NotificationSettings.defaults() {
    return NotificationSettings(
      enabledTypes: {
        for (final t in NotificationType.values) t: true,
      },
      reminderTime: const TimeOfDay(hour: 8, minute: 0),
    );
  }

  final Map<NotificationType, bool> enabledTypes;
  final TimeOfDay reminderTime;

  bool isEnabled(NotificationType type) => enabledTypes[type] ?? true;

  NotificationSettings copyWith({
    Map<NotificationType, bool>? enabledTypes,
    TimeOfDay? reminderTime,
  }) {
    return NotificationSettings(
      enabledTypes: enabledTypes ?? Map.from(this.enabledTypes),
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  NotificationSettings withToggle(NotificationType type, bool value) {
    return copyWith(
      enabledTypes: {...enabledTypes, type: value},
    );
  }

  // ─── Hive persistence ────────────────────────────────────────────────────

  static const _boxName = 'notification_settings';
  static const _keyPrefix = 'notif_';
  static const _keyReminderHour = 'reminder_hour';
  static const _keyReminderMinute = 'reminder_minute';

  static Future<NotificationSettings> loadFromHive() async {
    final box = await Hive.openBox<dynamic>(_boxName);

    final enabledTypes = <NotificationType, bool>{};
    for (final type in NotificationType.values) {
      enabledTypes[type] =
          box.get('$_keyPrefix${type.value}', defaultValue: true) as bool;
    }

    final hour = box.get(_keyReminderHour, defaultValue: 8) as int;
    final minute = box.get(_keyReminderMinute, defaultValue: 0) as int;

    return NotificationSettings(
      enabledTypes: enabledTypes,
      reminderTime: TimeOfDay(hour: hour, minute: minute),
    );
  }

  Future<void> saveToHive() async {
    final box = await Hive.openBox<dynamic>(_boxName);

    for (final entry in enabledTypes.entries) {
      await box.put('$_keyPrefix${entry.key.value}', entry.value);
    }
    await box.put(_keyReminderHour, reminderTime.hour);
    await box.put(_keyReminderMinute, reminderTime.minute);
  }
}

// ─── StateNotifier ────────────────────────────────────────────────────────────

class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier(this._fcmService)
      : super(NotificationSettings.defaults());

  final FcmService _fcmService;

  Future<void> load() async {
    state = await NotificationSettings.loadFromHive();
  }

  void toggleType(NotificationType type, {required bool enabled}) {
    state = state.withToggle(type, enabled);
  }

  void setReminderTime(TimeOfDay time) {
    state = state.copyWith(reminderTime: time);
  }

  /// Persists settings to Hive and applies side effects:
  /// - subscribe/unsubscribe from global FCM topics
  /// - schedule or cancel local daily reminder
  Future<void> save() async {
    await state.saveToHive();

    // Global FCM topics
    await _applyTopicSubscription(
      'streak_at_risk',
      state.isEnabled(NotificationType.streakAtRisk),
    );
    await _applyTopicSubscription(
      'weekly_leaderboard',
      state.isEnabled(NotificationType.weeklyLeaderboard),
    );
    await _applyTopicSubscription(
      'milestones',
      state.isEnabled(NotificationType.milestone),
    );

    // Local notifications
    final box = Hive.box('settings');
    final timezone = box.get('reminder_timezone') as String? ??
        DateTime.now().timeZoneName;

    if (state.isEnabled(NotificationType.dailyReminder)) {
      await LocalNotificationService.scheduleDaily(
        state.reminderTime.hour,
        state.reminderTime.minute,
        timezone,
      );
    } else {
      await LocalNotificationService.cancelDailyReminder();
    }

    if (state.isEnabled(NotificationType.streakAtRisk)) {
      await LocalNotificationService.scheduleStreakAtRisk(timezone);
    } else {
      await LocalNotificationService.cancelStreakAtRisk();
    }
  }

  Future<void> _applyTopicSubscription(
      String topic, bool shouldSubscribe) async {
    if (shouldSubscribe) {
      await _fcmService.subscribeToTopic(topic);
    } else {
      await _fcmService.unsubscribeFromTopic(topic);
    }
  }
}

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier(
    ref.watch(fcmServiceProvider),
  );
});
