import 'package:flutter/material.dart';
import '../models/user_stats.dart';

enum LambState { idle, excited, celebrating, worried, sad, sleeping, onFire }

class LambStateService {
  static LambState fromStats(
    UserStats stats, {
    bool readToday = false,
    DateTime? lastOpenedApp,
  }) {
    final now = DateTime.now();
    if (lastOpenedApp != null &&
        now.difference(lastOpenedApp).inDays >= 3) {
      return LambState.sleeping;
    }
    if (stats.currentStreak >= 100 && readToday) return LambState.onFire;
    if (stats.currentStreak >= 7 && readToday) return LambState.excited;
    final midnight = DateTime(now.year, now.month, now.day + 1);
    if (!readToday && midnight.difference(now).inHours < 2) {
      return LambState.worried;
    }
    return LambState.idle;
  }

  static String lottieAssetPath(LambState state) => switch (state) {
        LambState.idle => 'assets/lottie/lamb_idle.json',
        LambState.excited => 'assets/lottie/lamb_excited.json',
        LambState.celebrating => 'assets/lottie/lamb_celebrating.json',
        LambState.worried => 'assets/lottie/lamb_worried.json',
        LambState.sad => 'assets/lottie/lamb_sad.json',
        LambState.sleeping => 'assets/lottie/lamb_sleeping.json',
        LambState.onFire => 'assets/lottie/lamb_onfire.json',
      };

  static Color fallbackColor(LambState state) => switch (state) {
        LambState.idle => const Color(0xFFF5F0E8),
        LambState.excited => const Color(0xFFFF9800),
        LambState.celebrating => const Color(0xFFFFD700),
        LambState.worried => const Color(0xFFFF5722),
        LambState.sad => const Color(0xFF9E9E9E),
        LambState.sleeping => const Color(0xFF90A4AE),
        LambState.onFire => const Color(0xFFFF1744),
      };
}
