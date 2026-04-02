import 'package:flutter/services.dart';

/// Named haptic feedback methods so every interaction has a deliberate feel.
abstract class HapticsService {
  /// Primary action: "Read Now", check-in mark, XP store purchase.
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Confirmation: streak milestone, achievement unlocked (3-beat).
  static Future<void> heavy() => HapticFeedback.heavyImpact();

  /// Light acknowledgement: nudge sent, tab switch.
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Streak broken: single dull thud.
  static Future<void> error() => HapticFeedback.vibrate();

  /// Success pattern: mark-read check-in (heavy + short delay + light).
  static Future<void> success() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  /// Milestone pattern: 3 beats (heavy, medium, heavy).
  static Future<void> milestone() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
}
