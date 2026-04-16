import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/group_member.dart';
import 'package:iwannareadthebiblemore/features/groups/domain/models/plan.dart';

void main() {
  test('Group.fromDoc parses Firestore document correctly', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    await fakeFirestore.collection('groups').doc('g1').set({
      'name': 'Morning Crew',
      'description': 'Daily devotional group',
      'creatorId': 'user1',
      'inviteCode': 'ABC123',
      'memberIds': ['user1', 'user2'],
      'activePlanId': 'plan1',
      'groupStreak': 5,
      'weeklyXpBoard': {'user1': 100, 'user2': 80},
    });
    final doc = await fakeFirestore.collection('groups').doc('g1').get();
    final group = Group.fromDoc(doc);
    expect(group.id, 'g1');
    expect(group.name, 'Morning Crew');
    expect(group.inviteCode, 'ABC123');
    expect(group.memberIds, ['user1', 'user2']);
    expect(group.groupStreak, 5);
    expect(group.weeklyXpBoard['user1'], 100);
    expect(group.activePlanId, 'plan1');
  });

  test('GroupMember.fromDoc parses correctly', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    await fakeFirestore
        .collection('groups')
        .doc('g1')
        .collection('members')
        .doc('user1')
        .set({
      'displayName': 'Alice',
      'photoUrl': 'https://example.com/photo.jpg',
      'todayRead': true,
      'streak': 7,
    });
    final doc = await fakeFirestore
        .collection('groups')
        .doc('g1')
        .collection('members')
        .doc('user1')
        .get();
    final member = GroupMember.fromDoc(doc);
    expect(member.userId, 'user1');
    expect(member.displayName, 'Alice');
    expect(member.todayRead, true);
    expect(member.streak, 7);
  });

  test('ReadingPlan.fromDoc parses correctly', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    await fakeFirestore.collection('plans').doc('p1').set({
      'name': 'Gospel of John',
      'description': 'Read through the Gospel of John',
      'coverEmoji': '✝️',
      'totalDays': 21,
      'tags': ['gospel', 'john'],
      'isCustom': false,
      'readings': [
        {'day': 1, 'book': 'John', 'chapter': '1', 'title': 'The Word'},
      ],
    });
    final doc = await fakeFirestore.collection('plans').doc('p1').get();
    final plan = ReadingPlan.fromDoc(doc);
    expect(plan.name, 'Gospel of John');
    expect(plan.totalDays, 21);
    expect(plan.readings.length, 1);
    expect(plan.readings.first.book, 'John');
  });
}
