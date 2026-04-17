import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:hive_flutter/hive_flutter.dart';

class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _dailyReminderId = 1;
  static const _streakAtRiskId = 2;

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Deep link handled by FCM service for push; local notifs just open app
  }

  /// Schedule a daily reminder at the given time.
  /// Persists the time to Hive so it survives app restarts.
  static Future<void> scheduleDaily(int hour, int minute, String timezone) async {
    await init();
    await _plugin.cancel(_dailyReminderId);

    final box = Hive.box('settings');
    await box.put('reminder_hour', hour);
    await box.put('reminder_minute', minute);
    await box.put('reminder_timezone', timezone);

    final tz.TZDateTime scheduledTime = _nextInstanceOfTime(hour, minute, timezone);

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Time to read 📖',
      'Keep your streak alive — open today\'s reading',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: 'Daily Bible reading reminder',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule streak-at-risk notification 2 hours before midnight.
  static Future<void> scheduleStreakAtRisk(String userTimezone) async {
    await init();
    await _plugin.cancel(_streakAtRiskId);

    final scheduledTime = _nextInstanceOfTime(22, 0, userTimezone);

    await _plugin.zonedSchedule(
      _streakAtRiskId,
      'Streak at risk! 🔥',
      'You have 2 hours left to read today',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_at_risk',
          'Streak Alerts',
          channelDescription: 'Alerts when your streak is at risk',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  static Future<void> cancelDailyReminder() async {
    await init();
    await _plugin.cancel(_dailyReminderId);
  }

  static Future<void> cancelStreakAtRisk() async {
    await init();
    await _plugin.cancel(_streakAtRiskId);
  }

  /// Re-schedule saved notifications (call on app startup after sign-in).
  static Future<void> rescheduleFromSaved() async {
    await init();
    final box = Hive.box('settings');
    final hour = box.get('reminder_hour') as int?;
    final minute = box.get('reminder_minute') as int?;
    final timezone = box.get('reminder_timezone') as String? ?? 'UTC';

    if (hour != null && minute != null) {
      await scheduleDaily(hour, minute, timezone);
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute, String timezone) {
    late tz.Location location;
    try {
      location = tz.getLocation(timezone);
    } catch (_) {
      location = tz.UTC;
    }

    final now = tz.TZDateTime.now(location);
    var scheduled = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
