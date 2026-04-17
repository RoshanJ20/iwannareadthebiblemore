import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/onboarding/domain/onboarding_state.dart';

void main() {
  group('OnboardingData', () {
    test('defaults are applied correctly', () {
      const tz = 'UTC';
      const data = OnboardingData(timezone: tz);

      expect(data.goalMinutes, 10);
      expect(data.selectedPlanId, isNull);
      expect(data.reminderTime, const TimeOfDay(hour: 8, minute: 0));
      expect(data.timezone, tz);
    });

    test('copyWith updates goalMinutes', () {
      const data = OnboardingData(timezone: 'UTC');
      final updated = data.copyWith(goalMinutes: 20);

      expect(updated.goalMinutes, 20);
      expect(updated.selectedPlanId, isNull);
      expect(updated.reminderTime, data.reminderTime);
      expect(updated.timezone, data.timezone);
    });

    test('copyWith updates selectedPlanId', () {
      const data = OnboardingData(timezone: 'UTC');
      final updated = data.copyWith(selectedPlanId: 'plan_123');

      expect(updated.selectedPlanId, 'plan_123');
      expect(updated.goalMinutes, data.goalMinutes);
    });

    test('copyWith updates reminderTime', () {
      const data = OnboardingData(timezone: 'UTC');
      const newTime = TimeOfDay(hour: 21, minute: 30);
      final updated = data.copyWith(reminderTime: newTime);

      expect(updated.reminderTime, newTime);
      expect(updated.goalMinutes, data.goalMinutes);
    });

    test('copyWith updates timezone', () {
      const data = OnboardingData(timezone: 'UTC');
      final updated = data.copyWith(timezone: 'America/New_York');

      expect(updated.timezone, 'America/New_York');
      expect(updated.goalMinutes, data.goalMinutes);
    });

    test('copyWith with no args returns identical values', () {
      const data = OnboardingData(
        timezone: 'Europe/London',
        goalMinutes: 15,
        selectedPlanId: 'plan_abc',
        reminderTime: TimeOfDay(hour: 9, minute: 0),
      );
      final copy = data.copyWith();

      expect(copy.goalMinutes, data.goalMinutes);
      expect(copy.selectedPlanId, data.selectedPlanId);
      expect(copy.reminderTime, data.reminderTime);
      expect(copy.timezone, data.timezone);
    });
  });
}
