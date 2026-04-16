import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/gamification/domain/models/user_stats.dart';
import 'package:iwannareadthebiblemore/features/gamification/domain/services/lamb_state_service.dart';

void main() {
  const baseStats = UserStats(
    xpTotal: 0,
    xpBalance: 0,
    currentStreak: 5,
    longestStreak: 10,
    streakFreezes: 0,
  );

  test('sleeping when lastOpenedApp 4 days ago', () {
    final fourDaysAgo = DateTime.now().subtract(const Duration(days: 4));
    expect(
      LambStateService.fromStats(baseStats, lastOpenedApp: fourDaysAgo),
      LambState.sleeping,
    );
  });

  test('onFire when streak >= 100 and readToday', () {
    const highStreak = UserStats(
      xpTotal: 0, xpBalance: 0, currentStreak: 100, longestStreak: 100, streakFreezes: 0,
    );
    expect(
      LambStateService.fromStats(highStreak, readToday: true),
      LambState.onFire,
    );
  });

  test('excited when streak >= 7 and readToday', () {
    const streak7 = UserStats(
      xpTotal: 0, xpBalance: 0, currentStreak: 7, longestStreak: 7, streakFreezes: 0,
    );
    expect(
      LambStateService.fromStats(streak7, readToday: true),
      LambState.excited,
    );
  });

  test('idle as default when read today with low streak', () {
    expect(
      LambStateService.fromStats(baseStats, readToday: true),
      LambState.idle,
    );
  });

  test('idle when not read today but not close to midnight', () {
    expect(
      LambStateService.fromStats(baseStats, readToday: false),
      anyOf(LambState.idle, LambState.worried),
    );
  });
}
