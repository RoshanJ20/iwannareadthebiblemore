import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/gamification/domain/models/streak_tier.dart';

void main() {
  group('StreakTierX.fromStreak', () {
    test('0 → grey', () {
      expect(StreakTierX.fromStreak(0), StreakTier.grey);
      expect(StreakTierX.fromStreak(0).color, const Color(0xFF9E9E9E));
    });
    test('3 → orange', () {
      expect(StreakTierX.fromStreak(3), StreakTier.orange);
      expect(StreakTierX.fromStreak(3).color, const Color(0xFFFF9800));
    });
    test('7 → red', () {
      expect(StreakTierX.fromStreak(7), StreakTier.red);
    });
    test('30 → gold', () {
      expect(StreakTierX.fromStreak(30), StreakTier.gold);
      expect(StreakTierX.fromStreak(30).color, const Color(0xFFFFD700));
    });
    test('100 → diamond', () {
      expect(StreakTierX.fromStreak(100), StreakTier.diamond);
    });
  });
}
