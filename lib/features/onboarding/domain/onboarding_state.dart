import 'package:flutter/material.dart';

class OnboardingData {
  const OnboardingData({
    this.goalMinutes = 10,
    this.selectedPlanId,
    this.reminderTime = const TimeOfDay(hour: 8, minute: 0),
    required this.timezone,
  });

  final int goalMinutes;
  final String? selectedPlanId;
  final TimeOfDay reminderTime;
  final String timezone;

  OnboardingData copyWith({
    int? goalMinutes,
    Object? selectedPlanId = _sentinel,
    TimeOfDay? reminderTime,
    String? timezone,
  }) {
    return OnboardingData(
      goalMinutes: goalMinutes ?? this.goalMinutes,
      selectedPlanId: selectedPlanId == _sentinel
          ? this.selectedPlanId
          : selectedPlanId as String?,
      reminderTime: reminderTime ?? this.reminderTime,
      timezone: timezone ?? this.timezone,
    );
  }
}

const _sentinel = Object();
