import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iwannareadthebiblemore/features/gamification/data/repositories/firestore_user_stats_repository.dart';
import 'package:iwannareadthebiblemore/features/gamification/domain/repositories/user_stats_repository.dart';
import 'package:iwannareadthebiblemore/features/gamification/presentation/providers/gamification_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('allAchievementsProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('returns exactly 7 achievements', () {
      final achievements = container.read(allAchievementsProvider);
      expect(achievements.length, equals(7));
    });

    test('all achievements have non-empty fields', () {
      final achievements = container.read(allAchievementsProvider);
      for (final a in achievements) {
        expect(a.id, isNotEmpty);
        expect(a.title, isNotEmpty);
        expect(a.description, isNotEmpty);
        expect(a.iconEmoji, isNotEmpty);
        expect(a.condition, isNotEmpty);
      }
    });

    test('achievement ids are unique', () {
      final achievements = container.read(allAchievementsProvider);
      final ids = achievements.map((a) => a.id).toSet();
      expect(ids.length, equals(7));
    });

    test('contains expected achievement ids', () {
      final achievements = container.read(allAchievementsProvider);
      final ids = achievements.map((a) => a.id).toSet();
      expect(ids, containsAll([
        'first_flame',
        'month_of_faith',
        'better_together',
        'keepers_nudge',
        'in_the_beginning',
        'red_letters',
        'group_mvp',
      ]));
    });
  });

  group('userAchievementsProvider earned/locked logic', () {
    late ProviderContainer container;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      container = ProviderContainer(overrides: [
        userStatsRepositoryProvider.overrideWithValue(
          FirestoreUserStatsRepository(fakeFirestore),
        ),
      ]);
    });

    tearDown(() => container.dispose());

    test('returns only earned achievements when user has some', () async {
      await fakeFirestore
          .collection('users')
          .doc('user-1')
          .collection('achievements')
          .doc('a1')
          .set({'achievementId': 'first_flame', 'earnedAt': Timestamp.now()});

      final earned = await container
          .read(userAchievementsProvider('user-1').future);

      expect(earned.length, equals(1));
      expect(earned.first.id, equals('first_flame'));
    });

    test('returns empty list when user has no achievements', () async {
      await fakeFirestore.collection('users').doc('user-2').set({});

      final earned = await container
          .read(userAchievementsProvider('user-2').future);

      expect(earned, isEmpty);
    });
  });
}
