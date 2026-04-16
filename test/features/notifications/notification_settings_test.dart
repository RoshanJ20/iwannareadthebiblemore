import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iwannareadthebiblemore/features/notifications/domain/entities/notification_type.dart';
import 'package:iwannareadthebiblemore/features/notifications/presentation/providers/notification_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('NotificationSettings defaults', () {
    test('all types enabled by default', () {
      final settings = NotificationSettings.defaults();
      for (final type in NotificationType.values) {
        expect(settings.isEnabled(type), isTrue,
            reason: '${type.name} should be enabled by default');
      }
    });

    test('default reminder time is 08:00', () {
      final settings = NotificationSettings.defaults();
      expect(settings.reminderTime.hour, equals(8));
      expect(settings.reminderTime.minute, equals(0));
    });

    test('enabledTypes map contains all types', () {
      final settings = NotificationSettings.defaults();
      for (final type in NotificationType.values) {
        expect(settings.enabledTypes.containsKey(type), isTrue,
            reason: 'enabledTypes must contain ${type.name}');
      }
    });
  });

  group('NotificationSettings toggle', () {
    test('withToggle disables a type', () {
      final settings = NotificationSettings.defaults();
      final updated =
          settings.withToggle(NotificationType.dailyReminder, false);
      expect(updated.isEnabled(NotificationType.dailyReminder), isFalse);
      // Other types should remain enabled.
      expect(updated.isEnabled(NotificationType.milestone), isTrue);
    });

    test('withToggle enables a type after disabling', () {
      final settings = NotificationSettings.defaults()
          .withToggle(NotificationType.streakAtRisk, false);
      final reEnabled =
          settings.withToggle(NotificationType.streakAtRisk, true);
      expect(reEnabled.isEnabled(NotificationType.streakAtRisk), isTrue);
    });

    test('copyWith updates reminderTime', () {
      final settings = NotificationSettings.defaults();
      final updated = settings.copyWith(
          reminderTime: const TimeOfDay(hour: 20, minute: 30));
      expect(updated.reminderTime.hour, equals(20));
      expect(updated.reminderTime.minute, equals(30));
    });

    test('copyWith is immutable — original unchanged', () {
      final original = NotificationSettings.defaults();
      original.withToggle(NotificationType.friendNudge, false);
      expect(original.isEnabled(NotificationType.friendNudge), isTrue);
    });
  });

  group('NotificationSettings Hive persistence', () {
    test('saveToHive and loadFromHive round-trip toggles', () async {
      final settings = NotificationSettings.defaults()
          .withToggle(NotificationType.weeklyLeaderboard, false)
          .withToggle(NotificationType.groupActivity, false)
          .copyWith(reminderTime: const TimeOfDay(hour: 21, minute: 0));

      await settings.saveToHive();

      final loaded = await NotificationSettings.loadFromHive();

      expect(loaded.isEnabled(NotificationType.weeklyLeaderboard), isFalse);
      expect(loaded.isEnabled(NotificationType.groupActivity), isFalse);
      expect(loaded.isEnabled(NotificationType.dailyReminder), isTrue);
      expect(loaded.reminderTime.hour, equals(21));
      expect(loaded.reminderTime.minute, equals(0));
    });

    test('loadFromHive returns defaults when box is empty', () async {
      final loaded = await NotificationSettings.loadFromHive();
      expect(loaded.reminderTime.hour, equals(8));
      expect(loaded.reminderTime.minute, equals(0));
      for (final type in NotificationType.values) {
        expect(loaded.isEnabled(type), isTrue,
            reason: '${type.name} should default to enabled');
      }
    });
  });
}
