import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iwannareadthebiblemore/features/groups/data/repositories/firestore_group_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/data/repositories/firestore_plan_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/data/repositories/firestore_user_plan_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/data/seed_plans.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/repositories/group_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/repositories/plan_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/repositories/user_plan_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/presentation/providers/groups_providers.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

ProviderContainer _makeContainer() {
  final fakeFirestore = FakeFirebaseFirestore();
  final mockFunctions = MockFirebaseFunctions();
  final mockCallable = MockHttpsCallable();
  when(() => mockFunctions.httpsCallable(any())).thenReturn(mockCallable);

  final groupRepo =
      FirestoreGroupRepository(fakeFirestore, mockFunctions);
  final planRepo = FirestorePlanRepository(fakeFirestore);
  final userPlanRepo = FirestoreUserPlanRepository(fakeFirestore);

  return ProviderContainer(
    overrides: [
      groupRepositoryProvider.overrideWithValue(groupRepo),
      planRepositoryProvider.overrideWithValue(planRepo),
      userPlanRepositoryProvider.overrideWithValue(userPlanRepo),
    ],
  );
}

void main() {
  group('groupRepositoryProvider', () {
    test('provides a FirestoreGroupRepository', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final repo = container.read(groupRepositoryProvider);
      expect(repo, isA<FirestoreGroupRepository>());
      expect(repo, isA<GroupRepository>());
    });
  });

  group('planRepositoryProvider', () {
    test('provides a FirestorePlanRepository', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final repo = container.read(planRepositoryProvider);
      expect(repo, isA<FirestorePlanRepository>());
      expect(repo, isA<PlanRepository>());
    });
  });

  group('userPlanRepositoryProvider', () {
    test('provides a FirestoreUserPlanRepository', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final repo = container.read(userPlanRepositoryProvider);
      expect(repo, isA<FirestoreUserPlanRepository>());
      expect(repo, isA<UserPlanRepository>());
    });
  });

  group('prebuiltPlansProvider', () {
    test('returns the 5 seed plans', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final plans = container.read(prebuiltPlansProvider);
      expect(plans, equals(seedPlans));
      expect(plans.length, 5);
    });
  });

  group('todayUserPlanProvider', () {
    test('returns null when no plans exist', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final plan = container.read(todayUserPlanProvider('nonexistent'));
      expect(plan, isNull);
    });
  });
}
