import 'package:flutter/material.dart';

enum StreakTier { grey, orange, red, gold, diamond }

extension StreakTierX on StreakTier {
  static StreakTier fromStreak(int streak) {
    if (streak == 0) return StreakTier.grey;
    if (streak < 7) return StreakTier.orange;
    if (streak < 30) return StreakTier.red;
    if (streak < 100) return StreakTier.gold;
    return StreakTier.diamond;
  }

  Color get color => switch (this) {
        StreakTier.grey => const Color(0xFF9E9E9E),
        StreakTier.orange => const Color(0xFFFF9800),
        StreakTier.red => const Color(0xFFF44336),
        StreakTier.gold => const Color(0xFFFFD700),
        StreakTier.diamond => const Color(0xFF42A5F5),
      };
}
