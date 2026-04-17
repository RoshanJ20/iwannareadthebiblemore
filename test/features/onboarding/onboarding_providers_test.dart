import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/onboarding/presentation/providers/onboarding_providers.dart';

void main() {
  group('OnboardingNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('initial state has defaults', () {
      final state = container.read(onboardingProvider);

      expect(state.goalMinutes, 10);
      expect(state.selectedPlanId, isNull);
      expect(state.reminderTime, const TimeOfDay(hour: 8, minute: 0));
      expect(state.timezone, isNotEmpty);
    });

    test('setGoalMinutes updates goal', () {
      container.read(onboardingProvider.notifier).setGoalMinutes(5);
      expect(container.read(onboardingProvider).goalMinutes, 5);
    });

    test('setGoalMinutes to 20 updates goal', () {
      container.read(onboardingProvider.notifier).setGoalMinutes(20);
      expect(container.read(onboardingProvider).goalMinutes, 20);
    });

    test('setSelectedPlanId updates plan', () {
      container
          .read(onboardingProvider.notifier)
          .setSelectedPlanId('seed_genesis_journey');
      expect(
          container.read(onboardingProvider).selectedPlanId,
          'seed_genesis_journey');
    });

    test('setSelectedPlanId can clear plan with null', () {
      container
          .read(onboardingProvider.notifier)
          .setSelectedPlanId('some_plan');
      container.read(onboardingProvider.notifier).setSelectedPlanId(null);
      expect(container.read(onboardingProvider).selectedPlanId, isNull);
    });

    test('setReminderTime updates reminder', () {
      const newTime = TimeOfDay(hour: 20, minute: 45);
      container.read(onboardingProvider.notifier).setReminderTime(newTime);
      expect(container.read(onboardingProvider).reminderTime, newTime);
    });

    test('multiple updates do not interfere', () {
      final notifier = container.read(onboardingProvider.notifier);
      notifier.setGoalMinutes(15);
      notifier.setSelectedPlanId('plan_abc');
      notifier.setReminderTime(const TimeOfDay(hour: 7, minute: 0));

      final state = container.read(onboardingProvider);
      expect(state.goalMinutes, 15);
      expect(state.selectedPlanId, 'plan_abc');
      expect(state.reminderTime, const TimeOfDay(hour: 7, minute: 0));
    });
  });
}
