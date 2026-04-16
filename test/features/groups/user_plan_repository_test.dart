import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iwannareadthebiblemore/features/groups/data/repositories/firestore_user_plan_repository.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/entities/user_plan.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreUserPlanRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = FirestoreUserPlanRepository(fakeFirestore);
  });

  UserPlan _makePlan({
    String userId = 'user1',
    String planId = 'seed_genesis_journey',
    String? groupId,
    bool todayRead = false,
    bool isComplete = false,
    int currentDay = 1,
  }) {
    return UserPlan(
      id: '',
      userId: userId,
      planId: planId,
      groupId: groupId,
      startDate: DateTime(2025, 1, 1),
      currentDay: currentDay,
      completedDays: [],
      isComplete: isComplete,
      todayChapter: 'Genesis 1',
      todayRead: todayRead,
    );
  }

  group('createUserPlan', () {
    test('persists plan and returns it with a non-empty id', () async {
      final plan = _makePlan();
      final created = await repo.createUserPlan(plan);

      expect(created.id, isNotEmpty);
      expect(created.userId, 'user1');
      expect(created.planId, 'seed_genesis_journey');
      expect(created.todayRead, isFalse);

      final snap = await fakeFirestore.collection('userPlans').get();
      expect(snap.docs.length, 1);
    });

    test('stores groupId when provided', () async {
      final plan = _makePlan(groupId: 'group1');
      final created = await repo.createUserPlan(plan);

      final snap = await fakeFirestore
          .collection('userPlans')
          .doc(created.id)
          .get();
      expect(snap.data()!['groupId'], 'group1');
    });

    test('stores null groupId for solo plan', () async {
      final plan = _makePlan();
      final created = await repo.createUserPlan(plan);

      final snap = await fakeFirestore
          .collection('userPlans')
          .doc(created.id)
          .get();
      expect(snap.data()!['groupId'], isNull);
    });
  });

  group('markTodayRead', () {
    test('sets todayRead to true on the document', () async {
      final plan = _makePlan();
      final created = await repo.createUserPlan(plan);

      await repo.markTodayRead(created.id);

      final snap = await fakeFirestore
          .collection('userPlans')
          .doc(created.id)
          .get();
      expect(snap.data()!['todayRead'], isTrue);
    });
  });

  group('watchUserPlans', () {
    test('streams plans for the given userId', () async {
      await repo.createUserPlan(_makePlan(userId: 'user1'));
      await repo.createUserPlan(_makePlan(userId: 'user1'));
      await repo.createUserPlan(_makePlan(userId: 'user2'));

      final plans = await repo.watchUserPlans('user1').first;
      expect(plans.length, 2);
      expect(plans.every((p) => p.userId == 'user1'), isTrue);
    });

    test('returns empty list when user has no plans', () async {
      final plans = await repo.watchUserPlans('unknown').first;
      expect(plans, isEmpty);
    });
  });

  group('deleteUserPlan', () {
    test('removes the document from Firestore', () async {
      final created = await repo.createUserPlan(_makePlan());
      await repo.deleteUserPlan(created.id);

      final snap = await fakeFirestore
          .collection('userPlans')
          .doc(created.id)
          .get();
      expect(snap.exists, isFalse);
    });
  });

  group('UserPlan.fromFirestore', () {
    test('parses Timestamp fields correctly', () {
      final ts = Timestamp.fromDate(DateTime(2025, 6, 15));
      final data = {
        'userId': 'u1',
        'planId': 'p1',
        'groupId': null,
        'startDate': ts,
        'currentDay': 3,
        'completedDays': [1, 2],
        'isComplete': false,
        'todayChapter': 'Genesis 3',
        'todayRead': false,
      };
      final plan = UserPlan.fromFirestore('doc1', data);
      expect(plan.startDate, DateTime(2025, 6, 15));
      expect(plan.completedDays, [1, 2]);
      expect(plan.currentDay, 3);
    });
  });
}
