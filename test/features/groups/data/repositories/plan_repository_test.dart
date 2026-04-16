import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/groups/data/repositories/plan_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late PlanRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = PlanRepository(fakeFirestore, 'user1');
  });

  test('startPlan creates userPlan document', () async {
    await fakeFirestore.collection('plans').doc('p1').set({
      'name': 'Genesis',
      'description': 'Read Genesis',
      'coverEmoji': '📖',
      'totalDays': 10,
      'tags': ['beginners'],
      'isCustom': false,
      'readings': [
        {'day': 1, 'book': 'Genesis', 'chapter': '1', 'title': 'Creation'},
      ],
    });
    final userPlanId = await repo.startPlan(planId: 'p1');
    final doc =
        await fakeFirestore.collection('userPlans').doc(userPlanId).get();
    expect(doc.exists, true);
    final data = doc.data()!;
    expect(data['userId'], 'user1');
    expect(data['planId'], 'p1');
    expect(data['currentDay'], 1);
    expect(data['isComplete'], false);
    expect(data['todayRead'], false);
    expect(data['todayChapter'], 'Genesis 1');
    expect(data['groupId'], isNull);
  });

  test('startPlan with groupId sets activePlanId on group', () async {
    await fakeFirestore.collection('plans').doc('p1').set({
      'name': 'Genesis',
      'description': '',
      'coverEmoji': '📖',
      'totalDays': 10,
      'tags': [],
      'isCustom': false,
      'readings': [],
    });
    await fakeFirestore.collection('groups').doc('g1').set({
      'name': 'My Group',
      'activePlanId': null,
      'memberIds': ['user1'],
    });
    await repo.startPlan(planId: 'p1', groupId: 'g1');
    final groupDoc =
        await fakeFirestore.collection('groups').doc('g1').get();
    expect(groupDoc.data()!['activePlanId'], 'p1');
  });

  test('markTodayRead sets todayRead to true', () async {
    await fakeFirestore.collection('userPlans').doc('up1').set({
      'userId': 'user1',
      'planId': 'p1',
      'currentDay': 1,
      'todayRead': false,
      'isComplete': false,
      'completedDays': [],
      'todayChapter': 'Genesis 1',
    });
    await repo.markTodayRead('up1');
    final doc =
        await fakeFirestore.collection('userPlans').doc('up1').get();
    expect(doc.data()!['todayRead'], true);
  });

  test('startPlan throws if plan not found', () async {
    expect(() => repo.startPlan(planId: 'nonexistent'), throwsException);
  });

  test('watchPlanLibrary streams non-custom plans', () async {
    await fakeFirestore.collection('plans').doc('official').set({
      'name': 'Official Plan',
      'description': '',
      'coverEmoji': '📖',
      'totalDays': 7,
      'tags': [],
      'isCustom': false,
      'readings': [],
    });
    await fakeFirestore.collection('plans').doc('custom').set({
      'name': 'My Custom Plan',
      'description': '',
      'coverEmoji': '✨',
      'totalDays': 5,
      'tags': [],
      'isCustom': true,
      'readings': [],
    });
    final plans = await repo.watchPlanLibrary().first;
    expect(plans.length, 1);
    expect(plans.first.name, 'Official Plan');
  });
}
