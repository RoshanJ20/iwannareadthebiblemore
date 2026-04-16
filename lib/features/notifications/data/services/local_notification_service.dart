import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Stub service for scheduling local notifications using Hive for preference
/// persistence.
///
/// IMPORTANT: Actual scheduling requires the `flutter_local_notifications`
/// package, which is NOT yet in pubspec.yaml. Add it in a future step:
///
/// ```yaml
/// flutter_local_notifications: ^17.0.0
/// ```
///
/// Once added, replace the stub `_schedule*` bodies with real calls to
/// `FlutterLocalNotificationsPlugin`.
class LocalNotificationService {
  static const _boxName = 'local_notification_prefs';
  static const _keyDailyHour = 'daily_hour';
  static const _keyDailyMinute = 'daily_minute';
  static const _keyStreakAtRiskEnabled = 'streak_at_risk_enabled';
  static const _keyDailyEnabled = 'daily_enabled';

  late Box<dynamic> _box;

  /// Must be called once during app startup (after Hive.initFlutter).
  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Persists the preferred daily reminder time and (stub) schedules it.
  ///
  /// When `flutter_local_notifications` is added, call
  /// `flutterLocalNotificationsPlugin.zonedSchedule(...)` here.
  Future<void> scheduleDaily(TimeOfDay time) async {
    await _box.put(_keyDailyHour, time.hour);
    await _box.put(_keyDailyMinute, time.minute);
    await _box.put(_keyDailyEnabled, true);
    // TODO(plan-6): replace with flutter_local_notifications call
    _stubLog('scheduleDaily', {'hour': time.hour, 'minute': time.minute});
  }

  /// Persists the streak-at-risk scheduling preference and (stub) schedules it.
  ///
  /// The notification should fire 2 hours before midnight in [userTimezone]
  /// if the user has not read today.
  ///
  /// When `flutter_local_notifications` is added, use
  /// `tz.TZDateTime.from(scheduledDate, location)` with
  /// `package:timezone/timezone.dart`.
  Future<void> scheduleStreakAtRisk(String userTimezone) async {
    await _box.put(_keyStreakAtRiskEnabled, true);
    // TODO(plan-6): replace with flutter_local_notifications call
    _stubLog('scheduleStreakAtRisk', {'timezone': userTimezone});
  }

  /// Cancels all pending local notifications and clears persisted preferences.
  ///
  /// When `flutter_local_notifications` is added, call
  /// `flutterLocalNotificationsPlugin.cancelAll()` here.
  Future<void> cancelAll() async {
    await _box.put(_keyDailyEnabled, false);
    await _box.put(_keyStreakAtRiskEnabled, false);
    // TODO(plan-6): replace with flutter_local_notifications call
    _stubLog('cancelAll', {});
  }

  // ─── Preference Accessors ────────────────────────────────────────────────

  /// Returns the persisted daily reminder time, or 08:00 as default.
  TimeOfDay getDailyTime() {
    final hour = _box.get(_keyDailyHour, defaultValue: 8) as int;
    final minute = _box.get(_keyDailyMinute, defaultValue: 0) as int;
    return TimeOfDay(hour: hour, minute: minute);
  }

  bool get isDailyEnabled =>
      _box.get(_keyDailyEnabled, defaultValue: false) as bool;

  bool get isStreakAtRiskEnabled =>
      _box.get(_keyStreakAtRiskEnabled, defaultValue: false) as bool;

  // ─── Private helpers ─────────────────────────────────────────────────────

  void _stubLog(String method, Map<String, dynamic> args) {
    // ignore: avoid_print
    assert(() {
      // Only logs in debug; stripped in release.
      debugPrint('[LocalNotificationService] stub: $method($args)');
      return true;
    }());
  }
}
