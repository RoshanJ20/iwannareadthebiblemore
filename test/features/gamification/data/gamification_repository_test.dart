import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/gamification/data/gamification_repository.dart';
import 'package:iwannareadthebiblemore/features/gamification/domain/models/user_stats.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late GamificationRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = GamificationRepository(fakeFirestore, 'test-user');
  });

  test('watchUserStats emits empty when doc does not exist', () async {
    final stats = await repo.watchUserStats().first;
    expect(stats.xpTotal, 0);
    expect(stats.currentStreak, 0);
  });

  test('watchUserStats emits correct values from doc', () async {
    await fakeFirestore.collection('users').doc('test-user').set({
      'xpTotal': 1000,
      'xpBalance': 750,
      'currentStreak': 14,
      'longestStreak': 30,
      'streakFreezes': 2,
    });

    final stats = await repo.watchUserStats().first;
    expect(stats.xpTotal, 1000);
    expect(stats.xpBalance, 750);
    expect(stats.currentStreak, 14);
    expect(stats.longestStreak, 30);
    expect(stats.streakFreezes, 2);
  });

  test('watchAchievements returns all 7 with earned/unearned correctly', () async {
    final now = Timestamp.now();
    await fakeFirestore
        .collection('users')
        .doc('test-user')
        .collection('achievements')
        .doc('first_flame')
        .set({'earnedAt': now});

    final achievements = await repo.watchAchievements().first;
    expect(achievements.length, 7);

    final firstFlame = achievements.firstWhere((a) => a.id == 'first_flame');
    expect(firstFlame.earnedAt, isNotNull);

    final unearned = achievements.where((a) => a.id != 'first_flame').toList();
    expect(unearned.every((a) => a.earnedAt == null), isTrue);
  });
}
