import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/gamification/data/repositories/firestore_user_stats_repository.dart';
import 'package:iwannareadthebiblemore/features/gamification/domain/entities/user_stats.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirestoreUserStatsRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreUserStatsRepository repo;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repo = FirestoreUserStatsRepository(fakeFirestore);
    });

    test('streams UserStats with default zeros when doc is empty', () async {
      await fakeFirestore.collection('users').doc('user-1').set({});

      final stats = await repo.watchUserStats('user-1').first;

      expect(stats.userId, equals('user-1'));
      expect(stats.xpTotal, equals(0));
      expect(stats.xpBalance, equals(0));
      expect(stats.currentStreak, equals(0));
      expect(stats.longestStreak, equals(0));
      expect(stats.streakFreezes, equals(0));
      expect(stats.lastReadDate, isNull);
    });

    test('streams UserStats with correct values from Firestore', () async {
      final now = Timestamp.now();
      await fakeFirestore.collection('users').doc('user-2').set({
        'xpTotal': 1500,
        'xpBalance': 800,
        'currentStreak': 12,
        'longestStreak': 30,
        'lastReadDate': now,
        'streakFreezes': 2,
      });

      final stats = await repo.watchUserStats('user-2').first;

      expect(stats.xpTotal, equals(1500));
      expect(stats.xpBalance, equals(800));
      expect(stats.currentStreak, equals(12));
      expect(stats.longestStreak, equals(30));
      expect(stats.streakFreezes, equals(2));
      expect(stats.lastReadDate, isNotNull);
    });

    test('streams updated UserStats when Firestore doc changes', () async {
      await fakeFirestore.collection('users').doc('user-3').set({
        'xpTotal': 100,
        'currentStreak': 3,
      });

      final emitted = <UserStats>[];
      final sub = repo.watchUserStats('user-3').listen(emitted.add);

      await Future.delayed(Duration.zero);
      expect(emitted, isNotEmpty);
      expect(emitted.last.xpTotal, equals(100));

      await fakeFirestore.collection('users').doc('user-3').update({
        'xpTotal': 150,
        'currentStreak': 4,
      });

      await Future.delayed(Duration.zero);
      expect(emitted.last.xpTotal, equals(150));
      expect(emitted.last.currentStreak, equals(4));

      await sub.cancel();
    });

    test('watchEarnedAchievementIds returns empty list when no achievements', () async {
      await fakeFirestore.collection('users').doc('user-4').set({});

      final ids = await repo.watchEarnedAchievementIds('user-4').first;
      expect(ids, isEmpty);
    });

    test('watchEarnedAchievementIds returns achievement ids', () async {
      await fakeFirestore
          .collection('users')
          .doc('user-5')
          .collection('achievements')
          .doc('ach-1')
          .set({'achievementId': 'first_flame', 'earnedAt': Timestamp.now()});

      await fakeFirestore
          .collection('users')
          .doc('user-5')
          .collection('achievements')
          .doc('ach-2')
          .set({'achievementId': 'month_of_faith', 'earnedAt': Timestamp.now()});

      final ids = await repo.watchEarnedAchievementIds('user-5').first;
      expect(ids, containsAll(['first_flame', 'month_of_faith']));
      expect(ids.length, equals(2));
    });
  });
}
