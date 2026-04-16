import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwannareadthebiblemore/features/groups/data/repositories/group_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late GroupRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = GroupRepository(fakeFirestore, 'user1');
  });

  test('createGroup writes correct Firestore document', () async {
    final groupId =
        await repo.createGroup(name: 'Bible Study', description: 'A great group');
    final doc = await fakeFirestore.collection('groups').doc(groupId).get();
    expect(doc.exists, true);
    final data = doc.data()!;
    expect(data['name'], 'Bible Study');
    expect(data['creatorId'], 'user1');
    expect(data['memberIds'], contains('user1'));
    expect(data['groupStreak'], 0);
    expect((data['inviteCode'] as String).length, 6);
  });

  test('createGroup creates member subcollection doc for creator', () async {
    final groupId = await repo.createGroup(name: 'Test Group', description: '');
    final memberDoc = await fakeFirestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc('user1')
        .get();
    expect(memberDoc.exists, true);
    expect(memberDoc.data()!['todayRead'], false);
  });

  test('joinGroup adds userId to memberIds', () async {
    await fakeFirestore.collection('groups').doc('g1').set({
      'name': 'Existing Group',
      'description': '',
      'creatorId': 'otherUser',
      'inviteCode': 'JOIN01',
      'memberIds': ['otherUser'],
      'groupStreak': 0,
      'weeklyXpBoard': {},
    });
    await repo.joinGroup('JOIN01');
    final doc = await fakeFirestore.collection('groups').doc('g1').get();
    expect(doc.data()!['memberIds'], contains('user1'));
  });

  test('joinGroup throws if group not found', () async {
    expect(() => repo.joinGroup('BADCOD'), throwsException);
  });

  test('joinGroup throws if already a member', () async {
    await fakeFirestore.collection('groups').doc('g1').set({
      'name': 'Group',
      'description': '',
      'creatorId': 'user1',
      'inviteCode': 'MYMEMB',
      'memberIds': ['user1'],
      'groupStreak': 0,
      'weeklyXpBoard': {},
    });
    expect(() => repo.joinGroup('MYMEMB'), throwsException);
  });

  test('joinGroup throws if group is full (20 members)', () async {
    final members = List.generate(20, (i) => 'user$i');
    await fakeFirestore.collection('groups').doc('g1').set({
      'name': 'Full Group',
      'description': '',
      'creatorId': 'user0',
      'inviteCode': 'FULL01',
      'memberIds': members,
      'groupStreak': 0,
      'weeklyXpBoard': {},
    });
    expect(() => repo.joinGroup('FULL01'), throwsException);
  });

  test('watchMyGroups streams groups where userId is in memberIds', () async {
    await fakeFirestore.collection('groups').doc('g1').set({
      'name': 'My Group',
      'description': '',
      'creatorId': 'user1',
      'inviteCode': 'MYGRP1',
      'memberIds': ['user1'],
      'groupStreak': 0,
      'weeklyXpBoard': {},
    });
    await fakeFirestore.collection('groups').doc('g2').set({
      'name': 'Other Group',
      'description': '',
      'creatorId': 'otherUser',
      'inviteCode': 'OTHR01',
      'memberIds': ['otherUser'],
      'groupStreak': 0,
      'weeklyXpBoard': {},
    });
    final groups = await repo.watchMyGroups().first;
    expect(groups.length, 1);
    expect(groups.first.name, 'My Group');
  });
}
