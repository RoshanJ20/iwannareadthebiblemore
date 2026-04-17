import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/gamification/data/repositories/firestore_user_stats_repository.dart';
import 'package:iwannareadthebiblemore/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:iwannareadthebiblemore/features/gamification/presentation/widgets/mascot_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('mascotStateProvider', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ProviderContainer container;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      container = ProviderContainer(overrides: [
        userStatsRepositoryProvider.overrideWithValue(
          FirestoreUserStatsRepository(fakeFirestore),
        ),
      ]);
    });

    tearDown(() => container.dispose());

    Future<void> setStats(String userId, Map<String, dynamic> data) async {
      await fakeFirestore.collection('users').doc(userId).set(data);
      await Future.delayed(Duration.zero);
    }

    test('returns idle when no data yet (loading)', () {
      final state = container.read(mascotStateProvider('no-user'));
      expect(state, equals(MascotState.idle));
    });

    test('returns sleeping when no lastReadDate', () async {
      await setStats('user-1', {'currentStreak': 0});
      await container.read(userStatsProvider('user-1').future);

      final state = container.read(mascotStateProvider('user-1'));
      expect(state, equals(MascotState.sleeping));
    });

    test('returns idle when streak is low and read today', () async {
      final now = DateTime.now();
      final todayTs = Timestamp.fromDate(now);
      await setStats('user-1', {
        'currentStreak': 3,
        'lastReadDate': todayTs,
      });
      await container.read(userStatsProvider('user-1').future);

      final state = container.read(mascotStateProvider('user-1'));
      expect(state, equals(MascotState.idle));
    });

    test('returns excited when streak >= 7 and read today', () async {
      final now = DateTime.now();
      final todayTs = Timestamp.fromDate(now);
      await setStats('user-2', {
        'currentStreak': 7,
        'lastReadDate': todayTs,
      });
      await container.read(userStatsProvider('user-2').future);

      final state = container.read(mascotStateProvider('user-2'));
      expect(state, equals(MascotState.excited));
    });

    test('returns onFire when streak >= 100 and read today', () async {
      final now = DateTime.now();
      final todayTs = Timestamp.fromDate(now);
      await setStats('user-3', {
        'currentStreak': 100,
        'lastReadDate': todayTs,
      });
      await container.read(userStatsProvider('user-3').future);

      final state = container.read(mascotStateProvider('user-3'));
      expect(state, equals(MascotState.onFire));
    });

    test('returns sad when streak broken (currentStreak=0, read yesterday)', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await setStats('user-4', {
        'currentStreak': 0,
        'lastReadDate': Timestamp.fromDate(yesterday),
      });
      await container.read(userStatsProvider('user-4').future);

      final state = container.read(mascotStateProvider('user-4'));
      expect(state, equals(MascotState.sad));
    });

    test('returns sleeping when streak=0 and read 3+ days ago', () async {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      await setStats('user-5', {
        'currentStreak': 0,
        'lastReadDate': Timestamp.fromDate(threeDaysAgo),
      });
      await container.read(userStatsProvider('user-5').future);

      final state = container.read(mascotStateProvider('user-5'));
      expect(state, equals(MascotState.sleeping));
    });
  });
}
