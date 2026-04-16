import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/onboarding_state.dart';

class OnboardingNotifier extends StateNotifier<OnboardingData> {
  OnboardingNotifier()
      : super(OnboardingData(
          timezone: DateTime.now().timeZoneName,
        ));

  void setGoalMinutes(int minutes) {
    state = state.copyWith(goalMinutes: minutes);
  }

  void setSelectedPlanId(String? planId) {
    state = state.copyWith(selectedPlanId: planId);
  }

  void setReminderTime(TimeOfDay time) {
    state = state.copyWith(reminderTime: time);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingData>(
  (_) => OnboardingNotifier(),
);
