import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/notifications/domain/entities/notification_type.dart';

void main() {
  group('NotificationType', () {
    test('all 7 types exist', () {
      expect(NotificationType.values.length, equals(7));
    });

    test('value strings match spec', () {
      expect(NotificationType.dailyReminder.value, equals('daily_reminder'));
      expect(NotificationType.streakAtRisk.value, equals('streak_at_risk'));
      expect(NotificationType.friendNudge.value, equals('friend_nudge'));
      expect(NotificationType.groupActivity.value, equals('group_activity'));
      expect(NotificationType.milestone.value, equals('milestone'));
      expect(NotificationType.planCompletion.value, equals('plan_completion'));
      expect(
          NotificationType.weeklyLeaderboard.value, equals('weekly_leaderboard'));
    });

    test('all values have non-empty displayName', () {
      for (final type in NotificationType.values) {
        expect(type.displayName, isNotEmpty,
            reason: '${type.name} must have a displayName');
      }
    });

    test('fromValue round-trips for all types', () {
      for (final type in NotificationType.values) {
        expect(
          NotificationType.fromValue(type.value),
          equals(type),
          reason: 'fromValue(${type.value}) should return $type',
        );
      }
    });

    test('fromValue returns null for unknown string', () {
      expect(NotificationType.fromValue('unknown_type'), isNull);
      expect(NotificationType.fromValue(''), isNull);
    });

    test('contains dailyReminder', () {
      expect(NotificationType.values, contains(NotificationType.dailyReminder));
    });

    test('contains streakAtRisk', () {
      expect(NotificationType.values, contains(NotificationType.streakAtRisk));
    });

    test('contains friendNudge', () {
      expect(NotificationType.values, contains(NotificationType.friendNudge));
    });

    test('contains groupActivity', () {
      expect(NotificationType.values, contains(NotificationType.groupActivity));
    });

    test('contains milestone', () {
      expect(NotificationType.values, contains(NotificationType.milestone));
    });

    test('contains planCompletion', () {
      expect(NotificationType.values, contains(NotificationType.planCompletion));
    });

    test('contains weeklyLeaderboard', () {
      expect(
          NotificationType.values, contains(NotificationType.weeklyLeaderboard));
    });
  });
}
