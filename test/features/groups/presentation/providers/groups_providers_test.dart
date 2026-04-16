import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:iwannareadthebiblemore/features/groups/data/repositories/group_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/data/repositories/plan_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';

class MockUser extends Mock implements User {
  @override
  String get uid => 'testUser';
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  test('myGroupsProvider emits groups for authenticated user', () async {
    await fakeFirestore.collection('groups').doc('g1').set({
      'name': 'Test Group',
      'description': '',
      'creatorId': 'testUser',
      'inviteCode': 'TEST01',
      'memberIds': ['testUser'],
      'groupStreak': 0,
      'weeklyXpBoard': {},
    });

    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(
          GroupRepository(fakeFirestore, 'testUser'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final groups = await container.read(myGroupsProvider.future);
    expect(groups.length, 1);
    expect(groups.first.name, 'Test Group');
  });

  test('planLibraryProvider emits official plans', () async {
    await fakeFirestore.collection('plans').doc('p1').set({
      'name': 'Official Plan',
      'description': '',
      'coverEmoji': '📖',
      'totalDays': 7,
      'tags': [],
      'isCustom': false,
      'readings': [],
    });

    final container = ProviderContainer(
      overrides: [
        planRepositoryProvider.overrideWithValue(
          PlanRepository(fakeFirestore, 'testUser'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final plans = await container.read(planLibraryProvider.future);
    expect(plans.length, 1);
    expect(plans.first.name, 'Official Plan');
  });
}
